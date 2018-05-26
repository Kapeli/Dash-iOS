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

#import "DHLatencyTester.h"
#import "DHLatencyTestResult.h"

@implementation DHLatencyTester

+ (DHLatencyTester *)sharedLatency
{
    static dispatch_once_t pred;
    static DHLatencyTester *_latency = nil;
    
    dispatch_once(&pred, ^{
        _latency = [[DHLatencyTester alloc] init];
        [_latency setUp];
    });
    return _latency;
}

- (BOOL)performTests:(BOOL)forcePerform
{
    BOOL didPerform = NO;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didPerformLatencyTestsBefore"];
    @synchronized(self)
    {
        if(!self.queue)
        {
            self.queue = [[NSOperationQueue alloc] init] ;
            [self.queue setMaxConcurrentOperationCount:1];
        }
        for(DHLatencyTestResult *result in self.results)
        {
            if(forcePerform)
            {
                result.lastTestDate = nil;
            }
            if([result shouldPerformTest])
            {
                didPerform = YES;
                [self.queue addOperationWithBlock:^{
                    __block BOOL done = NO;
                    dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
                    dispatch_async(queue, ^{
                        [result performTest];
                        done = YES;
                    });
                    NSDate *startDate = [NSDate date];
                    while(!done && [[NSDate date] timeIntervalSinceDate:startDate] < 15 && (!result.startTestDate || [[NSDate date] timeIntervalSinceDate:result.startTestDate] < 3))
                    {
                        [NSThread sleepForTimeInterval:0.03];
                    }
                }];
            }
        }
        if(didPerform)
        {
            [self.queue addOperationWithBlock:^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self saveDefaults];
                });
            }];
        }
    }
    return didPerform;
}

- (void)setUp
{
    self.resultsAllowedInUserDefaults = [NSMutableArray array];
    self.defaultResults = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL didPerformTestsBefore = [defaults boolForKey:@"didPerformLatencyTestsBefore"];
    self.results = [NSMutableArray array];
    NSMutableArray *resultsTemp = [NSMutableArray array];
    for(NSDictionary *resultDict in [defaults objectForKey:@"latencyTestResults"])
    {
        [self.defaultResults addObject:[DHLatencyTestResult resultWithDictionaryRepresentation:resultDict]];
        [resultsTemp addObject:self.defaultResults.lastObject];
    }
    for(NSString *host in @[@"http://sanfrancisco.kapeli.com/feeds/", @"http://newyork.kapeli.com/feeds/", @"http://london.kapeli.com/feeds/"])
    {
        DHLatencyTestResult *result = [DHLatencyTestResult resultWithHost:host latency:10000.0];
        [self.resultsAllowedInUserDefaults addObject:result];
        if(![resultsTemp containsObject:result])
        {
            [resultsTemp addObject:result];
        }
    }
    [self sortLatencyTestResults:resultsTemp];
    self.results = [NSMutableArray arrayWithArray:resultsTemp];
    if(didPerformTestsBefore)
    {
        [self performTests:NO];
    }
}

- (void)saveDefaults
{
    if(![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(saveDefaults) withObject:nil waitUntilDone:YES];
        return;
    }
    NSMutableArray *array = [NSMutableArray array];
    @synchronized(self)
    {
        for(DHLatencyTestResult *result in self.results)
        {
            if(result.latency < 60 && [self.resultsAllowedInUserDefaults containsObject:result])
            {
                [array addObject:[result dictionaryRepresentation]];
            }
        }
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:array forKey:@"latencyTestResults"];
}

- (NSString *)bestMirrorReturningNil
{
    if(!self.results.count)
    {
        return nil;
    }
    return [[self sortedTestResults][0] host];
}

- (NSString *)secondBestMirrorReturningNil
{
    if(self.results.count < 2)
    {
        return nil;
    }
    return [[self sortedTestResults][1] host];
}

- (NSMutableArray *)sortedTestResults
{
    NSMutableArray *results = [NSMutableArray arrayWithArray:self.results];
    [self sortLatencyTestResults:results];
    return results;
}

- (void)sortLatencyTestResults:(NSMutableArray *)results
{
    [results sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        double myLatency = [obj1 adaptiveLatency];
        double theirLatency = [obj2 adaptiveLatency];
        if(myLatency < theirLatency)
        {
            return NSOrderedAscending;
        }
        else if(myLatency > theirLatency)
        {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (NSString *)bestMirror
{
    NSString *best = [self bestMirrorReturningNil];
    if(!best)
    {
        return @"http://kapeli.com/feeds/";
    }
    return best;
}


- (NSString *)secondBestMirror
{
    NSString *best = [self secondBestMirrorReturningNil];
    if(!best)
    {
        return @"http://london.kapeli.com/feeds/";
    }
    return best;
}

- (void)sortURLsBasedOnLatency:(NSMutableArray *)urls
{
    [urls sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        double myLatency = [self latencyForURL:obj1];
        double theirLatency = [self latencyForURL:obj2];
        if(myLatency < theirLatency)
        {
            return NSOrderedAscending;
        }
        else if(myLatency > theirLatency)
        {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (double)latencyForURL:(NSString *)aURL
{
    @synchronized(self)
    {
        for(DHLatencyTestResult *result in self.results)
        {
            if([aURL hasCaseInsensitivePrefix:result.host])
            {
                return [result adaptiveLatency];
            }
        }
    }
    return 10000.0;
}

- (void)checkExtraMirrors:(NSMutableArray *)mirrors
{
    @synchronized(self)
    {
        if(mirrors.count)
        {
            for(NSString *mirror in mirrors)
            {
                DHLatencyTestResult *result = [DHLatencyTestResult resultWithHost:mirror latency:10000.0];
                if(![self.results containsObject:result])
                {
                    [self.results addObject:result];
                }
                if(![self.resultsAllowedInUserDefaults containsObject:result])
                {
                    [self.resultsAllowedInUserDefaults addObject:result];
                }
            }
            [self performTests:NO];
        }
    }
}

@end
