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

#import "DHDBSearchController.h"
#import "DHBrowserTableViewCell.h"
#import "DHDBResult.h"
#import "DHDocsetManager.h"
#import "DHDocsetBrowser.h"
#import "DHNestedViewController.h"

@implementation DHDBSearchController

+ (DHDBSearchController *)searchControllerWithDocsets:(NSArray *)docsets typeLimit:(NSString *)typeLimit viewController:(UIViewController *)viewController;
{
    DHDBSearchController *controller = [[DHDBSearchController alloc] init];
    controller.docsets = docsets;
    controller.typeLimit = typeLimit;
    controller.viewController = viewController;
    controller.displayController = viewController.searchDisplayController;
    controller.displayController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [controller hookToSearchDisplayController:viewController.searchDisplayController];
    [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(traitCollectionDidChange:) name:DHWindowChangedTraitCollection object:nil];
    return controller;
}

- (void)viewWillAppear
{
    if(self.displayController.active)
    {
        
    }
}

- (void)viewDidAppear
{
    if(self.displayController.active)
    {

    }
}

- (void)viewWillDisappear
{
    if(self.displayController.active)
    {
    
    }
}

- (void)viewDidDisappear
{
    if(self.displayController.active)
    {

    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(self.results.count && !self.loading)
    {
        [self.displayController.searchResultsTableView reloadData];
    }
}

- (void)hookToSearchDisplayController:(UISearchDisplayController *)displayController
{
    displayController.delegate = self;
    displayController.searchResultsDataSource = self;
    displayController.searchResultsDelegate = self;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    self.loading = YES;
    tableView.allowsSelection = NO;
    if(isIOS11)
    {
        if(@available(iOS 11.0, *))
        {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    [tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    [tableView registerNib:[UINib nibWithNibName:@"DHLoadingCell" bundle:nil] forCellReuseIdentifier:@"DHLoadingCell"];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    if([self.viewController respondsToSelector:@selector(searchDisplayControllerWillBeginSearch:)])
    {
        [(id)self.viewController searchDisplayControllerWillBeginSearch:controller];
    }
    self.loading = YES;
    self.displayController.searchResultsTableView.allowsSelection = NO;
    [self.displayController.searchResultsTableView reloadData];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    if([self.viewController respondsToSelector:@selector(searchDisplayControllerDidBeginSearch:)])
    {
        [(id)self.viewController searchDisplayControllerDidBeginSearch:controller];
    }
    self.viewControllerTitle = self.viewController.navigationItem.title;
    self.viewController.navigationItem.title = @"Search";
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    if([self.viewController respondsToSelector:@selector(searchDisplayControllerWillEndSearch:)])
    {
        [(id)self.viewController searchDisplayControllerWillEndSearch:controller];
    }
    self.viewController.navigationItem.title = self.viewControllerTitle;
    [self.searcher cancelSearch];
    self.searcher = nil;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    if([self.viewController respondsToSelector:@selector(searchDisplayControllerDidEndSearch:)])
    {
        [(id)self.viewController searchDisplayControllerDidEndSearch:controller];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if(self.isRestoring)
    {
        self.displayController.searchResultsTableView.allowsSelection = YES;
        self.loading = NO;
        return YES;
    }
    [self.searcher cancelSearch];
    self.nextResults = [NSMutableArray array];
    BOOL wasEmpty = searchString.length <= 0;
    searchString = [searchString stringByRemovingWhitespaces];
    if(searchString.length)
    {
        self.searcher = [DHDBSearcher searcherWithDocsets:(self.docsets) ? self.docsets : [(id)self.viewController shownDocsets] query:searchString limitToType:self.typeLimit delegate:self];
    }
    else
    {
        self.results = [NSMutableArray array];
        if(wasEmpty)
        {
            self.loading = YES;
            self.displayController.searchResultsTableView.allowsSelection = NO;
        }
        else
        {
            self.loading = NO;
            self.displayController.searchResultsTableView.allowsSelection = YES;
        }
        return YES;
    }
    return NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    if([self.viewController isKindOfClass:[UITableViewController class]])
    {
        [(UITableViewController*)self.viewController tableView].separatorStyle = UITableViewCellSeparatorStyleNone;
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    if([self.viewController isKindOfClass:[UITableViewController class]])
    {
        [(UITableViewController*)self.viewController tableView].separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    [self.searcher cancelSearch];
    self.searcher = nil;
}

- (void)searcher:(DHDBSearcher *)searcher foundResults:(NSArray *)results hasMore:(BOOL)hasMore
{
    if(searcher == self.searcher)
    {
        NSInteger previousSelection = self.displayController.searchResultsTableView.indexPathForSelectedRow.row;
        BOOL isFirst = self.nextResults.count == 0;
        self.loading = NO;
        self.displayController.searchResultsTableView.allowsSelection = YES;
        [self.nextResults addObjectsFromArray:results];
        self.results = self.nextResults;
        [self.displayController.searchResultsTableView reloadData];
        if(isFirst && isRegularHorizontalClass && self.nextResults.count)
        {
            [self.displayController.searchResultsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
            DHDBResult *firstResult = self.results[0];
            [[DHDBResultSorter sharedSorter] resultWasSelected:firstResult inTableView:self.displayController.searchResultsTableView];
            [[DHWebViewController sharedWebViewController] loadResult:firstResult];
        }
        else if(isRegularHorizontalClass && !isFirst && self.results.count)
        {
            [self.displayController.searchResultsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:previousSelection inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        if(!hasMore)
        {
            self.nextResults = nil;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"DHNestedSegue"])
    {
        DHNestedViewController *nestedController = [segue destinationViewController];
        DHDBResult *result = self.results[self.displayController.searchResultsTableView.indexPathForSelectedRow.row];
        nestedController.result = result;
    }
    else if([[segue identifier] isEqualToString:@"DHSearchWebViewSegue"])
    {
        DHWebViewController *webViewController = [segue destinationViewController];
        DHDBResult *result = self.results[self.displayController.searchResultsTableView.indexPathForSelectedRow.row];
        webViewController.result = result;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.indexPathForSelectedRow.row < self.results.count)
    {
        DHDBResult *result = self.results[tableView.indexPathForSelectedRow.row];
        if(result.similarResults.count)
        {
            if(isRegularHorizontalClass)
            {
                [[DHWebViewController sharedWebViewController] loadResult:[result activeResult]];
            }
            [self.viewController performSegueWithIdentifier:@"DHNestedSegue" sender:self];
        }
        else
        {
            [[DHDBResultSorter sharedSorter] resultWasSelected:result inTableView:tableView];
            if(isRegularHorizontalClass)
            {
                [[DHWebViewController sharedWebViewController] loadResult:result];
            }
            else
            {
                [[DHWebViewController sharedWebViewController] loadResult:result];
                [self.viewController performSegueWithIdentifier:@"DHSearchWebViewSegue" sender:self];
            }
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.loading)
    {
        return 3;
    }
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.loading)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DHLoadingCell" forIndexPath:indexPath];
        cell.userInteractionEnabled = NO;
        if(indexPath.row == 2)
        {
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            [paragraph setAlignment:NSTextAlignmentCenter];
            UIFont *font = [UIFont boldSystemFontOfSize:20];
            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Searching..." attributes:@{NSParagraphStyleAttributeName : paragraph, NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8 alpha:1], NSFontAttributeName: font}];
        }
        else
        {
            cell.textLabel.text = @"";
        }
        return cell;
    }
    DHBrowserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DHBrowserCell" forIndexPath:indexPath];

    DHDBResult *result = (indexPath.row) < self.results.count ? self.results[indexPath.row] : nil;
    [cell makeEntryCell];
    cell.textLabel.attributedText = nil;
    cell.textLabel.font = [UIFont fontWithName:@"Menlo" size:16];
    cell.textLabel.text = result.name;
    cell.typeImageView.image = result.typeImage;
    cell.platformImageView.image = result.platformImage;
    [self highlightCell:cell result:result];
    [cell.titleLabel setRightDetailText:(result.similarResults.count) ? [NSString stringWithFormat:@"%ld", (unsigned long)result.similarResults.count+1] : @"" adjustMainWidth:YES];
    cell.accessoryType = (result.similarResults.count || !isRegularHorizontalClass) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

- (void)highlightCell:(DHBrowserTableViewCell *)cell result:(DHDBResult *)result
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:cell.textLabel.attributedText];
    BOOL didAddAttributes = NO;
    for(NSString *key in [DHDBResult highlightDictionary])
    {
        [string removeAttribute:key range:NSMakeRange(0, string.length)];
    }
    for(NSValue *highlightRangeValue in result.highlightRanges)
    {
        NSRange highlightRange = [highlightRangeValue rangeValue];
        [string addAttributes:[DHDBResult highlightDictionary] range:highlightRange];
        didAddAttributes = YES;
    }
    if(didAddAttributes)
    {
        cell.textLabel.attributedText = string;
    }
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.displayController.isActive forKey:@"searchIsActive"];
    if(self.displayController.isActive)
    {
        [coder encodeObject:[self.displayController.searchBar text] forKey:@"searchBarText"];
        if(self.results)
        {
            [coder encodeObject:self.results forKey:@"searchResults"];
        }
        NSIndexPath *selectedIndexPath = [self.displayController.searchResultsTableView indexPathForSelectedRow];
        if(selectedIndexPath)
        {
            [coder encodeObject:selectedIndexPath forKey:@"selectedIndexPath"];
        }
        BOOL isFirstResponder = [self.displayController.searchBar isFirstResponder];
        [coder encodeBool:isFirstResponder forKey:@"isFirstResponder"];
        [coder encodeCGPoint:self.displayController.searchResultsTableView.contentOffset forKey:@"scrollPoint"];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    BOOL isActive = [coder decodeBoolForKey:@"searchIsActive"];
    if(isActive)
    {
        self.isRestoring = YES;
        self.results = [coder decodeObjectForKey:@"searchResults"];
        NSString *searchBarText = [coder decodeObjectForKey:@"searchBarText"];
        NSIndexPath *selectedIndexPath = [coder decodeObjectForKey:@"selectedIndexPath"];
        BOOL isFirstResponder = [coder decodeBoolForKey:@"isFirstResponder"];
        CGPoint scrollPoint = [coder decodeCGPointForKey:@"scrollPoint"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((isRegularHorizontalClass) ? 0.5 * NSEC_PER_SEC : 0)), dispatch_get_main_queue(), ^{
            [self.displayController setActive:YES animated:isRegularHorizontalClass];
            if(searchBarText)
            {
                [self.displayController.searchBar setText:searchBarText];
            }
            if(selectedIndexPath)
            {
                [self.displayController.searchResultsTableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
            if(isFirstResponder)
            {
                [self.displayController.searchBar becomeFirstResponder];
            }
            self.displayController.searchResultsTableView.contentOffset = scrollPoint;
            self.isRestoring = NO;
        });
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.searcher cancelSearch];
}

@end
