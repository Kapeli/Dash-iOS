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

#import <UIKit/UIKit.h>

@interface UIView (DHUtils)

- (void)increaseFrameByX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height;

@end

CGRect CGIncreaseRect(CGRect rect, CGFloat x, CGFloat y, CGFloat width, CGFloat height);
CGPoint CGIncreasePoint(CGPoint point, CGFloat x, CGFloat y);
CGSize CGIncreaseSize(CGSize size, CGFloat width, CGFloat height);
