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

#import "DHTransferFeed.h"
#import "DHDocsetTransferrer.h"

@implementation DHTransferFeed

+ (DHTransferFeed *)feedWithPath:(NSString *)path isInstalled:(BOOL)installed
{
    DHTransferFeed *feed = [[self alloc] init];
    feed.feedURL = path;
    feed.feed = [path lastPathComponent];
    feed.installed = installed;
    return feed;
}

- (BOOL)loadDocset
{
    self.docset = (self.docset) ? : [DHDocset docsetAtPath:self.feedURL];
    return self.docset != nil;
}

- (NSString *)docsetNameWithVersion:(BOOL)withVersion
{
    return (self.docset) ? self.docset.name : self.feed;
}

- (NSString *)sortName
{
    return [self docsetNameWithVersion:NO];
}

- (BOOL)isEqual:(DHFeed *)object
{
    return [self.feed isEqualToString:[object feed]];
}

- (NSString *)uniqueIdentifier // Used to find a corresponding feed from a installed docset
{
    return self.feed;
}

- (UIImage *)icon
{
    return (self.docset) ? self.docset.icon : [UIImage imageNamed:@"Other"];
}

- (void)cancelInstall
{
    self.installed = NO;
    self.installing = NO;
    self.feedResult = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:[transfersPath stringByAppendingPathComponent:self.feed]])
    {
        [fileManager moveItemAtPath:self.feedURL toPath:[transfersPath stringByAppendingPathComponent:self.feed] error:nil];
        self.feedURL = [transfersPath stringByAppendingPathComponent:self.feed];
        self.docset = nil;
        [self loadDocset];
    }
    else
    {
        NSString *trashPath = [[DHDocsetTransferrer sharedTransferrer] uniqueTrashPath];
        [fileManager moveItemAtPath:self.feedURL toPath:trashPath error:nil];
        dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
        dispatch_async(queue, ^{
            [[NSFileManager defaultManager] removeItemAtPath:trashPath error:nil];
        });
    }
}

- (BOOL)isProperlyInstalled
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self.feedURL stringByAppendingPathComponent:@"Contents/Resources/optimisedIndex.dsidx"]];
}

- (BOOL)refreshIcon
{
    if(![self.docset.hasCustomIcon boolValue])
    {
        self.docset.hasCustomIcon = nil;
        [self.docset grabIcon];
        return [self.docset.hasCustomIcon boolValue];
    }
    return NO;
}

@end
