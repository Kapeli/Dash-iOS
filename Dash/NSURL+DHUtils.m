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

#import "NSURL+DHUtils.h"

@implementation NSURL (DHUtils)

+ (BOOL)URLIsFound:(NSString *)urlString timeoutInterval:(NSTimeInterval)timeout checkForRedirect:(BOOL)checkForRedirect
{
    NSURL *url = [NSURL URLWithString:urlString];
    if(url)
    {
        NSMutableURLRequest *httpRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
        [httpRequest setHTTPMethod:@"HEAD"];
        NSHTTPURLResponse *response = nil;
        [NSURLConnection sendSynchronousRequest:httpRequest returningResponse:&response error:nil];
        if(!response || ![response isKindOfClass:[NSHTTPURLResponse class]])
        {
            return NO;
        }
        if([response statusCode] != 200)
        {
            return NO;
        }
        if(checkForRedirect && ![[response URL] isEqual:url])
        {
            return NO;
        }
    }
    return YES;
}

@end
