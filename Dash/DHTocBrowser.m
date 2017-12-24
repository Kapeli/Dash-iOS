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

#import "DHTocBrowser.h"
#import "DHBrowserTableViewCell.h"
#import "DHJavaScript.h"

#define DHHeaderSeparatorInset 14

@implementation DHTocBrowser

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForURLSearch:) name:DHPrepareForURLSearch object:nil];
    self.clearsSelectionOnViewWillAppear = NO;
    
    if(iPad && isRegularHorizontalClass)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    [self.tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, DHHeaderSeparatorInset, 0, 0);
    self.tableView.rowHeight = 44;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(previousTraitCollection)
    {
        [super traitCollectionDidChange:previousTraitCollection];
    }
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.activeSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [self.activeSections[section] count];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHBrowserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DHBrowserCell" forIndexPath:indexPath];
    @try {
        NSDictionary *entry = self.activeSections[indexPath.section][indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:@"Menlo" size:16];
        cell.textLabel.text = entry[@"name"];
        cell.imageView.image = [UIImage imageNamed:entry[@"entryType"]];;
        cell.accessoryType = (!iPad || !isRegularHorizontalClass) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        [self highlightCell:cell];
    }
    @catch(NSException *exception) { NSLog(@"%@ %@", exception, [exception callStackSymbols]); }
    return cell;
}

- (void)highlightCell:(DHBrowserTableViewCell *)cell
{
    if(!self.searchController.active)
    {
        return;
    }
    NSRange range;
    NSInteger offset = 0;
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:cell.titleLabel.attributedText];
    for(NSString *key in [DHDBResult highlightDictionary])
    {
        [string removeAttribute:key range:NSMakeRange(0, string.length)];
    }
    NSString *substring = [[string string] copy];
    BOOL didAddAttributes = NO;
    while((range = [substring rangeOfString:self.searchController.searchBar.text options:NSCaseInsensitiveSearch]).location != NSNotFound)
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *entry = self.activeSections[indexPath.section][indexPath.row];
    NSString *hash = [entry[@"path"] stringByReplacingPercentEscapes];
    
    DHWebViewController *webViewController = [DHWebViewController sharedWebViewController];
    webViewController.nextAnchorChangeNotCausedByUserNavigation = YES;
    webViewController.anchorChangeInProgress = YES;
    webViewController.ignoreScroll = YES;
    [webViewController.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"if(window.location.hash == \"#%@\") { window.location.hash = ''; } window.location.hash = \"#%@\"", hash, hash]];
    webViewController.anchorChangeInProgress = NO;
    webViewController.ignoreScroll = NO;
    if([DHRemoteServer sharedServer].connectedRemote)
    {
        [[DHRemoteServer sharedServer] sendWebViewURL:[webViewController.webView stringByEvaluatingJavaScriptFromString:@"window.location.href"]];        
    }
    if(!iPad || !isRegularHorizontalClass)
    {
        [self performSelector:@selector(dismissModal:) withObject:self afterDelay:0.1f];
    }
    else
    {
//        if(self.webViewController.navigationController.toolbarHidden)
//        {
//            self.webViewController.ignoreScroll = YES;
//            [self.webViewController.navigationController setToolbarHidden:NO animated:YES];
//            self.webViewController.ignoreScroll = NO;
//        }
    }
}

- (NSMutableArray *)activeSections
{
    return self.searchController. active && self.searchController.searchBar.text.length ? self.filteredSections : self.sections;
}

- (NSMutableArray *)activeSectionTitles
{
    return self.searchController.active && self.searchController.searchBar.text.length ? self.filteredSectionTitles : self.sectionTitles;
}

- (IBAction)dismissModal:(id)sender
{
    [[DHWebViewController sharedWebViewController] removeDashClearedClass];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    self.searchController = controller;
    if(isIOS11)
    {
        if(@available(iOS 11.0, *))
        {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    tableView.rowHeight = 44;
    tableView.separatorInset = UIEdgeInsetsMake(0, DHHeaderSeparatorInset, 0, 0);
    if(iPad && isRegularHorizontalClass)
    {
        tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.f, 0.f, 0.f);
    }
    [tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.filteredSections = [NSMutableArray array];
    self.filteredSectionTitles = [NSMutableArray array];
    int i = 0;
    for(NSArray *section in self.sections)
    {
        NSMutableArray *filteredSection = [NSMutableArray array];
        for(NSDictionary *entry in section)
        {
            if([entry[@"name"] contains:searchString])
            {
                [filteredSection addObject:entry];
            }
        }
        if(filteredSection.count)
        {
            [self.filteredSections addObject:filteredSection];
            [self.filteredSectionTitles addObject:self.sectionTitles[i]];
        }
        ++i;
    }
    return YES;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self.tableView deselectAll:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.activeSectionTitles[section];
}

- (void)prepareForURLSearch:(id)sender
{
    if(!iPad || !isRegularHorizontalClass)
    {
        [self.searchDisplayController setActive:NO animated:NO];
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];        
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
