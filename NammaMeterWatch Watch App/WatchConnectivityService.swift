import Foundation
import Observation
import OSLog
@preconcurrency import WatchConnectivity

private let logger = Logger(subsystem: "sridharsm.NammaMeter.watchkitapp", category: "WatchConnectivity")

@MainActor
@Observable
final class WatchConnectivityService: NSObject {

  private(set) var isPhoneReachable = false
  var tripStore: WatchTripStore?

  override init() {
    super.init()
    guard WCSession.isSupported() else {
      logger.info("WatchConnectivity not supported")
      return
    }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  // MARK: - Send Command to iPhone

  func sendCommand(_ command: WatchCommand, completion: ((Bool) -> Void)? = nil) {
    guard WCSession.default.activationState == .activated, isPhoneReachable else {
      logger.warning("Cannot send command: iPhone not reachable")
      completion?(false)
      return
    }

    let message: [String: Any] = [WatchMessageKey.command: command.rawValue]
    WCSession.default.sendMessage(message, replyHandler: { reply in
      let ack = reply[WatchMessageKey.commandAck] as? String
      logger.debug("Command \(command.rawValue) ack: \(ack ?? "none")")
      Task { @MainActor in
        completion?(ack == "ok")
      }
    }, errorHandler: { error in
      logger.error("Command \(command.rawValue) failed: \(error.localizedDescription)")
      Task { @MainActor in
        completion?(false)
      }
    })
  }

  // MARK: - Process Incoming Messages

  private func processApplicationContext(_ context: [String: Any]) {
    guard let configDict = context[WatchMessageKey.config] else { return }
    do {
      let data = try JSONSerialization.data(withJSONObject: configDict)
      let config = try JSONDecoder().decode(WatchConfig.self, from: data)
      tripStore?.applyConfig(config)
      logger.debug("Applied config: \(config.cityName)")
    } catch {
      logger.error("Failed to decode config: \(error.localizedDescription)")
    }
  }

  private func processTripUpdate(_ message: [String: Any]) {
    guard let updateDict = message[WatchMessageKey.tripUpdate] else { return }
    do {
      let data = try JSONSerialization.data(withJSONObject: updateDict)
      let update = try JSONDecoder().decode(WatchTripUpdate.self, from: data)
      tripStore?.applyTripUpdate(update)
    } catch {
      logger.error("Failed to decode trip update: \(error.localizedDescription)")
    }
  }

  private func processTripSummary(_ userInfo: [String: Any]) {
    guard let summaryDict = userInfo[WatchMessageKey.tripSummary] else { return }
    do {
      let data = try JSONSerialization.data(withJSONObject: summaryDict)
      let summary = try JSONDecoder().decode(WatchTripSummary.self, from: data)
      tripStore?.addCompletedTrip(summary)
      logger.debug("Received completed trip summary")
    } catch {
      logger.error("Failed to decode trip summary: \(error.localizedDescription)")
    }
  }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    if let error {
      logger.error("WCSession activation failed: \(error.localizedDescription)")
    } else {
      logger.info("WCSession activated")
    }
    isPhoneReachable = session.isReachable
    let pendingContext = session.receivedApplicationContext
    if !pendingContext.isEmpty {
      processApplicationContext(pendingContext)
    }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    isPhoneReachable = session.isReachable
    logger.info("Phone reachability changed: \(session.isReachable)")
  }

  func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    processApplicationContext(applicationContext)
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any]
  ) {
    if message[WatchMessageKey.config] != nil {
      processApplicationContext(message)
    } else {
      processTripUpdate(message)
    }
  }

  func session(
    _ session: WCSession,
    didReceiveUserInfo userInfo: [String: Any] = [:]
  ) {
    processTripSummary(userInfo)
  }
}
