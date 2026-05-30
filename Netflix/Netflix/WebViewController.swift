import Cocoa
import WebKit
import AVKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {

    static let allowedHosts = [
        "netflix.com",
        "nflxvideo.net",
        "nflximg.net",
        "nflxso.net",
        "nflxext.com"
    ]

    var mainWebView: WKWebView!
    var introWebView: WKWebView!
    var transitionStarted = false
    private var startupFallbackWorkItem: DispatchWorkItem?

    static func isHostAllowed(_ host: String?) -> Bool {
        guard let host = host?.lowercased(), !host.isEmpty else {
            return false
        }

        return allowedHosts.contains { allowedHost in
            host == allowedHost || host.hasSuffix("." + allowedHost)
        }
    }

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
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        
        let styleSource = """
        (() => {
            const style = document.createElement('style');
            style.textContent = `
                body, html { background-color: black !important; }
                ::-webkit-scrollbar { display: none; }
            `;
            document.documentElement.appendChild(style);
        })();
        """
        let userScript = WKUserScript(source: styleSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        mainWebView = WKWebView(frame: .zero, configuration: config)
        mainWebView.navigationDelegate = self
        mainWebView.uiDelegate = self
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(togglePlayback),
            name: .mediaPlayPause,
            object: nil
        )
    }

    deinit {
        startupFallbackWorkItem?.cancel()
        NotificationCenter.default.removeObserver(self)
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
        
        // Never leave the intro overlay up indefinitely. Login, error, and region pages
        // do not expose the profile/browse selectors used by the readiness probe.
        let fallback = DispatchWorkItem { [weak self] in
            self?.revealNetflix()
        }
        startupFallbackWorkItem = fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: fallback)

        // Start probing for browse content after 3s so returning users transition sooner.
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.probeForNetflix()
                    }
                }
            }
        }
    }

    func revealNetflix() {
        guard !transitionStarted else { return }
        transitionStarted = true
        startupFallbackWorkItem?.cancel()
        startupFallbackWorkItem = nil
        
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

    // MARK: - Navigation

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.isFileURL || Self.isHostAllowed(url.host) {
            decisionHandler(.allow)
            return
        }

        if navigationAction.targetFrame?.isMainFrame == true || navigationAction.targetFrame == nil {
            NSWorkspace.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url, Self.isHostAllowed(url.host) {
            webView.load(URLRequest(url: url))
        } else if let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }

        return nil
    }

    // MARK: - Media controls

    @objc private func togglePlayback() {
        let script = """
        (() => {
            const video = document.querySelector('video');
            if (!video) { return false; }
            if (video.paused) {
                video.play();
            } else {
                video.pause();
            }
            return true;
        })();
        """

        mainWebView.evaluateJavaScript(script, completionHandler: nil)
    }
}
