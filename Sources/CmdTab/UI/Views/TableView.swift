import Cocoa
import SwiftUI

// MARK: - SwiftUI Glass Effect for Row Selection
@available(macOS 13.0, *)
struct RowSelectionGlassView: View {
  var body: some View {
    ZStack {
      if #available(macOS 26.0, *) {
        // Use glass effect for macOS 26+
        Color.clear
          .glassEffect(
            // .regular.interactive(),
            .clear.interactive(),
            // in: RoundedRectangle(cornerRadius: 8)
            in: DefaultGlassEffectShape()
          )
          .ignoresSafeArea()
      } else {
        // Fallback for older macOS versions
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.orange.opacity(0.4))
      }
    }
  }
}

@available(macOS 13.0, *)
class RowView: NSTableRowView {
  private var glassHostingView: NSHostingView<RowSelectionGlassView>?

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupGlassEffect()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupGlassEffect()
  }

  private func setupGlassEffect() {
    // Create SwiftUI hosting view for glass effect
    let hostingView = NSHostingView(rootView: RowSelectionGlassView())
    hostingView.autoresizingMask = [.width, .height]
    hostingView.alphaValue = 0  // Initially hidden

    // Insert at the bottom of the view hierarchy
    self.addSubview(hostingView, positioned: .below, relativeTo: nil)

    self.glassHostingView = hostingView
  }

  private let animationEnabled = true
  override var isSelected: Bool {
    didSet {
      // Animate the glass effect visibility
      if animationEnabled {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.1
          glassHostingView?.animator().alphaValue = isSelected ? 1.0 : 0.0
        }
      } else {
        if !isSelected {
          glassHostingView?.alphaValue = 0.0
        }
      }
    }
  }

  override func drawSelection(in dirtyRect: NSRect) {
    if !animationEnabled {
      glassHostingView?.alphaValue = 1.0
    }
    // No need to draw selection manually anymore
    // The glass effect handles it
  }

  override func drawBackground(in dirtyRect: NSRect) {
    NSColor.clear.setFill()
  }
}
