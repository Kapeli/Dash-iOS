//
//  SwiftMacro.swift
//  Dash
//
//  Created by chenhaoyu.1999 on 2021/3/26.
//  Copyright © 2021 Kapeli. All rights reserved.
//

import Foundation

var iPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

var isRetina: Bool {
    UIScreen.main.scale > 1
}

var isIOS11: Bool {
    Double(UIDevice.current.systemVersion)! - 11.0 < Double.ulpOfOne
}

var isRegularHorizontalClass: Bool {
    DHAppDelegate.shared()?.window?.rootViewController?.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular
}

var homePath: String {
    NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
}

var transferPath: String {
    NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
}

let DHPrepareForURLSearch = "DHPrepareForURLSearch"
let DHSplitViewControllerDidSeparate = "DHSplitViewControllerDidSeparate"
let DHSplitViewControllerDidCollapse = "DHSplitViewControllerDidCollapse"
let DHPerformURLSearch = "DHPerformURLSearch"
let DHWindowChangedTraitCollection = "DHWindowChangedTraitCollection"




