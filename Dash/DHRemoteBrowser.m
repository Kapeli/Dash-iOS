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

#import "DHRemoteBrowser.h"
#import "DHNestedViewController.h"
#import "DHWebView.h"

@implementation DHRemoteBrowser

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForURLSearch:) name:DHPrepareForURLSearch object:nil];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"DHLoadingCell" bundle:nil] forCellReuseIdentifier:@"DHLoadingCell"];
    
    self.tableView.rowHeight = 44;
    self.title = self.remote.name;
    self.remote.browser = self;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    if(isRegularHorizontalClass)
    {
        DHWebViewController *webViewController = [DHWebViewController sharedWebViewController];
        webViewController.webView.scrollView.delegate = nil;
        webViewController.navigationController.toolbarHidden = YES;
        [webViewController updateBackForwardButtonState];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(!isRegularHorizontalClass)
    {
        if(self.tableView.indexPathForSelectedRow)
        {
            [self.tableView scrollToRowAtIndexPath:self.tableView.indexPathForSelectedRow atScrollPosition:UITableViewScrollPositionNone animated:NO];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView deselectAll:YES];
        });
    }
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
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"DHNestedSegue"])
    {
        DHNestedViewController *nestedController = [segue destinationViewController];
        DHDBResult *result = self.results[self.tableView.indexPathForSelectedRow.row];
        nestedController.result = result;
    }
    else if([[segue identifier] isEqualToString:@"DHSearchWebViewSegue"])
    {
        DHWebViewController *webViewController = [segue destinationViewController];
        DHDBResult *result = self.results[self.tableView.indexPathForSelectedRow.row];
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
            [self performSegueWithIdentifier:@"DHNestedSegue" sender:self];
        }
        else
        {
            if(!isRegularHorizontalClass)
            {
                [self performSegueWithIdentifier:@"DHSearchWebViewSegue" sender:self];
            }
        }
        NSString *remoteName = [DHRemoteServer sharedServer].connectedRemote.name;
        if(remoteName)
        {
            [[DHRemoteServer sharedServer] sendObject:@{@"selectedRow": @(tableView.indexPathForSelectedRow.row), @"selectedRowName": (result.name) ? : @"justsendtheresults"} forRequestName:@"syncSelectedRow" encrypted:YES toMacName:remoteName];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    self.isEmpty = self.results.count <= 0;
    if(self.isEmpty)
    {
        return 4;
    }
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.isEmpty)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DHLoadingCell" forIndexPath:indexPath];
        cell.userInteractionEnabled = NO;
        if(indexPath.row == 2)
        {
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            [paragraph setAlignment:NSTextAlignmentCenter];
            UIFont *font = [UIFont boldSystemFontOfSize:20];
            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Nothing here..." attributes:@{NSParagraphStyleAttributeName : paragraph, NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8 alpha:1], NSFontAttributeName: font}];
        }
        else if(indexPath.row == 3)
        {
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            [paragraph setAlignment:NSTextAlignmentCenter];
            UIFont *font = [UIFont boldSystemFontOfSize:16];
            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Search for something on your Mac" attributes:@{NSParagraphStyleAttributeName : paragraph, NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8 alpha:1], NSFontAttributeName: font}];
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
    for(NSString *key in [DHDBResult highlightDictionary])
    {
        [string removeAttribute:key range:NSMakeRange(0, string.length)];
    }
    BOOL didAddAttributes = NO;
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

- (void)prepareForURLSearch:(id)sender
{
    [self.searchDisplayController setActive:NO animated:NO];
}

- (void)popNestedViewControllers
{
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    for(UIViewController *viewController in self.navigationController.viewControllers)
    {
        if([viewController isKindOfClass:[DHNestedViewController class]])
        {
            [viewControllers removeObjectIdenticalTo:viewController];
        }
    }
    [self.navigationController setViewControllers:viewControllers animated:YES];
}

- (DHNestedViewController *)nestedViewController
{
    for(UIViewController *controller in self.navigationController.viewControllers)
    {
        if([controller isKindOfClass:[DHNestedViewController class]])
        {
            return (id)controller;
        }
    }
    return nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.remote forKey:@"remote"];
    [coder encodeObject:self.results forKey:@"results"];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if(selectedIndexPath != nil)
    {
        [coder encodeObject:selectedIndexPath forKey:@"selectedIndexPath"];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    self.remote = [coder decodeObjectForKey:@"remote"];
    [self.remote connect];
    self.results = [coder decodeObjectForKey:@"results"];
    NSIndexPath *selectedIndexPath = [coder decodeObjectForKey:@"selectedIndexPath"];
    if(selectedIndexPath != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        });
    }
}

- (void)dealloc
{

}

@end
