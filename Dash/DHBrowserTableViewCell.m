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

#import "DHBrowserTableViewCell.h"

@implementation DHBrowserTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.titleLabel.isBrowserCell = YES;
}

- (void)makeEntryCell
{
    if(self.typeImageView)
    {
        return;
    }
    self.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    [self.titleLabel increaseFrameByX:24 y:0 width:-24 height:0];
    UIImageView *typeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.imageView.frame.origin.x+28, self.imageView.frame.origin.y+1, 14, 14)];
    [typeImageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    self.typeImageView = typeImageView;
    [self addSubview:typeImageView];
}

- (UIImageView *)imageView
{
    return self.platformImageView;
}

- (UILabel *)textLabel
{
    return self.titleLabel;
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index
{
    if(self.editing)
    {
        return;
    }
    [super insertSubview:view atIndex:index];
}

- (NSString *)accessibilityValue
{
    return [self.titleLabel accessibilityValue];
}

@end
