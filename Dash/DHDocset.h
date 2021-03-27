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

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
@import UIKit;

@interface DHDocset : NSObject

// If you add anything that gets changed by the user (e.g. custom keyword),
// you should also add it to grabUserDataFromDocset: as well to make it
// persist when the docset gets replaced during updates
@property (strong) NSString *relativePath;
@property (strong) NSString *tempOptimisedIndexPath;
@property (strong) NSString *name;
@property (strong) NSString *bundleIdentifier;
@property (strong) NSString *platform;
@property (strong) NSString *parseFamily;
@property (strong) NSString *nameShorteningFamily;
@property (strong) NSString *declaredInStyle;
@property (assign) BOOL isJavaScriptEnabled;
@property (assign) BOOL blocksOnlineResources;
@property (assign) BOOL isDashDocset;
@property (assign) BOOL isEnabled;
@property (strong) NSString *_indexFilePath;
@property (strong) NSString *pluginKeyword;
@property (strong) NSString *suggestedKeyword;
@property (strong) NSNumber *version;
@property (strong) UIImage *_icon;
@property (strong) NSString *_path;
@property (strong) NSNumber *hasCustomIcon;
@property (strong) NSString *repoIdentifier;
@property (strong) NSString *feedIdentifier;

- (void)grabUserDataFromDocset:(DHDocset *)docset;
+ (DHDocset *)docsetAtPath:(NSString *)path;
+ (DHDocset *)docsetWithDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
+ (DHDocset *)firstDocsetInsideFolder:(NSString *)path;
+ (NSConditionLock *)stepLock;
- (void)executeBlockWithinDocsetDBConnection:(void (^)(FMDatabase *db))block readOnly:(BOOL)readOnly lockCondition:(int)lockCondition optimisedIndex:(BOOL)optimisedIndex;
- (NSString *)documentsPath;
- (NSString *)resourcesPath;
- (NSString *)contentsPath;
- (NSString *)tarixPath;
- (NSString *)tarixIndexPath;
- (UIImage *)icon;
- (UIImage *)grabIcon;
- (NSString *)path;
- (NSDictionary *)plist;
- (NSString *)sqlPath;
- (NSString *)optimisedIndexPath;
- (NSString *)indexFilePath;

#define DHLockAllAllowed 3
#define DHLockSearchOnly 2
#define DHLockDontLock -1

@end
