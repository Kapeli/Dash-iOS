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

#import "DHCheatRepoList.h"
#import "DHLatencyTester.h"

@implementation DHCheatRepoList

+ (DHCheatRepoList *)sharedCheatRepoList
{
    static dispatch_once_t pred;
    static DHCheatRepoList *_cheatList = nil;
    
    dispatch_once(&pred, ^{
        _cheatList = [[DHCheatRepoList alloc] init];
        [_cheatList setUp];
    });
    return _cheatList;
}

- (void)setUp
{
}

- (void)reload
{
    BOOL success = NO;
    NSString *url = [[[[DHLatencyTester sharedLatency] bestMirror] stringByAppendingString:@"zzz/cheatsheets/cheat.json"] stringByConvertingKapeliHttpURLToHttps];
    NSString *json = [NSString stringWithContentsOfURLString:url];
    if(json)
    {
        NSDictionary *newJSON = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        if(newJSON)
        {
            self.json = newJSON;
            success = YES;
        }
    }
    if(!success)
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[DHLatencyTester sharedLatency] performTests:YES];
        });
    }
}

- (NSMutableArray *)allCheatsheets
{
    NSMutableArray *entries = [NSMutableArray array];
    [self.json[@"cheatsheets"] enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *value, BOOL *stop) {
        DHFeed *entry = [DHFeed entryWithName:value[@"name"] platform:@"cheatsheet" icon:nil];
        entry.aliases = value[@"aliases"];
        entry._uniqueIdentifier = key;
        entry._icon = [UIImage imageNamed:@"cheatsheet"];
        [entries addObject:entry];
    }];
    if(!entries.count)
    {
        return nil;
    }
    return entries;
}

- (NSString *)versionForEntry:(DHFeed *)entry
{
    if(!self.json)
    {
        return nil;
    }
    NSString *globalVersion = self.json[@"global_version"];
    NSString *version = self.json[@"cheatsheets"][entry.uniqueIdentifier][@"version"];
    if(version)
    {
        return [NSString stringWithFormat:@"Global: %@, Individual: %@", globalVersion, version];
    }
    return nil;
}

- (NSString *)downloadURLForEntry:(DHFeed *)entry
{
    if(!self.json)
    {
        return nil;
    }
    return [[[[DHLatencyTester sharedLatency] bestMirror] stringByAppendingFormat:@"zzz/cheatsheets/%@.tgz", entry.uniqueIdentifier] stringByConvertingKapeliHttpURLToHttps];
}

@end
