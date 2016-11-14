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

#import "DHDBSearcher.h"
#import "DHQueuedDB.h"
#import "DHTypes.h"
#import "DHDBNestedResultSorter.h"

@implementation DHDBSearcher

+ (DHDBSearcher *)searcherWithDocsets:(NSArray *)docsets query:(NSString *)query limitToType:(NSString *)typeLimit delegate:(id<DHDBSearcherDelegate>)delegate
{
    DHDBSearcher *searcher = [[DHDBSearcher alloc] init];
    searcher.query = [query copy];
    searcher.docsets = [NSArray arrayWithArray:docsets];
    searcher.typeLimit = typeLimit;
    searcher.delegate = delegate;
    searcher.currentThread = [[NSThread alloc] initWithTarget:searcher selector:@selector(doSearchThread) object:nil];
    [searcher.currentThread setThreadPriority:1.0f];
    [searcher.currentThread start];
    return searcher;
}

- (void)doSearchThread
{
    @autoreleasepool {
        NSMutableArray *queue = [NSMutableArray array];
        NSMutableArray *fuzzyQueue = [NSMutableArray array];
        NSConditionLock *stepLock = [DHDocset stepLock];
        @try {
            for(DHDocset *docset in self.docsets)
            {
                DHQueuedDB *db = [DHQueuedDB queueWithDocset:docset query:self.query typeLimit:self.typeLimit isFuzzy:NO];
                if(db)
                {
                    [queue addObject:db];
                }
                DHQueuedDB *fuzzyDB = [DHQueuedDB queueWithDocset:docset query:self.query typeLimit:self.typeLimit isFuzzy:YES];
                if(fuzzyDB)
                {
                    [fuzzyQueue addObject:fuzzyDB];
                }
            }
            NSMutableArray *results = nil;
            NSMutableArray *perfect = [NSMutableArray array];
            NSMutableArray *perfectOriginal = [NSMutableArray array];
            NSMutableArray *startsWith = [NSMutableArray array];
            NSMutableArray *startsWithOriginal = [NSMutableArray array];
            NSMutableArray *endsWith = [NSMutableArray array];
            NSMutableArray *endsWithOriginal = [NSMutableArray array];
            NSMutableArray *matches = [NSMutableArray array];
            NSMutableArray *originalMatches = [NSMutableArray array];
            NSMutableArray *fuzzyCamel = [NSMutableArray array];
            NSMutableArray *fuzzyPerfect = [NSMutableArray array];
            NSMutableArray *fuzzy = [NSMutableArray array];
            NSMutableArray *noMatch = [NSMutableArray array];
            NSMutableArray *allResults = [NSMutableArray array];
            NSMutableSet *duplicates = [NSMutableSet set];

            BOOL unifiedPerfectPhase = YES;
            BOOL unifiedPrefixPhase = NO;
            BOOL unifiedSuffixPhase = NO;
            BOOL unifiedContainsPhase = NO;
            BOOL fuzzyPhase = NO;
            BOOL shouldBreak = NO;
            BOOL didSendResultsOnce = NO;
            
            NSInteger count = 0;
            NSInteger maxLimit = 200; // you need to change this in DHUnifiedQueuedDB as well
            
            NSMutableArray *processingQueues = [NSMutableArray arrayWithArray:queue];
            while(YES)
            {
                if((unifiedPerfectPhase || unifiedPrefixPhase || unifiedSuffixPhase || (unifiedContainsPhase && count < maxLimit) || (fuzzyPhase)) && processingQueues.count)
                {
                    NSMutableArray *stepQueue = [NSMutableArray arrayWithArray:processingQueues];
                    for(int i=0; i < stepQueue.count; i++)
                    {
                        [DHDBSearcher checkForInterrupt];
                        DHQueuedDB *queuedDB = stepQueue[i];
                        if(![queuedDB step])
                        {
                            NSInteger index = [processingQueues indexOfObjectIdenticalTo:queuedDB];
                            if(index != NSNotFound)
                            {
                                [processingQueues removeObjectAtIndex:index];
                            }
                            [stepQueue removeObjectAtIndex:i];
                            --i;
                        }
                    }
                    NSInteger innerCount = 0;
                    while((unifiedPerfectPhase || (unifiedSuffixPhase && count <= maxLimit*2) || (unifiedPrefixPhase && count <= maxLimit) || (unifiedContainsPhase && count <= maxLimit) || (fuzzyPhase && innerCount <= maxLimit/2)) && stepQueue.count)
                    {
                        for(int i=0; i < stepQueue.count; i++)
                        {
                            DHQueuedDB *queuedDB = stepQueue[i];
                            if([queuedDB next])
                            {
                                DHDBResult *result = [queuedDB currentDBResult];
                                if(fuzzyPhase && result.whitespaceMatch)
                                {
                                    result = nil;
                                }
                                NSString *duplicateHash = [result duplicateHash];
                                if(duplicateHash)
                                {
                                    if([duplicates containsObject:duplicateHash])
                                    {
                                        continue;
                                    }
                                    [duplicates addObject:duplicateHash];
                                }
                                [DHDBSearcher checkForInterrupt];
                                if(result)
                                {
                                    [queuedDB addResultToResultDictionary:result];
                                    ++count;
                                    ++innerCount;
                                }
                            }
                            else
                            {
                                [stepQueue removeObjectAtIndex:i];
                                [DHDBSearcher checkForInterrupt];
                                --i;
                            }
                        }
                    }
                }
                else
                {
                    shouldBreak = YES;
                }
                
                if((fuzzyPhase && shouldBreak) || unifiedContainsPhase)
                {
                    for(DHQueuedDB *queueDB in queue)
                    {
                        [queueDB sortResultDictionary];
                    }
                    NSArray *types = [[DHTypes sharedTypes] orderedTypes];
                    if(self.typeLimit)
                    {
                        types = @[self.typeLimit];
                    }
                    NSArray *fuzzyCamelBackUp = [NSArray arrayWithArray:fuzzyCamel];
                    NSArray *fuzzyPerfectBackUp = [NSArray arrayWithArray:fuzzyPerfect];
                    NSArray *fuzzyBackUp = [NSArray arrayWithArray:fuzzy];
                    NSArray *noMatchBackUp = [NSArray arrayWithArray:noMatch];
                    [fuzzyCamel removeAllObjects];
                    [fuzzyPerfect removeAllObjects];
                    [fuzzy removeAllObjects];
                    [noMatch removeAllObjects];
                    
                    // Step 3: Order results based on priority and order similar results
                    for(NSString *type in types)
                    {
                        [DHDBSearcher checkForInterrupt];
                        for(DHQueuedDB *queueDB in queue)
                        {
                            for(DHDBResult *result in [queueDB resultsForType:type])
                            {
                                [DHDBSearcher checkForInterrupt];
                                NSInteger similar = [allResults indexOfObject:result];
                                if(similar != NSNotFound)
                                {
                                    if(!result.isSO)
                                    {
                                        [[allResults[similar] similarResults] addObject:result];
                                    }
                                }
                                else
                                {
                                    if(result.perfectMatch)
                                    {
                                        [perfect addObject:result];
                                    }
                                    else if(result.perfectMatchOriginal)
                                    {
                                        [perfectOriginal addObject:result];
                                    }
                                    else if(result.queryIsPrefix)
                                    {
                                        [startsWith addObject:result];
                                    }
                                    else if(result.queryIsSuffix)
                                    {
                                        [endsWith addObject:result];
                                    }
                                    else if(result.matchesQueryAtAll)
                                    {
                                        [matches addObject:result];
                                    }
                                    else if(result.queryIsPrefixOfOriginal)
                                    {
                                        [startsWithOriginal addObject:result];
                                    }
                                    else if(result.queryIsSuffixOfOriginal)
                                    {
                                        [endsWithOriginal addObject:result];
                                    }
                                    else if(result.originalMatchesQueryAtAll)
                                    {
                                        [originalMatches addObject:result];
                                    }
                                    else if(result.fuzzyCamel)
                                    {
                                        [fuzzyCamel addObject:result];
                                    }
                                    else if(result.fuzzyPerfect)
                                    {
                                        [fuzzyPerfect addObject:result];
                                    }
                                    else if(result.fuzzy)
                                    {
                                        [fuzzy addObject:result];
                                    }
                                    else
                                    {
                                        [noMatch addObject:result];
                                    }
                                    [allResults addObject:result];
                                    [result setIsActive:YES];
                                }
                            }
                        }
                    }
                    for(DHQueuedDB *queueDB in queue)
                    {
                        [queueDB setResultDictionary:[NSMutableDictionary dictionary]];
                    }
                    [fuzzyCamel addObjectsFromArray:fuzzyCamelBackUp];
                    [fuzzyPerfect addObjectsFromArray:fuzzyPerfectBackUp];
                    [fuzzy addObjectsFromArray:fuzzyBackUp];
                    [noMatch addObjectsFromArray:noMatchBackUp];
                    [DHDBSearcher checkForInterrupt];
                    results = [NSMutableArray array];
                    BOOL didSubmitFuzzies = NO;
                    if(unifiedContainsPhase)
                    {
                        [results addObjectsFromArray:perfect];
                        [results addObjectsFromArray:perfectOriginal];
                        [results addObjectsFromArray:startsWith];
                        [results addObjectsFromArray:endsWith];
                        [results addObjectsFromArray:matches];
                        [results addObjectsFromArray:startsWithOriginal];
                        [results addObjectsFromArray:endsWithOriginal];
                        [results addObjectsFromArray:originalMatches];
                        
                        [perfect removeAllObjects];
                        [perfectOriginal removeAllObjects];
                        [startsWith removeAllObjects];
                        [endsWith removeAllObjects];
                        [matches removeAllObjects];
                        [startsWithOriginal removeAllObjects];
                        [endsWithOriginal removeAllObjects];
                        [originalMatches removeAllObjects];
                    }
                    if((fuzzyPhase && shouldBreak) || (count >= maxLimit && unifiedContainsPhase))
                    {
                        [results addObjectsFromArray:fuzzyCamel];
                        [results addObjectsFromArray:fuzzyPerfect];
                        [results addObjectsFromArray:fuzzy];
                        [results addObjectsFromArray:noMatch];
                        
                        [fuzzyCamel removeAllObjects];
                        [fuzzyPerfect removeAllObjects];
                        [fuzzy removeAllObjects];
                        [noMatch removeAllObjects];
                        didSubmitFuzzies = YES;
                    }
                    
                    for(int i = 0; i < results.count; i++)
                    {
                        DHDBResult *result = results[i];
                        if(result.similarResults.count)
                        {
                            results[i] = [[DHDBNestedResultSorter sharedSorter] sortNestedResults:result];
                        }
                    }
                    
                    [DHDBSearcher checkForInterrupt];
                    if(results.count || didSubmitFuzzies || shouldBreak)
                    {
                        [DHDBSearcher checkForInterrupt];
                        if(results.count || (!didSendResultsOnce && (didSubmitFuzzies || shouldBreak)))
                        {
                            [DHDBSearcher checkForInterrupt];
                            
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [self.delegate searcher:self foundResults:[NSArray arrayWithArray:results] hasMore:!(didSubmitFuzzies || shouldBreak)];
                            });
                            [DHDBSearcher checkForInterrupt];
                            [DHDBSearcher checkForInterrupt];
                        }
                        didSendResultsOnce = results.count > 0;
                        if(didSubmitFuzzies || shouldBreak)
                        {
                            break;
                        }
                        [results removeAllObjects];
                    }
                }
                
                if(unifiedPerfectPhase)
                {
                    unifiedPerfectPhase = NO;
                    unifiedPrefixPhase = YES;
                }
                else if(unifiedPrefixPhase)
                {
                    unifiedPrefixPhase = NO;
                    unifiedSuffixPhase = YES;
                }
                else if(unifiedSuffixPhase)
                {
                    unifiedSuffixPhase = NO;
                    unifiedContainsPhase = YES;
                }
                if(!processingQueues.count && unifiedContainsPhase && count <= maxLimit)
                {
                    unifiedContainsPhase = NO;
                    fuzzyPhase = YES;
                    [processingQueues addObjectsFromArray:fuzzyQueue];
                    [queue removeAllObjects];
                    [queue addObjectsFromArray:fuzzyQueue];
                }
            }
            [stepLock lock];
            [stepLock unlockWithCondition:DHLockAllAllowed];
        }
        @catch(NSException *exception) {
            [stepLock lock];
            [stepLock unlockWithCondition:DHLockAllAllowed];
            if(![[exception name] isEqualToString:@"Interrupt"])
            {
                NSLog(@"FIXME: exception in doSearchThread: %@", exception);
                NSLog(@"%@", [NSThread callStackSymbols]);
                [self.delegate searcher:self foundResults:@[] hasMore:NO];
            }
        }
    }
}

- (void)cancelSearch
{
    [self.currentThread cancel];
    [self.currentThread setThreadPriority:0.00f];
    self.delegate = nil;
    self.currentThread = nil;
}

+ (void)checkForInterrupt
{
    if([[NSThread currentThread] isCancelled])
    {
        [NSException raise:@"Interrupt" format:@""];
    }
}

- (void)dealloc
{
    [self cancelSearch];
}

@end
