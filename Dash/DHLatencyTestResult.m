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

#import "DHLatencyTestResult.h"
#import "DHLatencyTester.h"

@implementation DHLatencyTestResult

+ (DHLatencyTestResult *)resultWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    return [DHLatencyTestResult resultWithHost:dictionary[@"host"] latency:[dictionary[@"latency"] doubleValue]];
}

+ (DHLatencyTestResult *)resultWithHost:(NSString *)host latency:(double)latency
{
    DHLatencyTestResult *result = [[DHLatencyTestResult alloc] init];
    result.host = host;
    result.latency = latency;
    return result;
}

- (NSDictionary *)dictionaryRepresentation
{
    return @{@"host": self.host, @"latency": @(self.latency)};
}

- (BOOL)shouldPerformTest
{
    return (!self.lastTestDate || [[NSDate date] timeIntervalSinceDate:self.lastTestDate] > 60) && !self.isPerformingTest;
}

- (void)performTest
{
    if([self shouldPerformTest])
    {
        self.startTestDate = [NSDate date];
        self.isPerformingTest = YES;
        double minLatency = 10000.0;
        BOOL success = NO;
        BOOL didCheckExtraMirrors = NO;
        for(int i = 0; i < 3; i++)
        {
            success = NO;
            self.startTestDate = [NSDate date];
            NSDate *then = [NSDate date];
            NSString *theHost = self.host;
            if([theHost hasSuffix:@"/"])
            {
                theHost = [theHost substringToDashIndex:theHost.length-1];
            }
            NSURL *url = [NSURL URLWithString:[[theHost stringByAppendingFormat:@"/latencyTest_v2.txt?cache_buster=%u", arc4random() % 1000000] stringByConvertingKapeliHttpURLToHttps]];
            if(url)
            {
                NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0f];
                NSURLResponse *response = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
                NSString *string = nil;
                if(data)
                {
                    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if(string && [string hasPrefix:@"Just a latency test. Move along."])
                    {
                        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:then];
                        
                        if(minLatency > latency)
                        {
                            minLatency = latency;
                            self.latency = latency;
                        }
                        success = YES;
                        if(!didCheckExtraMirrors)
                        {
                            // E.g. Extra mirrors: http://newyork3.kapeli.com/feeds/, http://newyork4.kapeli.com/feeds/
                            NSString *mirrorsString = [string substringFromStringReturningNil:@"Extra mirrors: "];
                            if(mirrorsString && mirrorsString.length)
                            {
                                NSMutableArray *mirrors = [NSMutableArray arrayWithArray:[mirrorsString componentsSeparatedByString:@", "]];
                                if(mirrors && mirrors.count)
                                {
                                    didCheckExtraMirrors = YES;
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [[DHLatencyTester sharedLatency] checkExtraMirrors:mirrors];
                                    });
                                }
                            }
                        }
                    }
                }
                if(!success)
                {
                    self.latency = 10000.0;
                    break;
                }
            }
        }
        if(success && minLatency > 0 && minLatency < 10000.0)
        {
            self.latency = minLatency;
        }
//        NSLog(@"%f for %@", self.latency, self.host);
        self.lastTestDate = [NSDate date];
        self.startTestDate = nil;
        self.isPerformingTest = NO;
    }
}

- (double)adaptiveLatency
{
    if(self.isPerformingTest && self.startTestDate)
    {
        double interval = [[NSDate date] timeIntervalSinceDate:self.startTestDate];
        return (interval > self.latency) ? interval : self.latency;
    }
    return self.latency;
}

- (BOOL)isEqual:(id)object
{
    return [self.host isEqualToString:[object host]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %f", self.host, [self adaptiveLatency]];
}

@end
