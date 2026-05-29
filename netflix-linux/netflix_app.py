import sys
import os
from PyQt6.QtCore import QUrl, Qt, QTimer
from PyQt6.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QStackedWidget
from PyQt6.QtWebEngineWidgets import QWebEngineView
from PyQt6.QtWebEngineCore import QWebEngineProfile, QWebEnginePage, QWebEngineScript

class NetflixPage(QWebEnginePage):
    ALLOWED_HOSTS = ["netflix.com", "www.netflix.com", "nflxvideo.net", "nflximg.net", "nflxso.net", "nflxext.com"]
    def acceptNavigationRequest(self, url, _type, isMainFrame):
        if not isMainFrame or url.isLocalFile(): return True
        host = url.host()
        if not host: return False
        if any(host == allowed or host.endswith("." + allowed) for allowed in self.ALLOWED_HOSTS):
            return True
        else:
            import webbrowser
            webbrowser.open(url.toString())
            return False

class NetflixApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Netflix")
        self.resize(1280, 800)
        self.setStyleSheet("QMainWindow { background-color: #000000; }")
        
        # Use a StackedWidget to hold both views
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)
        
        # 1. Main Netflix View (Bottom of stack)
        self.main_browser = QWebEngineView()
        profile = QWebEngineProfile.defaultProfile()
        profile.setHttpUserAgent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        
        # Hide scrollbars script
        script = QWebEngineScript()
        script.setSourceCode("var style = document.createElement('style'); style.innerHTML = 'body::-webkit-scrollbar { display: none; }'; document.head.appendChild(style);")
        script.setInjectionPoint(QWebEngineScript.InjectionPoint.DocumentReady)
        script.setWorldId(QWebEngineScript.ScriptWorldId.MainWorld)
        script.setRunsOnSubFrames(True)
        profile.scripts().insert(script)
        
        self.main_browser.setPage(NetflixPage(profile, self.main_browser))
        
        # 2. Intro View (Top of stack)
        self.intro_browser = QWebEngineView()
        self.intro_browser.setStyleSheet("background-color: transparent;")
        
        self.stack.addWidget(self.main_browser) # Index 0
        self.stack.addWidget(self.intro_browser) # Index 1
        self.stack.setCurrentIndex(1) # Show Intro first
        
        self.start_app_flow()

    def start_app_flow(self):
        # 1. Start pre-loading Netflix in the background
        self.main_browser.setUrl(QUrl("https://www.netflix.com"))
        
        # 2. Show Intro
        intro_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "intro", "index.html"))
        if os.path.exists(intro_path):
            self.intro_browser.setUrl(QUrl.fromLocalFile(intro_path))
            # Switch to Netflix after 4.5s
            QTimer.singleShot(4500, self.transition_to_main)
        else:
            self.transition_to_main()

    def transition_to_main(self):
        self.stack.setCurrentIndex(0)
        self.intro_browser.deleteLater()

    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_F11:
            if self.isFullScreen(): self.showNormal()
            else: self.showFullScreen()
        super().keyPressEvent(event)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("Netflix")
    window = NetflixApp()
    window.show()
    sys.exit(app.exec())
