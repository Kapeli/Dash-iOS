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

@interface DHRightDetailLabel : UILabel

/* DmytriE: Property Definitions:
 * @ *_rightDetailText: Pointer to the object which holds the text
 * @ maxRightDetailWidth: The width of the part of the cell which
 * contains the count of items for a given selection and the right
 * chevron.
 * @ isBrowserCell: Boolean which decideds whether it points to
 * another form with sub-selections or a Docset entry.
 * @ subtitle: The title of the browser or docset entry.
 */
@property (strong) NSString *_rightDetailText;
@property (assign, nonatomic) CGFloat maxRightDetailWidth;
@property (assign) BOOL isBrowserCell;
@property (strong) NSString *subtitle;

/** DmytriE:
 * @param rightDetailText: This is the number of sub-section elements which 
 */
- (void)setRightDetailText:(NSString *)rightDetailText;

/*DmytriE:
 */
+ (CGFloat)calculateMaxDetailWidthBasedOnLongestPossibleString:(NSString *)string;

/* DmytriE:
 * This adjusts the text on the screen based on whether the screen has
 * been rotated clock- or counterclock-wise.  It adjusts the font size
 * of the text.
 */
- (void)setRightDetailText:(NSString *)rightDetailText adjustMainWidth:(BOOL)adjustWidth;

@end
