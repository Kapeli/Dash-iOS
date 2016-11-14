//
//  MRStopableView.h
//  MRProgress
//
//  Created by Marius Rackwitz on 11.01.14.
//  Copyright (c) 2014 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 This protocol can be implemented by progress views, which supports a stop button, to stop the related and visualised
 running task.
 */
@protocol MRStopableView <NSObject>

/**
 A Boolean value that controls whether the receiver shows a stop button.
 
 If the value of this property is NO (the default), the receiver doesnot show a stop button. If the mayStop property is
 YES a stop button will be shown. You can catch fired events like known from UIButton by the property stopButton.
 */
@property (nonatomic, assign) BOOL mayStop;

/**
 A button, which should only be shown if mayStop is equal to YES.
 
 The button is in the middle of the control.
 */
@property (nonatomic, readonly, weak) UIButton *stopButton;

@end
