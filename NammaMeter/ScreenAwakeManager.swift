import UIKit
import Observation
import OSLog

@MainActor
@Observable
final class ScreenAwakeManager {
  var isEnabled = false {
    didSet {
      updateIdleTimer()
    }
  }

  var tripState: TripMeterState = .forHire {
    didSet {
      updateIdleTimer()
    }
  }

  private var isAppActive = true {
    didSet {
      updateIdleTimer()
    }
  }

  init() {
    registerForAppLifecycleEvents()
  }

  private func registerForAppLifecycleEvents() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillEnterBackground),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func appWillEnterBackground() {
    isAppActive = false
  }

  @objc private func appDidBecomeActive() {
    isAppActive = true
  }

  private func updateIdleTimer() {
    let shouldDisableIdleTimer = isEnabled && tripState == .inProgress && isAppActive
    UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer
    if shouldDisableIdleTimer {
      Log.trip.debug("Screen awake enabled during trip")
    } else {
      Log.trip.debug("Screen awake disabled")
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    DispatchQueue.main.async {
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }
}
