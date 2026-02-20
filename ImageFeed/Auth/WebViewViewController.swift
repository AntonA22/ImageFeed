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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        webView.addObserver(
//            self,
//            forKeyPath: #keyPath(WKWebView.estimatedProgress),
//            options: .new,
//            context: nil
//        )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

//        webView.removeObserver(
//            self,
//            forKeyPath: #keyPath(WKWebView.estimatedProgress),
//            context: nil
//        )
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            updateProgress()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
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
//    func webView(
//        _ webView: WKWebView,
//        decidePolicyFor navigationAction: WKNavigationAction,
//        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
//    ) {
//        if let code = code(from: navigationAction) {
//            print("✅ GOT CODE:", code)
//            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
//            decisionHandler(.cancel)
//        } else {
//            decisionHandler(.allow)
//        }
//    }
//
//    private func code(from navigationAction: WKNavigationAction) -> String? {
//        if
//            let url = navigationAction.request.url,
//            let urlComponents = URLComponents(string: url.absoluteString),
//            urlComponents.path == "/oauth/authorize/native",
//            let items = urlComponents.queryItems,
//            let codeItem = items.first(where: { $0.name == "code" })
//        {
//            return codeItem.value
//        } else {
//            return nil
//        }
//    }
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let code = code(from: navigationAction) {
            decisionHandler(.cancel)  // сначала cancel
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            return
        }
        decisionHandler(.allow)
    }

    private func code(from navigationAction: WKNavigationAction) -> String? {
        guard
            let url = navigationAction.request.url,
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else { return nil }

        return code
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
           print("❌ didFailProvisionalNavigation:", error)
           if let nsError = error as NSError? {
               print("domain:", nsError.domain, "code:", nsError.code, "info:", nsError.userInfo)
           }
       }

       func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
           print("❌ didFail navigation:", error)
       }

}
