//
//  MRNavigationBarProgressView.h
//  MRProgress
//
//  Created by Marius Rackwitz on 09.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRProgressView.h"


/**
 A custom progress view which can be displayed at the bottom edge of the navigation bar like in Messages app
 or at the top edge of the toolbar like in Safari.
 */
@interface MRNavigationBarProgressView : MRProgressView

/**
 Tint color of progress bar.
 */
@property (nonatomic, retain) UIColor *progressTintColor;

/**
 Current progress. Use associated setter for non animated changes. Otherwises use setProgress:aniamted:.
 */

/**
 Change progress animated.
 
 If you set a lower value than the current progess then the animation bounces.
 If you set a higher value than the current progress then the animation eases out.
 
 The progress bar will be hidden, if you set the progress to 1.0, automatically.
 
 @param progress The new progress value.
 
 @param animated Specify YES to animate the change or NO if you do not want the change to be animated.
 */
- (void)setProgress:(float)progress animated:(BOOL)animated;

/**
 Get current progress view or initialize a new for given navigation controller.
 
 @param navigationController  The navigationBar of the navigationController will be used to initialize the progress
 views frame and progressTintColor. The navigationController's delegate will be intercepted to automatically to remove
 the progress bar on push or pop. You can destroy the current instance by using removeFromSuperview, manually.
 */
+ (instancetype)progressViewForNavigationController:(UINavigationController *)navigationController;

@end


/**
 Helper to access MRNavigationBarProgressView from view controllers.
 */
@interface UINavigationController (NavigationBarProgressView)

/**
 Access an already initialized progressView.
 */
@property (nonatomic, readonly) MRNavigationBarProgressView *progressView;

@end
