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

#import "DHRepo.h"
#import "DHFeed.h"
#import "DHDBResult.h"
#import "DHDocsetManager.h"
#import "DHDocsetTransferrer.h"
#import "DHRightDetailLabel.h"

@implementation DHRepo

- (void)setUp // doesn't get called unless you call the singleton from DHAppDelegate
{
    // Don't count on anything being loaded here. Only stateless stuff.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *file = nil;
        NSString *installPath = [self docsetInstallFolderPath];
        NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:installPath];
        NSMutableArray *toDelete = [NSMutableArray array];
        while(file = [dirEnum nextObject])
        {
            if([[file pathExtension] isCaseInsensitiveEqual:@"docset"])
            {
                [dirEnum skipDescendants];
                continue;
            }
            if([[file lastPathComponent] hasPrefix:@"dash_temp_"])
            {
                [dirEnum skipDescendants];
                NSString *fullPath = [installPath stringByAppendingPathComponent:file];
                [toDelete addObject:fullPath];
            }
        }
        for(NSString *fullPath in toDelete)
        {
            [fileManager moveItemAtPath:fullPath toPath:[self uniqueTrashPath] error:nil];
        }
        [self emptyTrashAtPath:[self trashPath]];
    });
    
    // Define how the download circular progress icon appears.
    [MRCircularProgressView appearance].lineWidth = 2.0f;
    [MRCircularProgressView appearance].borderWidth = 1.0f;
}

- (IBAction)updateButtonPressed:(id)sender
{
    [self checkForUpdatesAndShowInterface:YES updateWithoutAsking:NO];
}

- (void)checkForUpdatesAndShowInterface:(BOOL)withInterface updateWithoutAsking:(BOOL)updateWithoutAsking
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[self defaultsScheduledUpdateKey]];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:[self defaultsUpdateLastCheckDateKey]];
    MRProgressOverlayView *overlay = nil;
    if(withInterface)
    {
        BOOL found = NO;
        for(DHFeed *feed in self.feeds)
        {
            if(feed.installed)
            {
                found = YES;
                break;
            }
        }
        if(!found)
        {
            [[[UIAlertView alloc] initWithTitle:@"Nothing to Update" message:@"You don't have any docsets installed. Download some!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        overlay = [MRProgressOverlayView showOverlayAddedTo:(isRegularHorizontalClass) ? self.splitViewController.view : self.navigationController.view title:@"Checking..." mode:MRProgressOverlayViewModeIndeterminate animated:YES stopBlock:^(MRProgressOverlayView *progressOverlayView) {
            self.updateOverlay = nil;
            [progressOverlayView dismiss:YES];
        }];
        self.updateOverlay = overlay;
    }
    dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
    dispatch_async(queue, ^{
        if(withInterface)
        {
            [NSThread sleepForTimeInterval:1.0f];
        }
        NSMutableArray *toUpdate = [NSMutableArray array];
        for(DHFeed *feed in self.feeds)
        {
            if(withInterface && self.updateOverlay != overlay)
            {
                return;
            }
            if(feed.installed && !feed.installing)
            {
                NSString *error = nil;
                DHFeedResult *result = [self loadFeed:feed error:&error];
                if(result && ![result.version isEqualToString:feed.installedVersion])
                {
                    [toUpdate addObject:feed];
                }
            }
        }
        [toUpdate filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject installed] && ![evaluatedObject installing];
        }]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(withInterface)
            {
                [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[self defaultsScheduledUpdateKey]];
                if(overlay == self.updateOverlay)
                {
                    if(!toUpdate.count)
                    {
                        [overlay setMode:MRProgressOverlayViewModeCheckmark];
                        [overlay setTitleLabelText:@"Up to date"];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [overlay dismiss:YES];
                        });
                    }
                    else
                    {
                        [overlay dismiss:YES completion:^{
                            [self showUpdateRequestForFeeds:toUpdate count:toUpdate.count docsetList:[self docsetListForFeeds:toUpdate]];
                        }];
                    }
                }
                return;
            }
            else if(toUpdate.count && !withInterface)
            {
                if(updateWithoutAsking)
                {
                    [self updateFeeds:toUpdate];
                }
                else
                {
                    [[NSUserDefaults standardUserDefaults] setInteger:toUpdate.count forKey:[self defaultsScheduledUpdateKey]];
                    [[NSUserDefaults standardUserDefaults] setObject:[self docsetListForFeeds:toUpdate] forKey:[self defaultsScheduledDocsetListUpdateKey]];
                }
            }
            else if(!toUpdate.count)
            {
                [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[self defaultsScheduledUpdateKey]];
            }
        });
    });
}

- (void)showUpdateRequestForFeeds:(NSArray *)toUpdate count:(NSInteger)feedCount docsetList:(NSString *)docsetList
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[self defaultsScheduledUpdateKey]];
    [UIAlertView showWithTitle:@"Updates Found" message:[NSString stringWithFormat:@"Updates are available for %ld %@:%@%@", (long)feedCount, (feedCount > 1) ? @"docsets" : @"docset", (feedCount > 1) ? @"\n\n" : @" ", docsetList] cancelButtonTitle:@"Maybe Later" otherButtonTitles:@[@"Update"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            if(toUpdate)
            {
                [self updateFeeds:toUpdate];
            }
            else
            {
                [self checkForUpdatesAndShowInterface:NO updateWithoutAsking:YES];
            }
        }
    }];
}

- (NSString *)docsetListForFeeds:(NSArray *)toUpdate
{
    NSMutableArray *sortedFeeds = [NSMutableArray arrayWithArray:toUpdate];
    [sortedFeeds sortUsingFunction:compareFeeds context:nil];
    NSMutableString *docsetList = [[NSMutableString alloc] init];
    NSInteger count = 0;
    for(DHFeed *feed in sortedFeeds)
    {
        if(docsetList.length)
        {
            [docsetList appendString:@"\n"];
        }
        [docsetList appendString:[feed docsetNameWithVersion:NO]];
        ++count;
        if(count > 15)
        {
            [docsetList appendString:@"\nand more..."];
            break;
        }
    }
    return docsetList;
}

- (void)updateFeeds:(NSArray *)feeds
{
    for(DHFeed *feed in feeds)
    {
        if(feed.installed && !feed.installing)
        {
            [self startInstallingFeed:feed isAnUpdate:YES];
        }
    }
}

- (BOOL)alertIfUpdatesAreScheduled
{
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:[self defaultsScheduledUpdateKey]];
    if(count > 0)
    {
        NSString *docsetList = [[NSUserDefaults standardUserDefaults] objectForKey:[self defaultsScheduledDocsetListUpdateKey]];
        if(docsetList && docsetList.length)
        {
            [self showUpdateRequestForFeeds:nil count:count docsetList:docsetList];
            return YES;
        }
    }
    return NO;
}

- (void)backgroundCheckForUpdatesIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldUpdate = [defaults boolForKey:[self defaultsAutomaticallyCheckForUpdatesKey]];
    NSDate *lastDate = [defaults objectForKey:[self defaultsUpdateLastCheckDateKey]];
    if(shouldUpdate && (!lastDate ||  [[NSDate date] timeIntervalSinceDate:lastDate] > 60*60*24))
    {
        [self checkForUpdatesAndShowInterface:NO updateWithoutAsking:NO];
    }
}

- (DHFeedResult *)loadFeed:(DHFeed *)feed error:(NSString **)returnError
{
    return nil;
}

/** DmytriE 2018-07-17: Based on the feed selected to install it takes the row value and
 *  finds it in the list of active feeds (list of available feeds to install).  It then
 *  determines whether the feed is downloadable.  If so, it begins installing the feed to
 *  your device.
 *
 *  @param sender: The event handler for button click
 *  @return Iteractive Button Action response
 */
- (IBAction)downloadButtonPressed:(id)sender
{
    NSUInteger row = [sender tag];
    DHFeed *feed = [self activeFeeds][row];
    
    if([self canInstallFeed:feed])
    {
        [self startInstallingFeed:feed isAnUpdate:NO];
    }
}

/** DmytriE 2018-07-17:
 *  @param  feed: DocSet to display Circular Progress Bar
 *  @return NONE
 */
- (void)showDownloadProgressViewForFeed:(DHFeed *)feed
{
    DHRepoTableViewCell *cell = feed.cell;
    feed.error = nil;
    cell.progressView.progress = 0.0;
    cell.progressView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.3 animations:^{
        cell.checkmark.alpha = 0.0;
        cell.checkmark.transform = CGAffineTransformMakeScale(0.01, 0.01);
        cell.uninstallButton.alpha = 0.0;
        cell.uninstallButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
        cell.errorButton.alpha = 0.0;
        cell.errorButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
        cell.progressView.alpha = 1.0;
        cell.progressView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.downloadButton.alpha = 0.0;
        cell.downloadButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished) {
        cell.downloadButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.errorButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.checkmark.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.uninstallButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        [feed adjustTitleLabelWidthBasedOnButtonsShown];
    }];
}

- (IBAction)errorButtonPressed:(id)sender
{
    NSUInteger row = [sender tag];
    DHFeed *feed = [self activeFeeds][row];
    [[[UIAlertView alloc] initWithTitle:@"Docset Install Failed" message:[NSString stringWithFormat:@"%@ Please check your Internet connection and available free space and try again.", feed.error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)showErrorButtonForFeed:(DHFeed *)feed
{
    DHRepoTableViewCell *cell = feed.cell;
    feed.detailString = @"";
    feed.maxRightDetailWidth = 0.0;
    cell.titleLabel.rightDetailText = @"";
    cell.errorButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [feed adjustTitleLabelWidthBasedOnButtonsShown];
    [UIView animateWithDuration:0.3 animations:^{
        cell.errorButton.alpha = 1.0;
        cell.errorButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:nil];
}

/** DmytriE: 2018-07-15: Display the uninstall (trash) icon for installed
 *  documentation sets.
 *  feed: The list of documentation sets
 *  @return NONE
 */
- (void)showUninstallButtonForFeed:(DHFeed *)feed
{
    DHRepoTableViewCell *cell = feed.cell;
    cell.uninstallButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    cell.checkmark.transform = CGAffineTransformMakeScale(0.01, 0.01);
    feed.detailString = @"";
    feed.maxRightDetailWidth = 0.0;
    cell.titleLabel.rightDetailText = @"";
    [feed adjustTitleLabelWidthBasedOnButtonsShown];
    feed.progressShown = NO;
    [UIView animateWithDuration:0.3 animations:^{
        cell.uninstallButton.alpha = 1.0;
        cell.uninstallButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.checkmark.alpha = 1.0;
        cell.checkmark.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.progressView.alpha = 0.0;
        cell.progressView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished) {
        cell.progressView.progress = 0.0;
        cell.progressView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}

/** DmytriE: 2018-07-15: Cancels the the download of the feed defined by the
 *  sender value.
 *  @param  sender: A UIBarItem which denotes the DocSet you wish to stop
 *  downloading information.
 */
- (IBAction)stopButtonPressed:(id)sender
{
    NSUInteger row = [sender tag];
    DHFeed *feed = [self activeFeeds][row];
    feed.installing = NO;
    [feed.feedResult.fileDownload cancelDownload];
    [self feedWasStopped:feed];
    feed.feedResult = nil;
    feed.progressShown = NO;
    feed.progress = 0.0;
    feed.detailString = @"";
    feed.maxRightDetailWidth = 0.0;
    feed.cell.titleLabel.rightDetailText = @"";
    
    // Display the downloaded feed and provide Uninstall button otherwise
    // display the download button.
    if(feed.installed)
    {
        [self setTitle:[feed docsetNameWithVersion:YES] forCell:feed.cell];
        [self showUninstallButtonForFeed:feed];
    }
    else
    {
        [self showDownloadButtonForFeed:feed];        
    }
}

- (void)feedWasStopped:(DHFeed *)feed
{
    
}

- (IBAction)uninstallButtonPressed:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[self defaultsScheduledUpdateKey]];
    NSUInteger row = [sender tag];
    DHFeed *feed = [self activeFeeds][row];
    feed.installed = NO;
    feed.installedVersion = nil;
    [self saveState];
    [self setTitle:[feed docsetNameWithVersion:YES] forCell:feed.cell];
    
    NSString *trashPath = [self uniqueTrashPath];
    NSString *feedPath = [self docsetPathForFeed:feed];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [[DHDocsetManager sharedManager] removeDocsetsInFolder:feedPath];

    [fileManager moveItemAtPath:feedPath toPath:trashPath error:nil];
    [self feedDidUninstall:feed];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self emptyTrashAtPath:trashPath];
    });
    [self showDownloadButtonForFeed:feed];
}

- (void)feedDidUninstall:(DHFeed *)feed
{
    
}

/** DmytriE 2018-07-16:
 *  @param trashPath: A pointer to the list of object which are destined
 *  to be removed from the user's device.
 *  @return NONE
 */
- (void)emptyTrashAtPath:(NSString *)trashPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    @autoreleasepool {
        NSString *file = nil;
        NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:trashPath];
        NSMutableArray *toDelete = [NSMutableArray array];
        while(file = [dirEnum nextObject])
        {
            if([[file pathExtension] isCaseInsensitiveEqual:@"docset"])
            {
                [dirEnum skipDescendants];
                NSString *fullPath = [trashPath stringByAppendingPathComponent:file];
                [toDelete addObject:[fullPath stringByAppendingPathComponent:@"Contents/Resources/tarix.tgz"]];
                [toDelete addObject:[fullPath stringByAppendingPathComponent:@"Contents/Resources/optimisedIndex.dsidx"]];
                [toDelete addObject:[fullPath stringByAppendingPathComponent:@"Contents/Resources/docSet.dsidx"]];
                continue;
            }
            if([[file pathExtension] isCaseInsensitiveEqual:@"dsidx"] || [[file pathExtension] isCaseInsensitiveEqual:@"tgz"] || [[file pathExtension] isCaseInsensitiveEqual:@"tarix"])
            {
                NSString *fullPath = [trashPath stringByAppendingPathComponent:file];
                [toDelete addObject:fullPath];
            }
        }
        for(NSString *path in toDelete)
        {
            [fileManager removeItemAtPath:path error:nil];
        }
    }
    [fileManager removeItemAtPath:trashPath error:nil];
}

/** DmytriE 2018-07-16: Display the appropriate button on the Repository
 *  download section.
 *  @param feed: Pointer to the list of all downloadable content
 *  @return NONE
 */
- (void)showDownloadButtonForFeed:(DHFeed *)feed
{
    DHRepoTableViewCell *cell = feed.cell;
    cell.downloadButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    feed.detailString = @"";
    feed.maxRightDetailWidth = 0.0;
    feed.cell.titleLabel.rightDetailText = @"";
    feed.progressShown = NO;
    
    // Display the desired images indicating the different stages (downloadable,
    // and completed).  Completed has the checkmark and uninstall image while
    // downloadable has the download image.
    [UIView animateWithDuration:0.3 animations:^{
        cell.downloadButton.alpha = 1.0;
        cell.downloadButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.progressView.alpha = 0.0;
        cell.progressView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        cell.checkmark.alpha = 0.0;
        cell.checkmark.transform = CGAffineTransformMakeScale(0.01, 0.01);
        cell.uninstallButton.alpha = 0.0;
        cell.uninstallButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished) {
        cell.progressView.progress = 0.0;
        cell.progressView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.uninstallButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        cell.checkmark.transform = CGAffineTransformMakeScale(1.0, 1.0);
        [feed adjustTitleLabelWidthBasedOnButtonsShown];
    }];
}

- (UITableView *)activeTableView
{
    return (self.searchBarActive) ? self.searchController.searchResultsTableView : self.tableView;
}

- (NSMutableArray *)activeFeeds
{
    return (self.searchBarActive) ? self.filteredFeeds : self.feeds;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([self activeFeeds].count) ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView != self.tableView)
    {
        return self.filteredFeeds.count;
    }
    return self.feeds.count;
}

/** DmytriE 2018-07-16:
 *  @param tableView:
 *  @param indexPath
 *  @return TableViewCell:
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHRepoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DHRepoCell" forIndexPath:indexPath];
    [cell.downloadButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -2, -10, -10)];
    [cell.uninstallButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    [cell.progressView setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -10)];
    [cell.errorButton setHitTestEdgeInsets:UIEdgeInsetsMake(-10, -10, -10, -6)];
    [cell setTagsToIndex:indexPath.row];
    NSArray *targetArray = (tableView != self.tableView) ? self.filteredFeeds : self.feeds;
    DHFeed *feed = targetArray[indexPath.row];
    cell.feed = feed;
    
    cell.titleLabel.opaque = NO;
    
    //cell.checkmark.image = [cell.checkmark.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.titleLabel.backgroundColor = [UIColor clearColor];
    cell.platform.image = feed.icon;
    [feed prepareCell:cell];
    cell.titleLabel.maxRightDetailWidth = feed.maxRightDetailWidth;
    cell.titleLabel.rightDetailText = feed.detailString;
    [self setSizeLabelForCell:cell];
    [self setTitle:[feed docsetNameWithVersion:!feed.installing] forCell:cell];
    
    // Group of actions which can be performed on any given cell feed
    [cell.progressView.stopButton addTarget:self action:@selector(stopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.errorButton addTarget:self action:@selector(errorButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.downloadButton addTarget:self action:@selector(downloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.uninstallButton addTarget:self action:@selector(uninstallButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

/** DmytriE: 2018-07-16: Sets the size of the label which holds the DocSet title
 *  @param cell: A cell in the DocSet Repo download table
 *  @return NONE
 */
- (void)setSizeLabelForCell:(DHRepoTableViewCell *)cell
{
    if(!isRegularHorizontalClass)
    {
        return;
    }
    if(cell.feed.installed && !cell.feed.installing && cell.feed.size && cell.feed.size.length)
    {
        NSString *label = [cell.feed.size stringByAppendingString:@""];
        cell.titleLabel.maxRightDetailWidth = [DHRightDetailLabel calculateMaxDetailWidthBasedOnLongestPossibleString:label];
        [cell.titleLabel setRightDetailText:label];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(DHRepoTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.feed.cell = nil;
    cell.feed = nil;
}

/** DmytriE: 2018-07-16: Highlights the text which matches the search query.
 *  @param  cell: The current cell being evaluated
 *  @return NONE
 */

/*
 * TODO: Determine why the search query "Ba" is returning "Xojo" when neither
 * of the characters are found there.
 */
- (void)highlightCell:(DHRepoTableViewCell *)cell
{
    NSRange range;
    NSInteger offset = 0;
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:cell.titleLabel.attributedText];
    NSString *substring = [[string string] copy];
    BOOL didAddAttributes = NO;
    
    // Iterate through the characters in the string and highlight those characters which
    // match the search query.
    while((range = [substring rangeOfString:self.filterQuery options:NSCaseInsensitiveSearch]).location != NSNotFound)
    {
        [string addAttributes:[DHDBResult highlightDictionary] range:NSMakeRange(range.location+offset, range.length)];
        substring = [substring substringFromDashIndex:range.location+range.length];
        offset += range.location+range.length;
        didAddAttributes = YES;
    }
    if(didAddAttributes)
    {
        cell.titleLabel.attributedText = string;
    }
}

/** DmytriE 2018-07-16:
 *  @param  tableView
 *  @return
 */
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if(self.searchBarActive || (self.searchBarActiveIsALie && !self.searchBarActive))
    {
        return nil;
    }
    return [self.feeds characterIndexTitles];
}

/** DmytriE 2018-07-17:
 *  @param  tableView: The current table view
 *  @param  title: Title of the documentation set
 *  @param  aIndex:
 *  @return Index of the first character match with the title
 */
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)aIndex
{
    NSInteger index = [self.feeds indexOfFirstObjectThatStartsWithCharacter:title];
    if(index != 0)
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    return index;
}

/** DmytriE 2018-07-17:
 *  @param  controller:
 *  @param  tableView: A view of all the
 *  @return NONE
 */
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [controller.searchResultsTableView registerNib:[UINib nibWithNibName:@"DHRepoCell" bundle:nil] forCellReuseIdentifier:@"DHRepoCell"];
    tableView.allowsSelection = NO;
}

/** DmytriE 2018-07-17: Begin searching by displaying search bar
 *  @param  controller: Current view controller
 *  @return NONE
 */
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    controller.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchController = controller;
    self.searchBarActive = YES;
    [self.tableView reloadSectionIndexTitles];
}

/** DmytriE 2018-07-17: Hide the repo search bar
 *  @param  controller: Current view controller
 *  @return NONE
 */
- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    self.searchBarActive = NO;
    [self reload];
}

/** DmytriE 2018-07-17: Reloads the docsets which match the query
 *  @param  controller: Current view controller
 *  @param  searchString: Search query string
 *  @return Truthy boolean indicating docset feed was filtered
 */
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterFeedsWithQuery:searchString];
    return YES;
}

/** DmytriE 2018-07-17: Display the search bar for the user to enter their query.
 *  @param  controller: Current view controller
 *  @param  tableView: View associated with the table.
 */
- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    if(!self.searchBarActive)
    {
        return;
    }
    self.searchBarActive = NO;
    self.searchBarActiveIsALie = YES;
    [self reload];
    self.searchBarActiveIsALie = NO;
    self.searchBarActive = YES;
}

- (void)reload
{
    [self.tableView reloadData];
}

/** DmytriE 2018-07-17: Set the search bar boolean value to false.
 *  @param  controller: Current view controller
 *  @return NONE
 */
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.searchBarActive = NO;
}

/** DmytriE 2018-07-16:
 *  @param  query: Text entered into search box
 *  @return NONE
 */
- (void)filterFeedsWithQuery:(NSString *)query
{
    self.filterQuery = query;
    self.filteredFeeds = [NSMutableArray array];
    NSMutableArray *aliasMatches = [NSMutableArray array];
    for(DHFeed *feed in self.feeds)
    {
        if([[feed docsetNameWithVersion:!feed.installing] contains:query])
        {
            [self.filteredFeeds addObject:feed];
        }
        else
        {
            /* DmytriE 2018-07-16: Iterate through the list of aliases for a given
             * docset.  If the query matches the aliases then it adds the feed to
             * the filtered feeds list.  The list of aliases are found in DashDocset-
             * Downloader.m
             *
             * TODO: Do we want to add DocSets based on aliases that are not
             * visible to the user?  It confused me when I did the "ba" search.
             * Add "subtitle" notice indicating it was selected from its alias.
             */
            for(NSString *alias in feed.aliases)
            {
                if([alias contains:query])
                {
                    [aliasMatches addObject:feed];
                    break;
                }
            }
        }
    }
    [self.filteredFeeds sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *myName = [obj1 docsetNameWithVersion:![obj1 installing]];
        NSString *theirName = [obj2 docsetNameWithVersion:![obj2 installing]];
        NSRange myMatch = [myName rangeOfString:query options:NSCaseInsensitiveSearch];
        NSRange theirMatch = [theirName rangeOfString:query options:NSCaseInsensitiveSearch];
        if(myMatch.location < theirMatch.location)
        {
            return NSOrderedAscending;
        }
        else if(myMatch.location > theirMatch.location)
        {
            return NSOrderedDescending;
        }
        else
        {
            return [[obj1 sortName] localizedCaseInsensitiveCompare:[obj2 sortName]];
        }
    }];
    [self.filteredFeeds addObjectsFromArray:aliasMatches];
}

/** DmytriE: 2018-07-16:
 *  @param  title: Name of the Documentation Set
 *  @param  cell: The cell which will be updated.
 *  @return NONE
 */
- (void)setTitle:(NSString *)title forCell:(DHRepoTableViewCell *)cell
{
    cell.titleLabel.text = title;
    if(self.searchBarActive && self.filterQuery.length)
    {
        [self highlightCell:cell];
    }
}

- (void)feedWillInstall:(DHFeed *)feed
{
    
}

/** DmytriE 2018-07-17:
 *  @param feed: Documentation set
 *  @param isAnUpdate: Using the isAnUpdate variable determines whether to
 *  download a new DocSet or retrieve the DocSet changes.
 *  @return NONE
 */
- (void)startInstallingFeed:(DHFeed *)feed isAnUpdate:(BOOL)isAnUpdate
{
    [self showDownloadProgressViewForFeed:feed];
    feed.progress = 0.0;
    feed.progressShown = YES;
    feed.installing = YES;
    feed.checkingForUpdates = NO;
    feed.error = nil;
    [self setTitle:[feed docsetNameWithVersion:NO] forCell:feed.cell];
    [self feedWillInstall:feed];
    dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:0.2f]; // without this there's a display glitch when internet is off and instant error is shown
        NSString *result = [self installFeed:feed isAnUpdate:isAnUpdate];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(!feed.installing || [result isEqualToString:@"cancelled"])
            {
                return; // user cancelled install
            }
            

            feed.installing = NO;
            NSString *version = feed.feedResult.version;
            feed.feedResult = nil;
            feed.progress = 0.0;
            if(!result)
            {
                feed.installed = YES;
                feed.installedVersion = version;
                [self saveState];
                [self setTitle:[feed docsetNameWithVersion:YES] forCell:feed.cell];
                [self showUninstallButtonForFeed:feed];
                [self setSizeLabelForCell:feed.cell];
                [feed adjustTitleLabelWidthBasedOnButtonsShown];
                DHDocset *docset = [DHDocset firstDocsetInsideFolder:[self docsetPathForFeed:feed]];
                docset.repoIdentifier = [self repoIdentifier];
                docset.feedIdentifier = [feed uniqueIdentifier];
                [[DHDocsetManager sharedManager] addDocset:docset andRemoveOthers:YES removeOnlyEqualPaths:[self isKindOfClass:[DHDocsetTransferrer class]]];
            }
            else if(isAnUpdate)
            {
                [self setTitle:[feed docsetNameWithVersion:YES] forCell:feed.cell];
                [self showUninstallButtonForFeed:feed];
                [feed adjustTitleLabelWidthBasedOnButtonsShown];
            }
            else
            {
                feed.error = result;
                [self showErrorButtonForFeed:feed];
                [self showDownloadButtonForFeed:feed];
                [feed adjustTitleLabelWidthBasedOnButtonsShown];
            }
        });
    });
}

- (NSString *)installFeed:(DHFeed *)feed isAnUpdate:(BOOL)isAnUpdate
{
    NSLog(@"installFeed: not implemented for %@", NSStringFromClass([self class]));
    return nil;
}

- (BOOL)canInstallFeed:(DHFeed *)feed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"DHRepoCell" bundle:nil] forCellReuseIdentifier:@"DHRepoCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self traitCollectionDidChange:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(previousTraitCollection)
    {
        [super traitCollectionDidChange:previousTraitCollection];
    }
    if(isRegularHorizontalClass)
    {
        [self.navigationItem setHidesBackButton:YES animated:NO];
    }
    else
    {
        [self.navigationItem setHidesBackButton:NO animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [[DHLatencyTester sharedLatency] performTests:NO];
    [self traitCollectionDidChange:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    if(self.searchController.isActive)
    {
        [self.searchController setActive:NO animated:YES];
    }
}

- (NSString *)docsetInstallFolderName
{
    NSLog(@"docsetInstallFolderName not implemented for %@", NSStringFromClass([self class]));
    return @"Unknown";
}

- (NSString *)repoIdentifier // Used to find a corresponding repo for a installed docset
{
    return [self docsetInstallFolderName];
}

- (NSString *)docsetInstallFolderPath
{
    return [[homePath stringByAppendingPathComponent:@"Docsets"] stringByAppendingPathComponent:[self docsetInstallFolderName]];
}

- (NSString *)docsetPathForFeed:(DHFeed *)feed
{
    NSString *filename = [[feed.feed lastPathComponent] stringByDeletingPathExtension];
    return [[self docsetInstallFolderPath] stringByAppendingPathComponent:filename];
}

- (NSString *)defaultsKey
{
    return NSStringFromClass([self class]);
}

- (NSString *)defaultsScheduledUpdateKey
{
    return [[self defaultsKey] stringByAppendingString:@"ScheduledUpdate"];
}

- (NSString *)defaultsScheduledDocsetListUpdateKey
{
    return [[self defaultsKey] stringByAppendingString:@"ScheduledUpdateDocsetList"];
}

- (NSString *)defaultsAutomaticallyCheckForUpdatesKey
{
    return @"AutomaticallyCheckForUpdates";
}

- (NSString *)defaultsUpdateLastCheckDateKey
{
    return [[self defaultsKey] stringByAppendingString:@"LastUpdateCheck"];
}

/** DmytriE:
 *  @param: NONE
 *  @return: Path to the recycle bin is the DocSet Install Path with ".Trash"
 *  appended to the end of the docSet installation path.  Following folder
 *  structure:
 *  /docset/Angular         (Contains docset data)
 *  /docset/Angular.Trash   (Uninstalled docset ready for deletion).
 */
- (NSString *)trashPath
{
    return [[self docsetInstallFolderPath] stringByAppendingPathComponent:@".Trash"];
}

/** DmytriE 2018-07-19:
 *  @param NONE
 *  @return path the the recycle bin.
 */
- (NSString *)uniqueTrashPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *trash = [self trashPath];
    [fileManager createDirectoryAtPath:trash withIntermediateDirectories:YES attributes:nil error:nil];
    for(int i = 0; i < 500; i++)
    {
        NSString *random = [trash stringByAppendingPathComponent:[NSString randomStringWithLength:8]];
        if(![fileManager fileExistsAtPath:random])
        {
            return random;
        }
    }
    return [trash stringByAppendingPathComponent:[NSString randomStringWithLength:8]];
}

- (NSString *)uniqueTempDirAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(int i = 0; i < 100; i++)
    {
        NSString *random = [path stringByAppendingPathComponent:[@"dash_temp_" stringByAppendingString:[NSString randomStringWithLength:8]]];
        if(![fileManager fileExistsAtPath:random])
        {
            return random;
        }
    }
    return [path stringByAppendingPathComponent:[@"dash_temp_" stringByAppendingString:[NSString randomStringWithLength:8]]];
}

- (void)saveState
{
    NSMutableArray *feeds = [NSMutableArray array];
    for(DHFeed *feed in self.feeds)
    {
        [feeds addObject:[feed dictionaryRepresentation]];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:feeds forKey:[self defaultsKey]];
}

- (BOOL)shouldStall
{
    return [self numberOfEntriesBeingInstalled] > 2;
}

- (NSInteger)numberOfEntriesBeingInstalled
{
    NSInteger count = 0;
    for(DHFeed *feed in self.feeds)
    {
        if(feed.installing && !feed.waiting)
        {
            ++count;
        }
    }
    return count;
}

- (NSInteger)indexOfFeedWithFeedURL:(NSString *)feedURL
{
    NSInteger i = 0;
    for(DHFeed *feed in self.feeds)
    {
        if([feed.feedURL isEqualToString:feedURL])
        {
            return i;
        }
        ++i;
    }
    return NSNotFound;
}

@end

NSInteger compareFeeds(id feed1, id feed2, void *context)
{
    NSString *myName = [feed1 sortName];
    NSString *theirName = [feed2 sortName];
    return [myName localizedCaseInsensitiveCompare:theirName];
}
