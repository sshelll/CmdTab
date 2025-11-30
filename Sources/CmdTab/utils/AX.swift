import AppKit

func checkAccessibilityPermissions() -> Bool {
  // Use string literal to avoid concurrency safety issues
  let options: [String: Any] = [
    "AXTrustedCheckOptionPrompt": true
  ]

  return AXIsProcessTrustedWithOptions(options as CFDictionary)
}
