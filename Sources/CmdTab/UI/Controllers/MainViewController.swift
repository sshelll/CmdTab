import Cocoa

@available(macOS 12.0, *)
@MainActor
class MainViewController:
  DataManagerDelegate,
  TableViewControllerDelegate
{
  private let appOrderManager: AppOrderManager
  private let dataManager: DataManager
  private let windowManager: WindowManager
  private let appObserver: AppObserver

  private let tableViewController: TableViewController
  private let searchController: SearchController

  // 替换为 SwiftUI 搜索框协调器
  private var searchCoordinator: GlassmorphismSearchCoordinator!
  private var tableView: VimTableView!

  init() {
    self.appOrderManager = AppOrderManager()
    self.dataManager = DataManager(appOrderManager: appOrderManager)
    self.windowManager = WindowManager()
    self.appObserver = AppObserver(appOrderManager: appOrderManager)

    self.tableViewController = TableViewController(dataManager: dataManager)
    self.searchController = SearchController(
      dataManager: dataManager,
      tableViewController: tableViewController
    )

    // Set up delegation
    self.dataManager.delegate = self
    self.tableViewController.delegate = self
  }

  func setupMainWindow() {
    let window = windowManager.createMainWindow()

    guard let contentView = window.contentView else {
      fatalError("Window content view is nil")
    }

    setupUI(in: contentView)
  }

  func showWindow() {
    dataManager.reloadSwitchableWindows()
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
    let _ = searchCoordinator.becomeFirstResponder()
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
    searchController.setupSearchCoordinator(searchCoordinator)
    tableViewController.setupTableView(tableView)
  }

  private func createSearchField(in view: NSView) {
    searchCoordinator = GlassmorphismSearchCoordinator()

    // search text change
    searchCoordinator.onTextChange = { [weak self] text in
      guard let self = self else { return }
      self.dataManager.updateSearchQuery(text)
      self.tableViewController.reloadData()
    }

    // move selection
    searchCoordinator.onMoveDown = { [weak self] in
      self?.tableView.moveSelection(down: true)
    }

    searchCoordinator.onMoveUp = { [weak self] in
      self?.tableView.moveSelection(down: false)
    }

    searchCoordinator.onEnter = { [weak self] in
      guard let self = self else { return }
      self.didRequestSwitch()
    }

    searchCoordinator.onEscape = { [weak self] in
      guard let self = self else { return }
      self.didRequestNormalMode()
    }

    let hostingView = searchCoordinator.createHostingView()
    view.addSubview(hostingView)
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
    guard let searchView = searchCoordinator.getHostingView() else { return }

    NSLayoutConstraint.activate([
      // Search field constraints
      searchView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      searchView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      searchView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      searchView.heightAnchor.constraint(equalToConstant: 44),

      // ScrollView constraints
      scrollView.topAnchor.constraint(equalTo: searchView.bottomAnchor, constant: 10),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
    ])
  }
}
