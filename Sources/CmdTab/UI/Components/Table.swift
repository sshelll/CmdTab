import Cocoa

@MainActor
protocol VimTableViewDelegate: AnyObject {
  func handleEnterKey()
  func handleEscapeKey()
  func handleSlashKey()
}

@MainActor
class VimTableView: NSTableView {
  weak var controllerDelegate: VimTableViewDelegate?

  override func keyDown(with event: NSEvent) {
    guard let chars = event.charactersIgnoringModifiers else {
      super.keyDown(with: event)
      return
    }

    switch chars {
    case "j", "l":
      moveSelection(down: true)
    case "k", "h":
      moveSelection(down: false)
    case "\r":  // Enter key
      if selectedRow >= 0 {
        // Notify delegate or perform action for selected row
        controllerDelegate?.handleEnterKey()
      }
    case "\u{1b}":  // Escape key
      controllerDelegate?.handleEscapeKey()
    case "/":
      controllerDelegate?.handleSlashKey()
    default:
      switch event.keyCode {
      case 125, 124:  // down + right arrow
        moveSelection(down: true)
      case 126, 123:  // up + left arrow
        moveSelection(down: false)
      default:
        super.keyDown(with: event)
      }
    }
  }

  func moveSelection(down: Bool) {
    let rowCount = self.numberOfRows
    guard rowCount > 0 else { return }

    var newRow = self.selectedRow
    if newRow == -1 {  // -1 means unselected
      newRow = down ? 0 : rowCount - 1
    } else if newRow == rowCount - 1 && down {
      newRow = 0
    } else if newRow == 0 && !down {
      newRow = rowCount - 1
    } else {
      newRow += down ? 1 : -1
    }

    self.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
    self.scrollRowToVisible(newRow)
  }
}

class RowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    if self.isSelected {
      let selectionColor = NSColor.systemOrange.withAlphaComponent(0.3)
      selectionColor.setFill()
      dirtyRect.fill()
    }
  }

  override func drawBackground(in dirtyRect: NSRect) {
    NSColor.clear.setFill()
    dirtyRect.fill()
  }
}
