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

#import "DHRemoteProtocol.h"
#import "DHRemoteServer.h"
#import "DHTarixProtocol.h"

@implementation DHRemoteProtocol

static NSDictionary *_lastResponseUserInfo;

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if([DHRemoteServer sharedServer].connectedRemote)
    {
        NSString *scheme = [[request URL] scheme];
        if([scheme isCaseInsensitiveEqual:@"file"] || [scheme hasPrefix:@"dash-"]) // dash-remote-snippet, dash-stack, dash-tarix, dash-man-page, dash-apple-api
        {
            return YES;
        }
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    if(![[[self.request URL] scheme] isEqualToString:@"dash-remote-snippet"])
    {
        NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:self.request];
        if(cachedResponse)
        {
            if(cachedResponse.userInfo)
            {
                _lastResponseUserInfo = cachedResponse.userInfo;
            }
            [[self client] URLProtocol:self didReceiveResponse:[cachedResponse response] cacheStoragePolicy:NSURLCacheStorageAllowed];
            [[self client] URLProtocol:self didLoadData:[cachedResponse data]];
            [[self client] URLProtocolDidFinishLoading:self];
            return;
        }
    }
    NSTimeInterval timeout = 60.0f;
#ifdef DEBUG
//    timeout = 6.0f;
#endif
    NSString *scheme = [[self.request URL] scheme];
    self.path = [[[self.request URL] path] stringByReplacingPercentEscapes];
    self.extension = [self.path pathExtension];
    self.mimeType = [NSString mimeTypeForPathExtension:self.extension];
    if([scheme hasPrefix:@"dash-"] && ![scheme isEqualToString:@"dash-tarix"])
    {
        self.mimeType = @"text/html";
    }
    
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(requestDidTimeout) userInfo:nil repeats:NO];
    DHRemoteServer *server = [DHRemoteServer sharedServer];
    dispatch_sync(dispatch_get_main_queue(), ^{
        while(YES)
        {
            self.identifier = [NSString randomStringWithLength:12];
            if(!server.requestsQueue[self.identifier])
            {
                server.requestsQueue[self.identifier] = self;
                break;
            }
        }
        NSURL *url = self.request.URL;
        if([[url scheme] isCaseInsensitiveEqual:@"dash-tarix"])
        {
            url = [NSURL URLWithString:[[url absoluteString] stringByReplacingOccurrencesOfString:@"dash-tarix://" withString:@"file://"]];
        }
        [server sendObject:@{@"url": url, @"identifier": self.identifier, @"mimeType": self.mimeType, @"extension": (self.extension) ? : @""} forRequestName:@"loadRequest" encrypted:YES toMacName:server.connectedRemote.name];
    });
}

- (void)requestDidTimeout
{
    [self stopLoading];
    [self receivedData:nil userInfo:nil isTimeout:YES];
}

- (void)receivedData:(NSMutableData *)data userInfo:(NSDictionary *)userInfo isTimeout:(BOOL)isTimeout
{
    if([userInfo[@"isInternal"] boolValue])
    {
        self.mimeType = @"text/html";
        self.extension = @"html";
    }
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request URL] MIMEType:self.mimeType expectedContentLength:-1 textEncodingName:nil];
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    self.timeoutTimer = [self.timeoutTimer invalidateTimer];
    BOOL hadData = data != nil;
    data = [DHTarixProtocol alterData:data scheme:[[self.request URL] scheme] path:self.path extension:self.extension mimeType:self.mimeType isTimeout:isTimeout];
    if(hadData && ([self.extension hasCaseInsensitivePrefix:@"htm"] || [self.mimeType contains:@"html"]))
    {
        _lastResponseUserInfo = userInfo;
    }
    if(!isTimeout && data)
    {
        NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:userInfo storagePolicy:NSURLCacheStorageAllowed];
        [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:self.request];
    }
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
    
    [self stopLoading];
}

+ (NSDictionary *)lastResponseUserInfo
{
    return _lastResponseUserInfo;
}

- (void)stopLoading
{
    self.timeoutTimer = [self.timeoutTimer invalidateTimer];
    if(self.identifier)
    {
        @synchronized([DHRemoteProtocol class])
        {
            [[DHRemoteServer sharedServer].requestsQueue removeObjectForKey:self.identifier];            
        }
    }
}

@end
