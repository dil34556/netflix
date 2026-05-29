import Cocoa
import WebKit
import AVKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {

    var mainWebView: WKWebView!
    var introWebView: WKWebView!
    var transitionStarted = false

    override func loadView() {
        // 1. ROOT BLACKOUT
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        self.view = view
        
        // 2. MAIN BROWSER (Start invisible)
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let styleSource = "body, html { background-color: black !important; } ::-webkit-scrollbar { display: none; }"
        let userScript = WKUserScript(source: styleSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        mainWebView = WKWebView(frame: .zero, configuration: config)
        mainWebView.navigationDelegate = self
        mainWebView.alphaValue = 0 // Hidden until ready
        mainWebView.setValue(false, forKey: "drawsBackground")
        mainWebView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainWebView)
        
        // 3. INTRO OVERLAY
        let introConfig = WKWebViewConfiguration()
        introConfig.mediaTypesRequiringUserActionForPlayback = []
        
        introWebView = WKWebView(frame: .zero, configuration: introConfig)
        introWebView.setValue(false, forKey: "drawsBackground")
        introWebView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(introWebView)
        
        NSLayoutConstraint.activate([
            mainWebView.topAnchor.constraint(equalTo: view.topAnchor),
            mainWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            introWebView.topAnchor.constraint(equalTo: view.topAnchor),
            introWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            introWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            introWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startAppFlow()
    }

    func startAppFlow() {
        guard let netflixUrl = URL(string: "https://www.netflix.com") else { return }
        mainWebView.load(URLRequest(url: netflixUrl))
        
        guard let introPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "Intro") else {
            self.revealNetflix()
            return
        }
        let introUrl = URL(fileURLWithPath: introPath)
        introWebView.loadFileURL(introUrl, allowingReadAccessTo: introUrl.deletingLastPathComponent())
        
        // Start probing for content after 3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.probeForNetflix()
        }
    }

    func probeForNetflix() {
        let checkScript = "document.querySelector('.profile-gate-label, .browse-navigation') !== null"
        mainWebView.evaluateJavaScript(checkScript) { [weak self] (result, error) in
            if let isReady = result as? Bool, isReady {
                // Content found! Wait 500ms then reveal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.revealNetflix()
                }
            } else {
                if self?.transitionStarted == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.probeForNetflix()
                    }
                }
            }
        }
    }

    func revealNetflix() {
        guard !transitionStarted else { return }
        transitionStarted = true
        
        // 1. Show main webview (still under intro)
        self.mainWebView.alphaValue = 1.0
        
        // 2. Fade out intro
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.5
            self.introWebView.animator().alphaValue = 0
        }, completionHandler: {
            self.introWebView.isHidden = true
            self.introWebView.removeFromSuperview()
        })
    }
}
