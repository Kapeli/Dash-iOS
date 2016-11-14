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
    @synchronized(self)
    {
        for(DHLatencyTestResult *result in self.results)
        {
            if(forcePerform)
            {
                result.lastTestDate = nil;
            }
            didPerform |= [result performTest];
        }
    }
    return didPerform;
}

- (void)setUp
{
    NSMutableArray *defaultResults = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for(NSDictionary *resultDict in [defaults objectForKey:@"latencyTestResults"])
    {
        [defaultResults addObject:[DHLatencyTestResult resultWithDictionaryRepresentation:resultDict]];
    }
    self.results = [NSMutableArray array];
    NSArray *defaultHosts = @[@"http://newyork.kapeli.com/feeds/", @"http://sanfrancisco.kapeli.com/feeds/", @"http://london.kapeli.com/feeds/"];
    for(NSString *host in defaultHosts)
    {
        DHLatencyTestResult *result = [DHLatencyTestResult resultWithHost:host latency:10000.0];
        NSInteger defaultIndex = [defaultResults indexOfObject:result];
        if(defaultIndex != NSNotFound)
        {
            [result setLatency:[defaultResults[defaultIndex] latency]];
        }
        [self.results addObject:result];
    }
    [self saveDefaults];
}

- (void)saveDefaults
{
    NSMutableArray *array = [NSMutableArray array];
    @synchronized(self)
    {
        for(DHLatencyTestResult *result in self.results)
        {
            [array addObject:[result dictionaryRepresentation]];
        }
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"latencyTestResults"];
    [defaults setObject:array forKey:@"latencyTestResults"];
    [defaults synchronize];
}

- (NSString *)bestMirrorReturningNil
{
    if(!self.results.count)
    {
        return nil;
    }
    NSMutableArray *results = [NSMutableArray arrayWithArray:self.results];
    [self sortLatencyTestResults:results];
    return [results[0] host];
}

- (NSString *)secondBestMirrorReturningNil
{
    if(self.results.count < 2)
    {
        return nil;
    }
    NSMutableArray *results = [NSMutableArray arrayWithArray:self.results];
    [self sortLatencyTestResults:results];
    return [results[1] host];
}

- (void)sortLatencyTestResults:(NSMutableArray *)results
{
    [results sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        double myLatency = [obj1 adaptiveLatency];
        double theirLatency = [obj2 adaptiveLatency];
        double delta = fabs(myLatency-theirLatency);
        if(delta < 0.03)
        {
            NSUInteger r = arc4random_uniform(2);
            if(r == 0)
            {
                return NSOrderedDescending;
            }
            else
            {
                return NSOrderedAscending;
            }
        }
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
        double delta = fabs(myLatency-theirLatency);
        if(delta < 0.03)
        {
            NSUInteger r = arc4random_uniform(2);
            if(r == 0)
            {
                return NSOrderedDescending;
            }
            else
            {
                return NSOrderedAscending;
            }
        }
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
        for(DHLatencyTestResult *result in self.results)
        {
            NSInteger i = 0;
            NSInteger found = NSNotFound;
            for(NSString *mirror in mirrors)
            {
                if([result.host isCaseInsensitiveEqual:mirror])
                {
                    found = i;
                    break;
                }
                ++i;
            }
            if(found != NSNotFound)
            {
                [mirrors removeObjectAtIndex:found];
            }
        }
        if(mirrors.count)
        {
            for(NSString *mirror in mirrors)
            {
                DHLatencyTestResult *result = [DHLatencyTestResult resultWithHost:mirror latency:10000.0];
                [self.results addObject:result];
                [result performTest];
            }
        }
    }
}

@end
