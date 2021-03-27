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
#import "DHDBSearchController.h"
@protocol SearchableController;

@interface DHTypeBrowser : UITableViewController <UINavigationControllerDelegate, SearchableController>

@property (strong) DHDocset *docset;
@property (strong) NSMutableArray *types;
@property (assign) BOOL isLoading;
@property (assign) BOOL isEmpty;
@property (strong) DHDBSearchController *dbSearchController;
@property (strong) UISearchController *searchController;
@property (strong) UITableView *searchResultTableView;
@property (assign) BOOL didFirstLoad;
@property (assign) BOOL isRestoring;
@property (assign) BOOL didLoad;

@end
