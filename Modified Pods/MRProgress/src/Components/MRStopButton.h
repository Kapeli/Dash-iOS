//
//  MRStopButton.h
//  MRProgress
//
//  Created by Marius Rackwitz on 27.12.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 Stop button used by progress views to stop the related and visualised running task.
 */
@interface MRStopButton : UIButton

/**
 Size ratio in comparision to the parent view
 
 The ratio by which the size of the click area will be resized in comparision to the parent size in default state.
 A positive value means that the stop button is smaller than the parent view.
 A negative value means that the stop button is bigger than the parent view.
 By default it has the value 0.3.
 
 The method frameThatFits: will ensure that this property is applied. It has to be called by the parent view in the
 layoutSubviews by class contract.
 */
@property (nonatomic, assign) CGFloat sizeRatio;
@property (nonatomic, assign) CGSize fixedSize;
/**
 Highlighted size ratio in comparision to the default state
 
 The ratio by which the size of the click area will be resized, while touch is tracked inside.
 A positive value means that the stop button will be shrinked.
 A negative value means that the stop button will be enlarged.
 By default it has the value 0.9.
 */
@property (nonatomic, assign) CGFloat highlightedSizeRatio;

/**
 Asks the view to calculate and return the frame to be displayed in its parent.
 
 @param parentSize   size of the parent node in the view hierachy
 */
- (CGRect)frameThatFits:(CGRect)parentSize;

@end
