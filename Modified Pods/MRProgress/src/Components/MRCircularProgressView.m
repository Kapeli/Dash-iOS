//
//  MRCircularProgressView.m
//  MRProgress
//
//  Created by Marius Rackwitz on 10.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MRCircularProgressView.h"
#import "MRProgressHelper.h"
#import "MRStopButton.h"


static NSString *const MRCircularProgressViewProgressAnimationKey = @"MRCircularProgressViewProgressAnimationKey";


@interface MRCircularProgressView ()

@property (nonatomic, strong, readwrite) NSNumberFormatter *numberFormatter;
@property (nonatomic, strong, readwrite) NSTimer *valueLabelUpdateTimer;

@property (nonatomic, weak, readwrite) UILabel *valueLabel;
@property (nonatomic, weak, readwrite) MRStopButton *stopButton;

@end


@implementation MRCircularProgressView {
    int _valueLabelProgressPercentDifference;
}

@synthesize stopButton = _stopButton;

+ (void)load {
    [self.appearance setAnimationDuration:0.3];
    [self.appearance setBorderWidth:2.0];
    [self.appearance setLineWidth:2.0];
}

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

+ (Class)layerClass {
    return CAShapeLayer.class;
}

- (CAShapeLayer *)shapeLayer {
    return (CAShapeLayer *)self.layer;
}

- (void)commonInit {
    self.isAccessibilityElement = YES;
    self.accessibilityLabel = NSLocalizedString(@"Determinate Progress", @"Accessibility label for circular progress view");
    self.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;
    
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    self.numberFormatter = numberFormatter;
    numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
    numberFormatter.locale = NSLocale.currentLocale;
    
    self.shapeLayer.fillColor = UIColor.clearColor.CGColor;
    
    UILabel *valueLabel = [UILabel new];
    self.valueLabel = valueLabel;
    valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    valueLabel.textColor = UIColor.blackColor;
    valueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:valueLabel];
    
    MRStopButton *stopButton = [MRStopButton new];
    [self addSubview:stopButton];
    self.stopButton = stopButton;
    
    self.mayStop = NO;
    
    self.progress = 0;
    
    [self tintColorDidChange];
}


#pragma mark - Properties

- (CGFloat)borderWidth {
    return self.shapeLayer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.shapeLayer.borderWidth = borderWidth;
}

- (CGFloat)lineWidth {
    return self.shapeLayer.lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    self.shapeLayer.lineWidth = lineWidth;
}


#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    const CGFloat offset = 4;
    CGRect valueLabelRect = self.bounds;
    valueLabelRect.origin.x += offset;
    valueLabelRect.size.width -= 2*offset;
    self.valueLabel.frame = valueLabelRect;
    
    self.layer.cornerRadius = self.frame.size.width / 2.0f;
    self.shapeLayer.path = [self layoutPath].CGPath;
    
    self.stopButton.frame = [self.stopButton frameThatFits:self.bounds];
}

- (UIBezierPath *)layoutPath {
    const double TWO_M_PI = 2.0 * M_PI;
    const double startAngle = 0.75 * TWO_M_PI;
    const double endAngle = startAngle + TWO_M_PI;
    
    CGFloat width = self.frame.size.width;
    CGFloat borderWidth = self.layer.borderWidth;
    CGFloat lineWidth = self.lineWidth;
    return [UIBezierPath bezierPathWithArcCenter:CGPointMake(width/2.0f, width/2.0f)
                                          radius:width/2.0f - lineWidth/2.0f - borderWidth/2.0f
                                      startAngle:startAngle
                                        endAngle:endAngle
                                       clockwise:YES];
}


#pragma mark - Hook tintColor

- (void)tintColorDidChange {
    [super tintColorDidChange];
    UIColor *tintColor = self.tintColor;
    self.shapeLayer.strokeColor = tintColor.CGColor;
    self.layer.borderColor = tintColor.CGColor;
    self.valueLabel.textColor = tintColor;
    self.stopButton.tintColor = tintColor;
}


#pragma mark - MRStopableView's implementation

- (void)setMayStop:(BOOL)mayStop {
    self.stopButton.hidden = !mayStop;
    self.valueLabel.hidden = mayStop;
}

- (BOOL)mayStop {
    return !self.stopButton.hidden;
}


#pragma mark - Control progress

- (void)setProgress:(float)progress {
    NSParameterAssert(progress >= 0 && progress <= 1);
    
    [self stopAnimation];
    
    _progress = progress;
    
    [self updateProgress];
}

- (void)updateProgress {
    [self updatePath];
    [self updateLabel:self.progress];
}

- (void)updatePath {
    self.shapeLayer.strokeEnd = self.progress;
}

- (void)updateLabel:(float)progress {
    self.valueLabel.text = [self.numberFormatter stringFromNumber:@(progress)];
    self.accessibilityValue = self.valueLabel.text;
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    if (animated) {
        if (ABS(self.progress - progress) < CGFLOAT_MIN) {
            return;
        }
        
        [self animateToProgress:progress];
    } else {
        self.progress = progress;
    }
}

- (void)setAnimationDuration:(CFTimeInterval)animationDuration {
    NSParameterAssert(animationDuration > 0);
    _animationDuration = animationDuration;
}

- (void)animateToProgress:(float)progress {
    [self stopAnimation];
    
    // Add shape animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = self.animationDuration;
    animation.fromValue = @(self.progress);
    animation.toValue = @(progress);
    animation.delegate = self;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [self.shapeLayer addAnimation:animation forKey:MRCircularProgressViewProgressAnimationKey];
    
    // Add timer to update valueLabel
    _valueLabelProgressPercentDifference = (progress - self.progress) * 100;
    CFTimeInterval timerInterval =  self.animationDuration / ABS(_valueLabelProgressPercentDifference);
    self.valueLabelUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:timerInterval
                                                                  target:self
                                                                selector:@selector(onValueLabelUpdateTimer:)
                                                                userInfo:nil
                                                                 repeats:YES];
    
    
    _progress = progress;
}

- (void)stopAnimation {
    // Stop running animation
    [self.layer removeAnimationForKey:MRCircularProgressViewProgressAnimationKey];
    
    // Stop timer
    [self.valueLabelUpdateTimer invalidate];
    self.valueLabelUpdateTimer = nil;
}

- (void)onValueLabelUpdateTimer:(NSTimer *)timer {
    if (_valueLabelProgressPercentDifference > 0) {
        _valueLabelProgressPercentDifference--;
    } else {
        _valueLabelProgressPercentDifference++;
    }
    
    [self updateLabel:self.progress - (_valueLabelProgressPercentDifference / 100.0f)];
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if(UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || self.hidden) {
        return [super pointInside:point withEvent:event];
    }
    
    CGRect relativeFrame = self.bounds;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitTestEdgeInsets);
    
    return CGRectContainsPoint(hitFrame, point);
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self updateProgress];
    [self stopAnimation];
}

@end
