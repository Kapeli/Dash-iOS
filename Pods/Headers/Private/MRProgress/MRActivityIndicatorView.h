//
//  MRActivityIndicatorView.h
//  MRProgress
//
//  Created by Marius Rackwitz on 10.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRStopableView.h"


/**
 Use an activity indicator to show that a task is in progress. An activity indicator appears as a circle slice that is
 either spinning or stopped.
 */
@interface MRActivityIndicatorView : UIView<MRStopableView> {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@package
    BOOL _animating;
#pragma clang diagnostic pop
}

/**
 A float value to indicate how thick the line of the activivity indicator is.
 
 The default value is 2.f. 
 */
@property (nonatomic) CGFloat lineWidth UI_APPEARANCE_SELECTOR;

/**
 A Boolean value that controls whether the receiver is hidden when the animation is stopped.
 
 If the value of this property is YES (the default), the receiver sets its hidden property (UIView) to YES when receiver
 is not animating. If the hidesWhenStopped property is NO, the receiver is not hidden when animation stops. You stop an
 animating progress indicator with the stopAnimating method.
 */
@property(nonatomic) BOOL hidesWhenStopped;

/**
 Starts the animation of the progress indicator.
 
 When the progress indicator is animated, the gear spins to indicate indeterminate progress. The indicator is animated
 until stopAnimating is called.
 */
- (void)startAnimating;

/**
 Stops the animation of the progress indicator.
 
 Call this method to stop the animation of the progress indicator started with a call to startAnimating. When animating
 is stopped, the indicator is hidden, unless hidesWhenStopped is NO.
 */
- (void)stopAnimating;

/**
 Returns whether the receiver is animating.

 @return YES if the receiver is animating, otherwise NO.
 */
- (BOOL)isAnimating;

@end
