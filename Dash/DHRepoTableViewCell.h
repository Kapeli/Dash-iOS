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
#import "MRProgress.h"
#import "DHRightDetailLabel.h"

@class DHFeed;

@interface DHRepoTableViewCell : UITableViewCell

@property (assign) IBOutlet UIButton *downloadButton;
@property (assign) IBOutlet MRCircularProgressView *progressView;
@property (assign) IBOutlet UIButton *errorButton;
@property (assign) IBOutlet DHRightDetailLabel *titleLabel;
@property (assign) IBOutlet UIButton *uninstallButton;
@property (assign) IBOutlet UIImageView *checkmark;
@property (assign) IBOutlet UIImageView *platform;
@property (weak) DHFeed *feed;

- (void)setTagsToIndex:(NSInteger)index;

@end
