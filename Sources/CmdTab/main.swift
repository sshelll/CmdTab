import Cocoa

// Check for accessibility permissions and prompt if needed
func checkAccessibilityPermissions() -> Bool {
  // Use string literal to avoid concurrency safety issues
  let options: [String: Any] = [
    "AXTrustedCheckOptionPrompt": true
  ]

  return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

func printSwitchableWindows() {
  print("Switchable Windows")
  print("============")
  let switchableApps = listSwitchableWindows()
  for app in switchableApps {
    print(app)
    print("============")
  }
}

func main() {
  guard checkAccessibilityPermissions() else {
    print("Need accessibility")
    return
  }
  printSwitchableWindows()
}

main()
