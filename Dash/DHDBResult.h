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
#import "DHDocset.h"
#import "DHDBResultSorter.h"

@interface DHDBResult : NSObject

@property (retain) NSString *path, *anchor, *relativePath, *fullPath, *name, *originalName, *type, *platform;
@property (retain) DHDocset *docset;
@property (retain) NSMutableArray *similarResults;
@property (retain) NSString *query;
@property (retain) NSString *_declaredInPage;
@property (retain) NSNumber *distanceFromQuery;
@property (assign) BOOL isHTTP, isSO, isPHP, isRust, isGo, isSwift;
@property (assign) BOOL perfectMatch, queryIsPrefix, queryIsSuffix, perfectMatchOriginal, queryIsPrefixOfOriginal, queryIsSuffixOfOriginal, matchesQueryAtAll, fuzzyCamel, fuzzyPerfect, fuzzy, whitespaceMatch, originalMatchesQueryAtAll, fuzzyShouldIgnore;
@property (retain) NSMutableArray *highlightRanges;
@property (assign) NSInteger fragmentation;
@property (assign) NSInteger actualFragmentation;
@property (assign) BOOL isApple;
@property (assign) NSInteger appleLanguage;
@property (assign) BOOL linkIsSwift;
@property (assign) NSInteger score;
@property (assign) BOOL isAGuide;
@property (assign) BOOL isActive;
@property (assign) BOOL isRemote;
@property (retain) UIImage *_typeImage;
@property (retain) UIImage *_platformImage;
@property (retain) NSString *remoteDocsetName;
@property (retain) NSString *remoteResultURL;
@property (retain) NSString *menuDescription; // used to build the declaredInPage, set it using #<dash_entry_menuDescription=value_encoded>
@property (retain) NSString *appleObjCPath;
@property (retain) NSString *appleSwiftPath;

+ (DHDBResult *)resultWithDocset:(DHDocset *)docset resultSet:(FMResultSet *)rs;
- (void)prepareName;
- (UIImage *)typeImage;
- (UIImage *)platformImage;
- (NSString *)declaredInPage;
- (void)highlightLabel:(UILabel *)label;
- (void)highlightWithQuery:(NSString *)aQuery;
+ (NSDictionary *)highlightDictionary;
- (NSComparisonResult)compare:(DHDBResult *)aResult;
- (NSComparisonResult)levenshteinCompare:(DHDBResult *)aResult;
- (NSComparisonResult)compareFuziness:(DHDBResult *)aResult;
- (float)levenshteinDistance;
- (NSString *)sortType;
- (NSString *)duplicateHash;
- (NSString *)browserDuplicateHash;
- (DHDBResult *)activeResult;
- (NSUInteger)indexOfActiveItem;
- (void)setActiveItemByIndex:(NSUInteger)index;
- (NSString *)webViewURL;

@end
