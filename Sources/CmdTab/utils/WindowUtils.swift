import AppKit

let UNKNOWN_APP = "(Unknown App)"
let NO_TITLE = "(no title)"

struct SwitchableWindow {
  let appName: String
  let pid: pid_t
  let windowTitle: String
}

func listRunningApplications() -> [NSRunningApplication] {
  return NSWorkspace.shared.runningApplications
    .filter { $0.activationPolicy == .regular }
}

func listSwitchableWindows() -> [SwitchableWindow] {
  var result: [SwitchableWindow] = []

  let apps = listRunningApplications()

  for app in apps {
    // 1. 优先取 FocusedWindow
    if let w = app.tryIntoAXFocusedWindow() {
      result.append(w)
      continue
    }

    // 2. fallback 到 AXWindows
    for win in app.tryIntoAXWindows() {
      result.append(win)
    }
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

    return self.intoSwitchableWindow(getWindowTitle(win))
  }

  func tryIntoAXWindows() -> [SwitchableWindow] {
    let axUI = self.getAxUIElem()

    var res: [SwitchableWindow] = []

    var windowsValue: AnyObject?
    AXUIElementCopyAttributeValue(
      axUI,
      kAXWindowsAttribute as CFString,
      &windowsValue
    )

    // AXWindows is [AXUIElement]
    let windows = windowsValue as? [AXUIElement] ?? []

    for win in windows {
      let title = getWindowTitle(win)
      res.append(self.intoSwitchableWindow(title))
    }

    return res
  }

  private func intoSwitchableWindow(_ title: String) -> SwitchableWindow {
    return
      SwitchableWindow(
        appName: self.getAppUnlocalizedName() ?? self.localizedName ?? UNKNOWN_APP,
        pid: self.processIdentifier,
        windowTitle: title
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
