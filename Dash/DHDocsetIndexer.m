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

#import "DHDocsetIndexer.h"
#import "DHTypes.h"
#import "DHFeedResult.h"

@implementation DHDocsetIndexer

+ (DHDocsetIndexer *)indexerForDocset:(DHDocset *)docset delegate:(id)delegate
{
    DHDocsetIndexer *indexer = [[DHDocsetIndexer alloc] init];
    indexer.docset = docset;
    indexer.delegate = delegate;
    if(![delegate isCancelled])
    {
        [delegate setRightDetail:@"Indexing..."];
        [indexer prepare];
        [indexer index];
    }
    return indexer;
}

- (void)prepare
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.docset.optimisedIndexPath error:nil];
    [fileManager removeItemAtPath:[self.docset.optimisedIndexPath stringByAppendingString:@"-journal"] error:nil];
    [fileManager removeItemAtPath:self.docset.tempOptimisedIndexPath error:nil];
    [fileManager removeItemAtPath:[self.docset.tempOptimisedIndexPath stringByAppendingString:@"-journal"] error:nil];
    [self.docset executeBlockWithinDocsetDBConnection:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:([self.docset isDashDocset]) ? @"SELECT COUNT(id) from searchIndex" : @"SELECT COUNT(Z_PK) FROM ZTOKEN"];
        if([rs next])
        {
            self.progressCount = [rs intForColumnIndex:0];
        }
#ifdef DEBUG
        [db setLogsErrors:NO];
#endif
        rs = [db executeQuery:@"SELECT COUNT(Z_PK) FROM ZNODE WHERE ZPRIMARYPARENT IS NOT NULL AND ZKDOCUMENTTYPE < 2 AND ZKNODETYPE = 'folder' AND (ZKPATH NOT LIKE 'navigation%' OR ZKPATH IS NULL)"];
        if([rs next])
        {
            self.progressCount += [rs intForColumnIndex:0];
        }
        else
        {
            rs = [db executeQuery:@"SELECT COUNT(z.Z_PK) FROM ZNODE z, ZNODEURL u WHERE z.Z_PK = u.ZNODE AND z.ZPRIMARYPARENT IS NOT NULL AND z.ZKDOCUMENTTYPE < 2 AND z.ZKNODETYPE = 2 AND (u.ZPATH NOT LIKE 'navigation%' OR u.ZPATH IS NULL)"];
            if([rs next])
            {
                self.hasV2Guides = YES;
                self.progressCount += [rs intForColumnIndex:0];
            }
        }
    } readOnly:YES lockCondition:DHLockDontLock optimisedIndex:NO];
}

- (void)index
{
    @autoreleasepool {
        @try {
            [self.docset executeBlockWithinDocsetDBConnection:^(FMDatabase *indexDB) {
                [self.docset executeBlockWithinDocsetDBConnection:^(FMDatabase *db) {
                    [self checkIfCancelled];
                    [indexDB beginDeferredTransaction];
                    [indexDB executeUpdate:@"CREATE TABLE searchIndex(rowid INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)"];
                    [indexDB executeUpdate:@"CREATE VIRTUAL TABLE queryIndex USING FTS4 (perfect, prefix, suffixes, matchinfo=fts3, compress=dashCompress, uncompress=dashUncompress, tokenize=simple XX [* ])"];
                    [indexDB executeUpdate:@"CREATE VIEW IF NOT EXISTS wholeIndex AS SELECT queryIndex.rowid AS rowid, name, type, path, perfect, prefix, suffixes FROM searchIndex JOIN queryIndex ON searchIndex.rowid = queryIndex.rowid;"];
                    [indexDB executeUpdate:@"CREATE TRIGGER index_insert INSTEAD OF INSERT ON wholeIndex\n"
                                            "BEGIN\n"
                                            "INSERT INTO searchIndex (name, type, path) VALUES (NEW.name, NEW.type, NEW.path);\n"
                                            "INSERT INTO queryIndex (rowid, perfect, prefix, suffixes) VALUES (last_insert_rowid(), NEW.perfect, NEW.prefix, NEW.suffixes);\n"
                                            "END;\n"];
                    BOOL isDash = self.docset.isDashDocset;
                    NSString *platform = self.docset.platform;
                    BOOL isMacOSX = [platform isEqualToString:@"macosx"] || [platform isEqualToString:@"osx"];
                    BOOL isApple = isMacOSX || [platform isEqualToString:@"ios"] || [platform isEqualToString:@"iphoneos"] || [platform isEqualToString:@"watchos"] || [platform isEqualToString:@"tvos"];
                    NSString *indexQuery = (isDash) ? @"SELECT path, 1, name, type, rowid FROM searchIndex " : @"SELECT f.ZPATH, m.ZANCHOR, t.ZTOKENNAME, ty.ZTYPENAME, t.rowid FROM ZTOKEN t, ZTOKENTYPE ty, ZFILEPATH f, ZTOKENMETAINFORMATION m WHERE ty.Z_PK = t.ZTOKENTYPE AND f.Z_PK = m.ZFILE AND m.ZTOKEN = t.Z_PK ";
                    BOOL hasTOKENUSR = NO;
                    if(!isDash && isApple)
                    {
                        hasTOKENUSR = [db columnExists:@"ZTOKENUSR" inTableWithName:@"ZTOKEN"];
                        if(hasTOKENUSR)
                        {
                            indexQuery = @"SELECT CASE WHEN m.ZFILE IS NOT NULL THEN f.ZPATH ELSE u.ZPATH END, CASE WHEN m.ZANCHOR IS NOT NULL THEN m.ZANCHOR ELSE u.ZANCHOR END, t.ZTOKENNAME, ty.ZTYPENAME, t.rowid, t.ZTOKENUSR FROM ZTOKEN t, ZTOKENTYPE ty, ZTOKENMETAINFORMATION m LEFT JOIN ZFILEPATH f ON m.ZFILE = f.Z_PK LEFT JOIN ZNODEURL u ON t.ZPARENTNODE = u.ZNODE WHERE ty.Z_PK = t.ZTOKENTYPE AND m.ZTOKEN = t.Z_PK ";
                        }
                    }
                    indexQuery = [indexQuery stringByAppendingString:[[DHTypes sharedTypes] unifiedSQLiteOrder:isDash platform:platform]];
                    if(hasTOKENUSR)
                    {
                        indexQuery = [indexQuery stringByReplacingOccurrencesOfString:@" ORDER BY " withString:@" ORDER BY f.ZPATH is NULL, "];
                    }
                    [self checkIfCancelled];

                    FMResultSet *rs = [db executeQuery:indexQuery];
                    BOOL next = [rs next];
                    BOOL isFetchingGuides = NO;
                    NSMutableSet *duplicates = [NSMutableSet set];
                    NSMutableDictionary *tokenUsers = [NSMutableDictionary dictionary];
                    NSInteger count = 0;
                    BOOL firstLoop = YES;
                    while(next || firstLoop)
                    {
                        @autoreleasepool {
                            NSString *anchor = nil;
                            if(!next && firstLoop)
                            {
                                firstLoop = NO;
                                goto next;
                            }
                            firstLoop = NO;
                            [self checkIfCancelled];
                            [self incrementProgressBy:1];
                            anchor = (isDash) ? @"" : [rs stringForColumnIndex:1];
                            if(isFetchingGuides || !(isMacOSX && anchor && anchor.length && [anchor rangeOfString:@"java" options:NSCaseInsensitiveSearch].location != NSNotFound))
                            {
                                NSString *path = [rs stringForColumnIndex:0];
                                NSString *name = [rs stringForColumnIndex:2];
                                NSString *type = [rs stringForColumnIndex:3];
                                type = [DHTypes singularFromEncoded:type notFoundReturn:@"Variable"];
                                if(hasTOKENUSR && !isFetchingGuides)
                                {
                                    NSString *tokenUser = [rs stringForColumnIndex:5];
                                    if(tokenUser && tokenUser.length)
                                    {
                                        if(!path)
                                        {
                                            NSArray *data = tokenUsers[tokenUser];
                                            path = data[0];
                                            anchor = data[1];
                                        }
                                        else
                                        {
                                            tokenUsers[tokenUser] = @[path, (anchor) ? [anchor stringByAppendingString:@"-dash-swift-hack"] : @"-dash-swift-hack"];
                                        }
                                    }
                                }
                                if((!path || !path.length) && hasTOKENUSR && isApple && ([name hasPrefix:@"WKInterface"] || [name hasPrefix:@"WKUserNotificationInterface"]) && [type isEqualToString:@"cl"])
                                {
                                    path = [NSString stringWithFormat:@"documentation/WatchKit/Reference/%@_class/index.html", name];
                                }
                                if(isFetchingGuides)
                                {
                                    if(!path || !path.length)
                                    {
                                        path = [@"ghttp://" stringByAppendingString:type];
                                    }
                                    else
                                    {
                                        path = [@"gfile://" stringByAppendingString:path];
                                    }
                                    NSInteger docType = [rs intForColumnIndex:4];
                                    type = (docType == 0) ? @"Guide" : @"Sample";
                                }
                                if(!path || !path.length || !name || !name.length || !type || !type.length)
                                {
                                    goto next;
                                }
                                if(anchor && anchor.length)
                                {
                                    path = [path stringByAppendingFormat:@"#%@", anchor];
                                }
                                if(name.length > 200)
                                {
                                    name = [name substringToIndex:200];
                                }
                                NSString *whitespaceFree = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
                                if(whitespaceFree.length)
                                {
                                    if(isApple)
                                    {
                                        if([name isEqualToString:@"NSMutableAttributedString"] && [path contains:@"UIKit/Reference/NSMutableAttributedString_UIKit_Additions/"])
                                        {
                                            path = [path stringByReplacingOccurrencesOfString:@"UIKit/Reference/NSMutableAttributedString_UIKit_Additions/" withString:@"Cocoa/Reference/Foundation/Classes/NSMutableAttributedString_Class/"];
                                        }
                                        else if([name isEqualToString:@"NSView"] && [path contains:@"MacOSXServer/"])
                                        {
                                            NSString *hash = [path substringFromString:@"#"];
                                            path = [[[[path substringToString:@"MacOSXServer/"] stringByAppendingString:@"Cocoa/Reference/ApplicationKit/Classes/NSView_Class/index.html"] stringByAppendingString:@"#"] stringByAppendingString:hash];
                                        }
                                        else if([name isEqualToString:@"NSATSTypesetter"] && [path contains:@"Cocoa/Reference/Foundation/Classes/NSXMLDTD_Class/"])
                                        {
                                            path = [path stringByReplacingOccurrencesOfString:@"Cocoa/Reference/Foundation/Classes/NSXMLDTD_Class/" withString:@"Cocoa/Reference/ApplicationKit/Classes/NSATSTypesetter_Class/"];
                                        }
                                        else if([name isEqualToString:@"NSDockTile"] && [path contains:@"Cocoa/Reference/NSTextInputClient_Protocol/"])
                                        {
                                            path = [path stringByReplacingOccurrencesOfString:@"Cocoa/Reference/NSTextInputClient_Protocol/" withString:@"Cocoa/Reference/NSDockTile_Class/"];
                                        }
                                        else if([name isEqualToString:@"NSFetchRequest"] && [path contains:@"Cocoa/Reference/CoreDataFramework/Classes/NSEntityDescription_Class/"])
                                        {
                                            path = [path stringByReplacingOccurrencesOfString:@"Cocoa/Reference/CoreDataFramework/Classes/NSEntityDescription_Class/" withString:@"Cocoa/Reference/CoreDataFramework/Classes/NSFetchRequest_Class/"];
                                        }
                                        else if([name isEqualToString:@"NSManagedObject"] && [path contains:@"Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectID_Class/"])
                                        {
                                            path = [path stringByReplacingOccurrencesOfString:@"Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectID_Class/" withString:@"Cocoa/Reference/CoreDataFramework/Classes/NSManagedObject_Class/"];
                                        }
                                        else if([@[@"Menu", @"DRBurnRef", @"DRFileRef", @"DRTrackRef", @"CSIdentity", @"AXObserver", @"DREraseRef", @"DRDeviceRef", @"DRFolderRef", @"CSIdentityQuery", @"DRCDTextBlockRef", @"CSIdentityAuthority", @"DRNotificationCenterRef"] containsObject:name] && ![path contains:@"#"] && [type isCaseInsensitiveEqual:@"cl"])
                                        {
                                            NSString *fixName = name;
                                            if(![name hasSuffix:@"Ref"])
                                            {
                                                fixName = [name stringByAppendingString:@"Ref"];
                                            }
                                            path = [path stringByAppendingFormat:@"#//apple_ref/c/tdef/%@", fixName];
                                        }
                                    }
                                    NSString *duplicateHash = [NSString stringWithFormat:@"%@%@%@", name, type, path];
                                    if(![duplicates containsObject:duplicateHash])
                                    {
                                        [duplicates addObject:duplicateHash];
                                        [indexDB executeUpdate:@"INSERT INTO wholeIndex(name, type, path, perfect, prefix, suffixes) VALUES(?, ?, ?, ?, ?, ?);", name, type, path, [whitespaceFree stringByReplacingSpecialFTSCharacters], [whitespaceFree FTSPrefix], [whitespaceFree allFTSSuffixes]];
                                        ++count;
                                        if(count % 2500 == 0)
                                        {
                                            [indexDB commit];
                                            [indexDB beginDeferredTransaction];
                                        }
                                        [self checkIfCancelled];
                                    }
                                }
                            }
                        next:
                            if(next)
                            {
                                next = [rs next];
                            }
                            if(!next && !isFetchingGuides)
                            {
#ifdef DEBUG
                                [db setLogsErrors:NO];
#endif
                                rs = [db executeQuery:(!self.hasV2Guides) ? @"SELECT ZKPATH, ZKANCHOR, ZKNAME, ZKURL, ZKDOCUMENTTYPE, rowid FROM ZNODE WHERE ZPRIMARYPARENT IS NOT NULL AND ZKDOCUMENTTYPE < 2 AND ZKNODETYPE = 'folder' AND (ZKPATH NOT LIKE 'navigation%' OR ZKPATH IS NULL)" : @"SELECT u.ZPATH, u.ZANCHOR, z.ZKNAME, u.ZBASEURL, z.ZKDOCUMENTTYPE, z.rowid FROM ZNODE z, ZNODEURL u WHERE z.Z_PK = u.ZNODE AND z.ZPRIMARYPARENT IS NOT NULL AND z.ZKDOCUMENTTYPE < 2 AND z.ZKNODETYPE = 2 AND (u.ZPATH NOT LIKE 'navigation%' OR u.ZPATH IS NULL)"];
                                next = [rs next];
                                isFetchingGuides = YES;
                            }
                        }
                    }
                    [self checkIfCancelled];
                    [indexDB executeUpdate:[NSString stringWithFormat:@"INSERT INTO queryIndex(queryIndex) VALUES('optimize');"]];
                    [self checkIfCancelled];
                    [indexDB commit];
                } readOnly:YES lockCondition:DHLockDontLock optimisedIndex:NO];
            } readOnly:NO lockCondition:DHLockDontLock optimisedIndex:YES];
        }
        @catch(NSException *exception) {
            if(![[exception name] isEqualToString:@"Indexing Interrupt"])
            {
                NSLog(@"FIXME: exception in index");
                NSLog(@"%@", exception);
                NSLog(@"%@", [NSThread callStackSymbols]);
            }
        }
        @finally {
            if(![self.delegate isCancelled])
            {
                if(self.currentProgress < self.progressCount && self.progressCount > 0)
                {
                    [self incrementProgressBy:self.progressCount-self.currentProgress];
                }
            }
        }
    }
}

- (void)incrementProgressBy:(NSUInteger)increment;
{
    self.currentProgress += increment;
    if(self.currentProgress > self.progressCount)
    {
        self.currentProgress = self.progressCount;
    }
    double currentPercent = (double)self.currentProgress/self.progressCount;
    double delta = currentPercent - self.lastDisplayedPercent;
    if(delta > 0.005f || delta < -0.005f || (self.currentProgress == self.progressCount && self.lastDisplayedPercent < 1.0))
    {
        self.lastDisplayedPercent = currentPercent;
        [self.delegate setIndexingProgress:currentPercent];
    }
}

- (void)checkIfCancelled
{
    if([self.delegate isCancelled])
    {
        [NSException raise:@"Indexing Interrupt" format:@""];
    }
}

@end
