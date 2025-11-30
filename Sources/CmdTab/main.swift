import Cocoa

// TEST: test only
func printSwitchableWindows() {
  print("Switchable Windows")
  print("============")
  let switchableApps = listSwitchableWindows()
  for app in switchableApps {
    print(app)
    print("============")
  }
}

@MainActor
func main() {
  guard checkAccessibilityPermissions() else {
    print("Need accessibility")
    return
  }

  printSwitchableWindows()

  let app = NSApplication.shared
  let delegate = AppDelegate()
  app.delegate = delegate
  app.setActivationPolicy(.regular)
  app.run()
}

main()
