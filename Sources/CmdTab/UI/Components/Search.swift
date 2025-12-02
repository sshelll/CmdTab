import AppKit
import SwiftUI

let PLACEHOLDER = "press 'i', '/' or 'a' to search and press 'esc' to quit"

// MARK: - Custom TextField with Special Keyboard Event Support
@available(macOS 12.0, *)
class CustomTextField: NSTextField {
  var onSpecialKey: ((NSEvent) -> Bool)?

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    // Handle special keys
    if let handler = onSpecialKey, handler(event) {
      return true
    }
    return super.performKeyEquivalent(with: event)
  }

  override func keyDown(with event: NSEvent) {
    // Handle special keys
    if let handler = onSpecialKey, handler(event) {
      return
    }
    super.keyDown(with: event)
  }
}

// MARK: - Custom TextField Representable with Direct Focus Control
@available(macOS 12.0, *)
struct FocusableTextField: NSViewRepresentable {
  @Binding var text: String
  var placeholder: String
  var onCommit: () -> Void
  var onSpecialKey: ((NSEvent) -> Bool)?

  class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: FocusableTextField

    init(_ parent: FocusableTextField) {
      self.parent = parent
    }

    func controlTextDidChange(_ obj: Notification) {
      guard let textField = obj.object as? NSTextField else { return }
      parent.text = textField.stringValue
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector)
      -> Bool
    {
      // Handle keyboard commands
      switch commandSelector {
      case #selector(NSResponder.cancelOperation(_:)):
        // Escape key
        if let event = NSApp.currentEvent,
          let handler = parent.onSpecialKey,
          handler(event)
        {
          return true
        }
      case #selector(NSResponder.insertNewline(_:)):
        // Enter key
        parent.onCommit()
        return true
      case #selector(NSResponder.moveDown(_:)),
        #selector(NSResponder.moveUp(_:)),
        #selector(NSResponder.moveLeft(_:)),
        #selector(NSResponder.moveRight(_:)),
        #selector(NSResponder.insertTab(_:)),
        #selector(NSResponder.insertBacktab(_:)):
        // Arrow keys and Tab key
        if let event = NSApp.currentEvent,
          let handler = parent.onSpecialKey,
          handler(event)
        {
          return true
        }
      default:
        break
      }
      return false
    }

    func controlTextDidEndEditing(_ obj: Notification) {
      if let textMovement = obj.userInfo?["NSTextMovement"] as? Int,
        textMovement == NSTextMovement.return.rawValue
      {
        parent.onCommit()
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeNSView(context: Context) -> CustomTextField {
    let textField = CustomTextField()
    textField.delegate = context.coordinator
    textField.isBordered = false
    textField.backgroundColor = .clear
    textField.focusRingType = .none
    textField.font = .systemFont(ofSize: 14)
    textField.textColor = .white
    textField.placeholderString = placeholder

    // Pass special key handler
    textField.onSpecialKey = onSpecialKey

    // Set placeholder color
    if let placeholder = textField.placeholderString {
      let attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.white.withAlphaComponent(0.5),
        .font: NSFont.systemFont(ofSize: 14),
      ]
      textField.placeholderAttributedString = NSAttributedString(
        string: placeholder,
        attributes: attributes
      )
    }

    return textField
  }

  func updateNSView(_ nsView: CustomTextField, context: Context) {
    if nsView.stringValue != text {
      nsView.stringValue = text
    }
    nsView.onSpecialKey = onSpecialKey
  }
}

// MARK: - SwiftUI Glassmorphism Search Field
@available(macOS 12.0, *)
struct GlassmorphismSearchField: View {
  @Binding var text: String
  var placeholder: String = "press 'i', '/' or 'a' to search and press 'esc' to quit"
  var onCommit: () -> Void = {}
  var onSpecialKey: ((NSEvent) -> Bool)?

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.white.opacity(0.7))
        .font(.system(size: 15, weight: .medium))

      FocusableTextField(
        text: $text,
        placeholder: placeholder,
        onCommit: onCommit,
        onSpecialKey: onSpecialKey
      )
      .frame(maxWidth: .infinity)

      if !text.isEmpty {
        Button(action: {
          text = ""
        }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.white.opacity(0.6))
            .font(.system(size: 15))
        }
        .buttonStyle(.plain)
        .help("Clear")
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
      ZStack {
        // Glassmorphism background
        VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

        // Gradient border
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(
            LinearGradient(
              colors: [
                .white.opacity(0.3),
                .white.opacity(0.15),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      }
    )
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
  }
}

// MARK: - NSVisualEffectView Wrapper
struct VisualEffectBlur: NSViewRepresentable {
  var material: NSVisualEffectView.Material
  var blendingMode: NSVisualEffectView.BlendingMode

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}

// MARK: - Custom NSHostingView with Keyboard Event Support
@available(macOS 12.0, *)
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

// MARK: - Search Field Coordinator
@available(macOS 12.0, *)
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
      placeholder: PLACEHOLDER,
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
    case 125, 124:  // Down arrow, Right arrow
      onMoveDown?()
      return true
    case 126, 123:  // Up arrow, Left arrow
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
