import Cocoa

@MainActor
protocol SearchControllerDelegate: AnyObject {
  func didRequestClose()
  func didRequestSwitch()
}

@MainActor
class SearchController: NSObject, NSSearchFieldDelegate {
  weak var delegate: SearchControllerDelegate?
  private let dataManager: DataManager
  private let tableViewController: TableViewController
  private weak var searchField: NSSearchField?
  private weak var tableView: VimTableView?

  init(dataManager: DataManager, tableViewController: TableViewController) {
    self.dataManager = dataManager
    self.tableViewController = tableViewController
    super.init()
  }

  func setupSearchField(_ searchField: NSSearchField, tableView: VimTableView) {
    self.searchField = searchField
    self.tableView = tableView
    searchField.delegate = self
  }

  // MARK: - NSSearchFieldDelegate

  func controlTextDidChange(_ obj: Notification) {
    guard let searchField = obj.object as? NSSearchField else { return }
    let searchText = searchField.stringValue

    dataManager.updateSearchQuery(searchText)
    tableViewController.reloadData()
  }

  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector)
    -> Bool
  {
    guard let tableView = tableView else { return false }

    switch commandSelector {
    case #selector(NSResponder.moveDown(_:)), #selector(NSResponder.moveRight(_:)):
      // ↓ and → moves down
      tableView.moveSelection(down: true)
      return true
    case #selector(NSResponder.moveUp(_:)), #selector(NSResponder.moveLeft(_:)):
      // ↑ and ← moves up
      tableView.moveSelection(down: false)
      return true
    case #selector(NSResponder.insertNewline(_:)):
      // Handle Enter key - could trigger window switching
      handleEnterKey()
      return true
    case #selector(NSResponder.cancelOperation(_:)):
      // Handle Escape key - could close the window
      handleEscapeKey()
      return true
    default:
      return false
    }
  }

  // MARK: - Private Methods

  private func handleEnterKey() {
    // TODO: Implement window switching logic
    // This would typically switch to the selected window
    print("Enter key pressed - should switch to selected window")
    delegate?.didRequestSwitch()
  }

  private func handleEscapeKey() {
    // TODO: Implement window closing logic
    // This would typically close the CmdTab window
    print("Escape key pressed - should close window")
    delegate?.didRequestClose()
  }

  func focusSearchField() {
    searchField?.becomeFirstResponder()
  }

  func clearSearch() {
    searchField?.stringValue = ""
    dataManager.updateSearchQuery("")
    tableViewController.reloadData()
  }
}
