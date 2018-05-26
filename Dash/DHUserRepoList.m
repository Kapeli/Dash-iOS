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

#import "DHUserRepoList.h"
#import "DHLatencyTester.h"

@implementation DHUserRepoList

+ (DHUserRepoList *)sharedUserRepoList
{
    static dispatch_once_t pred;
    static DHUserRepoList *_userList = nil;
    
    dispatch_once(&pred, ^{
        _userList = [[DHUserRepoList alloc] init];
        [_userList setUp];
    });
    return _userList;
}

- (void)setUp
{
}

- (void)reload
{
    BOOL success = NO;
    NSString *url = [[[[DHLatencyTester sharedLatency] bestMirror] stringByAppendingString:@"zzz/user_contributed/build/index.json"] stringByConvertingKapeliHttpURLToHttps];
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

- (NSMutableArray *)allUserDocsets
{
    NSMutableArray *entries = [NSMutableArray array];
    [self.json[@"docsets"] enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *value, BOOL *stop) {
        if([value[@"minimum_dash_version"] integerValue] <= 1 && (!value[@"enabled"] || [value[@"enabled"] boolValue]))
        {
            NSString *platform = [@"usercontrib" stringByAppendingString:key];
            DHFeed *entry = [DHFeed entryWithName:value[@"name"] platform:platform icon:nil];
            entry.aliases = value[@"aliases"];
            entry._isMajorVersioned = [value[@"major_versioned"] boolValue];
            entry._uniqueIdentifier = key;
            entry.authorLinkText = value[@"author"][@"name"];
            entry.authorLinkHref = [NSString stringWithFormat:@"https://github.com/Kapeli/Dash-User-Contributions/tree/master/docsets/%@#readme", entry.uniqueIdentifier];
            BOOL hasVersions = [self allVersionsForEntry:entry].count > 0;
            entry.doesNotHaveVersions = !hasVersions;
            entry._icon = [self imageForEntry:entry];
            [entries addObject:entry];
        }
    }];
    if(!entries.count)
    {
        return nil;
    }
    return entries;
}

- (UIImage *)imageForEntry:(DHFeed *)entry
{
    NSString *base64 = self.json[@"docsets"][entry.uniqueIdentifier][@"icon@2x"];
    if(base64.length)
    {
        return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters] scale:2];
    }
    return nil;
}

- (NSString *)versionForEntry:(DHFeed *)entry
{
    NSString *version = self.json[@"docsets"][entry.uniqueIdentifier][@"version"];
    if(version)
    {
        return version;
    }
    return nil;
}

- (NSMutableArray *)allVersionsForEntry:(DHFeed *)entry
{
    NSMutableArray *versions = [NSMutableArray array];
    NSArray *jsonVersions = self.json[@"docsets"][entry.uniqueIdentifier][@"specific_versions"];
    for(NSDictionary *jsonVersion in jsonVersions)
    {
        if([jsonVersion[@"archive"] length] && [jsonVersion[@"version"] length])
        {
            [versions addObject:[jsonVersion[@"version"] substringToString:@"/"]];
        }
    }
    if(!versions.count)
    {
        return nil;
    }
    return versions;
}

- (NSString *)downloadURLForEntry:(DHFeed *)entry
{
    if(!self.json)
    {
        return nil;
    }
    return [[[[DHLatencyTester sharedLatency] bestMirror] stringByAppendingFormat:@"zzz/user_contributed/build/%@/%@", entry.uniqueIdentifier, self.json[@"docsets"][entry.uniqueIdentifier][@"archive"]] stringByConvertingKapeliHttpURLToHttps];
}

- (NSString *)downloadURLForVersionedEntry:(DHFeed *)versionedEntry parentEntry:(DHFeed *)parentEntry
{
    for(NSDictionary *specificVersion in self.json[@"docsets"][parentEntry.uniqueIdentifier][@"specific_versions"])
    {
        if([[specificVersion[@"version"] substringToString:@"/"] isEqualToString:versionedEntry.uniqueIdentifier])
        {
            return [[[[DHLatencyTester sharedLatency] bestMirror] stringByAppendingFormat:@"zzz/user_contributed/build/%@/%@", parentEntry.uniqueIdentifier, specificVersion[@"archive"]] stringByConvertingKapeliHttpURLToHttps];
        }
    }
    return nil;
}

@end
