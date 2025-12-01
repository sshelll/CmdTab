import Cocoa
import Foundation

@MainActor
protocol DataManagerDelegate: AnyObject {
  func dataManagerDidUpdateData(_ dataManager: DataManager)
}

@MainActor
class DataManager {
  weak var delegate: DataManagerDelegate?

  var switchableWindows: [SwitchableWindow] = [] {
    didSet {
      updateMaxAppNameWidth()
      filterWindows()
    }
  }

  var filteredWindows: [SwitchableWindow] = []
  var maxAppNameWidth: CGFloat = 80

  private var searchQuery: String = "" {
    didSet {
      filterWindows()
    }
  }

  init() {
    loadSwitchableWindows()
  }

  func loadSwitchableWindows() {
    let windows = listSwitchableWindows()
    switchableWindows = windows
    filteredWindows = windows
    notifyDelegate()
  }

  func updateSearchQuery(_ query: String) {
    searchQuery = query
  }

  private func filterWindows() {
    if searchQuery.isEmpty {
      filteredWindows = switchableWindows
    } else {
      filteredWindows = switchableWindows.filter { window in
        window.appName.localizedCaseInsensitiveContains(searchQuery)
          || window.windowTitle.localizedCaseInsensitiveContains(searchQuery)
      }
    }
    // after updating filtered windows, notify the main window to refresh
    notifyDelegate()
  }

  private func updateMaxAppNameWidth() {
    maxAppNameWidth =
      switchableWindows
      .map { window in
        NSString(string: window.appName)
          .size(withAttributes: [.font: NSFont.systemFont(ofSize: 16)])
          .width
      }
      .max() ?? 80
  }

  func addWindows(_ windows: [SwitchableWindow]) {
    switchableWindows.append(contentsOf: windows)
  }

  // notify the main window to refresh
  private func notifyDelegate() {
    delegate?.dataManagerDidUpdateData(self)
  }
}
