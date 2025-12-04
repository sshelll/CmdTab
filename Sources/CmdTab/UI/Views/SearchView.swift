import SwiftUI

// MARK: - SwiftUI Glassmorphism Search Field
@available(macOS 13.0, *)
struct GlassmorphismSearchField: View {
  @Binding var text: String
  var placeholder: String = "press 'i', '/' or 'a' to search and press 'esc' to quit"
  var onCommit: () -> Void = {}
  var onSpecialKey: ((NSEvent) -> Bool)?

  var body: some View {
    let content = HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
        .font(.system(size: 15, weight: .medium))

      FocusableTextField(
        text: $text,
        placeholder: placeholder,
        onCommit: onCommit,
        onSpecialKey: onSpecialKey
      )
      .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)

    // macOS 26 supports glass effect!
    if #available(macOS 26.0, *) {
      return content.glassEffect(.clear.interactive())
    }

    return
      content
      .background(
        ZStack {
          // Glassmorphism background
          SearchFieldVisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

          // Gradient border
          RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
              LinearGradient(
                colors: [.white.opacity(0.3), .white.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1
            )
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
  }
}

// MARK: - NSVisualEffectView Wrapper
struct SearchFieldVisualEffectBlur: NSViewRepresentable {
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

// MARK: - Custom TextField Representable with Direct Focus Control
@available(macOS 13.0, *)
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

      // limit input
      if textField.stringValue.count > MAX_INPUT_LIMIT {
        textField.stringValue = String(textField.stringValue.prefix(MAX_INPUT_LIMIT))
        NSSound.beep()
      }

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
    textField.textColor = .labelColor
    textField.placeholderString = placeholder

    // Pass special key handler
    textField.onSpecialKey = onSpecialKey

    // Set placeholder color
    if let placeholder = textField.placeholderString {
      let attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.secondaryLabelColor,
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

// MARK: - Custom TextField with Special Keyboard Event Support
@available(macOS 13.0, *)
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
