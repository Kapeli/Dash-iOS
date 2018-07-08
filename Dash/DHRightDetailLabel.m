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

#import "DHRightDetailLabel.h"

@implementation DHRightDetailLabel

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if(self._rightDetailText.length)
    {
        NSMutableParagraphStyle *paragraph = NSMutableParagraphStyle.new;
        paragraph.alignment = NSTextAlignmentRight;
        rect = self.bounds;
        if(self.isBrowserCell)
        {
            rect.origin.y += 11;
            rect.size.width -= 2;
            if(isRetina)
            {
                rect.origin.y -= 0.5;                
            }
            // Defines the right most text.  This does not alter the Chevron!!
            [self._rightDetailText drawInRect:rect withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16], NSParagraphStyleAttributeName: paragraph, NSForegroundColorAttributeName: [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:147.0/255.0 alpha:1.0]}];
        }
        else
        {
            rect.origin.y += 3;
            rect.size.width -= 2;
            [self._rightDetailText drawInRect:rect withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12], NSParagraphStyleAttributeName: paragraph, NSForegroundColorAttributeName: [UIColor colorWithWhite:142.0/255.0 alpha:1.0]}];
        }
    }
    if(self.subtitle.length)
    {
        rect = self.bounds;
        rect.origin.y += 24;
        [self.subtitle drawInRect:rect withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11], NSForegroundColorAttributeName: [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:147.0/255.0 alpha:1.0]}];
    }
}

/* TODO: DmytriE: Shifts the text eastward */
- (void)drawTextInRect:(CGRect)rect
{
    if(self._rightDetailText.length)
    {
        rect = CGIncreaseRect(rect, 0, 0, -self.maxRightDetailWidth-12, 0);
    }
    if(self.subtitle.length)
    {
        rect = CGIncreaseRect(rect, 0, -7, 0, 0);
    }
    [super drawTextInRect:rect];
}

- (void)setRightDetailText:(NSString *)rightDetailText adjustMainWidth:(BOOL)adjustWidth
{
    [self setRightDetailText:rightDetailText];
    if(adjustWidth)
    {
        // Defines the font size based on whether it is a browser cell.  If it is
        // then the size if 20 otherwise it's 12.
        self.maxRightDetailWidth = [rightDetailText attributedSizeWithFont:[UIFont systemFontOfSize:(self.isBrowserCell) ? 20 : 12]].width;
    }
}

- (void)setRightDetailText:(NSString *)rightDetailText
{
    self._rightDetailText = rightDetailText;
    
    // Removes the right pointed chevron
    if(!rightDetailText.length)
    {
        self.maxRightDetailWidth = 0.0;
    }
    [self setNeedsDisplay];
}

+ (CGFloat)calculateMaxDetailWidthBasedOnLongestPossibleString:(NSString *)string
{
    CGSize size = [string attributedSizeWithFont:[UIFont systemFontOfSize:12]];
    return size.width;
}

- (NSString *)accessibilityValue
{
    return [[NSString stringWithFormat:@"%@ %@", self.subtitle ?: @"", self._rightDetailText ?: @""] trimWhitespace];
}

@end
