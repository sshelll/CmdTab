// WindowManager.swift
import Cocoa
import SwiftUI

@available(macOS 13.0, *)
@MainActor
class WindowManager: WindowDelegate {
  private var window: Window?

  // MARK: -- public funcs

  func createMainWindow() -> Window {
    let width: CGFloat = 600
    let height: CGFloat = 400

    let newWindow = Window(
      contentRect: NSRect(x: 0, y: 0, width: width, height: height),
      styleMask: [.fullSizeContentView],
      backing: .buffered,
      defer_: false,
      windowDelegate: self
    )

    configureWindow(newWindow)
    self.window = newWindow
    return newWindow
  }

  func showWindow() {
    guard let window = window else { return }

    // must set this to avoid space switch
    window.collectionBehavior = [.moveToActiveSpace]

    // always display on main screen
    if let mainScreen = NSScreen.screens.first {
      let visibleFrame = mainScreen.visibleFrame
      let windowSize = window.frame.size
      let x = (visibleFrame.width - windowSize.width) / 2 + visibleFrame.origin.x
      let y = (visibleFrame.height - windowSize.height) / 2 + visibleFrame.origin.y
      let newFrame = CGRect(x: x, y: y, width: windowSize.width, height: windowSize.height)
      window.setFrame(newFrame, display: true)
    }

    window.makeKeyAndOrderFront(nil)
  }

  func hideWindow() {
    window?.orderOut(nil)
  }

  func getWindow() -> Window? {
    return window
  }

  // MARK: -- WindowDelegate
  func onResignKey() {
    self.hideWindow()
  }

  // MARK: -- private funcs

  private func configureWindow(_ window: Window) {
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true

    // Use SwiftUI-based content view
    window.contentView = createSwiftUIContentView(for: window)
  }

  private func createSwiftUIContentView(for window: Window) -> NSView {
    // Create a container view that will hold actual content
    let contentView = NSView(frame: window.contentView!.bounds)
    contentView.autoresizingMask = [.width, .height]

    // Create SwiftUI background view
    let hostingView = NSHostingView(rootView: GlassmorphismWindowContentView())
    hostingView.frame = contentView.bounds
    hostingView.autoresizingMask = [.width, .height]

    contentView.addSubview(hostingView)

    return contentView
  }
}
