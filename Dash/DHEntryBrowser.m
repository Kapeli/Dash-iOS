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

#import "DHEntryBrowser.h"
#import "DHTypes.h"
#import "DHDBResult.h"
#import "DHDocsetManager.h"

@implementation DHEntryBrowser

- (void)viewDidLoad
{
    if(!self.docset)
    {
        // happens during state restoration
        return;
    }
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.searchController = [DHDBSearchController searchControllerWithDocsets:@[self.docset] typeLimit:self.type viewController:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForURLSearch:) name:DHPrepareForURLSearch object:nil];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"DHLoadingCell" bundle:nil] forCellReuseIdentifier:@"DHLoadingCell"];
    
    self.tableView.rowHeight = 44;

    if(self.isRestoring)
    {
        return;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(!self.didLoad && self.docset)
    {
        self.didLoad = YES;
        self.tableView.allowsSelection = NO;
        self.isLoading = YES;
        dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
        dispatch_async(queue, ^{
            [self.docset executeBlockWithinDocsetDBConnection:^(FMDatabase *db) {
                NSMutableSet *duplicates = [NSMutableSet set];
                NSMutableArray *entries = [NSMutableArray array];
                NSConditionLock *lock = [DHDocset stepLock];
                [lock lockWhenCondition:DHLockAllAllowed];
                FMResultSet *rs = [db executeQuery:@"SELECT path, name, type FROM searchIndex WHERE type = ? ORDER BY LOWER(name)", self.type];
                BOOL next = [rs next];
                [lock unlock];
                while(next)
                {
                    DHDBResult *result = [DHDBResult resultWithDocset:self.docset resultSet:rs];
                    if(result)
                    {
                        NSString *duplicateHash = [result browserDuplicateHash];
                        if(!duplicateHash || ![duplicates containsObject:duplicateHash])
                        {
                            if(duplicateHash)
                            {
                                [duplicates addObject:duplicateHash];
                            }
                            [entries addObject:result];
                        }
                    }
                    [lock lockWhenCondition:DHLockAllAllowed];
                    next = [rs next];
                    [lock unlock];
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.isLoading = NO;
                    self.isEmpty = entries.count <= 0;
                    if(!self.isEmpty)
                    {
                        self.tableView.allowsSelection = YES;
                    }
                    self.entries = entries;
                    [self.tableView reloadData];
                });
            } readOnly:YES lockCondition:DHLockAllAllowed optimisedIndex:YES];
        });
    }
    [self.tableView deselectAll:YES];
    [self.searchController viewWillAppear];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(previousTraitCollection)
    {
        [super traitCollectionDidChange:previousTraitCollection];
    }
    [self.tableView reloadData];
    [self.searchController traitCollectionDidChange:previousTraitCollection];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.searchController viewWillDisappear];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.searchController viewDidDisappear];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.searchController viewDidAppear];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.isLoading || self.isEmpty)
    {
        return 3;
    }
    NSInteger count = self.entries.count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHBrowserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(self.isLoading || self.isEmpty) ? @"DHLoadingCell" : @"DHBrowserCell" forIndexPath:indexPath];
    
    if((self.isLoading || self.isEmpty) && indexPath.row == 2)
    {
        cell.userInteractionEnabled = NO;
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraph setAlignment:NSTextAlignmentCenter];
        UIFont *font = [UIFont boldSystemFontOfSize:20];
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:(self.isEmpty) ? @"Nothing Here" : @"Loading..." attributes:@{NSParagraphStyleAttributeName : paragraph, NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8 alpha:1], NSFontAttributeName: font}];
    }
    else if(self.isLoading || self.isEmpty)
    {
        cell.userInteractionEnabled = NO;
        cell.textLabel.text = @"";
    }
    else
    {
        cell.userInteractionEnabled = YES;
        DHDBResult *entry = self.entries[indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:@"Menlo" size:16];
        cell.textLabel.text = entry.originalName;
        cell.imageView.image = [UIImage imageNamed:self.type];
        cell.accessoryType = (entry.similarResults.count || !isRegularHorizontalClass) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHDBResult *result = self.entries[indexPath.row];
    [[DHDBResultSorter sharedSorter] resultWasSelected:result inTableView:tableView];
    if(isRegularHorizontalClass)
    {
        [[DHWebViewController sharedWebViewController] loadResult:result];
    }
    else
    {
        [[DHWebViewController sharedWebViewController] loadResult:result];
        [self performSegueWithIdentifier:@"DHWebViewSegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"DHWebViewSegue"])
    {
        DHWebViewController *webViewController = [segue destinationViewController];
        DHDBResult *selectedEntry = self.entries[self.tableView.indexPathForSelectedRow.row];
        webViewController.result = selectedEntry;
    }
    else
    {
        [self.searchController prepareForSegue:segue sender:sender];
    }
}

- (void)prepareForURLSearch:(id)sender
{
    [self.searchDisplayController setActive:NO animated:NO];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.docset.relativePath forKey:@"docsetRelativePath"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.entries forKey:@"entries"];
    [self.searchController encodeRestorableStateWithCoder:coder];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *docsetRelativePath = [coder decodeObjectForKey:@"docsetRelativePath"];
    self.docset = [[DHDocsetManager sharedManager] docsetWithRelativePath:docsetRelativePath];
    self.type = [coder decodeObjectForKey:@"type"];
    self.title = [coder decodeObjectForKey:@"title"];
    self.isRestoring = YES;
    [self viewDidLoad];
    self.isRestoring = NO;
    self.entries = [coder decodeObjectForKey:@"entries"];
    [self.searchController decodeRestorableStateWithCoder:coder];
    [super decodeRestorableStateWithCoder:coder];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
