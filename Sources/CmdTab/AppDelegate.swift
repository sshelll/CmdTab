import Cocoa

@available(macOS 13.0, *)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, StatusControllerDelegate {
  private var mainViewController: MainViewController?
  private var statusController: StatusController!

  // NOTE: reserve these two vars to avoid GC and cause our hotkey not work
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?

  // MARK: -- NSApplicationDelegate

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupApplication()
    setupGlobalHotkey()
    NSApplication.shared.setActivationPolicy(.accessory)
  }

  func applicationWillTerminate(_ notification: Notification) {
    mainViewController?.cleanup()
    statusController.cleanup()
    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }
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
    let selfPointer = Unmanaged.passUnretained(self).toOpaque()
    let eventMask = (1 << CGEventType.keyDown.rawValue)

    self.eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { proxy, type, event, refcon in
        guard let refcon = refcon else {
          return Unmanaged.passUnretained(event)
        }
        let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        if keyCode == 48 && flags.contains(.maskCommand) {
          appDelegate.didRequestShowMainWindow()
          // prevent sending to sys
          return nil
        }

        // still pass to sys
        return Unmanaged.passUnretained(event)
      },
      userInfo: selfPointer
    )

    self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0)
    if let runLoopSource = runLoopSource {
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      CGEvent.tapEnable(tap: eventTap!, enable: true)
    } else {
      AlertCritical(
        msgText: "Register HotKey failed",
        informativeText: "CmdTab cannot register ⌘+Tab hotkey, will terminate immediately",
      )
    }
  }
}
