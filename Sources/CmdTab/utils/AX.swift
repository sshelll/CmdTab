import AppKit

func checkAccessibilityPermissions() -> Bool {
  // Use string literal to avoid concurrency safety issues
  let options: [String: Any] = [
    "AXTrustedCheckOptionPrompt": true
  ]

  return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

@MainActor
@available(macOS 13.0, *)
func isDarkMode() -> Bool {
  return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
}
