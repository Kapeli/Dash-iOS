//
//  MRProgressView.h
//  MRProgress
//
//  Created by Marius Rackwitz on 31.05.14.
//  Copyright (c) 2014 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 This class is only a intermediate step between the concrete custom progress view
 implementation provided in this library and UIKit's base class UIView and declaring
 the common interface of those custom views, which is similar to UIProgressView.
 This has the advantage that we can define an usual category on this class to extend
 the functionality of all other custom progress view subclasses provided by this library.
 */
@interface MRProgressView : UIView {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@protected
    float _progress;
}
#pragma clang diagnostic pop

/**
 Current progress. Use associated setter for non animated changes. Otherwises use setProgress:aniamted:.
 */
@property (nonatomic, assign) float progress;

/**
 Change progress animated.
 
 The animation will be always linear.
 
 @note See this as declared abstract. This MUST be overriden in subclasses.
 
 @param progress The new progress value.
 @param animated Specify YES to animate the change or NO if you do not want the change to be animated.
 */
- (void)setProgress:(float)progress animated:(BOOL)animated;

@end
