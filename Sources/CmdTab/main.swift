import Cocoa

@MainActor
func main() {
  // Check accessibility permissions first
  guard checkAccessibilityPermissions() else {
    print(
      "Accessibility permissions required. Please grant permissions in System Preferences > Security & Privacy > Privacy > Accessibility and run the app again."
    )
    return
  }

  // Setup application
  let app = NSApplication.shared
  let delegate = AppDelegate()

  // Configure and run the application
  app.delegate = delegate
  app.setActivationPolicy(.regular)
  app.run()
}

main()
