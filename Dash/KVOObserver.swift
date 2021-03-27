//
//  KVOObserver.swift
//  Dash iOS
//
//  Created by chenhaoyu.1999 on 2021/3/27.
//  Copyright © 2021 Kapeli. All rights reserved.
//

import Foundation
@objcMembers class KVOObserver: NSObject {
    var scrollView: UIScrollView?
    func observeScrollViewOffset(scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.addObserver(self, forKeyPath: "self.scrollView.contentOffset", options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newOffset = change?[NSKeyValueChangeKey.newKey] as? CGPoint {
            print(newOffset)
        }
    }
    
}
