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

#import "DHDocsetBrowser.h"
#import "DHWebViewController.h"
#import "DHPreferences.h"
#import "DHNavigationAnimator.h"
#import "DHRepo.h"
#import "DHDocsetManager.h"
#import "DHAppDelegate.h"
#import "DHDocsetDownloader.h"
#import "DHRemoteBrowser.h"
#import "DHWebView.h"
#import "DHDocsetBrowserViewModel.h"

static NSAttributedString *_titleBarItemAttributedStringTemplate = nil;

@interface DHDocsetBrowser ()
@property (nonatomic, strong) DHDocsetBrowserViewModel *viewModel;
@end

@implementation DHDocsetBrowser

- (NSArray<DHDocset *> *)shownDocsets {
    return self.viewModel.shownDocsets;
}

- (NSArray *)sections {
    return self.viewModel.sections;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.viewModel = [[DHDocsetBrowserViewModel alloc] init];
    self.clearsSelectionOnViewWillAppear = NO;
    self.searchController = [DHDBSearchController searchControllerWithDocsets:nil typeLimit:nil viewController:self];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:DHDocsetsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:DHRemotesChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:DHSettingsChangedNotification object:nil];
    self.tableView.rowHeight = 44;
    self.navigationController.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performURLSearch:) name:DHPerformURLSearch object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    if(!self.didFirstReload)
    {
        self.didFirstReload = YES;
        [self reload:nil];
    }
    [self.searchController viewDidAppear];
    [self grabTitleBarItemAttributedStringTemplate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.searchController viewDidDisappear];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
    [super viewWillAppear:animated];
    if(!self.isEditing)
    {
        [self.tableView deselectAll:YES];        
    }
    [self.searchController viewWillAppear];
    if([DHRemoteServer sharedServer].connectedRemote)
    {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [[DHRemoteServer sharedServer].connectedRemote disconnect];
        if(isRegularHorizontalClass)
        {
            DHWebViewController *webViewController = [DHWebViewController sharedWebViewController];
            [webViewController loadURL:[[NSBundle mainBundle] pathForResource:@"home" ofType:@"html"]];
            [(DHWebView*)webViewController.webView resetHistory];
            [webViewController updateBackForwardButtonState];
            webViewController.webView.scrollView.delegate = webViewController;
            webViewController.navigationController.toolbarHidden = NO;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.searchController viewWillDisappear];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(previousTraitCollection)
    {
        [super traitCollectionDidChange:previousTraitCollection];
    }
    [self.searchController traitCollectionDidChange:previousTraitCollection];
}

- (void)performURLSearch:(NSNotification *)notification
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    NSString *url = [notification object];
    NSString *query = nil;
    NSMutableOrderedSet *keywordDocsets = [NSMutableOrderedSet orderedSet];
    if([url hasCaseInsensitivePrefix:@"dash://"])
    {
        query = [url substringFromIndex:@"dash://".length];
    }
    else if([url hasCaseInsensitivePrefix:@"dash-plugin://"])
    {
        NSString *all = [[url stringByReplacingOccurrencesOfString:@"dash-plugin://" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, url.length)] trimWhitespace];
        query = ([all contains:@"query="]) ? [[all substringFromString:@"query="] substringToString:@"&"] : @"";
        NSString *keysString = ([all contains:@"keys="]) ? [[all substringFromString:@"keys="] substringToString:@"&"] : @"";
        if(keysString.length)
        {
            NSMutableArray *docsets = [NSMutableArray arrayWithArray:[DHDocsetManager sharedManager].docsets];
            NSArray *keys = [keysString componentsSeparatedByString:@","];
            for(__strong NSString *key in keys)
            {
                key = [[key stringByReplacingPercentEscapes] trimWhitespace];
                BOOL isExact = [key hasPrefix:@"exact:"];
                if(isExact)
                {
                    key = [key substringFromIndex:@"exact:".length];
                }
                if(key.length)
                {
                    NSMutableArray *aliasKeys = [NSMutableArray arrayWithObject:key];
                    if([key isCaseInsensitiveEqual:@"macosx"])
                    {
                        [aliasKeys addObject:@"osx"];
                    }
                    else if([key isCaseInsensitiveEqual:@"osx"])
                    {
                        [aliasKeys addObject:@"macosx"];
                    }
                    else if([key isCaseInsensitiveEqual:@"ios"])
                    {
                        [aliasKeys addObject:@"iphoneos"];
                    }
                    else if([key isCaseInsensitiveEqual:@"iphoneos"])
                    {
                        [aliasKeys addObject:@"ios"];
                    }
                    for(NSString *aliasKey in aliasKeys)
                    {
                        for(DHDocset *docset in docsets)
                        {
                            NSString *platform = [[[docset.platform stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
                            NSString *parseFamily = [[[docset.parseFamily stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
                            NSString *pluginKeyword = docset.pluginKeyword;
                            if((platform && platform.length && [platform isCaseInsensitiveEqual:aliasKey]) || (!isExact && parseFamily && parseFamily.length && [parseFamily isCaseInsensitiveEqual:aliasKey]) || (!isExact && pluginKeyword && pluginKeyword.length && [pluginKeyword isCaseInsensitiveEqual:aliasKey]))
                            {
                                [keywordDocsets addObject:docset];
                            }
                        }
                    }
                }
            }
        }
    }
    query = [[query stringByReplacingPercentEscapes] trimWhitespace];
    self.searchDisplayController.searchBar.text = @"";
    [self.searchDisplayController setActive:NO animated:NO];
    [self.searchDisplayController.searchBar resignFirstResponder];
    if((query && query.length) || keywordDocsets.count)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.00 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(keywordDocsets.count)
            {
                self.viewModel.keyDocsets = [NSMutableArray arrayWithArray:[keywordDocsets array]];
            }
            [self.searchDisplayController setActive:YES animated:NO];
            self.searchDisplayController.searchBar.text = query;
            if(!query.length)
            {
                [self.searchDisplayController.searchBar becomeFirstResponder];
            }
        });
    }
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Docsets";
    return [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0], NSForegroundColorAttributeName: [UIColor colorWithWhite:201.0/255.0 alpha:1.0]}];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"You can download some in Settings.";
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.lineSpacing = 4.0;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:13.0], NSForegroundColorAttributeName: [UIColor colorWithWhite:207.0/255.0 alpha:1.0], NSParagraphStyleAttributeName: paragraph};
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"placeholder_docsets"];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSString *text = @"Open Settings";
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

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    [self openSettings:self];
}

- (void)reload:(NSNotification *)notification
{
    if(self.isSearching)
    {
        if(!notification || [[notification name] isEqualToString:DHDocsetsChangedNotification])
        {
            self.needsToReloadWhenDoneSearching = YES;
        }
        return;
    }
    NSArray *selected = (self.isEditing) ? [self.tableView indexPathsForSelectedRows] : nil;
    [self updateSections:YES];
    self.navigationItem.rightBarButtonItem = ([DHDocsetManager sharedManager].docsets.count > 0) ? self.editButtonItem : nil;
    self.tableView.tableFooterView = (self.sections.count) ? nil : [UIView new];
    [self.tableView reloadData];
    for(NSIndexPath *toSelect in selected)
    {
        [self.tableView selectRowAtIndexPath:toSelect animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    [self updateSections:YES];
    return self.sections.count;
}

- (void)updateSections:(BOOL)withTitleUpdate
{
    [self.viewModel updateSectionsForEditing:self.isEditing andSearching:self.isSearching];
    if(withTitleUpdate)
    {
        [self updateTitle];
    }
}

- (void)updateTitle
{
    if([DHRemoteServer sharedServer].remotes.count && !self.isEditing)
    {
        self.navigationItem.title = (self.sections.count > 1 || [DHDocsetManager sharedManager].docsets.count) ? @"Docsets & Remotes" : @"Remotes";
    }
    else
    {
        self.navigationItem.title = @"Docsets";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sections[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.isEditing)
    {
        return ([DHRemoteServer sharedServer].remotes.count) ? @"Docsets" : nil;
    }
    if(self.sections.count > 1 || ([DHDocsetManager sharedManager].docsets.count && !self.shownDocsets.count))
    {
        return (section == 1 && self.shownDocsets.count) ? @"Docsets" : @"Remotes";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DHBrowserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DHBrowserCell" forIndexPath:indexPath];
    
    DHDocset *docset = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = docset.name;
    cell.detailTextLabel.text = @"";
    [cell.titleLabel setSubtitle:([docset isKindOfClass:[DHRemote class]]) ? @"Not Connected" : @""];
    cell.imageView.image = docset.icon;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [[DHDocsetManager sharedManager] moveDocsetAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.viewModel.canMoveRows;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 3;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
    {
        [self.shownDocsets[indexPath.row] setIsEnabled:YES];
        [[DHDocsetManager sharedManager] saveDefaults];
        return;
    }
    if([self.sections[indexPath.section][indexPath.row] isKindOfClass:[DHRemote class]])
    {
        [self performSegueWithIdentifier:@"DHRemoteBrowserSegue" sender:self];
    }
    else
    {
        [self performSegueWithIdentifier:@"DHTypeBrowserSegue" sender:self];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.editing)
    {
        [self.shownDocsets[indexPath.row] setIsEnabled:NO];
        [[DHDocsetManager sharedManager] saveDefaults];
        return;
    }
}

- (void)tableViewDidBeginEditing:(UITableView *)tableView
{
    BOOL remotesWereShown = [DHRemoteServer sharedServer].remotes.count > 0;
    BOOL docsetsWereShown = (!remotesWereShown && self.sections.count) || (remotesWereShown && self.sections.count > 1);
    if(docsetsWereShown)
    {
        [self.tableView selectRowsInIndexSet:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.tableView numberOfRowsInSection:self.sections.count-1])] inSection:self.sections.count-1 animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

    //    NSArray *current = self.shownDocsets;
    NSArray *new = [self.viewModel docsetsForEditing:YES];
    self.viewModel.shownDocsets = new;
    NSMutableArray *toInsert = [NSMutableArray array];
    for(NSInteger i = 0; i < new.count; i++)
    {
        DHDocset *docset = new[i];
        if(!docset.isEnabled)
        {
            [toInsert addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    [self updateSections:YES];
    [self.tableView beginUpdates];
    if(!docsetsWereShown)
    {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [self.tableView insertRowsAtIndexPaths:toInsert withRowAnimation:UITableViewRowAnimationFade];
    }
    if(remotesWereShown)
    {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
    [self.tableView reloadEmptyDataSet];
    self.tableView.tableFooterView = (self.sections.count) ? nil : [UIView new];
}

- (void)tableViewDidEndEditing:(UITableView *)tableView
{
    NSArray *current = self.shownDocsets;
    self.viewModel.shownDocsets = [self.viewModel docsetsForEditing:NO];
    NSMutableArray *toDelete = [NSMutableArray array];
    BOOL docsetsShouldBeShown = NO;
    for(int i = 0; i < current.count; i++)
    {
        if(![current[i] isEnabled])
        {
            [toDelete addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        else
        {
            docsetsShouldBeShown = YES;
        }
    }
    BOOL remotesShouldBeShown = [DHRemoteServer sharedServer].remotes.count > 0;
    [self updateSections:YES];
    [self.tableView beginUpdates];
    if(docsetsShouldBeShown)
    {
        [self.tableView deleteRowsAtIndexPaths:toDelete withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
    if(remotesShouldBeShown)
    {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
    [self.tableView reloadEmptyDataSet];
    self.tableView.tableFooterView = (self.sections.count) ? nil : [UIView new];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    if(self.viewModel.keyDocsets)
    {
        [self reload:nil];
    }
    self.isSearching = YES;
    BOOL remotesWereShown = [DHRemoteServer sharedServer].remotes.count > 0;
    if(remotesWereShown)
    {
        [self updateSections:YES];
        [self.tableView beginUpdates];
        if(remotesWereShown)
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView endUpdates];
        [self.tableView reloadEmptyDataSet];
        self.tableView.tableFooterView = (self.sections.count) ? nil : [UIView new];
    }
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    self.isSearching = NO;
    if(self.needsToReloadWhenDoneSearching || self.viewModel.keyDocsets)
    {
        self.viewModel.keyDocsets = nil;
        self.needsToReloadWhenDoneSearching = NO;
        [self reload:nil];
    }
    else
    {
        BOOL remotesShouldBeShown = [DHRemoteServer sharedServer].remotes.count > 0;
        if(remotesShouldBeShown)
        {
            [self updateSections:YES];
            [self.tableView beginUpdates];
            if(remotesShouldBeShown)
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            }
            [self.tableView endUpdates];
            [self.tableView reloadEmptyDataSet];
            self.tableView.tableFooterView = (self.sections.count) ? nil : [UIView new];
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateTitle];
    });
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    [self updateTitle];
}

- (void)orientationChanged:(id)sender
{
    [self.tableView reloadEmptyDataSet];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"DHTypeBrowserSegue"])
    {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        DHDocset *selectedDocset = self.sections[indexPath.section][indexPath.row];
        id typeBrowser = [segue destinationViewController];
        [typeBrowser setDocset:selectedDocset];
    }
    else if([[segue identifier] isEqualToString:@"DHRemoteBrowserSegue"])
    {
        if(isRegularHorizontalClass)
        {
            [(DHWebView*)[DHWebViewController sharedWebViewController].webView resetHistory];
        }
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        DHRemote *selectedRemote = self.sections[indexPath.section][indexPath.row];
        id remoteBrowser = [segue destinationViewController];
        [remoteBrowser setRemote:selectedRemote];
        [selectedRemote connect];
    }
    else
    {
        [self.searchController prepareForSegue:segue sender:sender];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController*)fromVC toViewController:(UIViewController*)toVC
{
    // You'll probably never need to modify this, ever!
    // What you're looking for is inside DHWebViewController
    if([fromVC isKindOfClass:[DHPreferences class]] || [toVC isKindOfClass:[DHPreferences class]])
    {
        if(![fromVC isKindOfClass:[DHRepo class]] && ![toVC isKindOfClass:[DHRepo class]])
        {
            return [[DHNavigationAnimator alloc] init];            
        }
    }
    return nil;
}

- (IBAction)openSettings:(id)sender
{
    if(!self.isActive || (isRegularHorizontalClass && [[self.splitViewController.viewControllers.lastObject topViewController] isKindOfClass:[DHDocsetDownloader class]]))
    {
        return;
    }
    [self performSegueWithIdentifier:@"DHOpenSettingsSegue" sender:self];
    if(isRegularHorizontalClass)
    {
        [self performSegueWithIdentifier:@"DHDocsetDownloaderToDetailSegue" sender:self];
        [[self.splitViewController.viewControllers.lastObject navigationItem] setHidesBackButton:YES];
    }
    [self.navigationItem.leftBarButtonItem setEnabled:NO];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if(self.navigationController.viewControllers.count > 1)
    {
        if([self.navigationController.visibleViewController respondsToSelector:@selector(searchController)] && [[(DHDocsetBrowser*)self.navigationController.visibleViewController searchController] isKindOfClass:[DHDBSearchController class]] && [(DHDocsetBrowser*)self.navigationController.visibleViewController searchController].displayController.active)
        {
            return NO;
        }
        else if([self.navigationController.visibleViewController isKindOfClass:[DHPreferences class]])
        {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [gestureRecognizer isKindOfClass:UIScreenEdgePanGestureRecognizer.class];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [self.searchController encodeRestorableStateWithCoder:coder];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    [self.searchController decodeRestorableStateWithCoder:coder];
}

- (void)applicationFinishedRestoringState
{
    [super applicationFinishedRestoringState];
}

+ (NSAttributedString *)titleBarItemAttributedStringTemplate
{
    return _titleBarItemAttributedStringTemplate;
}

- (void)grabTitleBarItemAttributedStringTemplate
{
    if(_titleBarItemAttributedStringTemplate)
    {
        return;
    }
    @try {
        for(UIView *view in self.navigationController.navigationBar.subviews)
        {
            for(UILabel *label in view.subviews)
            {
                if([label isKindOfClass:[UILabel class]])
                {
                    if([label.text isEqualToString:self.navigationItem.title])
                    {
                        _titleBarItemAttributedStringTemplate = [label.attributedText copy];
                        break;
                    }
                }
            }
            if(_titleBarItemAttributedStringTemplate)
            {
                break;
            }
        }
    }
    @catch(NSException *exception) { NSLog(@"%@ %@", exception, [exception callStackSymbols]); }
}

- (void)dealloc
{
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    self.navigationController.delegate = nil;
}

@end
