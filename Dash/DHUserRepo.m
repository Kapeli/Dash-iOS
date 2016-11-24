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

#import "DHUserRepo.h"
#import "DHUserRepoList.h"

@implementation DHUserRepo

static id singleton = nil;

+ (instancetype)sharedUserRepo
{
    if(singleton)
    {
        return singleton;
    }
    id userRepo = [[DHAppDelegate mainStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    [userRepo setUp];
    return userRepo;
}

- (void)setUp
{
    [super setUp];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadUserDocsetsIfNeeded];
}

- (void)reloadUserDocsetsIfNeeded
{
    if(!self.loading && (!self.lastListLoad || (!self.searchBar.text.length && [[NSDate date] timeIntervalSinceDate:self.lastListLoad] > 30)))
    {
        self.loading = YES;
        self.searchBar.userInteractionEnabled = NO;
        self.searchBar.alpha = 0.5;
        self.searchBar.placeholder = @"Loading...";
        [self.tableView reloadData];
        dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
        dispatch_async(queue, ^{
            [[DHUserRepoList sharedUserRepoList] reload];
            NSArray *feeds = [[DHUserRepoList sharedUserRepoList] allUserDocsets];
            NSLog(@"%@", feeds);
        });
    }
}

+ (id)alloc
{
    if(singleton)
    {
        return singleton;
    }
    return [super alloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(singleton)
    {
        return singleton;
    }
    self = [super initWithCoder:aDecoder];
    singleton = self;
    return self;
}

@end
