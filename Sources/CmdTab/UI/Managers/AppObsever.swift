import Cocoa

@MainActor
class AppObserver {
  private var activationObserver: NSObjectProtocol?
  private var terminationObserver: NSObjectProtocol?
  private let appOrderManager: AppOrderManager

  init(appOrderManager: AppOrderManager) {
    self.appOrderManager = appOrderManager
    setupObservers()
  }

  private func setupObservers() {
    // Observer for app activation
    activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
        as? NSRunningApplication
      {
        // Since we're already on the main queue, we can call the MainActor method directly
        DispatchQueue.main.async {
          self?.appOrderManager.applicationActivated(pid: app.processIdentifier)
        }
      }
    }

    // Observer for app termination
    terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didTerminateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
        as? NSRunningApplication
      {
        // Since we're already on the main queue, we can call the MainActor method directly
        DispatchQueue.main.async {
          self?.appOrderManager.applicationQuit(pid: app.processIdentifier)
        }
      }
    }
  }

  func cleanup() {
    if let observer = activationObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
      activationObserver = nil
    }
    if let observer = terminationObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
      terminationObserver = nil
    }
  }

  deinit {
    // Note: We can't call cleanup() here due to MainActor isolation
    // The cleanup should be called explicitly before deallocation
  }
}
