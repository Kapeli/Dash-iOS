//
//  DHWKWebView.swift
//  Dash
//
//  Created by chenhaoyu.1999 on 2021/3/28.
//  Copyright © 2021 Kapeli. All rights reserved.
//

import WebKit

@objcMembers class DHWebView: WKWebView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    static func viewportContent(_ frame: CGRect) -> String {
        String(format: "width=%ld", Int(frame.size.width)) + ", initial-scale=1"
    }
    
    func updateViewPortContent(_ frame: CGRect) {
        evaluateJavaScript("document.getElementById('dash_viewport').setAttribute('content', '\(Self.viewportContent(frame))');", completionHandler: nil)
    }
    
    func setHasHistory(_ hasHistory: Bool) {
        
    }
    
    func resetHistory() {
        
    }
    
    func stringByEvaluatingJavaScriptFrom(string: String){
        evaluateJavaScript(string, completionHandler: nil)
    }
}

