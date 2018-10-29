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

@interface DHDocsetManager : NSObject

@property (strong) NSMutableArray *docsets;

+ (DHDocsetManager *)sharedManager;
- (void)addDocset:(DHDocset *)docset andRemoveOthers:(BOOL)shouldRemove removeOnlyEqualPaths:(BOOL)removeOnlyEqualPaths;
- (void)removeDocsetsInFolder:(NSString *)path;
- (void)moveDocsetAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (DHDocset *)docsetForDocumentationPage:(NSString *)url;
- (NSMutableArray *)enabledDocsets;
- (void)saveDefaults;
- (DHDocset *)docsetWithRelativePath:(NSString *)relativePath;
- (DHDocset *)appleAPIReferenceDocset;

@end

#define DHDocsetsChangedNotification @"DHDocsetsChangedNotification"
