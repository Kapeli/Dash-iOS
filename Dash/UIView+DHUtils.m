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

#import "UIView+DHUtils.h"

@implementation UIView (DHUtils)

- (void)increaseFrameByX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height
{
    CGRect currentRect = self.frame;
    [self setFrame:CGIncreaseRect(currentRect, x, y, width, height)];
}

@end

CGRect CGIncreaseRect(CGRect rect, CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return CGRectMake(rect.origin.x+x, rect.origin.y+y, rect.size.width+width, rect.size.height+height);
}

CGPoint CGIncreasePoint(CGPoint point, CGFloat x, CGFloat y) {
    return CGPointMake(point.x+x, point.y+y);
}

CGSize CGIncreaseSize(CGSize size, CGFloat width, CGFloat height) {
    return CGSizeMake(size.width+width, size.height+height);
}