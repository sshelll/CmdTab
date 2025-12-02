import Cocoa
import Foundation

/// Manages the order of applications based on their activation history
/// Maintains a list of process identifiers (PIDs) ordered by most recently activated
@MainActor
class AppOrderManager {
  /// Array of PIDs ordered by activation time (most recent first)
  private var orderedPids: [pid_t] = []

  /// Maximum number of PIDs to keep in memory to prevent unbounded growth
  private let maxPidsToTrack = 100

  init() {
    // Initialize with currently running applications
    initializeWithRunningApps()
  }

  /// Initialize the order with currently running applications
  private func initializeWithRunningApps() {
    let runningApps = NSWorkspace.shared.runningApplications

    // Filter out system apps and add regular apps to the order
    for app in runningApps {
      if app.activationPolicy == .regular {
        orderedPids.append(app.processIdentifier)
      }
    }

    // Limit to max tracking size
    if orderedPids.count > maxPidsToTrack {
      orderedPids = Array(orderedPids.prefix(maxPidsToTrack))
    }
  }

  /// Called when an application is activated
  /// Moves the PID to the front of the order array
  func applicationActivated(pid: pid_t) {
    // Remove the PID if it already exists in the array
    orderedPids.removeAll { $0 == pid }

    // Add it to the front (most recent)
    orderedPids.insert(pid, at: 0)

    // Maintain maximum size
    if orderedPids.count > maxPidsToTrack {
      orderedPids = Array(orderedPids.prefix(maxPidsToTrack))
    }
  }

  /// Called when an application quits
  /// Removes the PID from the order array
  func applicationQuit(pid: pid_t) {
    orderedPids.removeAll { $0 == pid }
  }

  /// Returns the current order of PIDs (most recent first)
  func getOrderedPids() -> [pid_t] {
    return orderedPids
  }

  /// Sorts an array of SwitchableWindows by app activation order
  /// Windows from apps in the order list come first, sorted by their order
  /// Windows from apps not in the order list come after, in their original order
  func sortWindowsByAppOrder<T>(_ windows: [T], pidExtractor: (T) -> pid_t) -> [T] {
    return windows.sorted { window1, window2 in
      let pid1 = pidExtractor(window1)
      let pid2 = pidExtractor(window2)

      let index1 = getPriorityIndex(for: pid1)
      let index2 = getPriorityIndex(for: pid2)

      switch (index1, index2) {
      case (.some(let i1), .some(let i2)):
        // Both PIDs are in the order list, sort by their order
        return i1 < i2
      case (.some, .none):
        // Only first PID is in order list, it comes first
        return true
      case (.none, .some):
        // Only second PID is in order list, it comes first
        return false
      case (.none, .none):
        // Neither PID is in order list, maintain original order
        return false
      }
    }
  }

  /// Returns the priority index for a given PID
  /// Lower index means higher priority (more recently activated)
  /// Returns nil if PID is not found in the order
  private func getPriorityIndex(for pid: pid_t) -> Int? {
    return orderedPids.firstIndex(of: pid)
  }

  /// Debug method to print current order
  func printCurrentOrder() {
    print("Current app order (PIDs): \(orderedPids)")
  }
}
