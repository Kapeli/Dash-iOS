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

#import "DHDocsetTransferrer.h"
#import "DHAppDelegate.h"
#import "DHTransferFeed.h"

@implementation DHDocsetTransferrer

static id singleton = nil;

- (void)setUp // doesn't get called unless you call the singleton from DHAppDelegate
{
    [super setUp];
}

- (void)feedWillInstall:(DHTransferFeed *)feed
{
    feed.feedResult = [[DHFeedResult alloc] init];
    feed.feedResult.feed = feed;
    NSString *sourcePath = [transfersPath stringByAppendingPathComponent:feed.feed];
    @synchronized([DHDocsetTransferrer class])
    {
        feed.feedURL = [self docsetPathForFeed:feed];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:feed.feedURL])
        {
            NSString *trashPath = [self uniqueTrashPath];
            [fileManager moveItemAtPath:feed.feedURL toPath:trashPath error:nil];
            dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
            dispatch_async(queue, ^{
                [[NSFileManager defaultManager] removeItemAtPath:trashPath error:nil];
            });
        }
        [fileManager createDirectoryAtPath:feed.feedURL.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager moveItemAtPath:sourcePath toPath:feed.feedURL error:nil];
        feed.docset = nil;
        [feed loadDocset];
    }
}

- (NSString *)installFeed:(DHTransferFeed *)feed isAnUpdate:(BOOL)isAnUpdate
{
    DHFeedResult *result = feed.feedResult;
    DHDocset *docset = feed.docset;
    if(!result || result.isCancelled)
    {
        return @"cancelled";
    }
    if(!docset || !docset.optimisedIndexPath)
    {
        return @"Couldn't load docset. Either iTunes did not finish transferring it or the docset is corrupt.";
    }
    CGFloat maxWidth = [DHRightDetailLabel calculateMaxDetailWidthBasedOnLongestPossibleString:@"Indexing..."];
    [feed setMaxRightDetailWidth:maxWidth];
    [[[feed cell] titleLabel] setMaxRightDetailWidth:maxWidth];
    NSString *tempPath = [docset.optimisedIndexPath stringByAppendingString:@"_temp"];
    docset.tempOptimisedIndexPath = tempPath;
    [feed.feedResult setRightDetail:@"Waiting..."];
    @synchronized([DHDocsetIndexer class])
    {
        [DHDocsetIndexer indexerForDocset:docset delegate:feed.feedResult];
    }
    if(result.isCancelled)
    {
        return @"cancelled";
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtPath:tempPath toPath:docset.optimisedIndexPath error:nil];
    feed.docset.tempOptimisedIndexPath = nil;
    return nil;
}

- (void)feedWasStopped:(DHTransferFeed *)feed
{
    @synchronized([DHDocsetTransferrer class])
    {
        [feed cancelInstall];
    }
}

- (void)feedDidUninstall:(DHTransferFeed *)feed
{
    NSInteger row = [self.feeds indexOfObjectIdenticalTo:feed];
    if(row != NSNotFound)
    {
        [self.feeds removeObjectAtIndex:row];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        for(NSInteger i = row; i < self.feeds.count; i++)
        {
            DHTransferFeed *nextFeed = self.feeds[i];
            [nextFeed.cell setTagsToIndex:i];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(!self.feeds.count)
            {
                [self reload];
            }
        });
    }
    else
    {
        [self refreshFeeds:nil];
    }
}

- (IBAction)refreshFeeds:(id)sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *waitingPath = transfersPath;
    NSArray *waiting = [fileManager contentsOfDirectoryAtPath:waitingPath error:nil];
    self.loadedFeedsHash = [waiting componentsJoinedByString:@"xx"];
    NSMutableArray *newFeeds = [NSMutableArray array];
    for(NSString *docset in waiting)
    {
        if([docset hasCaseInsensitiveSuffix:@".docset"])
        {
            DHTransferFeed *feed = [DHTransferFeed feedWithPath:[waitingPath stringByAppendingPathComponent:docset] isInstalled:NO];
            [newFeeds addObject:feed];
        }
    }
    NSString *installedPath = [self docsetInstallFolderPath];
    for(NSString *docset in [fileManager contentsOfDirectoryAtPath:installedPath error:nil])
    {
        if([docset hasCaseInsensitiveSuffix:@".docset"])
        {
            DHTransferFeed *feed = [DHTransferFeed feedWithPath:[installedPath stringByAppendingPathComponent:docset] isInstalled:YES];
            if(![newFeeds containsObject:feed])
            {
                if(!self.feeds && ![feed isProperlyInstalled])
                {
                    [feed cancelInstall];
                }
                [newFeeds addObject:feed];
            }
        }
    }
    if(!self.feeds)
    {
        self.feeds = [NSMutableArray array];
    }
    NSMutableArray *oldFeeds = [NSMutableArray arrayWithArray:self.feeds];
    @synchronized([DHDocsetTransferrer class])
    {
        for(DHTransferFeed *newFeed in newFeeds)
        {
            NSInteger index = [oldFeeds indexOfObject:newFeed];
            if(index != NSNotFound)
            {
                DHTransferFeed *feed = oldFeeds[index];
                if((feed.installed || feed.installing) && !newFeed.installed)
                {
                    if(feed.installing)
                    {
                        [feed cancelInstall];
                    }
                    if(!newFeed.docset)
                    {
                        [newFeed loadDocset];
                    }
                    oldFeeds[index] = newFeed;
                }
                else
                {
                    [oldFeeds[index] refreshIcon];
                }
            }
            else
            {
                if(!newFeed.docset)
                {
                    [newFeed loadDocset];
                }
                [oldFeeds addObject:newFeed];
            }
        }
        for(DHTransferFeed *feed in [NSMutableArray arrayWithArray:oldFeeds])
        {
            if(![newFeeds containsObject:feed])
            {
                [oldFeeds removeObjectIdenticalTo:feed];
            }
        }
    }
    [oldFeeds sortUsingFunction:compareFeeds context:nil];
    self.feeds = oldFeeds;
    [self reload];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Transfer Docsets";
    return [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0], NSForegroundColorAttributeName: [UIColor colorWithWhite:201.0/255.0 alpha:1.0]}];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"You can transfer docsets using iTunes File Sharing or AirDrop.\n\nFor best results, docsets that are available for download should always be downloaded instead of transferred.";
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.lineSpacing = 4.0;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:13.0], NSForegroundColorAttributeName: [UIColor colorWithWhite:207.0/255.0 alpha:1.0], NSParagraphStyleAttributeName: paragraph};
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"placeholder_transfer"];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSString *text = @"Open Help";
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0], NSForegroundColorAttributeName: [[DHAppDelegate sharedDelegate].window.rootViewController.view.tintColor colorWithAlphaComponent:state == UIControlStateNormal ? 0.7 : 0.2]};
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return NO;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView
{
    return 24;
}

- (void)emptyDataSetWillAppear:(UIScrollView *)scrollView
{
    [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top)];
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://kapeli.com/dash_itunes_file_sharing"]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.ignoreReload = YES;
    [self poll];
    self.ignoreReload = NO;
    if(self.feeds.count)
    {
        [self reload];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationChanged:(id)sender
{
    [self.tableView reloadEmptyDataSet];
}

- (void)poll
{
    ++self.pollCounter;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(!self.loadedFeedsHash || ![[[fileManager contentsOfDirectoryAtPath:transfersPath error:nil] componentsJoinedByString:@"xx"] isEqualToString:self.loadedFeedsHash])
    {
        [self refreshFeeds:nil];
    }
    else
    {
        if(self.pollCounter % 3 == 0)
        {
            BOOL shouldReload = NO;
            for(DHTransferFeed *feed in self.feeds)
            {
                if(!feed.docset && [feed loadDocset])
                {
                    shouldReload = YES;
                }
                else if(feed.docset)
                {
                    shouldReload |= [feed refreshIcon];
                }
            }
            if(shouldReload)
            {
                [self.feeds sortUsingFunction:compareFeeds context:nil];
                [self reload];
            }
            self.pollCounter = 0;
        }
    }
}

- (void)reload
{
    if(self.ignoreReload)
    {
        return;
    }
    NSInteger count = [self tableView:self.tableView numberOfRowsInSection:0];
    self.tableView.tableFooterView = (count) ? nil : [UIView new];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPollTimer) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startPollTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self poll];
    [self startPollTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [super viewWillDisappear:animated];
    [self stopPollTimer];
    self.pollTimer = [self.pollTimer invalidateTimer];
}

- (void)startPollTimer
{
    [self stopPollTimer];
    self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(poll) userInfo:nil repeats:YES];
}

- (void)stopPollTimer
{
    self.pollTimer = [self.pollTimer invalidateTimer];
}

- (NSString *)docsetInstallFolderName
{
    return @"Transfers";
}

- (NSString *)docsetPathForFeed:(DHFeed *)feed
{
    return [[self docsetInstallFolderPath] stringByAppendingPathComponent:feed.feed];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHRepoTableViewCell *cell = (id)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell.downloadButton setImage:[UIImage imageNamed:@"transfer_button"] forState:UIControlStateNormal];
    [cell.downloadButton setBackgroundImage:nil forState:UIControlStateNormal];
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

- (IBAction)errorButtonPressed:(id)sender
{
    NSUInteger row = [sender tag];
    DHFeed *feed = [self activeFeeds][row];
    [[[UIAlertView alloc] initWithTitle:@"Docset Install Failed" message:feed.error delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

+ (instancetype)sharedTransferrer
{
    if(singleton)
    {
        return singleton;
    }
    id transferrer = [[DHAppDelegate mainStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    [transferrer setUp];
    return transferrer;
}

+ (id)alloc
{
    if(singleton)
    {
        return singleton;
    }
    return [super alloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(singleton)
    {
        return singleton;
    }
    self = [super initWithCoder:aDecoder];
    singleton = self;
    return self;
}


@end
