import Cocoa
import WebKit
import AVKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {

    var mainWebView: WKWebView!
    var introWebView: WKWebView!

    override func loadView() {
        // 1. ROOT VIEW - PURE BLACK (The ultimate safety layer)
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        self.view = view
        
        // 2. Setup Main Netflix WebView
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        
        // AGGRESSIVE ANTI-WHITE: Force black body and hide scrollbars
        let styleSource = """
            body { background-color: black !important; color: white !important; }
            html { background-color: black !important; }
            ::-webkit-scrollbar { display: none; }
        """
        let userScript = WKUserScript(source: styleSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        mainWebView = WKWebView(frame: .zero, configuration: config)
        mainWebView.navigationDelegate = self
        mainWebView.uiDelegate = self
        
        // Make WebView transparent so the black root view shows through
        mainWebView.setValue(false, forKey: "drawsBackground") 
        mainWebView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainWebView)
        
        // 3. Setup Intro WebView (Top Layer)
        let introConfig = WKWebViewConfiguration()
        introConfig.mediaTypesRequiringUserActionForPlayback = []
        
        introWebView = WKWebView(frame: .zero, configuration: introConfig)
        introWebView.setValue(false, forKey: "drawsBackground") // Also transparent
        introWebView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(introWebView)
        
        // Constraints to fill window
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
        // Load Netflix in background
        guard let netflixUrl = URL(string: "https://www.netflix.com") else { return }
        mainWebView.load(URLRequest(url: netflixUrl))
        
        // Load Intro
        guard let introPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "Intro") else {
            self.introWebView.isHidden = true
            return
        }
        let introUrl = URL(fileURLWithPath: introPath)
        introWebView.loadFileURL(introUrl, allowingReadAccessTo: introUrl.deletingLastPathComponent())
        
        // Seamless transition after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.7) { [weak self] in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1.2 // Smooth cross-fade
                self?.introWebView.animator().alphaValue = 0
            }, completionHandler: {
                self?.introWebView.isHidden = true
                self?.introWebView.removeFromSuperview()
            })
        }
    }

    // MARK: - Navigation Delegate
    static func isHostAllowed(_ host: String?) -> Bool {
        guard let host = host else { return false }
        let allowedHosts = ["netflix.com", "www.netflix.com", "nflxvideo.net", "nflximg.net", "nflxso.net", "nflxext.com"]
        return allowedHosts.contains { host == $0 || host.hasSuffix("." + $0) }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if url.isFileURL {
            decisionHandler(.allow)
            return
        }

        if WebViewController.isHostAllowed(url.host) {
            decisionHandler(.allow)
        } else {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
