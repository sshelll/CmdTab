import Cocoa

@MainActor
protocol SearchControllerDelegate: AnyObject {
  func didRequestNormalMode()
  func didRequestSwitch()
}

@available(macOS 12.0, *)
@MainActor
class SearchController: NSObject {
  weak var delegate: SearchControllerDelegate?
  private let dataManager: DataManager
  private let tableViewController: TableViewController
  private weak var searchCoordinator: GlassmorphismSearchCoordinator?

  init(dataManager: DataManager, tableViewController: TableViewController) {
    self.dataManager = dataManager
    self.tableViewController = tableViewController
    super.init()
  }

  func setupSearchCoordinator(_ coordinator: GlassmorphismSearchCoordinator) {
    self.searchCoordinator = coordinator
  }

  func clearSearch() {
    searchCoordinator?.setText("")
    dataManager.updateSearchQuery("")
    tableViewController.reloadData()
  }
}
