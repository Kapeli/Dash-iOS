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

#import "DHQueuedDB.h"
#import "DHDBSearcher.h"

@implementation DHQueuedDB

+ (DHQueuedDB *)queueWithDocset:(DHDocset *)docset query:(NSString *)query typeLimit:(NSString *)typeLimit isFuzzy:(BOOL)isFuzzy
{
    DHQueuedDB *queue = [[DHQueuedDB alloc] init];
    queue.resultDictionary = [NSMutableDictionary dictionary];
    queue.query = query;
    queue.queryQueue = [NSMutableArray array];
    queue.dbPath = docset.optimisedIndexPath;
    queue.docset = docset;
    queue.db = [FMDatabase databaseWithPath:queue.dbPath];
    queue.lock = [DHDocset stepLock];
    [queue.lock lock];
    BOOL didOpen = [queue.db openWithFlags:SQLITE_OPEN_READONLY];
    [queue.db registerFTSExtensions];
    [queue.db setLogsErrors:YES];
    [queue.lock unlockWithCondition:DHLockSearchOnly];
    if(!didOpen)
    {
        return nil;
    }
    if(!isFuzzy)
    {
        NSString *ftsEscapedQuery = [query stringByReplacingSpecialFTSCharacters];
        NSString *prefixedQuery = [ftsEscapedQuery stringByAppendingString:@"*"];
        NSString *likeQuery = [prefixedQuery stringByReplacingOccurrencesOfString:@"*" withString:@"%"];
        [queue.queryQueue addObject:[DHQueuedDB queuedQueryDictionary:@"SELECT path, name, type FROM searchIndex s, queryIndex q WHERE q.rowid = s.rowid AND q.perfect MATCH ?" andArgs:@[ftsEscapedQuery]]];
        [queue.queryQueue addObject:[DHQueuedDB queuedQueryDictionary:@"SELECT path, name, type FROM searchIndex s, queryIndex q WHERE q.rowid = s.rowid AND q.prefix MATCH ? LIMIT 200" andArgs:@[prefixedQuery]]];
        [queue.queryQueue addObject:[DHQueuedDB queuedQueryDictionary:@"SELECT path, name, type FROM searchIndex s, queryIndex q WHERE q.rowid = s.rowid AND q.suffixes MATCH ? AND q.prefix NOT LIKE ? LIMIT 200" andArgs:@[ftsEscapedQuery, likeQuery]]];
        [queue.queryQueue addObject:[DHQueuedDB queuedQueryDictionary:@"SELECT path, name, type FROM searchIndex s, queryIndex q WHERE q.rowid = s.rowid AND q.suffixes MATCH ? AND q.prefix NOT LIKE ? LIMIT 200" andArgs:@[[NSString stringWithFormat:@"%@ NOT %@", prefixedQuery, ftsEscapedQuery], likeQuery]]];
    }
    else if(query.length > 2)
    {
        NSString *escapedQuery = [query stringByReplacingOccurrencesOfString:@"~" withString:@"~~"];
        escapedQuery = [escapedQuery stringByReplacingOccurrencesOfString:@"_" withString:@"~_"];
        escapedQuery = [escapedQuery stringByReplacingOccurrencesOfString:@"%" withString:@"~%"];
        NSString *wildcardEverywhere = [escapedQuery stringByAddingWildcardsEverywhere:@"~"];
        [queue.queryQueue addObject:[DHQueuedDB queuedQueryDictionary:@"SELECT path, name, type FROM searchIndex WHERE name LIKE ? ESCAPE '~' AND name NOT LIKE ? ESCAPE '~' LIMIT 300;" andArgs:@[wildcardEverywhere, [[@"%" stringByAppendingString:escapedQuery] stringByAppendingString:@"%"]]]];
    }
    if(typeLimit)
    {
        for(NSMutableDictionary *dictionary in queue.queryQueue)
        {
            [dictionary[@"args"] insertObject:typeLimit atIndex:0];
            dictionary[@"sqlQuery"] = [dictionary[@"sqlQuery"] stringByReplacingOccurrencesOfString:@" WHERE " withString:@" WHERE type = ? AND "];
        }
    }
    return queue;
}

+ (NSDictionary *)queuedQueryDictionary:(NSString *)aQuery andArgs:(NSArray *)args
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:aQuery, @"sqlQuery", [args mutableCopy], @"args", nil];
}

- (BOOL)next
{
    [DHDBSearcher checkForInterrupt];
    [self.lock lock];
    if([self.currentRS next])
    {
        [self.lock unlockWithCondition:DHLockSearchOnly];
        [DHDBSearcher checkForInterrupt];
        return YES;
    }
    [self.lock unlockWithCondition:DHLockSearchOnly];
    [DHDBSearcher checkForInterrupt];
    return NO;
}

- (BOOL)step
{
    [DHDBSearcher checkForInterrupt];
    if(self.queryQueue.count)
    {
        NSDictionary *aQuery = (self.queryQueue)[0];
        [self.lock lock];
        self.currentRS = [self resultSetFromQueuedQueryDictionary:aQuery];
        [self.lock unlockWithCondition:DHLockSearchOnly];
        [self.queryQueue removeObjectAtIndex:0];
        [DHDBSearcher checkForInterrupt];
        return YES;
    }
    [self close];
    [DHDBSearcher checkForInterrupt];
    return NO;
}

- (DHDBResult *)currentDBResult
{
    DHDBResult *result = [DHDBResult resultWithDocset:self.docset resultSet:self.currentRS];
    return [self prepareResult:result];
}

- (DHDBResult *)prepareResult:(DHDBResult *)result
{
    [result setQuery:self.query];
    NSString *name = [[result name] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *originalName = [[result originalName] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if(![[result originalName] contains:self.query] && [originalName contains:self.query])
    {
        result.whitespaceMatch = YES;
    }
    self.hadPerfect = [originalName hasCaseInsensitiveSuffix:self.query] || [originalName hasCaseInsensitivePrefix:self.query];
    [DHDBSearcher checkForInterrupt];
    result.queryIsPrefix = [name hasCaseInsensitivePrefix:self.query];
    result.queryIsSuffix = [name hasCaseInsensitiveSuffix:self.query];
    result.perfectMatch = result.queryIsPrefix && result.queryIsSuffix && name.length == self.query.length;
    if(self.query.length)
    {
        result.matchesQueryAtAll = (result.queryIsSuffix || result.queryIsPrefix || [name rangeOfString:self.query options:NSCaseInsensitiveSearch].location != NSNotFound);
        result.originalMatchesQueryAtAll = result.matchesQueryAtAll || [originalName rangeOfString:self.query options:NSCaseInsensitiveSearch].location != NSNotFound;
        result.queryIsPrefixOfOriginal = [originalName hasCaseInsensitivePrefix:self.query];
        result.queryIsSuffixOfOriginal = [originalName hasCaseInsensitiveSuffix:self.query];
        result.perfectMatchOriginal = result.queryIsPrefixOfOriginal && result.queryIsSuffixOfOriginal && originalName.length == self.query.length;
    }
    [result highlightWithQuery:self.query];
    if(result.fuzzyShouldIgnore)
    {
        return nil;
    }
    return result;
}

- (FMResultSet *)resultSetFromQueuedQueryDictionary:(NSDictionary *)query
{
    return [self.db executeQuery:query[@"sqlQuery"] withArgumentsInArray:query[@"args"]];
}

- (void)close
{
    self.currentRS = nil;
    if(self.db && self.db.sqliteHandle)
    {
        [self.lock lock];
        [self.db close];
        [self.lock unlockWithCondition:DHLockAllAllowed];
    }
    self.db = nil;
}

- (void)addResultToResultDictionary:(DHDBResult *)result
{
    NSString *sortType = result.sortType;
    NSMutableArray *typeResults = (self.resultDictionary)[sortType];
    if(!typeResults)
    {
        typeResults = [NSMutableArray array];
        (self.resultDictionary)[sortType] = typeResults;
    }
    [typeResults addObject:result];
}

- (void)sortResultDictionary
{
    for(NSMutableArray *queueResults in [[self resultDictionary] allValues])
    {
        [queueResults sortUsingSelector:@selector(compareFuziness:)];
    }
}

- (NSMutableArray *)resultsForType:(NSString *)type
{
    return (self.resultDictionary)[type];
}

- (void)dealloc
{
    [self close];
}

@end
