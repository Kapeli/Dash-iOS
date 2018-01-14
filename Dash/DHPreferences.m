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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.updatesSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:[[DHDocsetDownloader sharedDownloader] defaultsAutomaticallyCheckForUpdatesKey]]];
    [self.alphabetizingSwitch setOn:[NSUserDefaults.standardUserDefaults boolForKey:DHDocsetDownloader.defaultsAlphabetizingKey]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateAlphabetizingSwitchFooterView:nil];
        [self updateUpdatesSwitchFooterView:nil];
    });
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
            UIViewController *controller = [[self.splitViewController.viewControllers lastObject] topViewController];
            NSString *controllerTitle = controller.navigationItem.title;
            BOOL found = NO;
            for(NSInteger section = 0; section < self.tableView.numberOfSections; section++)
            {
                for(NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++)
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    if([cell.textLabel.text isEqualToString:controllerTitle])
                    {
                        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                        found = YES;
                        break;
                    }
                }
            }
            if(!found)
            {
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
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
    if(isRegularHorizontalClass && [tableView.indexPathForSelectedRow isEqual:indexPath])
    {
        return nil;
    }
    if([[self.tableView cellForRowAtIndexPath:indexPath] selectionStyle] == UITableViewCellSelectionStyleNone)
    {
        return nil;
    }
    return indexPath;
}

- (NSString *)segueIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [[[self.tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    if([title isEqualToString:@"Main Docsets"])
    {
        if(isRegularHorizontalClass)
        {
            // Also used by DHSplitViewController. Make sure identifiers end with "ToDetailSegue"
            return @"DHDocsetDownloaderToDetailSegue";
        }
        return @"DHDocsetDownloaderToMasterSegue";
    }
    else if([title isEqualToString:@"User Contributed Docsets"])
    {
        if(isRegularHorizontalClass)
        {
            // Also used by DHSplitViewController. Make sure identifiers end with "ToDetailSegue"
            return @"DHUserRepoToDetailSegue";
        }
        return @"DHUserRepoToMasterSegue";
    }
    else if([title isEqualToString:@"Cheat Sheets"])
    {
        if(isRegularHorizontalClass)
        {
            // Also used by DHSplitViewController. Make sure identifiers end with "ToDetailSegue"
            return @"DHCheatRepoToDetailSegue";
        }
        return @"DHCheatRepoToMasterSegue";
    }
    else if([title isEqualToString:@"Transfer Docsets"])
    {
        if(isRegularHorizontalClass)
        {
            // Also used by DHSplitViewController. Make sure identifiers end with "ToDetailSegue"
            return @"DHDocsetTransferrerToDetailSegue";
        }
        return @"DHDocsetTransferrerToMasterSegue";
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *segueIdentifier = [self segueIdentifierForIndexPath:indexPath];
    if(segueIdentifier)
    {
        [self performSegueWithIdentifier:[self segueIdentifierForIndexPath:indexPath] sender:self];
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

- (IBAction)alphabetizingSwitchValueChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:DHDocsetDownloader.defaultsAlphabetizingKey];
    [NSNotificationCenter.defaultCenter postNotificationName:DHSettingsChangedNotification object:DHDocsetDownloader.defaultsAlphabetizingKey];
    [self updateAlphabetizingSwitchFooterView:nil];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)footer forSection:(NSInteger)section
{
    if(section == [tableView indexPathForCell:self.updatesCell].section)
    {
        [self updateUpdatesSwitchFooterView:footer];
    }
    else if(section == [tableView indexPathForCell:self.alphabetizingCell].section)
    {
        [self updateAlphabetizingSwitchFooterView:footer];
    }
}

- (void)updateUpdatesSwitchFooterView:(UITableViewHeaderFooterView *)footer
{
    footer = (footer) ? footer : [self.tableView footerViewForSection:[self.tableView indexPathForCell:self.updatesCell].section];
    [footer textLabel].text = [NSString stringWithFormat:@"Dash %@ notify you when docset updates are available.", (self.updatesSwitch.isOn) ? @"will" : @"won't"];
    [[footer textLabel] sizeToFit];
}

- (void)updateAlphabetizingSwitchFooterView:(UITableViewHeaderFooterView *)footer
{
    footer = (footer) ? footer : [self.tableView footerViewForSection:[self.tableView indexPathForCell:self.alphabetizingCell].section];
    [footer textLabel].text = [NSString stringWithFormat:@"Docsets %@ be sorted alphabetically in the docset browser.", (self.alphabetizingSwitch.isOn) ? @"will" : @"won't"];
    [[footer textLabel] sizeToFit];
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
