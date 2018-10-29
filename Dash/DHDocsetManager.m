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

#import "DHDocsetManager.h"

@implementation DHDocsetManager

+ (DHDocsetManager *)sharedManager
{
    static dispatch_once_t pred;
    static DHDocsetManager *_docsetManager = nil;
    
    dispatch_once(&pred, ^{
        _docsetManager = [[DHDocsetManager alloc] init];
        [_docsetManager setUp];
    });
    return _docsetManager;
}

- (void)setUp
{
    NSMutableArray *docsets = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(NSDictionary *dictionary in [[NSUserDefaults standardUserDefaults] objectForKey:@"docsets"])
    {
        DHDocset *docset = [DHDocset docsetWithDictionaryRepresentation:dictionary];
        if([fileManager fileExistsAtPath:docset.path])
        {
            [docsets addObject:docset];            
        }
    }
    self.docsets = docsets;
}

- (void)saveDefaults
{
    NSMutableArray *dictionaries = [NSMutableArray array];
    for(DHDocset *docset in self.docsets)
    {
        [dictionaries addObject:[docset dictionaryRepresentation]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:dictionaries forKey:@"docsets"];
}

- (void)addDocset:(DHDocset *)docset andRemoveOthers:(BOOL)shouldRemove removeOnlyEqualPaths:(BOOL)removeOnlyEqualPaths
{
    NSString *folder = [docset.path stringByDeletingLastPathComponent];
    if(!docset)
    {
        return;
    }
    NSInteger index = [self.docsets indexOfObject:docset];
    DHDocset *replaced = nil;
    if(index != NSNotFound)
    {
        replaced = self.docsets[index];
        [self.docsets removeObjectAtIndex:index];
    }
    if(shouldRemove)
    {
        NSIndexSet *toRemove = [self.docsets indexesOfObjectsPassingTest:^BOOL(DHDocset *obj, NSUInteger idx, BOOL *stop) {
            if(!removeOnlyEqualPaths)
            {
                if([[obj.path stringByDeletingLastPathComponent] isCaseInsensitiveEqual:folder])
                {
                    return YES;
                }
            }
            else if([obj.path isCaseInsensitiveEqual:docset.path])
            {
                return YES;
            }
            return NO;
        }];
        if(index == NSNotFound && toRemove.count)
        {
            index = toRemove.firstIndex;
            replaced = self.docsets[index];
        }
        [self.docsets removeObjectsAtIndexes:toRemove];
    }
    if(replaced)
    {
        [docset grabUserDataFromDocset:replaced];
        [self.docsets insertObject:docset atIndex:index];
    }
    else
    {
        [self.docsets addObject:docset];
    }
    [self saveDefaults];
    [[NSNotificationCenter defaultCenter] postNotificationName:DHDocsetsChangedNotification object:self];
}

- (void)removeDocsetsInFolder:(NSString *)path
{
    [self.docsets removeObjectsAtIndexes:[self.docsets indexesOfObjectsPassingTest:^BOOL(DHDocset *obj, NSUInteger idx, BOOL *stop) {
        if([[obj.path stringByDeletingLastPathComponent] isCaseInsensitiveEqual:path] || [obj.path isCaseInsensitiveEqual:path])
        {
            return YES;
        }
        return NO;
    }]];
    [self saveDefaults];
    [[NSNotificationCenter defaultCenter] postNotificationName:DHDocsetsChangedNotification object:self];
}

- (void)moveDocsetAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    DHDocset *toMove = self.docsets[fromIndex];
    [self.docsets removeObjectAtIndex:fromIndex];
    [self.docsets insertObject:toMove atIndex:toIndex];
    [self saveDefaults];
}

- (DHDocset *)docsetForDocumentationPage:(NSString *)url
{
    if([url hasPrefix:@"dash-apple-api://"])
    {
        return [self appleAPIReferenceDocset];
    }
    url = [[url stringByDeletingPathFragment] stringByReplacingPercentEscapes];
    for(DHDocset *docset in [NSArray arrayWithArray:self.docsets])
    {
        NSString *path = docset.path;
        if(path && [url rangeOfString:path].location != NSNotFound)
        {
            return docset;
        }
    }
    return nil;
}

- (DHDocset *)docsetWithRelativePath:(NSString *)relativePath
{
    for(DHDocset *docset in self.docsets)
    {
        if([docset.relativePath isEqualToString:relativePath])
        {
            return docset;
        }
    }
    return nil;
}

- (NSMutableArray *)enabledDocsets
{
    NSMutableArray *enabled = [NSMutableArray array];
    for(DHDocset *docset in self.docsets)
    {
        if(docset.isEnabled)
        {
            [enabled addObject:docset];
        }
    }
    return enabled;
}

- (DHDocset *)appleAPIReferenceDocset
{
    NSMutableOrderedSet *toCheck = [NSMutableOrderedSet orderedSet];
    [toCheck addObjectsFromArray:self.enabledDocsets];
    [toCheck addObjectsFromArray:self.docsets];
    for(DHDocset *docset in toCheck)
    {
        if([[[docset relativePath] lastPathComponent] isEqualToString:@"Apple_API_Reference.docset"] && [[NSFileManager defaultManager] fileExistsAtPath:[[docset documentsPath] stringByAppendingPathComponent:@"Apple Docs Helper"]] && ![[[docset plist] objectForKey:@"DashDocSetIsGeneratedForiOSCompatibility"] boolValue])
        {
            return docset;
        }
    }
    return nil;
}

@end
