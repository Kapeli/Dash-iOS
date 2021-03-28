//
//  UIViewController+MASAdditions.h
//  Masonry
//
//  Created by Craig Siemens on 2015-06-23.
//
//

#import "MASUtilities.h"
#import "MASConstraintMaker.h"
#import "MASViewAttribute.h"

#ifdef MAS_VIEW_CONTROLLER

@interface MAS_VIEW_CONTROLLER (MASAdditions)

/**
 *	following properties return a new MASViewAttribute with appropriate UILayoutGuide and NSLayoutAttribute
 */
@property (nonatomic, strong, readonly) MASViewAttribute *mas_topLayoutGuide;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_bottomLayoutGuide;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_topLayoutGuideTop;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_topLayoutGuideBottom;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_bottomLayoutGuideTop;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_bottomLayoutGuideBottom;


@end

#endif
