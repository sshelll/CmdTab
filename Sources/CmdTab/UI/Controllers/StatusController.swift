import Cocoa

@MainActor
protocol StatusControllerDelegate: AnyObject {
  func didRequestQuit()
  func didRequestShowMainWindow()
}

@MainActor
class StatusController {
  weak var delegate: StatusControllerDelegate?
  private var statusItem: NSStatusItem!

  init() {
    setupStatusItem()
  }

  private func setupStatusItem() {
    // create status bar item
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.title = "⌘Tab"

    // create the inner menu
    let menu = NSMenu()

    let showMainWindowItem = NSMenuItem(
      title: "Open cmd-tab", action: #selector(showMainWindow), keyEquivalent: "o")
    // quitMenuItem.keyEquivalentModifierMask = .command  // this is the default mask key
    showMainWindowItem.target = self
    menu.addItem(showMainWindowItem)

    let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
    quitMenuItem.target = self  // must specify the target, otherwise the item is useless
    menu.addItem(quitMenuItem)

    statusItem.menu = menu
  }

  // notify the AppDelegate to show main window
  @objc private func showMainWindow() {
    print("StatusController: showMainWindow() method called")
    delegate?.didRequestShowMainWindow()
  }

  // notify the AppDelegate to quit
  @objc private func quit() {
    print("StatusController: quit() method called")
    delegate?.didRequestQuit()
  }

}
