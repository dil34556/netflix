import Cocoa
import WebKit
import AVKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {

    var mainWebView: WKWebView!
    var introWebView: WKWebView!
    
    var netflixReady = false
    var introFinished = false
    var transitionStarted = false

    override func loadView() {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        self.view = view
        
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        
        let styleSource = """
            document.documentElement.style.backgroundColor = 'black';
            var style = document.createElement('style');
            style.innerHTML = 'html, body { background-color: black !important; } ::-webkit-scrollbar { display: none; }';
            document.head.appendChild(style);
        """
        let userScript = WKUserScript(source: styleSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        mainWebView = WKWebView(frame: .zero, configuration: config)
        mainWebView.navigationDelegate = self
        mainWebView.uiDelegate = self
        mainWebView.setValue(false, forKey: "drawsBackground") 
        mainWebView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainWebView)
        
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
        
        // Start probing for content
        probeForNetflixContent()
        
        guard let introPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "Intro") else {
            self.introWebView.isHidden = true
            return
        }
        let introUrl = URL(fileURLWithPath: introPath)
        introWebView.loadFileURL(introUrl, allowingReadAccessTo: introUrl.deletingLastPathComponent())
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.7) { [weak self] in
            self?.introFinished = true
            self?.checkTransition()
        }
    }

    func probeForNetflixContent() {
        let checkScript = "document.querySelector('.profile-gate-label, .browse-navigation, .watch-video') !== null"
        mainWebView.evaluateJavaScript(checkScript) { [weak self] (result, error) in
            if let isReady = result as? Bool, isReady {
                // Content found! Wait 300ms then transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.netflixReady = true
                    self?.checkTransition()
                }
            } else {
                // Not ready, probe again in 200ms
                if self?.transitionStarted == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.probeForNetflixContent()
                    }
                }
            }
        }
    }

    func checkTransition() {
        if netflixReady && introFinished && !transitionStarted {
            transitionStarted = true
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1.2
                self.introWebView.animator().alphaValue = 0
            }, completionHandler: {
                self.introWebView.isHidden = true
                self.introWebView.removeFromSuperview()
            })
        }
    }

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
