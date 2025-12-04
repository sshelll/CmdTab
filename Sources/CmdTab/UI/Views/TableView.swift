import Cocoa

class RowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    if self.isSelected {
      // TODO: customize theme
      let selectionColor = NSColor.systemOrange.withAlphaComponent(0.4)
      selectionColor.setFill()

      // Create rounded rectangle path with corner radius
      let cornerRadius: CGFloat = 8.0
      let selectionRect = self.bounds.insetBy(dx: 4, dy: 2)  // Add some padding
      let path = NSBezierPath(
        roundedRect: selectionRect, xRadius: cornerRadius, yRadius: cornerRadius)
      path.fill()
    }
  }

  override func drawBackground(in dirtyRect: NSRect) {
    NSColor.clear.setFill()
    dirtyRect.fill()
  }
}
