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

#import "DHDocsetBrowser.h"

@class DHNestedViewController;

@interface DHRemoteBrowser : UITableViewController  <UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (strong) DHRemote *remote;
@property (strong) NSMutableArray *results;
@property (assign) BOOL isEmpty;
@property (strong) DHDBSearchController *searchController;
@property (assign) BOOL didFirstLoad;
@property (assign) BOOL isRestoring;
@property (assign) BOOL didLoad;

- (void)popNestedViewControllers;
- (DHNestedViewController *)nestedViewController;

@end
