import AppKit

@MainActor
func AlertCritical(msgText: String, informativeText: String, terminate: Bool = false) {
  let alert = NSAlert()
  alert.messageText = msgText
  alert.informativeText = informativeText
  alert.alertStyle = .critical
  alert.addButton(withTitle: "OK")
  alert.runModal()
  if terminate {
    NSApp.terminate(nil)
  }
}
