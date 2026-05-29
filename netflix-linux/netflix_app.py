import sys
import os
from PyQt6.QtCore import QUrl, Qt, QTimer
from PyQt6.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QStackedWidget
from PyQt6.QtWebEngineWidgets import QWebEngineView
from PyQt6.QtWebEngineCore import QWebEngineProfile, QWebEnginePage, QWebEngineScript, QWebEngineSettings

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
        
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)
        
        # 1. Main Netflix View
        self.main_browser = QWebEngineView()
        self.main_browser.setStyleSheet("background-color: #000000;")
        profile = QWebEngineProfile.defaultProfile()
        profile.setHttpUserAgent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        
        script = QWebEngineScript()
        script.setSourceCode("var style = document.createElement('style'); style.innerHTML = 'body::-webkit-scrollbar { display: none; }'; document.head.appendChild(style);")
        script.setInjectionPoint(QWebEngineScript.InjectionPoint.DocumentReady)
        script.setWorldId(QWebEngineScript.ScriptWorldId.MainWorld)
        script.setRunsOnSubFrames(True)
        profile.scripts().insert(script)
        
        self.main_browser.setPage(NetflixPage(profile, self.main_browser))
        
        # 2. Intro View
        self.intro_browser = QWebEngineView()
        self.intro_browser.setStyleSheet("background-color: #000000;")
        
        # Enable autoplay without user interaction
        self.intro_browser.settings().setAttribute(
            QWebEngineSettings.WebAttribute.PlaybackRequiresUserGesture, False
        )
        
        self.stack.addWidget(self.main_browser) # Index 0
        self.stack.addWidget(self.intro_browser) # Index 1
        self.stack.setCurrentIndex(1)
        
        self.start_app_flow()

    def start_app_flow(self):
        # Pre-load Netflix
        self.main_browser.setUrl(QUrl("https://www.netflix.com"))
        
        intro_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "intro", "index.html"))
        if os.path.exists(intro_path):
            self.intro_browser.setUrl(QUrl.fromLocalFile(intro_path))
            # Increase overlap slightly to 4.7s to ensure main browser has painted
            QTimer.singleShot(4700, self.transition_to_main)
        else:
            self.transition_to_main()

    def transition_to_main(self):
        # Final smoothness: Ensure main browser is showing before deleting intro
        self.stack.setCurrentIndex(0)
        # Delay deletion of intro slightly to avoid 'nano-sec' gap
        QTimer.singleShot(100, lambda: self.intro_browser.deleteLater())

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
