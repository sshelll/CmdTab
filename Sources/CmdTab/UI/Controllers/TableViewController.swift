import Cocoa

@MainActor
protocol TableViewControllerDelegate: AnyObject {
  func didRequestClose()
  func didRequestSwitch()
  func didRequestSearchMode()
}

@MainActor
class TableViewController:
  NSObject,
  NSTableViewDataSource,
  NSTableViewDelegate,
  VimTableViewDelegate
{
  weak var delegate: TableViewControllerDelegate?
  private let dataManager: DataManager
  private weak var tableView: VimTableView?

  init(dataManager: DataManager) {
    self.dataManager = dataManager
    super.init()
  }

  func setupTableView(_ tableView: VimTableView) {
    self.tableView = tableView
    tableView.delegate = self
    tableView.controllerDelegate = self
    tableView.dataSource = self
    tableView.rowHeight = 28
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular

    // Add column
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("column"))
    column.title = "Items"
    tableView.addTableColumn(column)
  }

  func reloadData() {
    tableView?.reloadData()
    guard !dataManager.filteredWindows.isEmpty else { return }
    tableView?.moveSelection(down: true)
  }

  func activateSelected() {
    guard let row = self.tableView?.selectedRow else { return }
    dataManager.filteredWindows[row].activateFn()
  }

  // MARK: - VimTableViewDelegate

  func handleEnterKey() {
    delegate?.didRequestSwitch()
  }

  func handleEscapeKey() {
    delegate?.didRequestClose()
  }

  func handleSlashKey() {
    delegate?.didRequestSearchMode()
  }

  // MARK: - NSTableViewDataSource

  func numberOfRows(in tableView: NSTableView) -> Int {
    return dataManager.filteredWindows.count
  }

  // MARK: - NSTableViewDelegate

  func tableView(
    _ tableView: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int
  ) -> NSView? {
    let cell = NSTableCellView()

    guard row < dataManager.filteredWindows.count else { return cell }
    let window = dataManager.filteredWindows[row]

    let stackView = createWindowRowView(for: window)
    cell.addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -8),
      stackView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
    ])

    return cell
  }

  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return RowView()
  }

  // MARK: - Private Methods

  private func createWindowRowView(for window: SwitchableWindow) -> NSStackView {
    let iconView = createIconView(for: window)
    let appView = createAppNameView(for: window)
    let separatorView = createSeparatorView()
    let titleView = createAppTitleView(for: window)

    let stackView = NSStackView()
    stackView.orientation = .horizontal
    stackView.alignment = .centerY
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false

    stackView.addArrangedSubview(iconView)
    stackView.addArrangedSubview(appView)
    stackView.addArrangedSubview(separatorView)
    stackView.addArrangedSubview(titleView)

    return stackView
  }

  private func createIconView(for window: SwitchableWindow) -> NSImageView {
    let iconView = NSImageView()
    iconView.image = window.icon ?? NSImage(named: NSImage.applicationIconName)
    iconView.imageScaling = .scaleProportionallyUpOrDown
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.setContentHuggingPriority(.required, for: .horizontal)
    iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
    iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true

    return iconView
  }

  private func createAppNameView(for window: SwitchableWindow) -> NSTextField {
    let appView = NSTextField(labelWithString: window.appName)
    appView.font = .systemFont(ofSize: 16)
    appView.textColor = .labelColor
    appView.translatesAutoresizingMaskIntoConstraints = false
    appView.lineBreakMode = .byTruncatingTail
    appView.widthAnchor.constraint(equalToConstant: dataManager.maxAppNameWidth).isActive = true

    return appView
  }

  private func createSeparatorView() -> NSTextField {
    let separatorView = NSTextField(labelWithString: " - ")
    separatorView.font = .systemFont(ofSize: 16)
    separatorView.textColor = .secondaryLabelColor
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    separatorView.setContentHuggingPriority(.required, for: .horizontal)

    return separatorView
  }

  private func createAppTitleView(for window: SwitchableWindow) -> NSTextField {
    let titleView = NSTextField(labelWithString: window.windowTitle)
    titleView.font = .systemFont(ofSize: 16)
    titleView.textColor = .labelColor
    titleView.translatesAutoresizingMaskIntoConstraints = false
    titleView.lineBreakMode = .byTruncatingTail
    titleView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    return titleView
  }

}
