import AppKit

let UNKNOWN_APP = "(Unknown App)"
let NO_TITLE = "(no title)"

struct SwitchableWindow {
  let appName: String
  let pid: pid_t
  let windowTitle: String
  let icon: NSImage?
  let activateFn: () -> Void
}

func listRunningApplications() -> [NSRunningApplication] {
  var res: [NSRunningApplication] = []

  let frontmostApp = NSWorkspace.shared.frontmostApplication
  let frontmostAppPid = frontmostApp?.processIdentifier
  if let app = frontmostApp {
    res.append(app)
  }

  res.append(
    contentsOf: NSWorkspace.shared.runningApplications
      .filter {
        $0.activationPolicy == .regular && frontmostAppPid != $0.processIdentifier
      }
  )

  return res
}

func listSwitchableWindows() -> [SwitchableWindow] {
  var result: [SwitchableWindow] = []

  let apps = listRunningApplications()

  for app in apps {
    // 1. use AXWindows
    if let wins = app.tryIntoAXWindows(), !wins.isEmpty {
      for win in wins {
        result.append(win)
      }
      continue
    }

    // 2. fallback to FocusedWindow
    if let w = app.tryIntoAXFocusedWindow() {
      result.append(w)
      continue
    }

    let sw = app.intoSwitchableWindow(NO_TITLE, win: nil)
    result.append(sw)
  }

  return result
}

extension NSRunningApplication {
  func getAxUIElem() -> AXUIElement {
    return AXUIElementCreateApplication(self.processIdentifier)
  }

  func tryIntoAXFocusedWindow() -> SwitchableWindow? {
    let axUI = self.getAxUIElem()

    var focusedValue: AnyObject?

    let err = AXUIElementCopyAttributeValue(
      axUI,
      kAXFocusedWindowAttribute as CFString,
      &focusedValue
    )
    guard err == .success else { return nil }

    // AXFocusedWindow is AXUIElement
    let win = focusedValue as! AXUIElement

    return self.intoSwitchableWindow(getWindowTitle(win), win: win)
  }

  func tryIntoAXWindows() -> [SwitchableWindow]? {
    let axUI = self.getAxUIElem()

    var res: [SwitchableWindow] = []

    var windowsValue: AnyObject?
    AXUIElementCopyAttributeValue(
      axUI,
      kAXWindowsAttribute as CFString,
      &windowsValue
    )

    // AXWindows is [AXUIElement]
    guard let windows = windowsValue as? [AXUIElement] else { return nil }

    for win in windows {
      guard filterAXWindowsByAttrs(win: win) else { continue }
      let title = getWindowTitle(win)
      res.append(self.intoSwitchableWindow(title, win: win))
    }

    return res
  }

  func filterAXWindowsByAttrs(win: AXUIElement) -> Bool {
    var hidden: AnyObject?
    AXUIElementCopyAttributeValue(
      win,
      kAXHiddenAttribute as CFString,
      &hidden
    )
    if let h = hidden as? Int, h == 0 {
      return false
    }
    return true
  }

  func intoSwitchableWindow(_ title: String, win: AXUIElement?) -> SwitchableWindow {
    return
      SwitchableWindow(
        appName: self.getAppUnlocalizedName() ?? self.localizedName ?? UNKNOWN_APP,
        pid: self.processIdentifier,
        windowTitle: title,
        icon: self.icon,
        activateFn: {
          // has window, activate it
          if let windowElement = win {
            // before activate the window, put it to front
            AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
            self.activate()
            return
          }

          // no window, launch it
          NSWorkspace.shared.launchApplication(
            withBundleIdentifier: self.bundleIdentifier ?? "",
            options: [.default],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
          )
        }
      )
  }

  private func getWindowTitle(_ axUI: AXUIElement) -> String {
    var titleValue: AnyObject?
    AXUIElementCopyAttributeValue(axUI, kAXTitleAttribute as CFString, &titleValue)
    return titleValue as? String ?? NO_TITLE
  }

  private func getAppUnlocalizedName() -> String? {
    var rawName: String?
    if let url = self.bundleURL,
      let info = NSDictionary(contentsOf: url.appendingPathComponent("Contents/Info.plist"))
    {
      rawName = info["CFBundleName"] as? String
    }
    return rawName
  }
}
