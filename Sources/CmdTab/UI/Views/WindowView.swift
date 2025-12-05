import SwiftUI

// MARK: - SwiftUI Glass Background View
@available(macOS 13.0, *)
struct GlassmorphismWindowContentView: View {
  var body: some View {
    ZStack {
      // macOS 26 supports glass effect!
      if #available(macOS 26.0, *) {
        Color.clear
          .glassEffect(
            // .clear.tint(Color(red: 255 / 255, green: 208 / 255, blue: 191 / 255)).interactive(),
            .regular.interactive(),
            // .clear.interactive(),
            // .identity.interactive(),
            in: RoundedRectangle(cornerRadius: 18)
          )
          .ignoresSafeArea()
      } else {
        // Fallback for older macOS versions
        WindowVisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
          .ignoresSafeArea()
      }
    }
  }
}

// MARK: - NSVisualEffectView Wrapper (for macOS < 26)
struct WindowVisualEffectBlur: NSViewRepresentable {
  var material: NSVisualEffectView.Material
  var blendingMode: NSVisualEffectView.BlendingMode

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    view.wantsLayer = true
    view.layer?.cornerRadius = 18
    view.layer?.masksToBounds = true
    view.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}
