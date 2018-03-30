//
//  MRIconView.h
//  MRProgress
//
//  Created by Marius Rackwitz on 22.10.13.
//  Copyright (c) 2013 Marius Rackwitz. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 Base class for icons which are given by an UIBezierPath and drawn with a CAShapeLayer.
 Their circular outer border and their line is colored in their tintColor.
 */
@interface MRIconView : UIView

/**
 Inner path.
 */
- (UIBezierPath *)path;

@end


/**
 Draws a checkmark.
 */
@interface MRCheckmarkIconView : MRIconView

@end


/**
 Draws a cross.
 */
@interface MRCrossIconView : MRIconView

@end
