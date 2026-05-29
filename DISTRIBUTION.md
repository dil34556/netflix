# Distribution & Sharing Guide

If you want other people to use your Netflix app, follow these steps to package and share it professionally.

---

##  Sharing the macOS App

To share the Mac app, you can't just send the source code; you need to "Archive" it into a single `.app` file.

### 1. Create the App Bundle
1. In Xcode, go to **Product** -> **Archive**.
2. Once the archive is complete, the "Organizer" window will open.
3. Click **Distribute App** -> **Copy App**.
4. This creates a `Netflix.app` file.

### 2. Handling Security (Gatekeeper)
If you send this `.app` to a friend, their Mac will say it is from an "Unidentified Developer".
- **The Simple Way:** Tell them to **Right-Click** the app and select **Open** (don't just double-click).
- **The Pro Way:** You need an Apple Developer Account ($99/year) to "Notarize" the app, which tells Apple the app is safe.

---

## 🐧 Sharing the Linux App (Fedora/Ubuntu)

Since the Linux version is Python-based, you should turn it into a "Standalone Binary" so others don't have to install Python manually.

### 1. Build a Standalone Binary
Use **PyInstaller** to bundle everything into one file:
```bash
# Install PyInstaller
pip install pyinstaller

# Create the binary
cd netflix-linux
pyinstaller --onefile --windowed --name Netflix netflix_app.py
```
This will create a `dist/` folder containing a single `Netflix` file that others can run.

### 2. Create an App Shortcut (.desktop file)
To make the app appear in the Fedora App Grid, create a file named `netflix.desktop`:
```ini
[Desktop Entry]
Name=Netflix
Exec=/path/to/your/Netflix-binary
Icon=/path/to/icon.png
Type=Application
Categories=Video;Player;
```
Move this to `~/.local/share/applications/`.

---

## 🌐 General Sharing Strategy

### 1. Use GitHub (Recommended)
Upload your code to a GitHub repository.
- Others can "Fork" or "Clone" it.
- You can use **GitHub Actions** to automatically build the Mac `.app` and Linux binary every time you update the code.

### 2. Create a "Release"
On GitHub, go to the "Releases" tab and upload your `Netflix.app` (zipped) and your Linux binary. This gives users a direct download link.
