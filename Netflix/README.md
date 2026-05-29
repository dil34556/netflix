# Netflix Mac App

This project was generated based on the instructions in `Netflix-Mac-App-Creation.md`.

## How to Build

Since this project was generated in a Linux environment, you will need a Mac with Xcode 15+ to build and run it.

### 1. Create a new Xcode Project
1. Open Xcode on your Mac.
2. File → New → Project.
3. Choose: **macOS** → **App**.
4. Product Name: **Netflix**.
5. Interface: **Storyboard** (though we use programmatic UI, this sets up the right lifecycle).
6. Language: **Swift**.

### 2. Add the Files
1. In the project navigator, delete `AppDelegate.swift` and `ViewController.swift` (if they exist).
2. Right-click the `Netflix` folder and select **Add Files to "Netflix"...**.
3. Select the files from the `Netflix/Netflix` directory:
   - `AppDelegate.swift`
   - `WebViewController.swift`
   - `MediaKeyHandler.swift`
   - `Info.plist` (You may need to point Xcode to this file in Target Settings -> Info)
   - `Netflix.entitlements` (Point to this in Target Settings -> Build Settings -> Code Signing Entitlements)

### 3. Configure Target Settings
1. **General Tab:** Ensure "Minimum Deployments" is set to macOS 13.0 or higher.
2. **Signing & Capabilities:**
   - Enable **App Sandbox**.
   - Under **App Sandbox**, check **Outgoing Connections (Client)**.
   - You may need to manually add the `com.apple.security.cs.allow-unsigned-executable-memory` entitlement if it's not present.

### 4. App Icon
1. Drag your Netflix icon into `Assets.xcassets` -> `AppIcon`.

### 5. Build and Run
- Press `Cmd + R` to run the app.

## Features
- **Chromeless Window:** Native look with transparent titlebar.
- **Navigation Lock:** Only `netflix.com` and related domains are allowed.
- **External Links:** Open in the default browser.
- **Media Keys:** Play/Pause support (via `MediaKeyHandler`).
- **PiP Support:** Native Picture-in-Picture.
- **Persistent Login:** Uses default `WKWebView` data store.
