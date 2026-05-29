import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var webViewController: WebViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        
        let windowRect = NSRect(x: 0, y: 0, width: 1280, height: 800)

        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Hide title bar for clean look
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .darkAqua) // Force Dark Mode for Netflix look
        window.center()
        window.title = "Netflix"
        window.minSize = NSSize(width: 800, height: 600)

        webViewController = WebViewController()
        window.contentViewController = webViewController
        window.makeKeyAndOrderFront(nil)
        
        MediaKeyHandler.setup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        appMenu.addItem(withTitle: "About Netflix", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences...", action: nil, keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Netflix", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Window Menu
        let windowMenu = NSMenu(title: "Window")
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f").keyEquivalentModifierMask = [.control, .command]
        
        NSApp.mainMenu = mainMenu
    }
}
