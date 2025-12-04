import SwiftUI

let MAX_INPUT_LIMIT = 20

// MARK: - Search Field Coordinator
@available(macOS 13.0, *)
@MainActor
class GlassmorphismSearchCoordinator: NSObject {
  private var hostingView: KeyboardHostingView<GlassmorphismSearchField>!
  private var textBinding: Binding<String>!
  private var textState: TextState!

  // Keyboard event callbacks
  var onTextChange: ((String) -> Void)?
  var onMoveDown: (() -> Void)?
  var onMoveUp: (() -> Void)?
  var onEnter: (() -> Void)?
  var onEscape: (() -> Void)?

  func createHostingView(initialText: String = "") -> NSView {
    // Create Published property to drive SwiftUI
    textState = TextState(text: initialText)

    textBinding = Binding(
      get: { [weak textState] in textState?.text ?? "" },
      set: { [weak self, weak textState] newValue in
        textState?.text = newValue
        self?.onTextChange?(newValue)
      }
    )

    let searchField = GlassmorphismSearchField(
      text: textBinding,
      onCommit: { [weak self] in
        self?.onEnter?()
      },
      onSpecialKey: { [weak self] event in
        return self?.handleKeyEvent(event) ?? false
      }
    )

    hostingView = KeyboardHostingView(rootView: searchField)
    hostingView.translatesAutoresizingMaskIntoConstraints = false

    // Set keyboard event handler (as fallback)
    hostingView.keyDownHandler = { [weak self] event in
      return self?.handleKeyEvent(event) ?? false
    }

    return hostingView
  }

  func getHostingView() -> NSView? {
    return hostingView
  }

  func setText(_ text: String) {
    textBinding?.wrappedValue = text
  }

  func becomeFirstResponder() -> Bool {
    // Directly find and focus the internal NSTextField
    if let textField = findTextField(in: hostingView) {
      return hostingView.window?.makeFirstResponder(textField) ?? false
    }
    return hostingView.window?.makeFirstResponder(hostingView) ?? false
  }

  // Recursively find NSTextField
  private func findTextField(in view: NSView?) -> NSTextField? {
    guard let view = view else { return nil }

    if let textField = view as? NSTextField {
      return textField
    }

    for subview in view.subviews {
      if let found = findTextField(in: subview) {
        return found
      }
    }
    return nil
  }

  private func handleKeyEvent(_ event: NSEvent) -> Bool {
    // leave cmd+? to the os
    if event.modifierFlags.contains(.command) {
      return false
    }

    switch event.keyCode {
    case 125:  // Down arrow
      onMoveDown?()
      return true
    case 126:  // Up arrow
      onMoveUp?()
      return true
    case 36:  // Enter/Return
      onEnter?()
      return true
    case 53:  // Escape
      onEscape?()
      return true
    case 48:  // Tab
      if event.modifierFlags.contains(.shift) {
        onMoveUp?()
      } else {
        onMoveDown?()
      }
      return true
    default:
      return false
    }
  }

  // inner stateful class, use it to listen text change
  private class TextState: ObservableObject {
    @Published var text: String

    init(text: String) {
      self.text = text
    }
  }
}

// MARK: - Custom NSHostingView with Keyboard Event Support
@available(macOS 13.0, *)
class KeyboardHostingView<Content: View>: NSHostingView<Content> {
  var keyDownHandler: ((NSEvent) -> Bool)?

  override var acceptsFirstResponder: Bool { true }

  override func becomeFirstResponder() -> Bool {
    // Try to find the internal NSTextField and make it the first responder
    if let textField = findTextField(in: self) {
      return window?.makeFirstResponder(textField) ?? false
    }
    return super.becomeFirstResponder()
  }

  override func keyDown(with event: NSEvent) {
    if let handler = keyDownHandler, handler(event) {
      return
    }
    super.keyDown(with: event)
  }

  // Recursively find NSTextField
  private func findTextField(in view: NSView) -> NSTextField? {
    if let textField = view as? NSTextField {
      return textField
    }
    for subview in view.subviews {
      if let found = findTextField(in: subview) {
        return found
      }
    }
    return nil
  }
}
