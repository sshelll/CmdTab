import Cocoa

@available(macOS 12.0, *)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, StatusControllerDelegate {
  private var mainViewController: MainViewController?
  private var statusController: StatusController!

  // MARK: -- NSApplicationDelegate

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupApplication()
    setupGlobalHotkey()
    NSApplication.shared.setActivationPolicy(.accessory)
  }

  func applicationWillTerminate(_ notification: Notification) {
    mainViewController?.cleanup()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // MARK: -- StatusControllerDelegate + Hotkey

  func didRequestShowMainWindow() {
    NSApp.activate(ignoringOtherApps: true)
    mainViewController?.showWindow()
  }

  func didRequestQuit() {
    NSApp.terminate(nil)
  }

  // MARK: -- private funcs

  private func setupApplication() {
    // status bar
    statusController = StatusController()
    statusController.delegate = self

    // main win
    mainViewController = MainViewController()
    mainViewController?.setupMainWindow()
  }

  private func setupGlobalHotkey() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { proxy, type, event, refcon in
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        if keyCode == 48 && flags.contains(.maskCommand) {
          DispatchQueue.main.async {
            if let appDelegate = NSApp.delegate as? AppDelegate {
              appDelegate.didRequestShowMainWindow()
            }
          }
          return nil  // prevent sending to sys
          // return Unmanaged.passUnretained(event)  // still pass to sys
        }
        return Unmanaged.passUnretained(event)
      },
      userInfo: nil
    )

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap!, enable: true)
  }
}
