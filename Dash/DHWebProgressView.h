#import <UIKit/UIKit.h>

@interface DHWebProgressView : UIView

@property (nonatomic) float progress;
@property (nonatomic) float actualProgress;

@property (retain) NSTimer *fakeLoadTimer;
@property (nonatomic) UIView *progressBarView;
@property (nonatomic) NSTimeInterval barAnimationDuration; // default 0.1
@property (nonatomic) NSTimeInterval fadeAnimationDuration; // default 0.27
@property (nonatomic) NSTimeInterval fadeOutDelay; // default 0.1

- (void)setProgress:(float)progress animated:(BOOL)animated;
- (void)fakeSetProgress:(float)progress;

@end
