# Netflix App - Installation & Testing Guide

This guide covers how to set up and test the Netflix application on both **macOS** and **Linux (Fedora)**.

---

##  macOS Setup (Native Swift App)

### 1. Requirements
- A Mac running **macOS 13.0 (Ventura)** or newer.
- **Xcode 15+** installed from the Mac App Store.

### 2. Project Assembly
1. **Open Xcode** and select "Create a new Xcode project".
2. Choose **macOS** -> **App**.
3. **Product Name:** `Netflix`.
4. **Interface:** Storyboard (The app uses programmatic UI, but this sets the correct lifecycle).
5. **Language:** Swift.
6. **Add Files:** 
   - Delete the default `AppDelegate.swift` and `ViewController.swift`.
   - Right-click the project folder in Xcode and select "Add Files to Netflix...".
   - Select the files from the `/Netflix/Netflix/` folder:
     - `AppDelegate.swift`
     - `WebViewController.swift`
     - `MediaKeyHandler.swift`
     - `Info.plist`
     - `Netflix.entitlements`

### 3. Configuration
- **Signing & Capabilities:** Enable "App Sandbox" and check "Outgoing Connections (Client)".
- **Build Settings:** Ensure the "Code Signing Entitlements" path points to `Netflix.entitlements`.

### 4. Running & Testing
- **Run:** Press `Cmd + R` in Xcode.
- **Manual Test:** 
  - Verify the window has no address bar.
  - Test that external links open in Safari, not the app.
  - Verify media keys (Play/Pause) work.

---

## 🐧 Linux Setup (Fedora - Python/PyQt6)

### 1. Requirements
- Fedora Linux (or any distro with Python 3).
- Internet connection for Netflix DRM.

### 2. Install Dependencies
Open your terminal and run:
```bash
sudo dnf install python3-pyqt6-webengine
```

### 3. Running the App
1. Navigate to the project folder:
   ```bash
   cd netflix-linux
   ```
2. Run the application:
   ```bash
   python3 netflix_app.py
   ```

### 4. Running & Testing
- **Toggle Fullscreen:** Press `F11`.
- **Navigation Check:** Click any external link (like a "Help" link) to ensure it opens in your default system browser (Firefox/Chrome).
- **Persistence:** Log in, close the app, and reopen it to verify you are still logged in.

---

## 🛠 Project Structure
- `Netflix/`: Contains the macOS Swift source files.
- `netflix-linux/`: Contains the Linux Python source files.
