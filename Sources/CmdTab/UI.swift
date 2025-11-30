import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate,
  NSSearchFieldDelegate
{

  var window: MainWindow!
  var searchField: NSSearchField!
  var tableView: VimTableView!
  var items = ["First item", "Second item", "Third item", "Fourth item"]

  // NOTE: entry
  func applicationDidFinishLaunching(_ notification: Notification) {
    createWindow()
    window.makeKeyAndOrderFront(nil)
    window.center()
    window.makeFirstResponder(searchField)
  }

  // NOTE: create the main window
  func createWindow() {
    let width: CGFloat = 600
    let height: CGFloat = 400

    window = MainWindow(
      contentRect: NSRect(x: 0, y: 0, width: width, height: height),
      styleMask: [.fullSizeContentView],  // 无边框风格
      backing: .buffered,
      defer: false
    )

    window.isOpaque = false
    window.backgroundColor = .clear
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.level = .floating
    window.isMovableByWindowBackground = true

    let contentView = NSVisualEffectView(frame: window.contentView!.bounds)
    contentView.autoresizingMask = [.width, .height]
    contentView.material = .sidebar
    contentView.state = .active
    contentView.wantsLayer = true
    contentView.layer?.cornerRadius = 18
    contentView.layer?.masksToBounds = true

    window.contentView = contentView

    setupUI(in: contentView)
  }

  // NOTE: setup window ui
  func setupUI(in view: NSView) {
    // Search field
    searchField = NSSearchField(
      frame: NSRect(x: 20, y: view.bounds.height - 60, width: view.bounds.width - 40, height: 30),
    )
    searchField.autoresizingMask = [.width, .minYMargin]
    searchField.delegate = self
    view.addSubview(searchField)

    // Table View
    let scrollView = NSScrollView(
      frame: NSRect(x: 20, y: 20, width: view.bounds.width - 40, height: view.bounds.height - 100),
    )
    scrollView.autoresizingMask = [.width, .height]

    // tableView = NSTableView(frame: scrollView.bounds)
    tableView = VimTableView(frame: scrollView.bounds)
    tableView.delegate = self
    tableView.dataSource = self

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("column"))
    column.title = "Items"
    column.width = scrollView.bounds.width
    tableView.addTableColumn(column)
    // tableView.rowHeight = 32

    tableView.headerView = nil  // 不显示表头（更像 Alfred/Spotlight）

    scrollView.documentView = tableView
    scrollView.hasVerticalScroller = true
    scrollView.wantsLayer = true
    scrollView.layer?.cornerRadius = 12
    scrollView.layer?.masksToBounds = true
    scrollView.backgroundColor = .clear
    scrollView.drawsBackground = false

    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular

    view.addSubview(scrollView)
  }

  // NOTE: override NSTableViewDataSource
  func numberOfRows(in tableView: NSTableView) -> Int {
    return items.count
  }

  // NOTE: override table style
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    let text = NSTextField(labelWithString: items[row])
    text.font = NSFont.systemFont(ofSize: 16)
    text.textColor = .labelColor
    text.autoresizingMask = [.width]
    text.translatesAutoresizingMaskIntoConstraints = false

    let cell = NSTableCellView()
    cell.addSubview(text)

    NSLayoutConstraint.activate([
      text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
      text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10),
      text.topAnchor.constraint(equalTo: cell.topAnchor, constant: 4),
      text.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -4),
    ])

    return cell
  }

  // NOTE: override table.row style
  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return RowView()
  }

  // NOTE: override NSSearchFieldDelegate
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector)
    -> Bool
  {
    guard let tableView = tableView else { return false }

    switch commandSelector {
    case #selector(NSResponder.moveDown(_:)), #selector(NSResponder.moveRight(_:)):
      tableView.moveSelection(down: true)
      return true
    case #selector(NSResponder.moveUp(_:)), #selector(NSResponder.moveLeft(_:)):
      tableView.moveSelection(down: false)
      return true
    default:
      return false
    }
  }
}
