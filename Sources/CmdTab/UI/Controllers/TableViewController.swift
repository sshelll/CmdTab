import Cocoa

@MainActor
protocol TableViewControllerDelegate: AnyObject {
  func didRequestClose()
  func didRequestSwitch()
  func didRequestSearchMode()
}

@available(macOS 13.0, *)
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
    guard !dataManager.windowSearchResults.isEmpty else { return }
    tableView?.moveSelection(down: true)
  }

  func activateSelected() {
    guard let row = self.tableView?.selectedRow else { return }
    dataManager.windowSearchResults[row].window.activateFn()
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
    return dataManager.windowSearchResults.count
  }

  // MARK: - NSTableViewDelegate

  func tableView(
    _ tableView: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int
  ) -> NSView? {
    let cell = NSTableCellView()

    guard row < dataManager.windowSearchResults.count else { return cell }
    let searchResult = dataManager.windowSearchResults[row]

    let stackView = createWindowRowView(for: searchResult)
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

  private func createWindowRowView(for searchResult: WindowSearchResult) -> NSStackView {
    let isDark = isDarkMode()
    let sepColor: NSColor = isDark ? .secondaryLabelColor : .black
    let textColor: NSColor = isDark ? .labelColor : .black
    let highlightColor: NSColor = isDark ? .systemYellow : .controlAccentColor

    let window = searchResult.window
    let iconView = createIconView(for: window)
    let appView = createAppNameView(for: searchResult, textColor: textColor, hi: highlightColor)
    let separatorView = createSeparatorView(color: sepColor)
    let titleView = createAppTitleView(for: searchResult, textColor: textColor, hi: highlightColor)

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

  private func createAppNameView(
    for searchResult: WindowSearchResult,
    textColor: NSColor, hi: NSColor
  ) -> NSTextField {
    let appView = NSTextField()

    appView.attributedStringValue = createHighlightedTextWithIndices(
      text: searchResult.window.appName,
      matchIndices: searchResult.appNameMatches,
      font: .systemFont(ofSize: 16),
      textColor: textColor,
      // TODO: customized theme
      highlightColor: hi,
    )
    appView.isEditable = false
    appView.isBordered = false
    appView.backgroundColor = .clear
    appView.translatesAutoresizingMaskIntoConstraints = false
    appView.widthAnchor.constraint(equalToConstant: dataManager.maxAppNameWidth).isActive = true

    return appView
  }

  private func createSeparatorView(color textColor: NSColor) -> NSTextField {
    let separatorView = NSTextField(labelWithString: " - ")
    separatorView.font = .systemFont(ofSize: 16)
    separatorView.textColor = textColor
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    separatorView.setContentHuggingPriority(.required, for: .horizontal)

    return separatorView
  }

  private func createAppTitleView(
    for searchResult: WindowSearchResult,
    textColor: NSColor, hi: NSColor
  ) -> NSTextField {
    let titleView = NSTextField()

    titleView.attributedStringValue = createHighlightedTextWithIndices(
      text: searchResult.window.windowTitle,
      matchIndices: searchResult.titleMatches,
      font: .systemFont(ofSize: 16),
      textColor: textColor,
      // TODO: customized theme
      highlightColor: hi,
    )
    titleView.isEditable = false
    titleView.isBordered = false
    titleView.backgroundColor = .clear
    titleView.translatesAutoresizingMaskIntoConstraints = false
    titleView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    return titleView
  }

  // MARK: - Text Highlighting Helper

  private func createHighlightedTextWithIndices(
    text: String,
    matchIndices: [Int],
    font: NSFont,
    textColor: NSColor,
    highlightColor: NSColor
  ) -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: text)

    // Create paragraph style for line breaking
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byTruncatingTail

    // Set default attributes including paragraph style
    attributedString.addAttribute(
      .font, value: font, range: NSRange(location: 0, length: text.count))
    attributedString.addAttribute(
      .foregroundColor, value: textColor, range: NSRange(location: 0, length: text.count))
    attributedString.addAttribute(
      .paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))

    // Highlight individual characters based on match indices from Fuse
    for index in matchIndices {
      guard index < text.count else { continue }
      let nsRange = NSRange(location: index, length: 1)
      attributedString.addAttribute(.foregroundColor, value: highlightColor, range: nsRange)
    }

    return attributedString
  }
}
