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

#import "DHNestedViewController.h"
#import "DHBrowserTableViewCell.h"

@implementation DHNestedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.title = self.result.name;
    [self.tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    for(DHDBResult *result in self.result.similarResults)
    {
        if(result.docset != self.result.docset)
        {
            self.hasMultipleDocsets = YES;
        }
        else if(result.isRemote && ![result.remoteDocsetName isEqualToString:self.result.remoteDocsetName])
        {
            self.hasMultipleDocsets = YES;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(isRegularHorizontalClass)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[self activeRow] inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        });
    }
    else
    {
        if(self.result.isRemote)
        {
            if(self.tableView.indexPathForSelectedRow)
            {
                [self.tableView scrollToRowAtIndexPath:self.tableView.indexPathForSelectedRow atScrollPosition:UITableViewScrollPositionNone animated:NO];
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView deselectAll:YES];
            });
        }
        else
        {
            [self.tableView deselectAll:YES];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(isRegularHorizontalClass && !self.didDecode)
    {
        [[DHDBResultSorter sharedSorter] resultWasSelected:[self resultForRow:[self activeRow]] inTableView:self.tableView];
    }
    self.didDecode = NO;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.result.similarResults.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHBrowserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DHBrowserCell" forIndexPath:indexPath];
    
    DHDBResult *result = [self resultForRow:indexPath.row];
    [cell makeEntryCell];
    cell.textLabel.attributedText = nil;
    NSString *title = [result.declaredInPage substringFromString:@" - "];
    title = (title.length) ? title : result.originalName;
    cell.textLabel.text = title;
    if(self.hasMultipleDocsets)
    {
        cell.titleLabel.subtitle = (result.isRemote) ? result.remoteDocsetName : result.docset.name;
    }
    cell.titleLabel.font = [UIFont fontWithName:@"Menlo" size:16];
    cell.typeImageView.image = result.typeImage;
    cell.platformImageView.image = result.platformImage;
    cell.accessoryType = (!isRegularHorizontalClass) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

- (void)clearIsActive
{
    self.result.isActive = NO;
    for(DHDBResult *result in self.result.similarResults)
    {
        result.isActive = NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHDBResult *result = [self resultForRow:tableView.indexPathForSelectedRow.row];
    [[DHDBResultSorter sharedSorter] resultWasSelected:result inTableView:tableView];
    [[DHDBNestedResultSorter sharedSorter] increaseRankForResult:result];
    if(isRegularHorizontalClass)
    {
        [self clearIsActive];
        result.isActive = YES;
        [[DHWebViewController sharedWebViewController] loadResult:result];
    }
    else
    {
        [[DHWebViewController sharedWebViewController] loadResult:result];
        [self performSegueWithIdentifier:@"DHSearchWebViewSegue" sender:self];
    }
    if(result.isRemote)
    {
        NSString *remoteName = [DHRemoteServer sharedServer].connectedRemote.name;
        if(remoteName)
        {
            [[DHRemoteServer sharedServer] sendObject:@{@"selectedNestedRow": @(tableView.indexPathForSelectedRow.row), @"selectedRowName": (self.result.name) ? : @"justsendtheresults"} forRequestName:@"syncNestedSelectedRow" encrypted:YES toMacName:remoteName];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"DHSearchWebViewSegue"])
    {
        DHWebViewController *webViewController = [segue destinationViewController];
        DHDBResult *result = [self resultForRow:self.tableView.indexPathForSelectedRow.row];
        webViewController.result = result;
    }
}

- (DHDBResult *)resultForRow:(NSInteger)row
{
    return row == 0 ? self.result : self.result.similarResults[row-1];
}

- (NSInteger)activeRow
{
    int i = 1;
    for(DHDBResult *result in self.result.similarResults)
    {
        if(result.isActive)
        {
            return i;
        }
        ++i;
    }
    return 0;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.result forKey:@"result"];
    [coder encodeBool:self.hasMultipleDocsets forKey:@"hasMultipleDocsets"];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if(selectedIndexPath != nil)
    {
        [coder encodeObject:selectedIndexPath forKey:@"selectedIndexPath"];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    self.didDecode = YES;
    self.result = [coder decodeObjectForKey:@"result"];
    self.hasMultipleDocsets = [coder decodeBoolForKey:@"hasMultipleDocsets"];
    self.title = self.result.name;
    NSIndexPath *selectedIndexPath = [coder decodeObjectForKey:@"selectedIndexPath"];
    if(selectedIndexPath != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        });
    }
}

@end
