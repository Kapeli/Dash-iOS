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

#import "DHSplitViewController.h"
#import "DHWebViewController.h"
#import "DHRepo.h"
#import "DHPreferences.h"
#import "DHTocBrowser.h"
#import "DHDocsetBrowser.h"

@implementation DHSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = (id)self;
    self.preferredPrimaryColumnWidthFraction = (iPad) ? 0.39 : 0.35;
    self.maximumPrimaryColumnWidth = 320;

}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UINavigationController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    DHWebViewController *webViewController = [DHWebViewController sharedWebViewController];
    DHTocBrowser *tocBrowser = webViewController.actualTOCBrowser;
    [tocBrowser dismissModal:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:DHSplitViewControllerDidCollapse object:nil];

//    if([secondaryViewController.topViewController isKindOfClass:[DHRepo class]])
//    {
//        [secondaryViewController setViewControllers:[NSArray arrayWithObject:secondaryViewController.topViewController] animated:NO];
//        return NO;
//    }
    return YES;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UINavigationController *)masterViewController
{
    [splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
    DHWebViewController *webViewController = [DHWebViewController sharedWebViewController];
    [webViewController removeDashClearedClass];
    DHTocBrowser *tocBrowser = webViewController.actualTOCBrowser;
    [tocBrowser dismissModal:self];
    NSMutableArray *detailViewControllers = [NSMutableArray arrayWithObject:webViewController];
    NSMutableArray *newMasterViewControllers = [NSMutableArray array];
    for(UIViewController *viewController in masterViewController.viewControllers)
    {
        if([viewController isKindOfClass:[DHRepo class]])
        {
            [detailViewControllers addObject:viewController];
        }
        else if(![viewController isKindOfClass:[DHWebViewController class]])
        {
            [newMasterViewControllers addObject:viewController];
        }
    }
    [masterViewController setViewControllers:newMasterViewControllers animated:NO];
    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    detailNavigationController.delegate = webViewController;
    if([[masterViewController topViewController] isKindOfClass:[DHPreferences class]] && ![[detailViewControllers lastObject] isKindOfClass:[DHRepo class]])
    {
        DHPreferences *preferences = (id)[masterViewController topViewController];
        NSIndexPath *indexPath = (preferences.tableView.indexPathForSelectedRow) ? preferences.tableView.indexPathForSelectedRow : [NSIndexPath indexPathForRow:0 inSection:0];
        NSString *identifier = [[preferences segueIdentifierForIndexPath:indexPath] substringToString:@"ToDetailSegue"];
        id viewController = [[DHAppDelegate mainStoryboard] instantiateViewControllerWithIdentifier:identifier];
        [detailViewControllers addObject:viewController];
    }
    else if(![[masterViewController topViewController] isKindOfClass:[DHPreferences class]] && [[detailViewControllers lastObject] isKindOfClass:[DHRepo class]])
    {
        while([[detailViewControllers lastObject] isKindOfClass:[DHRepo class]])
        {
            [detailViewControllers removeLastObject];
        }
    }
    [detailNavigationController setViewControllers:detailViewControllers animated:NO];
    [masterViewController setToolbarHidden:YES animated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:DHSplitViewControllerDidSeparate object:nil];
    return detailNavigationController;
}

- (NSArray<UIKeyCommand *> *)keyCommands
{
    if([self currentSearchBar])
    {
        return @[[UIKeyCommand keyCommandWithInput:@"f" modifierFlags:UIKeyModifierCommand action:@selector(handleCommandF) discoverabilityTitle:([self currentSearchBar].placeholder) ? [self currentSearchBar].placeholder : @"Search"]];
    }
    return @[];
}

- (UISearchBar *)currentSearchBar
{
    for(id childController in [self childViewControllers])
    {
        id controller = childController;
        if([childController isKindOfClass:[UINavigationController class]])
        {
            controller = [childController visibleViewController];
        }
        if([controller respondsToSelector:@selector(searchBar)] && [controller searchBar])
        {
            return [controller searchBar];
        }
        if([controller respondsToSelector:@selector(searchController)] && [controller searchController])
        {
            return [[[(DHDocsetBrowser*)controller searchController] displayController] searchBar];
        }
    }
    return nil;
}

- (void)handleCommandF
{
    [[self currentSearchBar] becomeFirstResponder];
}

@end
