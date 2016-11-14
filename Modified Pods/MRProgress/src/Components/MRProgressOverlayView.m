//
//  MRProgressOverlayView.m
//  MRProgress
//
//  Created by Marius Rackwitz on 09.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MRProgressOverlayView.h"
#import "MRActivityIndicatorView.h"
#import "MRBlurView.h"
#import "MRCircularProgressView.h"
#import "MRIconView.h"
#import "MRProgressHelper.h"


static const CGFloat MRProgressOverlayViewCornerRadius = 7;
static const CGFloat MRProgressOverlayViewMotionEffectExtent = 10;


@interface MRProgressOverlayView () {
    NSDictionary *_savedAttributes;
}

@property (nonatomic, weak, readwrite) UIView *dialogView;
@property (nonatomic, weak, readwrite) UIView *blurView;
@property (nonatomic, weak, readwrite) UILabel *titleLabel;

- (UIView *)createModeView;
- (UIView *)createViewForMode:(MRProgressOverlayViewMode)mode;

- (MRActivityIndicatorView *)createActivityIndicatorView;
- (MRActivityIndicatorView *)createSmallActivityIndicatorView;
- (UIActivityIndicatorView *)createSmallDefaultActivityIndicatorView;
- (MRCircularProgressView *)createCircularProgressView;
- (UIProgressView *)createHorizontalBarProgressView;
- (MRIconView *)createCheckmarkIconView;
- (MRIconView *)createCrossIconView;
- (UIView *)createCustomView;

- (void)showModeView:(UIView *)modeView;
- (void)hideModeView:(UIView *)modeView;

- (BOOL)mayStop;

- (void)setSubviewTransform:(CGAffineTransform)transform alpha:(CGFloat)alpha;

- (void)registerForNotificationCenter;
- (void)unregisterFromNotificationCenter;
- (void)deviceOrientationDidChange:(NSNotification *)notification;

- (void)registerForKVO;
- (void)unregisterFromKVO;
- (NSArray *)observableKeypaths;

- (CGAffineTransform)transformForOrientation;

- (NSDictionary *)titleTextAttributesToCopy;

@end


@implementation MRProgressOverlayView

static void *MRProgressOverlayViewObservationContext = &MRProgressOverlayViewObservationContext;

#pragma mark - Static helper methods

+ (instancetype)showOverlayAddedTo:(UIView *)view animated:(BOOL)animated {
    MRProgressOverlayView *overlayView = [self new];
    [view addSubview:overlayView];
    [overlayView show:animated];
    return overlayView;
}

+ (instancetype)showOverlayAddedTo:(UIView *)view title:(NSString *)title mode:(MRProgressOverlayViewMode)mode animated:(BOOL)animated {
    MRProgressOverlayView *overlayView = [self new];
    overlayView.mode = mode;
    overlayView.titleLabelText = title;
    [view addSubview:overlayView];
    [overlayView show:animated];
    return overlayView;
}

+ (instancetype)showOverlayAddedTo:(UIView *)view title:(NSString *)title mode:(MRProgressOverlayViewMode)mode animated:(BOOL)animated stopBlock:(MRProgressOverlayViewStopBlock)stopBlock {
    MRProgressOverlayView *overlayView = [self new];
    overlayView.mode = mode;
    overlayView.titleLabelText = title;
    overlayView.stopBlock = stopBlock;
    [view addSubview:overlayView];
    [overlayView show:animated];
    return overlayView;
}

+ (BOOL)dismissOverlayForView:(UIView *)view animated:(BOOL)animated {
    return [self dismissOverlayForView:view animated:animated completion:nil];
}

+ (BOOL)dismissOverlayForView:(UIView *)view animated:(BOOL)animated completion:(void(^)())completionBlock {
    MRProgressOverlayView *overlayView = [self overlayForView:view];
    if (overlayView) {
        [overlayView dismiss:animated completion:completionBlock];
        return YES;
    }
    return NO;
}

+ (NSUInteger)dismissAllOverlaysForView:(UIView *)view animated:(BOOL)animated {
    return [self dismissAllOverlaysForView:view animated:animated completion:nil];
}

+ (NSUInteger)dismissAllOverlaysForView:(UIView *)view animated:(BOOL)animated completion:(void(^)())completionBlock {
    NSArray *views = [self allOverlaysForView:view];
    for (MRProgressOverlayView *overlayView in views) {
        [overlayView dismiss:animated completion:completionBlock];
    }
    return views.count;
}

+ (instancetype)overlayForView:(UIView *)view {
    NSEnumerator *subviewsEnum = view.subviews.reverseObjectEnumerator;
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            return (MRProgressOverlayView *)subview;
        }
    }
    return nil;
}

+ (NSArray *)allOverlaysForView:(UIView *)view {
    NSMutableArray *overlays = [NSMutableArray new];
    NSArray *subviews = view.subviews;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:self]) {
            [overlays addObject:view];
        }
    }
    return overlays;
}


#pragma mark - Initialization

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
    self.accessibilityViewIsModal = YES;
    
    self.hidden = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    const CGFloat cornerRadius = MRProgressOverlayViewCornerRadius;
    
    // Create blurView
    self.blurView = [self createBlurView];
    self.blurView.layer.cornerRadius = cornerRadius;
    
    // Create container with contents
    UIView *dialogView = [UIView new];
    [self addSubview:dialogView];
    self.dialogView = dialogView;
    [self applyMotionEffects];
    
    // Style the dialog to match the iOS7 UIAlertView
    dialogView.backgroundColor = UIColor.clearColor;
    dialogView.layer.cornerRadius = cornerRadius;
    dialogView.layer.shadowRadius = cornerRadius + 5;
    dialogView.layer.shadowOpacity = 0.1f;
    dialogView.layer.shadowOffset = CGSizeMake(-(cornerRadius+5)/2.0f, -(cornerRadius+5)/2.0f);
    
    // Create titleLabel
    UILabel *titleLabel = [UILabel new];
    self.titleLabel = titleLabel;
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Loading ..." attributes:@{
        NSForegroundColorAttributeName: UIColor.blackColor,
        NSFontAttributeName:            [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSKernAttributeName:            NSNull.null,  // turn on auto-kerning
    }];
    titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [dialogView addSubview:titleLabel];
    
    // Create modeView
    [self createModeView];
    
    // Observe key paths and notification center
    [self registerForKVO];
    [self registerForNotificationCenter];
    
    [self tintColorDidChange];
}


#pragma mark - Clean up

- (void)dealloc {
    [self unregisterFromKVO];
    [self unregisterFromNotificationCenter];
}


#pragma mark - Notifications

- (void)registerForNotificationCenter {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)unregisterFromNotificationCenter {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    if ([self.superview isKindOfClass:UIWindow.class]) {
        [UIView animateWithDuration:0.3 animations:^{
            [self manualLayoutSubviews];
        }];
    } else {
        [self manualLayoutSubviews];
    }
}


#pragma mark - Key-Value-Observing

- (void)registerForKVO {
    for (NSString *keyPath in self.observableKeypaths) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionPrior context:MRProgressOverlayViewObservationContext];
    }
}

- (void)unregisterFromKVO {
    for (NSString *keyPath in self.observableKeypaths) {
        [self removeObserver:self forKeyPath:keyPath];
    }
}

- (NSArray *)observableKeypaths {
    return @[@"titleLabel.text"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == MRProgressOverlayViewObservationContext) {
        if ([keyPath isEqualToString:@"titleLabel.text"]) {
            if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
                _savedAttributes = self.titleTextAttributesToCopy;
                return;
            } else {
                if (!_savedAttributes) {
                    self.titleLabelText = self.titleLabel.text;
                    #if DEBUG
                        NSLog(@"** WARNING - Instance of %@ used automatically setTitleLabelText: internally, instead of titleLabel.text, but some text attributes may been lost.",
                              NSStringFromClass(self.class));
                    #endif
                } else {
                    self.titleLabelText = (id)[[NSAttributedString alloc] initWithString:self.titleLabel.text attributes:_savedAttributes];
                    _savedAttributes = nil;
                }
            }
        }
        [self manualLayoutSubviews];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark - Create subviews

- (UIView *)createBlurView {
    UIView *blurView = [MRBlurView new];
    blurView.alpha = 0.98;
    [self addSubview:blurView];
    
    return blurView;
}

- (UIView *)createModeView {
    UIView *modeView = [self createViewForMode:self.mode];
    self.modeView = modeView;
    modeView.tintColor = self.tintColor;
    
    if ([modeView conformsToProtocol:@protocol(MRStopableView)]
        && [modeView respondsToSelector:@selector(stopButton)]) {
        UIButton *stopButton = [((id<MRStopableView>)modeView) stopButton];
        [stopButton addTarget:self action:@selector(modeViewStopButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return modeView;
}

- (void)setModeView:(UIView *)modeView {
    _modeView = modeView;
    [self.dialogView addSubview:modeView];
}

- (UIView *)createViewForMode:(MRProgressOverlayViewMode)mode {
    switch (mode) {
        case MRProgressOverlayViewModeIndeterminate:
            return [self createActivityIndicatorView];
        
        case MRProgressOverlayViewModeIndeterminateSmall:
            return [self createSmallActivityIndicatorView];
        
        case MRProgressOverlayViewModeIndeterminateSmallDefault:
            return [self createSmallDefaultActivityIndicatorView];
        
        case MRProgressOverlayViewModeDeterminateCircular:
            return [self createCircularProgressView];
        
        case MRProgressOverlayViewModeDeterminateHorizontalBar:
            return [self createHorizontalBarProgressView];
        
        case MRProgressOverlayViewModeCheckmark:
            return [self createCheckmarkIconView];
        
        case MRProgressOverlayViewModeCross:
            return [self createCrossIconView];
            
        case MRProgressOverlayViewModeCustom:
            return [self createCustomView];
    }
    return nil;
}


#pragma mark - Mode view factory methods

- (MRActivityIndicatorView *)createActivityIndicatorView {
    // Create activity indicator for indeterminate mode
    MRActivityIndicatorView *activityIndicatorView = [MRActivityIndicatorView new];
    return activityIndicatorView;
}

- (MRActivityIndicatorView *)createSmallActivityIndicatorView {
    // Create small activity indicator for text mode
    MRActivityIndicatorView *smallActivityIndicatorView = [MRActivityIndicatorView new];
    smallActivityIndicatorView.hidesWhenStopped = YES;
    return smallActivityIndicatorView;
}

- (UIActivityIndicatorView *)createSmallDefaultActivityIndicatorView {
    // Create small default activity indicator for text mode
    UIActivityIndicatorView *smallDefaultActivityIndicatorView = [UIActivityIndicatorView new];
    smallDefaultActivityIndicatorView.hidesWhenStopped = YES;
    smallDefaultActivityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    return smallDefaultActivityIndicatorView;
}

- (MRCircularProgressView *)createCircularProgressView {
    // Create circular progress view for determinate circular mode
    MRCircularProgressView *circularProgressView = [MRCircularProgressView new];
    return circularProgressView;
}

- (UIProgressView *)createHorizontalBarProgressView {
    // Create horizontal progress bar for determinate horizontal bar mode
    UIProgressView *horizontalBarProgressView = [UIProgressView new];
    return horizontalBarProgressView;
}

- (MRIconView *)createCheckmarkIconView {
    // Create checkmark icon view for checkmark mode
    MRCheckmarkIconView *checkmarkIconView = [MRCheckmarkIconView new];
    return checkmarkIconView;
}

- (MRIconView *)createCrossIconView {
    // Create cross icon view for cross mode
    MRCrossIconView *crossIconView = [MRCrossIconView new];
    return crossIconView;
}

- (UIView *)createCustomView {
    // Create custom base view
    return [UIView new];
}


#pragma mark - Title label text

- (NSDictionary *)titleTextAttributesToCopy {
    if (self.titleLabel.text.length > 0) {
        return [self.titleLabel.attributedText attributesAtIndex:0 effectiveRange:NULL];
    } else {
        return @{};
    }
}

- (void)setTitleLabelText:(NSString *)titleLabelText {
    self.titleLabelAttributedText = [[NSAttributedString alloc] initWithString:titleLabelText attributes:self.titleTextAttributesToCopy];
    [self manualLayoutSubviews];
}

- (NSString *)titleLabelText {
    return self.titleLabel.text;
}

- (void)setTitleLabelAttributedText:(NSAttributedString *)titleLabelAttributedText {
    self.titleLabel.attributedText = titleLabelAttributedText;
    [self manualLayoutSubviews];
}

- (NSAttributedString *)titleLabelAttributedText {
    return self.titleLabel.attributedText;
}


#pragma mark - Tint color

- (void)setTintColor:(UIColor *)tintColor {
    // Implemented to silent warning
    super.tintColor = tintColor;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    self.modeView.tintColor = self.tintColor;
}


#pragma mark - Mode

- (void)setMode:(MRProgressOverlayViewMode)mode {
    [self hideModeView:self.modeView];
    
    _mode = mode;
    
    [self showModeView:[self createModeView]];
    [self updateModeViewMayStop];
    
    if (!self.hidden) {
        [self manualLayoutSubviews];
    }
}

- (void)showModeView:(UIView *)modeView {
    modeView.hidden = NO;
    if ([modeView respondsToSelector:@selector(startAnimating)]) {
        [modeView performSelector:@selector(startAnimating)];
    }
}

- (void)hideModeView:(UIView *)modeView {
    modeView.hidden = YES;
    if ([modeView respondsToSelector:@selector(stopAnimating)]) {
        [modeView performSelector:@selector(stopAnimating)];
    }
}


#pragma mark - Stop button

- (void)setStopBlock:(MRProgressOverlayViewStopBlock)stopBlock {
    _stopBlock = stopBlock;
    
    if (![self updateModeViewMayStop]) {
        #if DEBUG
            NSLog(@"** WARNING - %@: %@ is only valid to call when the mode view supports %@ declared in %@!",
                  NSStringFromClass(self.class),
                  NSStringFromSelector(_cmd),
                  NSStringFromSelector(@selector(setMayStop:)),
                  NSStringFromProtocol(@protocol(MRStopableView)));
        #endif
    }
}

- (BOOL)mayStop {
    return _stopBlock != nil;
}

- (BOOL)updateModeViewMayStop {
    if ([self.modeView conformsToProtocol:@protocol(MRStopableView)]
        && [self.modeView respondsToSelector:@selector(setMayStop:)]) {
        [((id<MRStopableView>)self.modeView) setMayStop:self.mayStop];
        return YES;
    }
    return NO;
}

- (void)modeViewStopButtonTouchUpInside {
    if (self.stopBlock) {
        self.stopBlock(self);
    }
}


#pragma mark - A11y

- (BOOL)accessibilityPerformEscape {
    if (self.mayStop) {
        [self modeViewStopButtonTouchUpInside];
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - Transitions

- (void)setSubviewTransform:(CGAffineTransform)transform alpha:(CGFloat)alpha {
    self.blurView.transform = transform;
    self.blurView.alpha = alpha;
    self.dialogView.transform = transform;
    self.dialogView.alpha = alpha;
}

- (void)show:(BOOL)animated {
    [self showModeView:self.modeView];
    
    [self manualLayoutSubviews];
    
    if (animated) {
        [self setSubviewTransform:CGAffineTransformMakeScale(1.3f, 1.3f) alpha:0.5f];
        self.backgroundColor = UIColor.clearColor;
    }
    
    self.hidden = NO;
    
    void(^animBlock)() = ^{
        [self setSubviewTransform:CGAffineTransformIdentity alpha:1.0f];
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:animBlock
                         completion:nil];
    } else {
        animBlock();
    }
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.titleLabelText);
}

- (void)dismiss:(BOOL)animated {
    [self dismiss:animated completion:nil];
}

- (void)dismiss:(BOOL)animated completion:(void(^)())completionBlock {
    [self hide:animated completion:^{
        [self removeFromSuperview];
        if (completionBlock) {
            completionBlock();
        }
    }];
}

- (void)hide:(BOOL)animated {
    [self hide:animated completion:nil];
}

- (void)hide:(BOOL)animated completion:(void(^)())completionBlock {
    [self setSubviewTransform:CGAffineTransformIdentity alpha:1.0f];
    
    void(^animBlock)() = ^{
        [self setSubviewTransform:CGAffineTransformMakeScale(0.6f, 0.6f) alpha:0.0f];
        self.backgroundColor = UIColor.clearColor;
    };
    
    void(^animCompletionBlock)(BOOL) = ^(BOOL finished) {
        self.hidden = YES;
        [self hideModeView:self.modeView];
        
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        
        if (completionBlock) {
            completionBlock();
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:animBlock
                         completion:animCompletionBlock];
    } else {
        animBlock();
        animCompletionBlock(YES);
    }
}


#pragma mark - Layout

- (CGAffineTransform)transformForOrientation {
    if ([self.superview isKindOfClass:UIWindow.class]) {
        return CGAffineTransformMakeRotation(MRRotationForStatusBarOrientation());
    }
    return CGAffineTransformIdentity;
}

// Don't overwrite layoutSubviews here. This would cause issues with animation.
- (void)manualLayoutSubviews {
    self.transform = self.transformForOrientation;
    
    CGRect bounds = self.superview.bounds;
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        insets = scrollView.contentInset;
    }
    
    self.center = CGPointMake((bounds.size.width - insets.left - insets.right) / 2.0f,
                              (bounds.size.height - insets.top - insets.bottom) / 2.0f);

    if ([self.superview isKindOfClass:UIWindow.class] && UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        // Swap width and height
        self.bounds = (CGRect){CGPointZero, {bounds.size.height, bounds.size.width}};
    } else {
        self.bounds = (CGRect){CGPointZero, bounds.size};
    }
    
    const CGFloat dialogPadding = 15;
    const CGFloat modePadding = 30;
    const CGFloat dialogMargin = 10;
    const CGFloat dialogMinWidth = 150;
    
    const BOOL hasSmallIndicator = self.mode == MRProgressOverlayViewModeIndeterminateSmall
        || self.mode == MRProgressOverlayViewModeIndeterminateSmallDefault;
    const BOOL isTextNonEmpty = self.titleLabel.text.length > 0;
    
    CGFloat dialogWidth = hasSmallIndicator ? CGRectGetWidth(bounds) - dialogMargin * 2 : dialogMinWidth;
    if (self.mode == MRProgressOverlayViewModeCustom) {
        dialogWidth = self.modeView.frame.size.width + 2*modePadding;
    }
    
    CGFloat y = (isTextNonEmpty || hasSmallIndicator) ? 7 : modePadding;
    
    CGSize modeViewSize;
    if (hasSmallIndicator) {
        modeViewSize = CGSizeMake(20, 20);
    }
    
    if (!self.titleLabel.hidden && isTextNonEmpty) {
        const CGFloat innerViewWidth = dialogWidth - 2*dialogPadding;
        
        CGFloat titleLabelMinX = dialogPadding;
        CGFloat titleLabelMaxWidth = innerViewWidth;
        CGFloat offset = 0;
        
        if (hasSmallIndicator) {
            offset = modeViewSize.width + 7;
        }
        
        titleLabelMinX += offset;
        titleLabelMaxWidth -= offset;
        
        y += 3;
        
        CGSize titleLabelMaxSize = CGSizeMake(titleLabelMaxWidth, self.bounds.size.height);
        CGRect boundingRect = [self.titleLabel.attributedText boundingRectWithSize:titleLabelMaxSize
                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                           context:nil];
        CGSize titleLabelSize = CGSizeMake(MRCGFloatCeil(boundingRect.size.width),
                                           MRCGFloatCeil(boundingRect.size.height));
        CGPoint titleLabelOrigin;
        if (hasSmallIndicator) {
            CGFloat titleLabelMinWidth = dialogMinWidth - 2*dialogPadding - offset;
            if (titleLabelSize.width > titleLabelMinWidth) {
                dialogWidth = titleLabelSize.width + offset + 2*dialogPadding;
                titleLabelOrigin = CGPointMake(titleLabelMinX, y);
            } else {
                dialogWidth = dialogMinWidth;
                titleLabelOrigin = CGPointMake(titleLabelMinX + (titleLabelMinWidth - titleLabelSize.width) / 2.0f, y);
            }
            
            CGPoint modeViewOrigin = CGPointMake(titleLabelOrigin.x - offset,
                                                 y + (titleLabelSize.height - modeViewSize.height) / 2.0f);
            CGRect modeViewFrame = {modeViewOrigin, modeViewSize};
            self.modeView.frame = modeViewFrame;
        } else {
            titleLabelOrigin = CGPointMake(titleLabelMinX + (titleLabelMaxWidth - titleLabelSize.width) / 2.0f, y);
        }
        
        CGRect titleLabelFrame = {titleLabelOrigin, titleLabelSize};
        self.titleLabel.frame = titleLabelFrame;
        
        y += CGRectGetMaxY(titleLabelFrame);
    } else if (hasSmallIndicator) {
        dialogWidth = modeViewSize.width + 2*y;
        
        CGPoint modeViewOrigin = CGPointMake(y, y);
        CGRect modeViewFrame = {modeViewOrigin, modeViewSize};
        self.modeView.frame = modeViewFrame;
        
        y += CGRectGetMaxY(modeViewFrame);
    }
    
    if (!hasSmallIndicator) {
        const CGFloat innerViewWidth = dialogWidth - 2*modePadding;
        
        CGRect modeViewFrame;
        CGFloat paddingBottom = 0;
        
        if (self.mode != MRProgressOverlayViewModeDeterminateHorizontalBar) {
            modeViewFrame = CGRectMake(modePadding, y, innerViewWidth, innerViewWidth);
            paddingBottom = isTextNonEmpty ? 20 : modePadding;
        } else {
            modeViewFrame = CGRectMake(10, y, dialogWidth-20, 5);
            paddingBottom = 15;
        }
        
        self.modeView.frame = modeViewFrame;
        y += modeViewFrame.size.height + paddingBottom;
    }
    
    {
        self.dialogView.frame = MRCenterCGSizeInCGRect(CGSizeMake(dialogWidth, y), self.bounds);
        
        self.blurView.frame = self.dialogView.frame;
    }
}


#pragma mark - Control progress

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    NSParameterAssert(progress >= 0 && progress <= 1);
    _progress = progress;
    [self applyProgressAnimated:(BOOL)animated];
}
    
- (void)applyProgressAnimated:(BOOL)animated {
    if ([self.modeView respondsToSelector:@selector(setProgress:animated:)]) {
        [((id)self.modeView) setProgress:self.progress animated:animated];
    } else if ([self.modeView respondsToSelector:@selector(setProgress:)]) {
        if (animated) {
            #if DEBUG
                NSLog(@"** WARNING - %@: %@ is only valid to call when receiver is in a determinate mode or custom view supports %@!",
                      NSStringFromClass(self.class),
                      NSStringFromSelector(_cmd),
                      NSStringFromSelector(@selector(setProgress:animated:)));
            #endif
        }
        [((id)self.modeView) setProgress:self.progress];
    } else {
        NSAssert(self.mode == MRProgressOverlayViewModeDeterminateCircular
                 || self.mode == MRProgressOverlayViewModeDeterminateHorizontalBar,
                 @"Mode must support %@, but doesnot!", NSStringFromSelector(@selector(setProgress:animated:)));
        #if DEBUG
            NSLog(@"** ERROR - %@: %@ or %@ are only valid to call when receiver is in a determinate mode!",
                  NSStringFromClass(self.class),
                  NSStringFromSelector(@selector(setProgress:)),
                  NSStringFromSelector(_cmd));
        #endif
    }
}


#pragma mark - Helper to create UIMotionEffects

- (UIInterpolatingMotionEffect *)motionEffectWithKeyPath:(NSString *)keyPath type:(UIInterpolatingMotionEffectType)type {
    UIInterpolatingMotionEffect *effect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:keyPath type:type];
    effect.minimumRelativeValue = @(-MRProgressOverlayViewMotionEffectExtent);
    effect.maximumRelativeValue = @(MRProgressOverlayViewMotionEffectExtent);
    return effect;
}

- (void)applyMotionEffects {
    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[[self motionEffectWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis],
                                        [self motionEffectWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis]];
    [self.dialogView addMotionEffect:motionEffectGroup];
    [self.blurView addMotionEffect:motionEffectGroup];
}

@end
