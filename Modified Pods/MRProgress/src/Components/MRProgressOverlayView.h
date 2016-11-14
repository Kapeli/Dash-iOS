//
//  MRProgressOverlayView.h
//  MRProgress
//
//  Created by Marius Rackwitz on 09.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MRProgressOverlayView;


/** (MRProgressOverlayViewStopBlock) */
typedef void(^MRProgressOverlayViewStopBlock)(MRProgressOverlayView *progressOverlayView);

/** (MRProgressOverlayViewMode) */
typedef NS_ENUM(NSUInteger, MRProgressOverlayViewMode){
    /** Progress is shown using a large round activity indicator view. (MRActivityIndicatorView) This is the default. */
    MRProgressOverlayViewModeIndeterminate,
    /** Progress is shown using a round, pie-chart like, progress view. (MRCircularProgressView) */
    MRProgressOverlayViewModeDeterminateCircular,
    /** Progress is shown using a horizontal progress bar. (UIProgressView) */
    MRProgressOverlayViewModeDeterminateHorizontalBar,
    /** Shows primarily a label. Progress is shown using a small activity indicator. (MRActivityIndicatorView) */
    MRProgressOverlayViewModeIndeterminateSmall,
    /** Shows primarily a label. Progress is shown using a small activity indicator. (UIActivityIndicatorView in UIActivityIndicatorViewStyleGray) */
    MRProgressOverlayViewModeIndeterminateSmallDefault,
    /** Shows a checkmark. (MRCheckmarkIconView) */
    MRProgressOverlayViewModeCheckmark,
    /** Shows a cross. (MRCrossIconView) */
    MRProgressOverlayViewModeCross,
    /** Shows a custom view. (UIView) */
    MRProgressOverlayViewModeCustom,
};


/**
 Progress HUD to be shown over a whole view controller's view or window.
 Similar look to UIAlertView.
 */
@interface MRProgressOverlayView : UIView

/**
 Creates a new overlay, adds it to provided view and shows it. The counterpart to this method is dismissOverlayForView:animated.
 
 @param view The view that the overlay will be added to
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @return A reference to the created overlay.
 */
+ (instancetype)showOverlayAddedTo:(UIView *)view animated:(BOOL)animated;

/**
 Creates a new overlay, adds it to provided view and shows it. The counterpart to this method is dismissOverlayForView:animated.
 
 @param view The view that the overlay will be added to
 @param title Title label text
 @param mode Visualization mode
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @return A reference to the created overlay.
 */
+ (instancetype)showOverlayAddedTo:(UIView *)view title:(NSString *)title mode:(MRProgressOverlayViewMode)mode animated:(BOOL)animated;

/**
 Creates a new overlay, adds it to provided view and shows it. The counterpart to this method is dismissOverlayForView:animated.
 
 @param view The view that the overlay will be added to
 @param title Title label text
 @param mode Visualization mode
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @param stopBlock Block, which will be called when stop button is tapped.
 @return A reference to the created overlay.
 */
+ (instancetype)showOverlayAddedTo:(UIView *)view title:(NSString *)title mode:(MRProgressOverlayViewMode)mode animated:(BOOL)animated stopBlock:(MRProgressOverlayViewStopBlock)stopBlock;

/**
 Finds the top-most overlay subview and hides it. The counterpart to this method is showOverlayAddedTo:animated:.
 
 @param view The view that is going to be searched for a overlay subview.
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @return YES if a overlay was found and removed, NO otherwise.
 */
+ (BOOL)dismissOverlayForView:(UIView *)view animated:(BOOL)animated;

/**
 Finds the top-most overlay subview and hides it. The counterpart to this method is showOverlayAddedTo:animated:.
 
 @param view The view that is going to be searched for a overlay subview.
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @param completionBlock block will be called, when the animation has finished.
 @return YES if a overlay was found and removed, NO otherwise.
 */
+ (BOOL)dismissOverlayForView:(UIView *)view animated:(BOOL)animated completion:(void(^)())completionBlock;

/**
 Finds all the overlay subviews and hides them.
 
 @param view The view that is going to be searched for overlay subviews.
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @return the number of overlays found and removed.
 */
+ (NSUInteger)dismissAllOverlaysForView:(UIView *)view animated:(BOOL)animated;

/**
 Finds all the overlay subviews and hides them.
 
 @param view The view that is going to be searched for overlay subviews.
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @param completionBlock block will be called, when the animation has finished.
 @return the number of overlays found and removed.
 */
+ (NSUInteger)dismissAllOverlaysForView:(UIView *)view animated:(BOOL)animated completion:(void(^)())completionBlock;

/**
 Finds the top-most overlay subview and returns it.
 
 @param view The view that is going to be searched.
 @return A reference to the last overlay subview discovered.
 */
+ (instancetype)overlayForView:(UIView *)view;

/**
 Finds all overlay subviews and returns them.
 
 @param view The view that is going to be searched.
 @return All found overlay views (array of MBProgressOverlayView objects).
 */
+ (NSArray *)allOverlaysForView:(UIView *)view;

/**
 Allows customization of blur effect.
 
 If you override this method, you are responsible for adding the view to hierachy.
 The view will not be retained.
 The cornerRadius of the layer of the returnValue will be initialized.
 */
- (UIView *)createBlurView;

/**
 Visualisation mode.
 
 How the progress should be visualised.
 */
@property (nonatomic, assign) MRProgressOverlayViewMode mode;

/**
 Current progress.
 
 Use associated setter for non animated changes. Otherwises use setProgress:aniamted:.
 */
@property (nonatomic, assign) float progress;

/**
 Title label text.
 
 By default "Loading ...".
 This will automatically call setTitleLabelAttributedText: with current string attributes.
 */
@property (nonatomic, strong) NSString *titleLabelText UI_APPEARANCE_SELECTOR;

/**
 Title label attributed text.
 */
@property (nonatomic, strong) NSAttributedString *titleLabelAttributedText;

/**
 Title label.
 
 Use this reference to customize titleLabel appearance.
 If you want to customize the titleLabel's text attributes, use setTitleLabelText:.
 Attention:
 Never set titleLabel.text manually. This would unset titleLabel.attributedText where the layout relies on.
 */
@property (readonly, weak) UILabel *titleLabel;

/**
 Mode view.
 
 Should only be customized when in MRProgressOverlayViewModeCustom. In other modes you will get the documented
 components. When mode is changed to MRProgressOverlayViewModeCustom from another, this property will be initialized
 with a new UIView instance. You should make sure to call setMode: first. You are responsible to set the frame size.
 */
@property (nonatomic, strong) UIView *modeView;

/**
 Block, which will be called when stop button is tapped.
 
 Use this to set a block, which is callend when UIControlEventTouchUpInside is fired on the mode view's stop button,
 if available. The receiver will not be hidden or dismissed, automatically.
 */
@property (nonatomic, copy) MRProgressOverlayViewStopBlock stopBlock;

/**
 Change the tint color of the mode views.
 
 Redeclared to document usage, internally tintColorDidChange is used.
 
 @param tintColor The new tint color
 */
- (void)setTintColor:(UIColor *)tintColor;

/**
 Change progress animated.
 
 The animation will be always linear.
 
 @param progress The new progress value.
 @param animated Specify YES to animate the change or NO if you do not want the change to be animated.
 */
- (void)setProgress:(float)progress animated:(BOOL)animated;

/**
 Show the progress view.
 
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 */
- (void)show:(BOOL)animated;

/**
 Hide the progress view.
 
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 */
- (void)hide:(BOOL)animated;

/**
 Hide the progress view and remove on animation completion from the view hierachy.
 
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 */
- (void)dismiss:(BOOL)animated;

/**
 Hide the progress view and remove on animation completion from the view hierachy.
 
 @param animated Specify YES to animate the transition or NO if you do not want the transition to be animated.
 @param completionBlock block will be called, when the animation has finished.
 */
- (void)dismiss:(BOOL)animated completion:(void(^)())completionBlock;

@end
