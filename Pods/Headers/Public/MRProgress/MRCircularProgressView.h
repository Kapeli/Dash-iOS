//
//  MRCircularProgressView.h
//  MRProgress
//
//  Created by Marius Rackwitz on 10.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRProgressView.h"
#import "MRStopableView.h"


/**
 You use the MRCircularProgressView class to depict the progress of a task over time.
 */
@interface MRCircularProgressView : MRProgressView<MRStopableView>

/**
 Value label.
 
 The label where the current progress is displayed, if the receiver's property mayStop has the value NO.
 */
@property (nonatomic, weak, readonly) UILabel *valueLabel;

/**
 Current progress.
 
 Use associated setter for non animated changes. Otherwises use setProgress:animated:.
 */
@property(nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;

/**
 Duration of an animated progress change.
 
 Default is 0.3s. Must be larger than zero.
 */
@property (nonatomic, assign) CFTimeInterval animationDuration UI_APPEARANCE_SELECTOR;

/**
 The line width of the outer circle
 
 Default is 2.0. Must be larger than zero.
 */
@property (nonatomic, assign) CGFloat borderWidth UI_APPEARANCE_SELECTOR;

/**
 The line width of the inner circle
 
 Default is 2.0. Must be larger than zero.
 */
@property (nonatomic, assign) CGFloat lineWidth UI_APPEARANCE_SELECTOR;

/**
 Change progress animated.
 
 The animation will be always linear.
 
 @param progress The new progress value.
 
 @param animated Specify YES to animate the change or NO if you do not want the change to be animated.
 */
- (void)setProgress:(float)progress animated:(BOOL)animated;

@end
