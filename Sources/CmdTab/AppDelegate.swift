import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, StatusControllerDelegate {
  private var mainViewController: MainViewController?
  private var statusController: StatusController!
  private var window: Window?
  private var pendingWindows: [SwitchableWindow] = []

  // INFO: override funcs

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupApplication()

    // Add any pending windows
    if !pendingWindows.isEmpty {
      mainViewController?.addSwitchableWindows(pendingWindows)
      pendingWindows.removeAll()
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    // Cleanup if needed
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  func didRequestShowMainWindow() {
    print("AppDelegate: didRequestShowMainWindow() called - showing main window")
    NSApp.activate(ignoringOtherApps: true)
    mainViewController?.showWindow()
  }

  func didRequestQuit() {
    print("AppDelegate: didRequestQuit() called - terminating app")
    NSApp.terminate(nil)
  }

  // INFO: public funcs

  func addSwitchableWindows(_ windows: [SwitchableWindow]) {
    if let mainViewController = mainViewController {
      mainViewController.addSwitchableWindows(windows)
    } else {
      // Store windows to add them later when the app finishes launching
      pendingWindows.append(contentsOf: windows)
    }
  }

  // INFO: private funcs

  private func setupApplication() {
    // status bar
    statusController = StatusController()
    statusController.delegate = self

    // main win
    mainViewController = MainViewController()
    window = mainViewController?.setupMainWindow()
    mainViewController?.showWindow()
  }
}
