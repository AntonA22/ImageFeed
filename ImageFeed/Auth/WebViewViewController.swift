//
//  WebViewViewControlle.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 01.02.2026.
//

import UIKit
import WebKit

enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

final class WebViewViewController: UIViewController {
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!

    weak var delegate: WebViewViewControllerDelegate?
    
    private var estimatedProgressObservation: NSKeyValueObservation?
    private var handledAuthorizationCode: String?
   
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        progressView.progress = 0
        progressView.isHidden = false

        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
            options: [.new]
        ) { [weak self] _, _ in
            self?.updateProgress()
        }

        loadAuthView()
    }
    
    deinit {
        estimatedProgressObservation?.invalidate()
    }
    
    private func updateProgress() {
        let progress = webView.estimatedProgress
        progressView.progress = Float(progress)

        // скрываем прогресс, когда загрузка почти 100%
        progressView.isHidden = fabs(progress - 1.0) <= 0.0001
    }
    
    private func loadAuthView() {
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            print("WebViewViewController: URLComponents init failed for authorize URL")
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
           print("WebViewViewController: urlComponents.url is nil. components=\(urlComponents)")
           return
       }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let code = code(from: navigationAction) {
            if handledAuthorizationCode == code {
                decisionHandler(.cancel)
                return
            }
            handledAuthorizationCode = code
            decisionHandler(.cancel)  // сначала cancel
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            return
        }
        decisionHandler(.allow)
    }

    private func code(from navigationAction: WKNavigationAction) -> String? {
        guard
            let url = navigationAction.request.url,
            url.host == "unsplash.com",
            url.path == "/oauth/authorize/native",
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else { return nil }

        return code
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        // Expected for OAuth redirect: we cancel navigation after extracting code.
        if nsError.domain == "WebKitErrorDomain", nsError.code == 102 {
            return
        }
        print("❌ didFailProvisionalNavigation:", error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ didFail navigation:", error)
    }

}
