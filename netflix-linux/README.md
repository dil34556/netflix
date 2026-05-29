# Netflix Linux App (Fedora)

This is a native Linux version of the Netflix app, built using Python and PyQt6. It mimics the behavior of the macOS version by providing a chromeless, dedicated window for Netflix.

## Requirements

You need to install Python and the PyQt6 WebEngine library on Fedora:

```bash
sudo dnf install python3-pyqt6-webengine
```

## How to Run

1. Navigate to this directory:
   ```bash
   cd netflix-linux
   ```
2. Run the application:
   ```bash
   python3 netflix_app.py
   ```

## Features
- **Chromeless Window:** No address bar, tabs, or browser navigation UI.
- **Navigation Lock:** Only Netflix domains are allowed. External links open in your default system browser (Firefox/Chrome).
- **Persistence:** Keeps you logged in between sessions.
- **Fullscreen:** Press `F11` to toggle fullscreen mode.
- **Native Look:** Uses a dark theme for the window container to match Netflix.
