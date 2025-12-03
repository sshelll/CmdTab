import Cocoa
import Foundation
import Fuse

// Structure to hold window with its search match information
struct WindowSearchResult {
  let window: SwitchableWindow
  let appNameMatches: [Int]  // Indices of matched characters in app name
  let titleMatches: [Int]  // Indices of matched characters in window title
  let appNameScore: Double  // Fuse score for app name match
  let titleScore: Double  // Fuse score for title match
  let combinedScore: Double  // Combined score for sorting
}

@MainActor
protocol DataManagerDelegate: AnyObject {
  func dataManagerDidUpdateData(_ dataManager: DataManager)
}

@MainActor
class DataManager {
  weak var delegate: DataManagerDelegate?

  let fuse = Fuse()
  private let appOrderManager: AppOrderManager

  var switchableWindows: [SwitchableWindow] = [] {
    didSet {
      updateMaxAppNameWidth()
      filterWindowsByFuse()
    }
  }

  var windowSearchResults: [WindowSearchResult] = []  // Store filtered windows with search details
  var maxAppNameWidth: CGFloat = 50

  // Make searchQuery public so TableViewController can access it for highlighting
  var currentSearchQuery: String {
    return searchQuery
  }

  private var searchQuery: String = "" {
    didSet {
      filterWindowsByFuse()
    }
  }

  init(appOrderManager: AppOrderManager) {
    self.appOrderManager = appOrderManager
  }

  func reloadSwitchableWindows() {
    let windows = listSwitchableWindows()
    switchableWindows = windows
    notifyDelegate()
  }

  func updateSearchQuery(_ query: String) {
    searchQuery = query
  }

  private func filterWindowsByFuse() {
    if searchQuery.isEmpty {
      // When no search query, sort by app activation order
      var sortedWindows = appOrderManager.sortWindowsByAppOrder(switchableWindows) { $0.pid }
      if sortedWindows.count > 1 {
        // swap the first 2
        sortedWindows.swapAt(0, 1)
      }

      windowSearchResults = sortedWindows.map { window in
        WindowSearchResult(
          window: window,
          appNameMatches: [],
          titleMatches: [],
          appNameScore: 1.0,
          titleScore: 1.0,
          combinedScore: 1.0
        )
      }
    } else {
      // Search app names and window titles separately to get individual match indices
      var searchResults: [WindowSearchResult] = []
      let searchPattern = fuse.createPattern(from: searchQuery)

      for window in switchableWindows {
        // let appNameResult = fuse.search(searchQuery, in: [window.appName])
        let appNameResult = fuse.search(searchPattern, in: window.appName)
        let titleResult = fuse.search(searchPattern, in: window.windowTitle)

        // Convert ranges to individual indices for highlighting
        let appNameMatches = appNameResult?.ranges.flatMap { Array($0) } ?? []
        let titleMatches = titleResult?.ranges.flatMap { Array($0) } ?? []

        let appScore = appNameResult?.score ?? 1.0
        let titleScore = titleResult?.score ?? 1.0
        let combinedScore = min(appScore, titleScore)

        // Only include if there's a match in either app name or title
        if combinedScore < 1.0 {
          searchResults.append(
            WindowSearchResult(
              window: window,
              appNameMatches: appNameMatches,
              titleMatches: titleMatches,
              appNameScore: appScore,
              titleScore: titleScore,
              combinedScore: combinedScore
            ))
        }
      }

      // Sort by best match score using the stored scores (no more duplicate searches!)
      searchResults.sort { lhs, rhs in
        return lhs.combinedScore < rhs.combinedScore
      }

      windowSearchResults = searchResults
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

  // notify the main window to refresh
  private func notifyDelegate() {
    delegate?.dataManagerDidUpdateData(self)
  }
}
