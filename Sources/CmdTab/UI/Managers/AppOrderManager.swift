import Cocoa
import Foundation

/// Manages the order of applications based on their activation history
/// Maintains a list of process identifiers (PIDs) ordered by most recently activated
@MainActor
class AppOrderManager {
  /// Node in the doubly linked list
  private class Node {
    let pid: pid_t
    var prev: Node?
    var next: Node?

    init(pid: pid_t) {
      self.pid = pid
    }
  }

  /// Head of the linked list (most recently activated)
  private var head: Node?

  /// Tail of the linked list (least recently activated)
  private var tail: Node?

  /// Map for O(1) lookup of nodes by PID
  private var pidToNode: [pid_t: Node] = [:]

  /// Current number of tracked PIDs
  private var count = 0

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
        addToHead(pid: app.processIdentifier)
      }
    }
  }

  /// Adds a node to the head of the linked list
  private func addToHead(pid: pid_t) {
    // Check if we've reached the maximum capacity
    if count >= maxPidsToTrack {
      // Remove the tail node to make space
      removeTail()
    }

    let newNode = Node(pid: pid)
    pidToNode[pid] = newNode

    if head == nil {
      // Empty list
      head = newNode
      tail = newNode
    } else {
      // Add to head
      newNode.next = head
      head?.prev = newNode
      head = newNode
    }

    count += 1
  }

  /// Removes a node from the linked list
  private func removeNode(_ node: Node) {
    if node.prev != nil {
      node.prev?.next = node.next
    } else {
      // Node is head
      head = node.next
    }

    if node.next != nil {
      node.next?.prev = node.prev
    } else {
      // Node is tail
      tail = node.prev
    }

    pidToNode.removeValue(forKey: node.pid)
    count -= 1
  }

  /// Removes the tail node
  private func removeTail() {
    guard let tailNode = tail else { return }
    removeNode(tailNode)
  }

  /// Moves an existing node to the head of the list
  private func moveToHead(_ node: Node) {
    // If already at head, do nothing
    if node === head { return }

    // Remove from current position
    if node.prev != nil {
      node.prev?.next = node.next
    }

    if node.next != nil {
      node.next?.prev = node.prev
    } else {
      // Node was tail
      tail = node.prev
    }

    // Add to head
    node.prev = nil
    node.next = head
    head?.prev = node
    head = node
  }

  /// Called when an application is activated
  /// Moves the PID to the front of the order list
  func applicationActivated(pid: pid_t) {
    if let existingNode = pidToNode[pid] {
      // PID already exists, move it to head
      moveToHead(existingNode)
    } else {
      // New PID, add it to head
      addToHead(pid: pid)
    }
  }

  /// Called when an application quits
  /// Removes the PID from the order list
  func applicationQuit(pid: pid_t) {
    if let node = pidToNode[pid] {
      removeNode(node)
    }
  }

  /// Returns the current order of PIDs (most recent first)
  func getOrderedPids() -> [pid_t] {
    var result: [pid_t] = []
    var current = head
    while let node = current {
      result.append(node.pid)
      current = node.next
    }
    return result
  }

  /// Sorts an array of SwitchableWindows by app activation order
  /// Windows from apps in the order list come first, sorted by their order
  /// Windows from apps not in the order list come after, in their original order
  func sortWindowsByAppOrder<T>(_ windows: [T], pidExtractor: (T) -> pid_t) -> [T] {
    // Pre-compute priority indices for all PIDs in one pass
    // This avoids O(n) lookup for each comparison during sorting
    let priorityMap = self.getPriorityIndexMap()

    return windows.sorted { window1, window2 in
      let pid1 = pidExtractor(window1)
      let pid2 = pidExtractor(window2)

      let index1 = priorityMap[pid1]
      let index2 = priorityMap[pid2]

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

  /// Returns the priority index map of current state
  private func getPriorityIndexMap() -> [pid_t: Int] {
    var priorityMap: [pid_t: Int] = [:]
    var priority = 0
    var current = head
    while let node = current {
      priorityMap[node.pid] = priority
      priority += 1
      current = node.next
    }
    return priorityMap
  }

  /// Debug method to print current order
  func printCurrentOrder() {
    print("Current app order (PIDs): \(getOrderedPids())")
  }
}
