//
//  Copyright (C) 2016  Kapeli
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "DHNavigationAnimator.h"
#import "DHPreferences.h"
#import "DHWebViewController.h"
#import "DHDocsetDownloader.h"

@implementation DHNavigationAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    if(self.noAnimation)
    {
        return 0.00001;
    }
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    if(!isRegularHorizontalClass)
    {
        BOOL isOpening = [toViewController isKindOfClass:[DHPreferences class]];
        if(isOpening)
        {
            [[transitionContext containerView] addSubview:toViewController.view];
            toViewController.view.alpha = 1;
            CGRect endFrame = fromViewController.view.frame;
            CGRect startFrame = endFrame;
            startFrame.origin.y = CGRectGetMaxY(endFrame);
            startFrame.size.height = [transitionContext containerView].frame.size.height;
            toViewController.view.frame = startFrame;
            
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                toViewController.view.frame = [transitionContext containerView].frame;
            } completion:^(BOOL finished) {
                fromViewController.view.transform = CGAffineTransformIdentity;
                [transitionContext completeTransition:YES];
            }];
        }
        else
        {
            [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];
            toViewController.view.alpha = 1;
            CGRect endFrame = fromViewController.view.frame;
            CGRect toFrame = fromViewController.view.frame;
            toFrame.origin.y = CGRectGetMaxY(fromViewController.navigationController.navigationBar.frame);
            toFrame.size.height -= toFrame.origin.y;
            toViewController.view.frame = toFrame;
            endFrame.origin.y = CGRectGetMaxY(endFrame);
            
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                fromViewController.view.frame = endFrame;
            } completion:^(BOOL finished) {
                fromViewController.view.transform = CGAffineTransformIdentity;
                [transitionContext completeTransition:YES];
            }];
        }
    }
    else
    {
        BOOL isOpening = [toViewController isKindOfClass:[DHPreferences class]] || [toViewController isKindOfClass:[DHDocsetDownloader class]];
        if(isOpening)
        {
            [[transitionContext containerView] addSubview:toViewController.view];
            toViewController.view.alpha = 0;
            toViewController.view.frame = [transitionContext containerView].frame;
            
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                toViewController.view.alpha = 1;
            } completion:^(BOOL finished) {
                fromViewController.view.transform = CGAffineTransformIdentity;
                [transitionContext completeTransition:YES];
            }];
        }
        else{
            [[transitionContext containerView] addSubview:toViewController.view];
            toViewController.view.alpha = 0;
            CGRect toFrame = fromViewController.view.frame;
            toFrame.origin.y = CGRectGetMaxY(fromViewController.navigationController.navigationBar.frame);
            toFrame.size.height -= toFrame.origin.y;
            toViewController.view.frame = toFrame;
            
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                toViewController.view.alpha = 1;
            } completion:^(BOOL finished) {
                fromViewController.view.transform = CGAffineTransformIdentity;
                [transitionContext completeTransition:YES];
            }];
        }
    }
}

@end
