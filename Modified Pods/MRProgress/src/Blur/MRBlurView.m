//
//  MRBlurView.m
//  MRProgress
//
//  Created by Marius Rackwitz on 10.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MRBlurView.h"
#import "UIImage+MRImageEffects.h"
#import "MRProgressHelper.h"


@interface MRBlurView ()

@property (nonatomic, assign) BOOL redrawOnFrameChange;

@end


@implementation MRBlurView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setPlaceholder];
    self.clipsToBounds = YES;
    [self registerForNotificationCenter];
}

- (void)dealloc {
    [self unregisterFromNotificationCenter];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.redrawOnFrameChange) {
        self.redrawOnFrameChange = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self redraw];
        });
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    // See `didMoveToWindow`
    if (self.window) {
        [self redraw];
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    // As the documentation states: The window property may be nil by the time that this method is called
    if (self.window) {
        // This is needed e.g. for the push animation of UINavigationController.
        CFTimeInterval timeInterval = CATransaction.animationDuration > 0 ? CATransaction.animationDuration : 0.25;
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC));
        dispatch_after(time, dispatch_get_main_queue(), ^{
            [self redraw];
        });
    }
}


#pragma mark - Notifications

- (void)registerForNotificationCenter {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self
               selector:@selector(statusBarOrientationDidChange:)
                   name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)unregisterFromNotificationCenter {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self];
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    self.redrawOnFrameChange = YES;
}


#pragma mark - Redraw

- (void)setPlaceholder {
    self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
}

- (void)clearPlaceholder {
    self.backgroundColor = UIColor.clearColor;
}

- (void)redraw {
    #if DEBUG
        if (!NSThread.isMainThread) {
            NSLog(@"** WARNING - %@ -%@ should be always called on the main thread!",
                  NSStringFromClass(self.class),
                  NSStringFromSelector(_cmd));
        }
    #endif
    
    // This has to happen on the main queue, as the view hierachy will be redrawn.
//    __block UIImage *image = self.snapshot;
    
    if (!self.image) {
        [self setPlaceholder];
    }
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        image = [image mr_applyBlurWithRadius:30.0 tintColor:[UIColor colorWithWhite:0.97 alpha:0.82] saturationDeltaFactor:1.0 maskImage:nil];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // Fade on content's change, dependent if there was already an image.
//            CATransition *transition = [CATransition new];
//            transition.duration = self.image ? 0.3 : 0.1;
//            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//            transition.type = kCATransitionFade;
//            [self.layer addAnimation:transition forKey:nil];
//            
//            if (self.image) {
//                [self clearPlaceholder];
//            }
//            
//            self.image = image;
//        });
//    });
}


#pragma mark - Snapshot helper

- (UIImage *)snapshot {
    BOOL wasHidden = self.superview.hidden;
    self.superview.hidden = YES;
    
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    
    // Absolute origin of receiver
    CGPoint origin = self.bounds.origin;
    if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        origin = CGPointMake(origin.y, origin.x);
    }
    origin = [self convertPoint:origin toView:window];
    CGSize size = self.frame.size;
    
    // Begin context (with device scale)
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    const CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Apply window tranforms
    // Author: NSElvis
    // Source: http://stackoverflow.com/a/8017292
    CGContextTranslateCTM(context, window.center.x, window.center.y);
    CGContextConcatCTM(context, window.transform);
    CGContextTranslateCTM(context, -window.bounds.size.width  * window.layer.anchorPoint.x,
                                   -window.bounds.size.height * window.layer.anchorPoint.y);
    
    // Rotate according to device orientation
    CGContextRotateCTM(context, 2*M_PI - MRRotationForStatusBarOrientation());
    
    // Translate to draw at the absolute origin of the receiver
    CGContextTranslateCTM(context, -origin.x, -origin.y);
    
    // Draw the window
    [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
    
    // Capture the image and exit context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.superview.hidden = wasHidden;
    
    return image;
}

@end
