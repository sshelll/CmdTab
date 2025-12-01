import Cocoa

@MainActor
class WindowManager {
    private var window: Window?
    
    func createMainWindow() -> Window {
        let width: CGFloat = 600
        let height: CGFloat = 400
        
        let newWindow = Window(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        configureWindow(newWindow)
        self.window = newWindow
        
        return newWindow
    }
    
    private func configureWindow(_ window: Window) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .floating
        window.isMovableByWindowBackground = true
        
        let contentView = createContentView(for: window)
        window.contentView = contentView
    }
    
    private func createContentView(for window: Window) -> NSVisualEffectView {
        let contentView = NSVisualEffectView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        contentView.material = .sidebar
        contentView.state = .active
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 18
        contentView.layer?.masksToBounds = true
        
        return contentView
    }
    
    func showWindow() {
        guard let window = window else { return }
        window.makeKeyAndOrderFront(nil)
        window.center()
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
    
    func getWindow() -> Window? {
        return window
    }
}
