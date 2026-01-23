import Cocoa
import HotKey

@available(macOS 13.0, *)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, StatusControllerDelegate {
  private var mainViewController: MainViewController?
  private var statusController: StatusController!

  // NOTE: reserve these two vars to avoid GC and cause our hotkey not work
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?

  private var hotkey: HotKey?
  private var isHandlingCmdTab = false

  // MARK: -- NSApplicationDelegate

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupApplication()
    setupGlobalHotKey()
    setupGlobalHotKeyUnstable()
    NSApplication.shared.setActivationPolicy(.accessory)
  }

  func applicationWillTerminate(_ notification: Notification) {
    mainViewController?.cleanup()
    statusController.cleanup()

    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }

    if let runLoopSource = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    }

    hotkey = nil
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // MARK: -- StatusControllerDelegate + Hotkey

  func didRequestShowMainWindow() {
    NSApp.activate(ignoringOtherApps: true)
    self.mainViewController?.showWindow()
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

  private func setupGlobalHotKey() {
    self.hotkey = HotKey(key: .tab, modifiers: [.option])
    self.hotkey!.keyDownHandler = { [weak self] in
      self?.didRequestShowMainWindow()
    }
  }

  // cmd-tab is a mac os builtin shortcut which cannot be disabled
  private func setupGlobalHotKeyUnstable() {
    let selfPointer = Unmanaged.passUnretained(self).toOpaque()
    let eventMask =
      (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.tapDisabledByTimeout.rawValue)
      | (1 << CGEventType.tapDisabledByUserInput.rawValue)

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: { proxy, type, event, refcon in
          guard let refcon = refcon else {
            return Unmanaged.passUnretained(event)
          }
          let appDelegate = Unmanaged<AppDelegate>
            .fromOpaque(refcon)
            .takeUnretainedValue()

          let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
          let flags = event.flags

          switch type {
          // if disabled, re-enable it
          case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = appDelegate.eventTap {
              CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)

          case .keyDown:
            let isCmdTab =
              keyCode == 48  // Tab
              && flags.contains(.maskCommand)

            if isCmdTab {
              appDelegate.isHandlingCmdTab = true
              DispatchQueue.main.async {
                appDelegate.didRequestShowMainWindow()
              }
              // don't pass to macos
              return nil
            }

            return Unmanaged.passUnretained(event)

          case .keyUp:
            // if we didn't catch the down event, don't eat this up event
            guard appDelegate.isHandlingCmdTab else {
              return Unmanaged.passUnretained(event)
            }
            // Tab keyUp or Command keyUp means this round is end
            if keyCode == 48 || !flags.contains(.maskCommand) {
              appDelegate.isHandlingCmdTab = false
              return nil
            }
            return Unmanaged.passUnretained(event)

          default:
            return Unmanaged.passUnretained(event)
          }
        },
        userInfo: selfPointer
      )
    else {
      AlertCritical(
        msgText: "Register HotKey failed",
        informativeText: "CmdTab cannot register ⌘+Tab hotkey, will terminate immediately",
        terminate: true,
      )
      return
    }
    self.eventTap = eventTap

    self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0)
    if let runLoopSource = runLoopSource {
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      CGEvent.tapEnable(tap: eventTap, enable: true)
    } else {
      AlertCritical(
        msgText: "Register HotKey failed",
        informativeText: "CmdTab cannot register ⌘+Tab hotkey, will terminate immediately",
        terminate: true,
      )
    }
  }
}
