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

@protocol DHDBSearcherDelegate;
@interface DHDBSearcher : NSObject

@property (retain) NSThread *currentThread;
@property (retain) NSString *query;
@property (retain) NSArray *docsets;
@property (weak) id<DHDBSearcherDelegate> delegate;
@property (retain) NSString *typeLimit;

+ (DHDBSearcher *)searcherWithDocsets:(NSArray *)docsets query:(NSString *)query limitToType:(NSString *)typeLimit delegate:(id<DHDBSearcherDelegate>)delegate;
- (void)cancelSearch;
+ (void)checkForInterrupt;

@end




@protocol DHDBSearcherDelegate <NSObject>

- (void)searcher:(DHDBSearcher *)searcher foundResults:(NSArray *)results hasMore:(BOOL)hasMore;

@end

