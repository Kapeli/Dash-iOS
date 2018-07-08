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
#import "DHRightDetailLabel.h"

@interface DHBrowserTableViewCell : UITableViewCell


@property (assign) UIImageView *typeImageView;

/** This property is linked to the entry label.  It holds the entry's label, and the image associated with the programming language.
 * @property titleLabel: The name associated with the image used
 * @property platformImageView: The image defining the type of language and/or category (functions, guides, classes, etc)
 */
@property (weak) IBOutlet DHRightDetailLabel *titleLabel;
@property (assign) IBOutlet UIImageView *platformImageView;

- (void)makeEntryCell;

@end
