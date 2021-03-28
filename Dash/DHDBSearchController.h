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

#import <Foundation/Foundation.h>
#import "DHDBSearcher.h"
@protocol SearchViewController;

@interface DHDBSearchController : NSObject <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate, DHDBSearcherDelegate>

@property (assign) BOOL loading;
@property (retain) NSArray *docsets;
@property (retain) NSString *typeLimit;
@property (retain) NSMutableArray *results;
@property (retain) NSMutableArray *nextResults;
@property (weak) UISearchController *searchController;
@property (weak) UIViewController<SearchViewController> *viewController;
@property (retain) DHDBSearcher *searcher;
@property (retain) NSString *viewControllerTitle;
@property (assign) BOOL isRestoring;

+ (DHDBSearchController *)searchControllerWithDocsets:(NSArray *)docsets typeLimit:(NSString *)typeLimit viewController:(UIViewController<SearchViewController> *)viewController;
- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewDidDisappear;
- (void)viewWillDisappear;
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
- (void)hookToSearchController:(UISearchController *)searchController;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder;
- (void)decodeRestorableStateWithCoder:(NSCoder *)coder;

@end
