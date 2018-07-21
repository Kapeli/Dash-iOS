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

/** DmytriE 2018-07-15: Customizes the default configuration of any controls to
 *  update the properties for that object.
 *  @return NONE
 */
- (void)awakeFromNib
{
    [super awakeFromNib];
    self.titleLabel.isBrowserCell = YES;
}

/** DmytriE 2018-07-15:
 *  @return NONE
 */
- (void)makeEntryCell
{
    // Returns if there is an image associated with the cell.
    if(self.typeImageView)
    {
        return;
    }
    self.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    [self.titleLabel increaseFrameByX:24 y:0 width:-24 height:0];
    
    // Create image view within the cell's frame and then add it to the view.
    UIImageView *typeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.imageView.frame.origin.x+28, self.imageView.frame.origin.y+1, 14, 14)];
    typeImageView.layer.cornerRadius = 5;
    typeImageView.clipsToBounds = YES;
    [typeImageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    self.typeImageView = typeImageView;
    [self addSubview:typeImageView];
}

/** DmytriE 2018-07-12: Returns appropriate documentation set image.
 *  @return platformImageView: Pointer to the ImageView
 */
- (UIImageView *)imageView
{
    return self.platformImageView;
}

/** DmytriE 2018-07-12: Returns the text label.
 *  @return Pointer to the cell text label.
 */
- (UILabel *)textLabel
{
    return self.titleLabel;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    /* DmytriE 2018-07-21: This section of code was removed to allow for orientation
     * changes to occur while also displaying the counter in the RightDetailLabel
     * for iPhones 6 - X.
     * Not sure what the purpose of this section was...
     */
    if(self.accessoryType == UITableViewCellAccessoryDisclosureIndicator)
    {
        // Determien the width of the iPhone then subtract the width of the frame.
        // This will be the width that is required to produce the desired result.
       //[self.titleLabel setFrame:CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, self.frame.size.width-self.titleLabel.frame.origin.x-33, self.titleLabel.frame.size.height)];
    }
    else
    {
        //[self.titleLabel setFrame:CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, self.frame.size.width-self.titleLabel.frame.origin.x-16, self.titleLabel.frame.size.height)];
    }
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
