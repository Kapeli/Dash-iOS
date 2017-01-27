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

#import "DHTypeBrowser.h"
#import "DHTypes.h"
#import "DHDocsetManager.h"

@implementation DHTypeBrowser

- (void)viewDidLoad
{
    if(!self.docset)
    {
        // happens during state restoration
        return;
    }
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.searchController = [DHDBSearchController searchControllerWithDocsets:@[self.docset] typeLimit:nil viewController:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForURLSearch:) name:DHPrepareForURLSearch object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enforceSmartTitleBarButton) name:DHSplitViewControllerDidSeparate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enforceSmartTitleBarButton) name:DHSplitViewControllerDidCollapse object:nil];
    [self.tableView registerNib:[UINib nibWithNibName:@"DHBrowserCell" bundle:nil] forCellReuseIdentifier:@"DHBrowserCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"DHLoadingCell" bundle:nil] forCellReuseIdentifier:@"DHLoadingCell"];

    self.tableView.rowHeight = 44;
    self.title = self.docset.name;
    [self enforceSmartTitleBarButton];
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
        if(isRegularHorizontalClass && self.isActive)
        {
            [[DHWebViewController sharedWebViewController] loadURL:[self.docset indexFilePath]];
        }
        
        NSString *typesCache = [self.docset.path stringByAppendingPathComponent:@".types.plist"];
        NSDictionary *typesCacheDict = [NSDictionary dictionaryWithContentsOfFile:typesCache];
        if(([self.docset.path contains:@"Apple_API_Reference"] || [self.docset.platform isEqualToString:@"apple"]) && typesCacheDict && [typesCacheDict[@"language"] integerValue] != [DHAppleActiveLanguage currentLanguage])
        {
            typesCacheDict = nil;
        }
        if(typesCacheDict && typesCacheDict[@"types"] && [typesCacheDict[@"types"] isKindOfClass:[NSArray class]] && [typesCacheDict[@"types"] count])
        {
            self.types = [typesCacheDict[@"types"] mutableCopy];
        }
        else
        {
            self.tableView.allowsSelection = NO;
            self.isLoading = YES;
            dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
            dispatch_async(queue, ^{
                [self.docset executeBlockWithinDocsetDBConnection:^(FMDatabase *db) {
                    NSMutableArray *types = [NSMutableArray array];
                    NSMutableDictionary *typesDict = [NSMutableDictionary dictionary];
                    NSConditionLock *lock = [DHDocset stepLock];
                    NSString *platform = self.docset.platform;
                    [lock lockWhenCondition:DHLockAllAllowed];
                    NSString *query = @"SELECT type, COUNT(rowid) FROM searchIndex GROUP BY type";
                    if([self.docset.platform isEqualToString:@"apple"])
                    {
                        if([DHAppleActiveLanguage currentLanguage] == DHNewActiveAppleLanguageSwift)
                        {
                            query = @"SELECT type, COUNT(rowid) FROM searchIndex WHERE path NOT LIKE '%<dash_entry_language=objc>%' AND path NOT LIKE '%<dash_entry_language=occ>%' GROUP BY type";
                        }
                        else
                        {
                            query = @"SELECT type, COUNT(rowid) FROM searchIndex WHERE path NOT LIKE '%<dash_entry_language=swift>%' GROUP BY type";
                        }
                    }
                    FMResultSet *rs = [db executeQuery:query];
                    BOOL next = [rs next];
                    [lock unlock];
                    while(next)
                    {
                        NSString *type = [rs stringForColumnIndex:0];
                        if(type && type.length)
                        {
                            NSInteger count = [rs intForColumnIndex:1];
                            NSString *pluralName = [DHTypes pluralFromEncoded:type];
                            if([pluralName isEqualToString:@"Categories"] && ([platform isEqualToString:@"python"] || [platform isEqualToString:@"flask"] || [platform isEqualToString:@"twisted"] || [platform isEqualToString:@"django"] || [platform isEqualToString:@"actionscript"] || [platform isEqualToString:@"nodejs"]))
                            {
                                pluralName = @"Modules";
                            }
                            
                            typesDict[type] = @{@"type": type, @"count": @(count), @"plural": pluralName};
                        }
                        [lock lockWhenCondition:DHLockAllAllowed];
                        next = [rs next];
                        [lock unlock];
                    }
                    NSMutableArray *typeOrder = [NSMutableArray arrayWithArray:[[DHTypes sharedTypes] orderedTypes]];
                    [typeOrder removeObject:@"Guide"];
                    [typeOrder removeObject:@"Section"];
                    [typeOrder removeObject:@"Sample"];
                    [typeOrder removeObject:@"File"];
                    [typeOrder addObject:@"Guide"];
                    [typeOrder addObject:@"Section"];
                    [typeOrder addObject:@"Sample"];
                    [typeOrder addObject:@"File"];
                    if([platform isEqualToString:@"go"] || [platform isEqualToString:@"godoc"])
                    {
                        [typeOrder removeObject:@"Type"];
                        [typeOrder insertObject:@"Type" atIndex:0];
                    }
                    if([platform isEqualToString:@"swift"])
                    {
                        [typeOrder removeObject:@"Type"];
                        [typeOrder insertObject:@"Type" atIndex:0];
                    }
                    for(NSString *key in typeOrder)
                    {
                        NSDictionary *type = typesDict[key];
                        if(type)
                        {
                            [types addObject:type];
                        }
                    }
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        self.isLoading = NO;
                        self.isEmpty = types.count <= 0;
                        if(!self.isEmpty)
                        {
                            self.tableView.allowsSelection = YES;
                        }
                        self.types = types;
                        NSMutableDictionary *newTypesCacheDict = [@{@"types": types} mutableCopy];;
                        if([self.docset.path contains:@"Apple_API_Reference.docset"] || [self.docset.platform isEqualToString:@"apple"])
                        {
                            newTypesCacheDict[@"language"] = @([DHAppleActiveLanguage currentLanguage]);
                        }
                        [newTypesCacheDict writeToFile:typesCache atomically:NO];
                        [self.tableView reloadData];
                    });
                } readOnly:YES lockCondition:DHLockAllAllowed optimisedIndex:YES];
            });
        }
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
    [self.searchController traitCollectionDidChange:previousTraitCollection];
    [self enforceSmartTitleBarButton];
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
    NSInteger count = self.types.count;
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
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:(self.isEmpty) ? @"Empty Docset" : @"Loading..." attributes:@{NSParagraphStyleAttributeName : paragraph, NSForegroundColorAttributeName: [UIColor colorWithWhite:0.8 alpha:1], NSFontAttributeName: font}];
    }
    else if(self.isLoading || self.isEmpty)
    {
        cell.userInteractionEnabled = NO;
        cell.textLabel.text = @"";
    }
    else
    {
        cell.userInteractionEnabled = YES;
        NSDictionary *type = self.types[indexPath.row];
        cell.textLabel.text = type[@"plural"];
        [cell.titleLabel setRightDetailText:[type[@"count"] stringValue] adjustMainWidth:YES];
        cell.imageView.image = [UIImage imageNamed:type[@"type"]];;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"DHEntryBrowserSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"DHEntryBrowserSegue"])
    {
        id entryBrowser = [segue destinationViewController];
        [entryBrowser setDocset:self.docset];
        NSDictionary *selectedType = self.types[self.tableView.indexPathForSelectedRow.row];
        [entryBrowser setType:selectedType[@"type"]];
        [entryBrowser setTitle:selectedType[@"plural"]];
    }
    else if([[segue identifier] isEqualToString:@"DHShowIndexPageSegue"])
    {
        DHWebViewController *webViewController = [segue destinationViewController];
        webViewController.urlToLoad = [self.docset indexFilePath];
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
    [self.searchController encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.docset.relativePath forKey:@"docsetRelativePath"];
    [coder encodeObject:self.types forKey:@"types"];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *docsetRelativePath = [coder decodeObjectForKey:@"docsetRelativePath"];
    self.docset = [[DHDocsetManager sharedManager] docsetWithRelativePath:docsetRelativePath];
    self.isRestoring = YES;
    [self viewDidLoad];
    self.isRestoring = NO;
    self.types = [coder decodeObjectForKey:@"types"];
    [self.searchController decodeRestorableStateWithCoder:coder];
    [super decodeRestorableStateWithCoder:coder];
}

- (void)enforceSmartTitleBarButton
{
    if(isRegularHorizontalClass)
    {
        if(self.navigationItem.titleView)
        {
            self.navigationItem.titleView = nil;
            self.title = self.docset.name;
        }
    }
    else if(!self.navigationItem.titleView && NSClassFromString(@"UINavigationItemView") && ![[self.docset indexFilePath] isCaseInsensitiveEqual:[[NSBundle mainBundle] pathForResource:@"home" ofType:@"html"]] && [DHDocsetBrowser titleBarItemAttributedStringTemplate])
    {
        @try {
            UILabel *titleLabel = nil;
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            NSMutableAttributedString *title = [[DHDocsetBrowser titleBarItemAttributedStringTemplate] mutableCopy];
            [title.mutableString setString:[NSString stringWithFormat:@"%@  ", self.docset.name]];
            [title addAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor], NSFontAttributeName: [UIFont fontWithName:@"Ionicons" size:20], NSBaselineOffsetAttributeName: @(-2)} range:NSMakeRange(title.mutableString.length-1, 1)];
            [button setAttributedTitle:title forState:UIControlStateNormal];
            [button addTarget:self action:@selector(smartTitleBarButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            button.frame = titleLabel.frame;
            self.navigationItem.titleView = button;
        }
        @catch(NSException *exception) { NSLog(@"%@ %@", exception, [exception callStackSymbols]); }
    }
}

- (void)smartTitleBarButtonPressed:(id)sender
{
    [[DHWebViewController sharedWebViewController] loadURL:[self.docset indexFilePath]];
    [self performSegueWithIdentifier:@"DHShowIndexPageSegue" sender:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
