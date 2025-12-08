import Cocoa

@MainActor
protocol WindowDelegate: AnyObject {
  func onResignKey()
}

class Window: NSWindow {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  weak var windowDelegate: WindowDelegate?

  override func resignKey() {
    windowDelegate?.onResignKey()
  }

  init(
    contentRect: NSRect,
    styleMask: NSWindow.StyleMask,
    backing: NSWindow.BackingStoreType,
    defer_: Bool,
    windowDelegate: WindowDelegate
  ) {
    self.windowDelegate = windowDelegate
    super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: defer_)
  }
}
