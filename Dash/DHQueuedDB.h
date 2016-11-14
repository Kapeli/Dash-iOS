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
#import "FMResultSet.h"
#import "DHDBResult.h"

@interface DHQueuedDB : NSObject

@property (retain, nonatomic) NSString *query;
@property (retain, nonatomic) NSMutableArray *queryQueue;
@property (retain, nonatomic) FMResultSet *currentRS;
@property (retain, nonatomic) NSString *dbPath;
@property (retain, nonatomic) FMDatabase *db;
@property (retain, nonatomic) DHDocset *docset;
@property (assign, nonatomic) BOOL hadPerfect;
@property (retain, nonatomic) NSMutableDictionary *resultDictionary;
@property (retain, nonatomic) NSConditionLock *lock;

+ (DHQueuedDB *)queueWithDocset:(DHDocset *)docset query:(NSString *)query typeLimit:(NSString *)typeLimit isFuzzy:(BOOL)isFuzzy;
- (BOOL)next;
- (BOOL)step;
- (DHDBResult *)currentDBResult;
- (void)addResultToResultDictionary:(DHDBResult *)result;
- (void)sortResultDictionary;
- (NSMutableArray *)resultsForType:(NSString *)type;

@end
