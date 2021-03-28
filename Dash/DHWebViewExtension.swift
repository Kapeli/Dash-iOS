//
//  DHWebViewExtension.swift
//  Dash
//
//  Created by chenhaoyu.1999 on 2021/3/28.
//  Copyright © 2021 Kapeli. All rights reserved.
//

@objc extension DHWebViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateBackForwardButtonState()
        progressView.setProgress(0, animated: false)
        progressView.fakeSetProgress(0.6)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = (navigationAction.request as NSURLRequest)
        let requestURLString = request.url?.absoluteString
        if requestURLString == "about:blank" {
            decisionHandler(.cancel)
            return
        }
        let isFrame = requestURLString == request.mainDocumentURL?.absoluteString
        if !isFrame {
            lastLoadDate = Date()
            previousMainFrameURL = mainFrameURL
            mainFrameURL = requestURLString
            if !anchorChangeInProgress {
                updateStopReloadButtonState()
                setToolbarHidden(false)
            }
        }
        let schemeEqualToFile = (request.url?.scheme ?? "").compare("file", options: .caseInsensitive, range: nil, locale: nil) == .orderedSame
        if !anchorChangeInProgress && schemeEqualToFile {
            let isMain = request.url == request.mainDocumentURL
            let mutRequest: NSMutableURLRequest? = (navigationAction.request as? NSMutableURLRequest)
            let url = requestURLString?.replacingOccurrences(of: "file://", with: "dash-tarix://")
            let newURL = URL(string: url ?? "")
            mutRequest?.url = newURL
            if isMain {
                mutRequest?.mainDocumentURL = newURL
            }
            perform(#selector(updateBackForwardButtonState), with: self, afterDelay: 0.1)
            decisionHandler(.allow)
            return
        }
        let navigationType = navigationAction.navigationType
        if navigationType == .linkActivated || navigationType == .formSubmitted || navigationType == .formResubmitted {
            DHRemoteServer.shared()?.sendWebViewURL(requestURLString)
        }
        perform(#selector(updateBackForwardButtonState), with: self, afterDelay: 0.1)
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if stopButtonIsShown {
            updateStopReloadButtonState()
        }
        updateBackForwardButtonState()
        updateTitle()
        setUpScripts()
        setUpTOC()
        progressView.setProgress(1, animated: true)
        if isRestoreScroll {
            webView.scrollView.setContentOffset(webViewOffset, animated: false)
            isRestoreScroll = false
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if stopButtonIsShown {
            updateStopReloadButtonState()
        }
        var customMessage = nil as String?
        updateTitle()
        let error = error as NSError
        let errorInfo = ((error.userInfo[NSURLErrorFailingURLStringErrorKey] as? NSString) ?? "").substring(from: "://") ?? ""
        let mainFrameUrlSubstring = (mainFrameURL as? NSString)?.substring(from: "://") ?? ""
        if error.code == NSURLErrorCancelled || (error.domain == "WebKitErrorDomain" && error.code == 204) || (error.domain == "WebKitErrorDomain" && error.code == 102 && !(errorInfo.caseInsensitiveCompare(mainFrameUrlSubstring) == ComparisonResult.orderedSame)) {
            return
        } else if error.domain == "WebKitErrorDomain" && error.code == 102 {
            customMessage = "Invalid URL."
        }
        mainFrameURL = previousMainFrameURL
        progressView.setProgress(1, animated: true)
        let alert = UIAlertController(title: "Error Loading Page", message: customMessage ?? error.localizedDescription, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        alert.show(self, sender: nil)
        
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
        if stopButtonIsShown {
            updateStopReloadButtonState()
        }
        var customMessage = nil as String?
        updateTitle()
        let error = error as NSError
        let errorInfo = ((error.userInfo[NSURLErrorFailingURLStringErrorKey] as? NSString) ?? "").substring(from: "://") ?? ""
        let mainFrameUrlSubstring = (mainFrameURL as NSString?)?.substring(from: "://") ?? ""
        if error.code == NSURLErrorCancelled || (error.domain == "WebKitErrorDomain" && error.code == 204) || (error.domain == "WebKitErrorDomain" && error.code == 102 && !(errorInfo.caseInsensitiveCompare(mainFrameUrlSubstring) == ComparisonResult.orderedSame)) {
            return
        } else if error.domain == "WebKitErrorDomain" && error.code == 102 {
            customMessage = "Invalid URL."
        }
        mainFrameURL = previousMainFrameURL
        progressView.setProgress(1, animated: true)
        let alert = UIAlertController(title: "Error Loading Page", message: customMessage ?? error.localizedDescription, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        alert.show(self, sender: nil)
    }
}
import SnapKit

@objc extension DHWebViewController: WKScriptMessageHandler {
    func configWebView() {
        
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(self,  name: "JSListener")
        configuration.userContentController = controller
        configuration.setURLSchemeHandler(DHTarixSchemeHandler(), forURLScheme: "dash-tarix")
        configuration.setURLSchemeHandler(DHAppleAPISchemeHandler(), forURLScheme: "dash-apple-api")
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.dataDetectorTypes = []
        
        webView = DHWebView(frame: .zero, configuration: configuration)
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        webView.navigationDelegate = self
        
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
    }
}
