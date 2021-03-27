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
#import "Dash-Swift.h"

@interface DHDBSearchController()
@property (retain) KVOObserver *observer;
@end

@implementation DHDBSearchController

+ (DHDBSearchController *)searchControllerWithDocsets:(NSArray *)docsets typeLimit:(NSString *)typeLimit viewController:( UIViewController<SearchableController>*)viewController;
{
    DHDBSearchController *controller = [[DHDBSearchController alloc] init];
    controller.docsets = docsets;
    controller.typeLimit = typeLimit;
    controller.viewController = viewController;
    controller.searchController = viewController.searchController;
    controller.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    controller.searchController.searchBar.barTintColor = [UIColor colorWithRed:0.79 green:0.79 blue:0.81 alpha:1.00];
    controller.searchController.searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
    
    [controller hookToSearchController:viewController.searchController];
    [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(traitCollectionDidChange:) name:DHWindowChangedTraitCollection object:nil];
    return controller;
}

- (void)viewWillAppear
{
    if(self.searchController.active)
    {
        
    }
}

- (void)viewDidAppear
{
    if(self.searchController.active)
    {

    }
}

- (void)viewWillDisappear
{
    if(self.searchController.active)
    {
    
    }
}

- (void)viewDidDisappear
{
    if(self.searchController.active)
    {

    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(self.results.count && !self.loading)
    {
        [self.viewController.searchResultTableView reloadData];
    }
}

- (void)hookToSearchController:(UISearchController *)searchController {
    
    searchController.delegate = self;
    searchController.searchBar.delegate = self;
    searchController.searchResultsUpdater = self;
    self.viewController.searchResultTableView.delegate = self;
    self.viewController.searchResultTableView.dataSource = self;
    
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    self.loading = YES;
    UITableView *tableView = self.viewController.searchResultTableView;
    tableView.allowsSelection = NO;
    [tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    [tableView registerNib:[UINib nibWithNibName:@"DHLoadingCell" bundle:nil] forCellReuseIdentifier:@"DHLoadingCell"];
    if([self.viewController isKindOfClass:[UITableViewController class]])
    {
        [(UITableViewController*)self.viewController tableView].separatorStyle = UITableViewCellSeparatorStyleNone;
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    [self.searchController.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSClassFromString(@"_UISearchBarContainerView")]) {
            obj.backgroundColor = [UIColor colorWithRed:0.78 green:0.78 blue:0.81 alpha:1.00];
            *stop = YES;
        }
    }];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if([self.viewController respondsToSelector:@selector(searchBarTextDidBeginEditing:)])
    {
        [(id)self.viewController searchBarTextDidBeginEditing:searchBar];
    }
    self.loading = YES;
    self.viewController.searchResultTableView.allowsSelection = NO;
    [self.viewController.searchResultTableView reloadData];
    self.viewControllerTitle = self.viewController.navigationItem.title;
    self.viewController.navigationItem.title = @"Search";
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    if([self.viewController respondsToSelector:@selector(willDismissSearchController:)])
    {
        [(id)self.viewController willDismissSearchController:searchController];
    }
    self.viewController.navigationItem.title = self.viewControllerTitle;
    
    if([self.viewController isKindOfClass:[UITableViewController class]])
    {
        [(UITableViewController*)self.viewController tableView].separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    [self.searcher cancelSearch];
    self.searcher = nil;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if(self.isRestoring)
    {
        self.viewController.searchResultTableView.allowsSelection = YES;
        self.loading = NO;
        [self.viewController.searchResultTableView reloadData];
        return;
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
            self.viewController.searchResultTableView.allowsSelection = NO;
        }
        else
        {
            self.loading = NO;
            self.viewController.searchResultTableView.allowsSelection = YES;
        }
    }
}

//- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
//{
//    if(self.isRestoring)
//    {
//        self.viewController.searchResultTableView.allowsSelection = YES;
//        self.loading = NO;
//        return YES;
//    }
//    [self.searcher cancelSearch];
//    self.nextResults = [NSMutableArray array];
//    BOOL wasEmpty = searchString.length <= 0;
//    searchString = [searchString stringByRemovingWhitespaces];
//    if(searchString.length)
//    {
//        self.searcher = [DHDBSearcher searcherWithDocsets:(self.docsets) ? self.docsets : [(id)self.viewController shownDocsets] query:searchString limitToType:self.typeLimit delegate:self];
//    }
//    else
//    {
//        self.results = [NSMutableArray array];
//        if(wasEmpty)
//        {
//            self.loading = YES;
//            self.viewController.searchResultTableView.allowsSelection = NO;
//        }
//        else
//        {
//            self.loading = NO;
//            self.viewController.searchResultTableView.allowsSelection = YES;
//        }
//        return YES;
//    }
//    return NO;
//}

//- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
//{
//    if([self.viewController isKindOfClass:[UITableViewController class]])
//    {
//        [(UITableViewController*)self.viewController tableView].separatorStyle = UITableViewCellSeparatorStyleNone;
//    }
//}

//- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
//{
//    if([self.viewController isKindOfClass:[UITableViewController class]])
//    {
//        [(UITableViewController*)self.viewController tableView].separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//    }
//    [self.searcher cancelSearch];
//    self.searcher = nil;
//}

- (void)searcher:(DHDBSearcher *)searcher foundResults:(NSArray *)results hasMore:(BOOL)hasMore
{
    if(searcher == self.searcher)
    {
        NSInteger previousSelection = self.viewController.searchResultTableView.indexPathForSelectedRow.row;
        BOOL isFirst = self.nextResults.count == 0;
        self.loading = NO;
        self.viewController.searchResultTableView.allowsSelection = YES;
        [self.nextResults addObjectsFromArray:results];
        self.results = self.nextResults;
        [self.viewController.searchResultTableView reloadData];
        if(isFirst && isRegularHorizontalClass && self.nextResults.count)
        {
            [self.viewController.searchResultTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
            DHDBResult *firstResult = self.results[0];
            [[DHDBResultSorter sharedSorter] resultWasSelected:firstResult inTableView:self.viewController.searchResultTableView];
            [[DHWebViewController sharedWebViewController] loadResult:firstResult];
        }
        else if(isRegularHorizontalClass && !isFirst && self.results.count)
        {
            [self.viewController.searchResultTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:previousSelection inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
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
        DHDBResult *result = self.results[self.viewController.searchResultTableView.indexPathForSelectedRow.row];
        nestedController.result = result;
    }
    else if([[segue identifier] isEqualToString:@"DHSearchWebViewSegue"])
    {
        DHWebViewController *webViewController = [segue destinationViewController];
        DHDBResult *result = self.results[self.viewController.searchResultTableView.indexPathForSelectedRow.row];
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
    [coder encodeBool:self.searchController.isActive forKey:@"searchIsActive"];
    if(self.searchController.active)
    {
        [coder encodeObject:[self.searchController.searchBar text] forKey:@"searchBarText"];
        if(self.results)
        {
            [coder encodeObject:self.results forKey:@"searchResults"];
        }
        NSIndexPath *selectedIndexPath = [self.viewController.searchResultTableView indexPathForSelectedRow];
        if(selectedIndexPath)
        {
            [coder encodeObject:selectedIndexPath forKey:@"selectedIndexPath"];
        }
        BOOL isFirstResponder = [self.searchController.searchBar isFirstResponder];
        [coder encodeBool:isFirstResponder forKey:@"isFirstResponder"];
        [coder encodeCGPoint:self.viewController.searchResultTableView.contentOffset forKey:@"scrollPoint"];
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
            if (isRegularHorizontalClass) {
                self.searchController.active = YES;
            } else {
                [UIView performWithoutAnimation:^{
                    self.searchController.active = NO;
                }];
            }
            if(searchBarText)
            {
                [self.searchController.searchBar setText:searchBarText];
            }
            if(selectedIndexPath)
            {
                [self.viewController.searchResultTableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
            if(isFirstResponder)
            {
                [self.searchController.searchBar becomeFirstResponder];
            }
            self.viewController.searchResultTableView.contentOffset = scrollPoint;
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
