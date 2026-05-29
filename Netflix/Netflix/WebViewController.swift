import Cocoa
import WebKit
import AVKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {

    var mainWebView: WKWebView!
    var introWebView: WKWebView!

    override func loadView() {
        let view = NSView()
        self.view = view
        
        // 1. Setup Main Netflix WebView (Background)
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        
        let styleSource = "body::-webkit-scrollbar { display: none; }"
        let userScript = WKUserScript(source: styleSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        mainWebView = WKWebView(frame: .zero, configuration: config)
        mainWebView.navigationDelegate = self
        mainWebView.uiDelegate = self
        mainWebView.setValue(false, forKey: "drawsBackground")
        mainWebView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainWebView)
        
        // 2. Setup Intro WebView (Foreground)
        let introConfig = WKWebViewConfiguration()
        introConfig.mediaTypesRequiringUserActionForPlayback = []
        
        introWebView = WKWebView(frame: .zero, configuration: introConfig)
        introWebView.setValue(false, forKey: "drawsBackground")
        introWebView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(introWebView)
        
        // Constraints
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
        // Start pre-loading Netflix in the background
        guard let netflixUrl = URL(string: "https://www.netflix.com") else { return }
        mainWebView.load(URLRequest(url: netflixUrl))
        
        // Show Intro
        guard let introPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "Intro") else {
            self.introWebView.isHidden = true
            return
        }
        let introUrl = URL(fileURLWithPath: introPath)
        introWebView.loadFileURL(introUrl, allowingReadAccessTo: introUrl.deletingLastPathComponent())
        
        // Seamless transition after 4.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
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
