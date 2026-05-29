# Netflix Mac App — Build Instructions

## Overview
A native Mac application that wraps Netflix inside a chromeless WKWebView window.
The user gets a 100% native Mac app feel — no browser chrome, no tabs, no URL bar —
just Netflix, behaving like a real macOS app.

---

## Use Case & Requirements

### What the app does
- Launches Netflix directly as a standalone Mac app from the Dock
- Shows Netflix full-screen or windowed with zero browser UI
- Locks navigation to `netflix.com` only — no other sites accessible
- Handles login sessions persistently (user stays logged in)
- Supports native Mac features: PiP, media keys, fullscreen, Stage Manager

### What the app does NOT do
- No address bar
- No tabs
- No browser bookmarks or history UI
- No ability to open other websites
- No intercepting or downloading streams (fully legal, DRM-safe)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9+ |
| UI Framework | AppKit (NSWindow, NSWindowController) |
| Web Engine | WKWebView (WebKit) |
| Media | AVKit (Picture-in-Picture) |
| Build Tool | Xcode 15+ |
| Min OS | macOS 13 Ventura |

---

## Project Setup

### 1. Create Xcode Project
```
1. Open Xcode
2. File → New → Project
3. Choose: macOS → App
4. Product Name: Netflix
5. Interface: Storyboard (or SwiftUI — see note below)
6. Language: Swift
7. Uncheck "Include Tests" (optional)
```

> **Note:** Use AppKit (Storyboard) for maximum native control over the window chrome.

### 2. Configure Info.plist
Add the following keys:

```xml
<!-- Allow Netflix to load -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>netflix.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>

<!-- App name shown in menu bar -->
<key>CFBundleName</key>
<string>Netflix</string>

<!-- Minimum macOS version -->
<key>LSMinimumSystemVersion</key>
<string>13.0</string>
```

### 3. Entitlements
In your `.entitlements` file:

```xml
<key>com.apple.security.network.client</key>
<true/>

<!-- Required for DRM / FairPlay -->
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
```

---

## Core Code

### AppDelegate.swift
```swift
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var webViewController: WebViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        window.center()
        window.title = "Netflix"
        window.minSize = NSSize(width: 800, height: 600)

        webViewController = WebViewController()
        window.contentViewController = webViewController
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
```

---

### WebViewController.swift
```swift
import Cocoa
import WebKit
import AVKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {

    var webView: WKWebView!

    override func loadView() {
        // WKWebView configuration
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"

        // Enable media playback
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        // Allow Picture-in-Picture
        config.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Remove white flash on load
        webView.setValue(false, forKey: "drawsBackground")

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadNetflix()
    }

    func loadNetflix() {
        guard let url = URL(string: "https://www.netflix.com") else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // MARK: - Lock navigation to Netflix only
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let allowedHosts = [
            "netflix.com",
            "www.netflix.com",
            "nflxvideo.net",       // Netflix CDN
            "nflximg.net",         // Netflix images
            "nflxso.net",          // Netflix static assets
            "nflxext.com"          // Netflix extensions/auth
        ]

        let host = url.host ?? ""
        let isAllowed = allowedHosts.contains { host == $0 || host.hasSuffix("." + $0) }

        if isAllowed {
            decisionHandler(.allow)
        } else {
            // Open external links (e.g. password reset emails) in Safari
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }

    // Prevent new windows/tabs from opening
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Load in same view instead of new window
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}
```

---

### Media Key Support (MediaKeyHandler.swift)
```swift
import Cocoa

class MediaKeyHandler {
    static func setup() {
        NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { event in
            // keyCode 16 = Play/Pause, 20 = Previous, 19 = Next
            if event.type == .systemDefined && event.subtype.rawValue == 8 {
                let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
                let keyFlags = (event.data1 & 0x0000FFFF)
                let keyDown = (keyFlags & 0xFF00) >> 8 == 0xA

                if keyDown {
                    switch Int32(keyCode) {
                    case 16: // Play/Pause
                        NotificationCenter.default.post(name: .mediaPlayPause, object: nil)
                    default:
                        break
                    }
                }
            }
            return event
        }
    }
}

extension Notification.Name {
    static let mediaPlayPause = Notification.Name("mediaPlayPause")
}
```

---

## Menu Bar Setup

In `MainMenu.xib` or programmatically, strip the default browser menus and keep only:

```
Netflix (App Menu)
├── About Netflix
├── ─────────────
├── Preferences... (Cmd+,)
├── ─────────────
└── Quit Netflix (Cmd+Q)

Window
├── Minimize (Cmd+M)
├── Zoom
├── ─────────────
├── Enter Full Screen (Ctrl+Cmd+F)
└── Picture in Picture
```

Remove: Edit, Format, View, History, Bookmarks, Help (browser defaults)

---

## App Icon

1. Design or download a 1024x1024 Netflix icon (the red N)
2. Use [Icon Set Creator](https://apps.apple.com/app/icon-set-creator/id939343785) or `iconutil` to generate `.icns`
3. Drag into `Assets.xcassets → AppIcon`

---

## Persistent Login (Cookie Storage)

WKWebView stores cookies automatically in its own data store.
To make login persist across app restarts, use the default (non-ephemeral) configuration:

```swift
// DO use default config (persists cookies):
let config = WKWebViewConfiguration()

// DO NOT use this (clears on quit):
// config.websiteDataStore = .nonPersistent()
```

---

## Picture-in-Picture

WKWebView on macOS 13+ supports PiP natively via the Netflix player controls.
No extra code needed — the PiP button appears in the Netflix video player automatically.

To add a menu bar shortcut:
```swift
// In your menu action:
@IBAction func enterPiP(_ sender: Any) {
    webView.evaluateJavaScript(
        "document.querySelector('video')?.webkitSetPresentationMode('picture-in-picture')",
        completionHandler: nil
    )
}
```

---

## Build & Run

```bash
# Open project
open Netflix.xcodeproj

# Build (Cmd+B)
# Run  (Cmd+R)

# Archive for distribution
# Product → Archive → Distribute App
```

---

## Optional Enhancements (Phase 2)

| Feature | How |
|---------|-----|
| Dark mode titlebar | `window.appearance = NSAppearance(named: .darkAqua)` |
| Keyboard shortcut for fullscreen | `Ctrl+Cmd+F` via menu |
| Loading screen | Show Netflix logo while page loads |
| Offline error screen | Custom WKWebView error handler |
| Touch Bar support | `NSTouchBar` with play/pause button |
| Auto-launch on login | `SMLoginItemSetEnabled` |
| Sparkle auto-updater | Add [Sparkle framework](https://sparkle-project.org) |

---

## Distribution Options

| Method | Details |
|--------|---------|
| **Direct download** | Archive → Export `.app` → zip & share |
| **Mac App Store** | Requires Apple Developer account ($99/yr), sandboxing review |
| **Notarization** | Required for Gatekeeper on macOS 13+ if distributing outside App Store |

---

## AI Prompt to Build This

Use this prompt with Claude or any AI coding assistant to generate the full project:

```
Build a native macOS app using Swift, AppKit, and WKWebView that works as a 
dedicated Netflix client. Requirements:

1. The app opens netflix.com in a WKWebView that fills the entire window
2. No browser chrome — no address bar, no tabs, no bookmarks toolbar
3. The window titlebar should be transparent and hidden (fullSizeContentView)
4. Lock all navigation to netflix.com and its CDN subdomains only. Any 
   external links should open in the default browser instead.
5. Prevent new windows or tabs from opening — load everything in the same view
6. Persist login cookies between sessions using the default WKWebView data store
7. Support Picture-in-Picture via the native video player controls
8. Strip the menu bar to only: App menu (About, Preferences, Quit) and Window menu
9. Set the user agent to Safari so Netflix serves the correct experience
10. Minimum macOS target: 13.0 Ventura
11. App should feel 100% native — no visible browser elements at any time

Generate: AppDelegate.swift, WebViewController.swift, Info.plist configuration,
and entitlements file. Use AppKit (not SwiftUI) for maximum window control.
```

---

*Stack: Swift 5.9 · AppKit · WKWebView · AVKit · Xcode 15 · macOS 13+*
