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

#import "DHDBNestedResultSorter.h"
#import "DHDBResult.h"

@implementation DHDBNestedResultSorter

static DHDBNestedResultSorter *_sorter = nil;

+ (DHDBNestedResultSorter *)sharedSorter
{
    @synchronized([DHDBNestedResultSorter class])
	{
		if(!_sorter)
		{
			_sorter = [[DHDBNestedResultSorter alloc] init];
            [_sorter setUp];
		}
	}
	return _sorter;
}

- (void)setUp
{
    self.ranks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"nestedResultSortRanks"] mutableCopy];
    if(!self.ranks)
    {
        self.ranks = [NSMutableDictionary dictionary];
    }
}

- (DHDBResult *)sortNestedResults:(DHDBResult *)parentResult
{
    NSMutableArray *allResults = [parentResult similarResults];
    [allResults insertObject:parentResult atIndex:0];
    parentResult.similarResults = [NSMutableArray array];
    [parentResult setIsActive:NO];
    
    NSCharacterSet *symbolsSet = [NSCharacterSet characterSetWithCharactersInString:@":./\\#"];
    [allResults sortUsingComparator:^NSComparisonResult(DHDBResult *obj1, DHDBResult *obj2) {
        NSInteger rank1 = [self rankForResult:obj1];
        NSInteger rank2 = [self rankForResult:obj2];
        if(rank1 > rank2)
        {
            return NSOrderedAscending;
        }
        else if(rank2 > rank1)
        {
            return NSOrderedDescending;
        }
        if(obj1.perfectMatchOriginal && !obj2.perfectMatchOriginal)
        {
            return NSOrderedAscending;
        }
        else if(obj2.perfectMatchOriginal && !obj1.perfectMatchOriginal)
        {
            return NSOrderedDescending;
        }
        if(obj1.queryIsPrefixOfOriginal && !obj2.queryIsPrefixOfOriginal)
        {
            return NSOrderedAscending;
        }
        else if(obj2.queryIsPrefixOfOriginal && !obj1.queryIsPrefixOfOriginal)
        {
            return NSOrderedDescending;
        }
        if(obj1.queryIsSuffixOfOriginal && !obj2.queryIsSuffixOfOriginal)
        {
            return NSOrderedAscending;
        }
        else if(obj2.queryIsSuffixOfOriginal && !obj1.queryIsSuffixOfOriginal)
        {
            return NSOrderedDescending;
        }
        if(obj1.originalMatchesQueryAtAll && !obj2.originalMatchesQueryAtAll)
        {
            return NSOrderedAscending;
        }
        else if(obj2.originalMatchesQueryAtAll && !obj1.originalMatchesQueryAtAll)
        {
            return NSOrderedDescending;
        }
        NSInteger count1 = [[[obj1 declaredInPage] stringByReplacingOccurrencesOfString:@"..." withString:@""] countOfCharactersInSet:symbolsSet];
        NSInteger count2 = [[[obj2 declaredInPage] stringByReplacingOccurrencesOfString:@"..." withString:@""] countOfCharactersInSet:symbolsSet];
        if(count1 < count2)
        {
            return NSOrderedAscending;
        }
        else if(count2 < count1)
        {
            return NSOrderedDescending;
        }
        return [[obj1 declaredInPage] localizedCaseInsensitiveCompare:[obj2 declaredInPage]];
    }];
    
    DHDBResult *newParent = allResults[0];
    [allResults removeObjectAtIndex:0];
    newParent.similarResults = allResults;
    [newParent setIsActive:YES];
    return newParent;
}

- (NSInteger)rankForResult:(DHDBResult *)aResult
{
    NSMutableDictionary *nestedEntry = (self.ranks)[[aResult name]];
    if(!nestedEntry)
    {
        return 0;
    }
    NSNumber *rank = nestedEntry[[aResult relativePath]];
    if(!rank)
    {
        return 0;
    }
    return [rank integerValue];
}

- (void)increaseRankForResult:(DHDBResult *)aResult
{
    if(aResult.isRemote)
    {
        return;
    }
    NSMutableDictionary *entries = self.ranks;
    if(entries.count > 500)
    {
        [self purgeDictionary:entries];
    }
    NSMutableDictionary *nestedEntry = entries[[aResult name]];
    if(!nestedEntry)
    {
        nestedEntry = [NSMutableDictionary dictionaryWithObject:@1 forKey:[aResult relativePath]];
        entries[[aResult name]] = nestedEntry;
    }
    else
    {
        nestedEntry = [NSMutableDictionary dictionaryWithDictionary:nestedEntry];
        NSNumber *rank = nestedEntry[[aResult relativePath]];
        if([rank integerValue] <= 0)
        {
            nestedEntry[[aResult relativePath]] = @1;
        }
        else
        {
            nestedEntry[[aResult relativePath]] = @([rank integerValue]+1);
        }
        entries[[aResult name]] = nestedEntry;
    }
    [self saveDefaults:entries];
}


- (void)saveDefaults:(NSMutableDictionary *)entries
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:entries forKey:@"nestedResultSortRanks"];
}

- (void)purgeDictionary:(NSMutableDictionary *)entries
{
    NSInteger threshold = 0;
    while(entries.count > 250)
    {
        ++threshold;
        @autoreleasepool {
            NSMutableArray *entriesToRemove = [NSMutableArray array];
            __block NSMutableDictionary *toReplace = [NSMutableDictionary dictionary];
            [entries enumerateKeysAndObjectsUsingBlock:^(id entryKey, id entry, BOOL *stop) {
                NSMutableArray *nestedToRemove = [NSMutableArray array];
                [entry enumerateKeysAndObjectsUsingBlock:^(id nestedKey, id nested, BOOL *stop2) {
                    if([nested integerValue] <= threshold)
                    {
                        [nestedToRemove addObject:nestedKey];
                    }
                }];
                entry = [NSMutableDictionary dictionaryWithDictionary:entry];
                [entry removeObjectsForKeys:nestedToRemove];
                if([entry count] == 0)
                {
                    [entriesToRemove addObject:entryKey];
                }
                else
                {
                    toReplace[entryKey] = entry;
                }
            }];
            [entries removeObjectsForKeys:entriesToRemove];
            [toReplace enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                entries[key] = obj;
            }];
        }
    }
    for(NSString *entryKey in [entries allKeys])
    {
        NSMutableDictionary *nestedEntry = entries[entryKey];
        for(NSString *nestedKey in [nestedEntry allKeys])
        {
            nestedEntry[nestedKey] = @([nestedEntry[nestedKey] integerValue]-threshold);
        }
    }
}

@end
