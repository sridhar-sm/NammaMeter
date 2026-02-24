import Foundation
import Observation
import OSLog
@preconcurrency import WatchConnectivity

private let logger = Logger(subsystem: "sridharsm.NammaMeter", category: "PhoneConnectivity")

@MainActor
@Observable
final class PhoneConnectivityService: NSObject {

  private let watchConnectivityEnabled: Bool
  private(set) var isWatchReachable = false
  private var lastTripUpdateSent: Date = .distantPast
  private let throttleInterval: TimeInterval = 2.0

  // Last-sent values for threshold-based change detection
  private var lastSentState: String = ""
  private var lastSentFare: Double = 0
  private var lastSentDistanceMeters: Double = 0
  private var lastSentElapsedSeconds: TimeInterval = 0
  private var lastSentWaitingSeconds: TimeInterval = 0
  private var lastSentRoadName: String = ""

  // Store references for handling Watch commands (set via configure)
  private var meterStore: MeterStore?
  private var settingsStore: SettingsStore?
  private var tripStore: TripStore?

  override init() {
    watchConnectivityEnabled = !TestEnvironment.isRunningTests
    super.init()
    guard watchConnectivityEnabled else {
      logger.info("Skipping WatchConnectivity activation in test environment")
      return
    }
    guard WCSession.isSupported() else {
      logger.info("WatchConnectivity not supported on this device")
      return
    }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  /// Wire up store references so Watch commands can be handled.
  func configure(meterStore: MeterStore, settingsStore: SettingsStore, tripStore: TripStore) {
    self.meterStore = meterStore
    self.settingsStore = settingsStore
    self.tripStore = tripStore
  }

  // MARK: - Send Config

  func sendConfig(from settingsStore: SettingsStore) {
    guard watchConnectivityEnabled else { return }
    guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }

    let cityInfo = settingsStore.activeCityInfo
    let profile = settingsStore.activeProfileForCurrentSelection

    let favoriteSummaries: [WatchFavoriteSummary] = settingsStore.whatIfFavorites.compactMap { fav in
      guard let favProfile = settingsStore.whatIfProfile(for: fav) else { return nil }
      return WatchFavoriteSummary(
        cityName: favProfile.name,
        vehicleType: favProfile.vehicleType,
        vehicleDisplayName: VehicleTypeCatalog.displayName(for: favProfile.vehicleType),
        currencyCode: favProfile.cityKey.currencyCode
      )
    }

    let config = WatchConfig(
      cityName: cityInfo.cityName,
      vehicleType: profile?.vehicleType ?? "",
      vehicleDisplayName: VehicleTypeCatalog.displayName(for: profile?.vehicleType ?? ""),
      currencyCode: profile?.cityKey.currencyCode ?? "INR",
      meterFaceStyle: settingsStore.meterFaceStyle,
      digitWheelStyle: settingsStore.digitWheelStyle,
      whatIfFavorites: favoriteSummaries
    )

    do {
      let data = try JSONEncoder().encode(config)
      guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
      try WCSession.default.updateApplicationContext([WatchMessageKey.config: dict])
      // Also push via sendMessage for immediate delivery when Watch is active
      if isWatchReachable {
        WCSession.default.sendMessage(
          [WatchMessageKey.config: dict],
          replyHandler: nil,
          errorHandler: { _ in }
        )
      }
      logger.debug("Sent config to Watch: \(cityInfo.cityName)")
    } catch {
      logger.error("Failed to send config: \(error.localizedDescription)")
    }
  }

  // MARK: - Send Trip Update

  /// Send trip update to Watch if observable changes exceed display thresholds.
  /// Pass `force: true` for state transitions (start/stop/reset) to bypass throttle and thresholds.
  func sendTripUpdate(from meterStore: MeterStore, settingsStore: SettingsStore, force: Bool = false) {
    guard watchConnectivityEnabled else { return }
    guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
    guard isWatchReachable else { return }

    let now = Date()
    let state = meterStore.tripState.wireValue
    let fare = meterStore.fare
    let distance = meterStore.distanceMeters
    let elapsed = meterStore.elapsed
    let waiting = meterStore.waitingDuration
    let roadName = meterStore.currentRoadName

    if !force {
      // Enforce minimum interval
      guard now.timeIntervalSince(lastTripUpdateSent) >= throttleInterval else { return }

      // Only send if an observable change exceeds display thresholds
      let stateChanged = state != lastSentState
      let fareChanged = abs(fare - lastSentFare) > 0.10          // > 10 paise
      let distanceChanged = abs(distance - lastSentDistanceMeters) >= 100  // >= 0.1 km
      let timeChanged = abs(elapsed - lastSentElapsedSeconds) >= 60        // >= 1 minute
      let waitChanged = abs(waiting - lastSentWaitingSeconds) >= 60        // >= 1 minute
      let roadChanged = roadName != lastSentRoadName

      guard stateChanged || fareChanged || distanceChanged || timeChanged || waitChanged || roadChanged else { return }
    }

    // Update tracking
    lastTripUpdateSent = now
    lastSentState = state
    lastSentFare = fare
    lastSentDistanceMeters = distance
    lastSentElapsedSeconds = elapsed
    lastSentWaitingSeconds = waiting
    lastSentRoadName = roadName

    let cityInfo = settingsStore.activeCityInfo
    let whatIfResults: [WatchWhatIfResult] = meterStore.whatIfResults.map { result in
      WatchWhatIfResult(
        cityName: result.cityName,
        vehicleType: result.vehicleType,
        vehicleDisplayName: VehicleTypeCatalog.displayName(for: result.vehicleType),
        currencyCode: result.currencyCode,
        fare: result.fareInNativeCurrency
      )
    }

    let update = WatchTripUpdate(
      timestamp: now,
      state: state,
      fare: fare,
      currencyCode: meterStore.activeCurrencyCode,
      distanceMeters: distance,
      elapsedSeconds: elapsed,
      waitingSeconds: waiting,
      currentSpeedKph: meterStore.currentSpeedKph,
      isWaiting: meterStore.isWaiting,
      isNight: meterStore.conditions.isNight,
      cityName: cityInfo.cityName,
      vehicleType: settingsStore.selectedVehicleType ?? "",
      currentRoadName: roadName,
      whatIfResults: whatIfResults
    )

    do {
      let data = try JSONEncoder().encode(update)
      guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
      WCSession.default.sendMessage(
        [WatchMessageKey.tripUpdate: dict],
        replyHandler: nil,
        errorHandler: { error in
          logger.debug("Trip update send failed: \(error.localizedDescription)")
        }
      )
    } catch {
      logger.error("Failed to encode trip update: \(error.localizedDescription)")
    }
  }

  // MARK: - Send Completed Trip

  func sendCompletedTrip(_ trip: Trip) {
    guard watchConnectivityEnabled else { return }
    guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }

    let summary = WatchTripSummary(
      id: trip.id,
      startDate: trip.startDate,
      endDate: trip.endDate,
      fare: trip.fare,
      currencyCode: trip.rateSnapshot.currencyCode ?? "INR",
      distanceMeters: trip.distanceMeters,
      duration: trip.duration,
      cityName: trip.rateSnapshot.cityName ?? "",
      vehicleType: trip.rateSnapshot.vehicleType ?? ""
    )

    do {
      let data = try JSONEncoder().encode(summary)
      guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
      WCSession.default.transferUserInfo([WatchMessageKey.tripSummary: dict])
      logger.debug("Queued completed trip for Watch transfer")
    } catch {
      logger.error("Failed to encode trip summary: \(error.localizedDescription)")
    }
  }

  // MARK: - Handle Watch Command

  private func handleCommand(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    guard
      let meterStore, let settingsStore, let tripStore,
      let commandString = message[WatchMessageKey.command] as? String,
      let command = WatchCommand(rawValue: commandString)
    else {
      replyHandler([WatchMessageKey.commandAck: "unknown"])
      return
    }

    switch command {
    case .startTrip:
      guard meterStore.tripState == .forHire else {
        replyHandler([WatchMessageKey.commandAck: "not_for_hire"])
        return
      }
      let cityInfo = settingsStore.activeCityInfo
      let profile = settingsStore.activeProfileForCurrentSelection
      meterStore.startTrip(
        settings: settingsStore.settings,
        cityId: cityInfo.cityId,
        cityName: cityInfo.cityName,
        surcharges: profile?.surcharges,
        perMinuteWhenSlow: profile?.rates.perMinuteWhenSlow,
        slowSpeedThresholdKph: profile?.rates.slowSpeedThresholdKph,
        vehicleType: profile?.vehicleType,
        currencyCode: profile?.cityKey.currencyCode,
        whatIfFavorites: settingsStore.whatIfFavorites,
        whatIfProfileLookup: { settingsStore.whatIfProfile(for: $0) }
      )
      replyHandler([WatchMessageKey.commandAck: "ok"])

    case .stopTrip:
      guard meterStore.tripState == .inProgress else {
        replyHandler([WatchMessageKey.commandAck: "not_in_progress"])
        return
      }
      meterStore.stopTrip(tripStore: tripStore)
      replyHandler([WatchMessageKey.commandAck: "ok"])

    case .enterWait:
      guard meterStore.isOnTrip, !meterStore.isWaiting else {
        replyHandler([WatchMessageKey.commandAck: "ignored"])
        return
      }
      meterStore.toggleWaiting()
      replyHandler([WatchMessageKey.commandAck: "ok"])

    case .exitWait:
      guard meterStore.isOnTrip, meterStore.isWaiting else {
        replyHandler([WatchMessageKey.commandAck: "ignored"])
        return
      }
      meterStore.toggleWaiting()
      replyHandler([WatchMessageKey.commandAck: "ok"])

    case .resetTrip:
      guard meterStore.tripState == .complete else {
        replyHandler([WatchMessageKey.commandAck: "not_complete"])
        return
      }
      meterStore.resetToForHire()
      replyHandler([WatchMessageKey.commandAck: "ok"])
    }
  }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityService: WCSessionDelegate {

  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    if let error {
      logger.error("WCSession activation failed: \(error.localizedDescription)")
    } else {
      logger.info("WCSession activated: \(String(describing: activationState.rawValue))")
    }
    let reachable = session.isReachable
    Task { @MainActor in
      self.isWatchReachable = reachable
    }
  }

  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
    logger.info("WCSession became inactive")
  }

  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    logger.info("WCSession deactivated, reactivating")
    session.activate()
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    let reachable = session.isReachable
    Task { @MainActor in
      self.isWatchReachable = reachable
      logger.info("Watch reachability changed: \(reachable)")
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    // Copy values out of the nonisolated context before crossing to MainActor
    let commandString = message[WatchMessageKey.command] as? String
    // WCSession guarantees replyHandler is safe to call from any isolation domain
    nonisolated(unsafe) let reply = replyHandler
    Task { @MainActor in
      var msg: [String: Any] = [:]
      if let commandString {
        msg[WatchMessageKey.command] = commandString
      }
      self.handleCommand(msg, replyHandler: reply)
    }
  }
}
