import Cocoa

@MainActor
class MainViewController:
  DataManagerDelegate,
  SearchControllerDelegate,
  TableViewControllerDelegate
{
  private let appOrderManager: AppOrderManager
  private let dataManager: DataManager
  private let windowManager: WindowManager
  private let appObserver: AppObserver

  private let tableViewController: TableViewController
  private let searchController: SearchController

  private var searchField: NSSearchField!
  private var tableView: VimTableView!

  init() {
    self.appOrderManager = AppOrderManager()
    self.dataManager = DataManager(appOrderManager: appOrderManager)
    self.windowManager = WindowManager()
    self.appObserver = AppObserver(appOrderManager: appOrderManager)

    self.tableViewController = TableViewController(dataManager: dataManager)
    self.searchController = SearchController(
      dataManager: dataManager,
      tableViewController: tableViewController,
    )

    // Set up delegation
    self.dataManager.delegate = self
    self.searchController.delegate = self
    self.tableViewController.delegate = self
  }

  func setupMainWindow() -> Window {
    let window = windowManager.createMainWindow()

    guard let contentView = window.contentView else {
      fatalError("Window content view is nil")
    }

    setupUI(in: contentView)

    return window
  }

  func showWindow() {
    dataManager.loadSwitchableWindows()
    searchController.clearSearch()
    windowManager.showWindow()
    windowManager.getWindow()?.makeFirstResponder(tableView)
  }

  // MARK: - SearchControllerDelegate + TableViewControllerDelegate

  func didRequestClose() {
    windowManager.hideWindow()
  }

  func didRequestSwitch() {
    tableViewController.activateSelected()
    didRequestClose()
  }

  func didRequestSearchMode() {
    windowManager.getWindow()?.makeFirstResponder(searchField)
  }

  func didRequestNormalMode() {
    windowManager.getWindow()?.makeFirstResponder(tableView)
  }

  // MARK: - Cleanup

  func cleanup() {
    appObserver.cleanup()
  }

  // MARK: - DataManagerDelegate

  func dataManagerDidUpdateData(_ dataManager: DataManager) {
    tableViewController.reloadData()
  }

  // MARK: - Private Methods

  private func setupUI(in view: NSView) {
    createSearchField(in: view)
    createScrollView(in: view)
    setupConstraints(in: view)

    // Setup controllers to control inner views
    searchController.setupSearchField(searchField, tableView: tableView)
    tableViewController.setupTableView(tableView)
  }

  private func createSearchField(in view: NSView) {
    searchField = NSSearchField()
    searchField.translatesAutoresizingMaskIntoConstraints = false
    searchField.placeholderString = "press 'i', '/' or 'a' to search and press esc to quit"
    // searchField.placeholderString = "press 'i', '/' or 'a' to search and press esc to quit"
    // if #available(macOS 10.14, *) {
    //   searchField.appearance = NSAppearance(named: .aqua)
    // }
    view.addSubview(searchField)
  }

  private func createScrollView(in view: NSView) {
    let scrollView = NSScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.drawsBackground = false
    scrollView.hasVerticalScroller = true
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = NSEdgeInsetsZero

    tableView = VimTableView()
    scrollView.documentView = tableView
    view.addSubview(scrollView)
  }

  private func setupConstraints(in view: NSView) {
    guard let scrollView = tableView.enclosingScrollView else { return }

    NSLayoutConstraint.activate([
      // Search field constraints
      searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      searchField.heightAnchor.constraint(equalToConstant: 30),

      // ScrollView constraints
      scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
    ])
  }
}
