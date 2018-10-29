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
#import "DHRepoTableViewCell.h"
#import "DHLatencyTester.h"
#import "MRProgress.h"
#import "DHDocsetIndexer.h"
#import "DHUnarchiver.h"

@interface DHRepo : UITableViewController <UIActionSheetDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (strong) NSMutableArray *feeds;
@property (strong) NSMutableArray *filteredFeeds;
@property (assign) BOOL searchBarActive;
@property (assign) BOOL searchBarActiveIsALie;
@property (assign) BOOL didFirstReload;
@property (weak) UISearchDisplayController *searchController;
@property (strong) NSString *filterQuery;
@property (weak) MRProgressOverlayView *updateOverlay;
@property (assign) IBOutlet UISearchBar *searchBar;
@property (assign) BOOL loading;
@property (assign) NSString *loadingText;

- (void)setUp;
- (IBAction)downloadButtonPressed:(id)sender;
- (IBAction)uninstallButtonPressed:(id)sender;
- (IBAction)errorButtonPressed:(id)sender;
- (NSString *)installFeed:(DHFeed *)feed isAnUpdate:(BOOL)isAnUpdate;
- (BOOL)canInstallFeed:(DHFeed *)aFeed;
- (NSString *)docsetPathForFeed:(DHFeed *)feed;
- (NSString *)defaultsKey;
- (NSString *)uniqueTempDirAtPath:(NSString *)path;
- (void)saveState;
- (NSMutableArray *)activeFeeds;
- (IBAction)updateButtonPressed:(id)sender;
- (BOOL)alertIfUpdatesAreScheduled;
- (void)backgroundCheckForUpdatesIfNeeded;
- (NSString *)repoIdentifier; // Used to find a corresponding repo for a installed docset
- (NSString *)defaultsAutomaticallyCheckForUpdatesKey;
@property (nonatomic, strong, readonly, class) NSString *defaultsAlphabetizingKey;
- (void)emptyTrashAtPath:(NSString *)trashPath;
- (NSString *)docsetInstallFolderPath;
- (NSString *)uniqueTrashPath;
- (void)reload;
- (BOOL)shouldStall;
- (NSInteger)numberOfEntriesBeingInstalled;
- (NSInteger)indexOfFeedWithFeedURL:(NSString *)feedURL;
- (void)startInstallingFeed:(DHFeed *)feed isAnUpdate:(BOOL)isAnUpdate;
- (NSString *)defaultsScheduledUpdateKey;
- (void)updateFeeds:(NSArray *)feeds;
- (void)checkForUpdatesAndShowInterface:(BOOL)withInterface updateWithoutAsking:(BOOL)updateWithoutAsking;

@end

NSInteger compareFeeds(id feed1, id feed2, void *context);

#define DHSettingsChangedNotification @"DHSettingsChangedNotification"
