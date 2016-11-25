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

#import "DHPreferences.h"
#import "DHWebViewController.h"
#import "DHAppDelegate.h"
#import "DHDocsetDownloader.h"
#import "DHDocsetTransferrer.h"

@implementation DHPreferences

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForURLSearch:) name:DHPrepareForURLSearch object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openDownloads:) name:DHOpenDownloads object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openTransfers:) name:DHOpenTransfers object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.updatesSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:[[DHDocsetDownloader sharedDownloader] defaultsAutomaticallyCheckForUpdatesKey]]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.toolbar setHidden:YES];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(previousTraitCollection)
    {
        [super traitCollectionDidChange:previousTraitCollection];
    }
    [self.tableView reloadData];
    if(isRegularHorizontalClass)
    {
        self.clearsSelectionOnViewWillAppear = NO;
        if(!self.tableView.indexPathForSelectedRow)
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:([[[self.splitViewController.viewControllers lastObject] topViewController] isKindOfClass:[DHDocsetTransferrer class]]) ? 1 : 0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
        }
    }
    else
    {
        [self.tableView deselectAll:YES];
        self.clearsSelectionOnViewWillAppear = YES;
    }
}

- (IBAction)dismissModal:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    UINavigationController *rightNavController = self.splitViewController.viewControllers.lastObject;
    id toPopTo = nil;
    for(id viewController in [[rightNavController.viewControllers reverseObjectEnumerator] allObjects])
    {
        if([viewController isKindOfClass:[DHWebViewController class]])
        {
            toPopTo = viewController;
            break;
        }
    }
    if(toPopTo)
    {
        [(DHWebViewController *)toPopTo view].frame = rightNavController.view.bounds;
        [rightNavController popToViewController:toPopTo animated:YES];
    }
    else
    {
        [rightNavController popViewControllerAnimated:YES];
    }
    [[rightNavController navigationItem] setHidesBackButton:NO];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[self.tableView cellForRowAtIndexPath:indexPath] selectionStyle] == UITableViewCellSelectionStyleNone)
    {
        return NO;
    }
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // prevent selection of rows that are already selected
    if(isRegularHorizontalClass && tableView.indexPathForSelectedRow.row == indexPath.row)
    {
        return nil;
    }
    if([[self.tableView cellForRowAtIndexPath:indexPath] selectionStyle] == UITableViewCellSelectionStyleNone)
    {
        return nil;
    }
    return indexPath;
}

- (NSString *)detailSegueIdentifierForRow:(NSInteger)row
{
    // Also used by DHSplitViewController. Make sure identifiers end with "ToDetailSegue"
    if(row == 0)
    {
        return @"DHDocsetDownloaderToDetailSegue";
    }
    else if(row == 1)
    {
        return @"DHDocsetTransferrerToDetailSegue";
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        if(indexPath.row == 0)
        {
            [self openDownloads:nil];
        }
        else if(indexPath.row == 1)
        {
            [self openTransfers:nil];
        }
    }
}

- (void)openDownloads:(id)sender {
    if(isRegularHorizontalClass) {
        [self performSegueWithIdentifier:@"DHDocsetDownloaderToDetailSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"DHDocsetDownloaderToMasterSegue" sender:self];
    }
}

- (void)openTransfers:(id)sender {
    if(isRegularHorizontalClass) {
        [self performSegueWithIdentifier:@"DHDocsetTransferrerToDetailSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"DHDocsetTransferrerToMasterSegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if(isRegularHorizontalClass)
    {
        UINavigationController *rightNavController = self.splitViewController.viewControllers.lastObject;
        NSMutableArray *newViewControllers = [NSMutableArray array];
        for(NSUInteger i = 0; i < rightNavController.viewControllers.count; i++)
        {
            id vc = rightNavController.viewControllers[i];
            if([vc isKindOfClass:[DHWebViewController class]] || i == rightNavController.viewControllers.count-1)
            {
                [newViewControllers addObject:vc];
            }
        }
        [rightNavController setViewControllers:newViewControllers];
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(isRegularHorizontalClass)
    {
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [DHAppDelegate sharedDelegate].window.rootViewController.view.tintColor;
        bgColorView.layer.masksToBounds = YES;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
        cell.selectedBackgroundView = bgColorView;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        if(cell.selectionStyle != UITableViewCellSelectionStyleNone)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;            
        }
        cell.textLabel.highlightedTextColor = [UIColor blackColor];
        cell.detailTextLabel.highlightedTextColor = [UIColor blackColor];
        cell.selectedBackgroundView = nil;
    }
}

- (IBAction)updatesSwitchValueChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:[DHDocsetDownloader sharedDownloader].defaultsAutomaticallyCheckForUpdatesKey];
    [self updateUpdatesSwitchFooterView:nil];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    [self updateUpdatesSwitchFooterView:view];
}

- (void)updateUpdatesSwitchFooterView:(UITableViewHeaderFooterView *)footer
{
    footer = (footer) ?: [self.tableView footerViewForSection:1];
    [footer textLabel].text = [NSString stringWithFormat:@"Dash %@ notify you when docset updates are available.         ", (self.updatesSwitch.isOn) ? @"will" : @"won't"];
    
}

- (void)prepareForURLSearch:(id)sender
{
    [self dismissModal:self];
}

- (UIModalTransitionStyle)modalTransitionStyle
{
    return [super modalTransitionStyle];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if(selectedIndexPath != nil)
    {
        [coder encodeObject:selectedIndexPath forKey:@"selectedIndexPath"];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    NSIndexPath *selectedIndexPath = [coder decodeObjectForKey:@"selectedIndexPath"];
    if(selectedIndexPath != nil)
    {
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else
        selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if (self.splitViewController.viewControllers.count == 2 && [selectedIndexPath compare:[NSIndexPath indexPathForRow:0 inSection:0]] == NSOrderedSame) {
        UINavigationController *nav = [self.splitViewController.viewControllers lastObject];
        if ([nav isKindOfClass:[UINavigationController class]] && ![nav.topViewController isKindOfClass:[DHDocsetDownloader class]]) {
            NSMutableArray *newViewControllers = [NSMutableArray array];
            [newViewControllers addObjectsFromArray:nav.viewControllers];
            [newViewControllers addObject:[DHDocsetDownloader sharedDownloader]];
            [nav setViewControllers:newViewControllers];
        }
    }
}

- (IBAction)getDashForMacOS:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://kapeli.com/dash"]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
