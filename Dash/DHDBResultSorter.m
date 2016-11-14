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

#import "DHDBResultSorter.h"
#import "DHDBResult.h"
#import "DHAppDelegate.h"

@implementation DHDBResultSorter

+ (DHDBResultSorter *)sharedSorter
{
    static dispatch_once_t pred;
    static DHDBResultSorter *_resultSorter = nil;
    
    dispatch_once(&pred, ^{
        _resultSorter = [[DHDBResultSorter alloc] init];
        [_resultSorter setUp];
    });
    return _resultSorter;
}

- (void)setUp
{
    self.ranks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"resultSortRanks"] mutableCopy];
    if(!self.ranks)
    {
        self.ranks = [NSMutableDictionary dictionary];
    }
}

- (void)resultWasSelected:(DHDBResult *)aResult inTableView:(UITableView *)tableView
{
    if(aResult.isRemote)
    {
        return;
    }
    if(!isRegularHorizontalClass)
    {
        [self increaseRankNow:aResult];
        return;
    }
    if([self.rankIncreaseTimer isValid])
    {
        [self.rankIncreaseTimer invalidate];
        self.rankIncreaseTimer = nil;
    }
    self.visiblePoint = tableView.contentOffset;
    self.rankIncreaseTimer = [NSTimer scheduledTimerWithTimeInterval:6.0f target:self selector:@selector(increaseRankForResult:) userInfo:@[aResult, tableView] repeats:NO];
}

- (void)increaseRankForResult:(NSTimer *)timer
{
    DHDBResult *aResult = [timer userInfo][0];
    if(aResult.isRemote)
    {
        return;
    }
    UITableView *tableView = [timer userInfo][1];
    if(tableView.window && !tableView.isHidden && CGPointEqualToPoint(self.visiblePoint, tableView.contentOffset))
    {
        [self increaseRankNow:aResult];
    }
}

- (void)increaseRankNow:(DHDBResult *)aResult
{
    if(aResult.isRemote)
    {
        return;
    }
    NSString *identifier = [self identifierForResult:aResult];
    if(!identifier || !identifier.length || (self.lastIncreasedIdentifier && [identifier isEqualToString:self.lastIncreasedIdentifier]))
    {
        return;
    }
    self.lastIncreasedIdentifier = identifier;
    NSMutableDictionary *ranks = self.ranks;
    if(ranks.count > 1000)
    {
        [self purgeDictionary:ranks];
    }
    NSNumber *rankNumber = ranks[identifier];
    NSInteger rank = 0;
    if(rankNumber)
    {
        rank = [rankNumber integerValue];
    }
    ++rank;
    ranks[identifier] = @(rank);
    [self saveDefaults:ranks];
}

- (NSInteger)rankForResult:(DHDBResult *)aResult
{
    NSNumber *rank = (self.ranks)[[self identifierForResult:aResult]];
    if(rank)
    {
        return [rank integerValue];
    }
    return 0;
}

- (NSString *)identifierForResult:(DHDBResult *)aResult
{
    return [[aResult name] stringByAppendingFormat:@" - %@", aResult.type];
}

- (void)saveDefaults:(NSMutableDictionary *)entries
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:entries forKey:@"resultSortRanks"];
}

- (void)purgeDictionary:(NSMutableDictionary *)ranks
{
    NSInteger threshold = 0;
    while(ranks.count > 500)
    {
        ++threshold;
        @autoreleasepool {
            NSMutableArray *ranksToRemove = [NSMutableArray array];
            [ranks enumerateKeysAndObjectsUsingBlock:^(id rankKey, id rank, BOOL *stop) {
                if([rank integerValue] <= threshold)
                {
                    [ranksToRemove addObject:rankKey];
                }
            }];
            [ranks removeObjectsForKeys:ranksToRemove];
        }
    }
    for(NSString *rank in [ranks allKeys])
    {
        ranks[rank] = @([ranks[rank] integerValue]-threshold);
    }
}

@end
