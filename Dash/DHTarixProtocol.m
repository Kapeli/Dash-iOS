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

#import "DHTarixProtocol.h"
#import "DHUnarchiver.h"
#import "DHCSS.h"
#import "DHWebViewController.h"
#import "DHWebView.h"

@implementation DHTarixProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if([[[request URL] scheme] isCaseInsensitiveEqual:@"file"])
    {
        return YES;
    }
    else if([[[request URL] scheme] isCaseInsensitiveEqual:@"dash-tarix"])
    {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSString *path = [[[self.request URL] path] stringByReplacingPercentEscapes];
    NSString *extension = [path pathExtension];
    NSString *mimeType = [NSString mimeTypeForPathExtension:extension];
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request URL]
                                                        MIMEType:mimeType
                                           expectedContentLength:-1
                                                textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    NSMutableData *data = [DHUnarchiver tarixReadFile:path toFile:nil];
    if(!data)
    {
        data = [NSMutableData dataWithContentsOfFile:path];
    }
    data = [DHTarixProtocol alterData:data scheme:[[self.request URL] scheme] path:path extension:extension mimeType:mimeType isTimeout:NO];
    
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}

+ (NSMutableData *)alterData:(NSMutableData *)data scheme:(NSString *)scheme path:(NSString *)path extension:(NSString *)extension mimeType:(NSString *)mimeType isTimeout:(BOOL)isTimeout
{
    if(!data)
    {
        if([[path lastPathComponent] hasPrefix:@"Dash-Intercept-"])
        {
            path = [[NSBundle mainBundle] pathForResource:[[[path lastPathComponent] stringByDeletingPathExtension] substringFromDashIndex:@"Dash-Intercept-".length] ofType:[path pathExtension]];
            data = [NSMutableData dataWithContentsOfFile:path];
        }
    }
    BOOL isHTML = [extension hasCaseInsensitivePrefix:@"htm"] || [mimeType contains:@"html"];
    BOOL isCSS = [extension hasCaseInsensitivePrefix:@"css"] || [mimeType contains:@"css"];
    BOOL isJS = [extension hasCaseInsensitivePrefix:@"js"];
    if(isHTML && data)
    {
        DHWebViewController *webController = [DHWebViewController sharedWebViewController];
        NSString *cssString = [NSString stringWithFormat:@"<head><style>%@</style>", [DHCSS currentCSSStringWithTextModifier]];
        
        __block CGRect webViewFrame = CGRectZero;
        if([NSThread isMainThread])
        {
            webViewFrame = webController.webView.frame;
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                webViewFrame = webController.webView.frame;
            });
        }
        NSString *viewportString = [NSString stringWithFormat:@"<meta id='dash_viewport' name='viewport' content='%@'/></head>", [DHWebView viewportContent:webViewFrame]];
        NSMutableString *content = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(content)
        {
            [content replaceOccurrencesOfString:@"<head>" withString:cssString options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
            [content replaceOccurrencesOfString:@"</head>" withString:viewportString options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
            data = (id)[content dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    else if(isCSS && data)
    {
        NSMutableString *content = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(content)
        {
            // if I don't remove this, things get weird when I'm scrolling in UIViewC class
            // because it believes orientation changes when the toolbar gets hidden
            for(NSString *toRemove in @[@"and (orientation:portrait)", @"and (orientation:landscape)"])
            {
                [content replaceOccurrencesOfString:toRemove withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
            }
            data = (id)[content dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    else if(isJS && data && [path contains:@"Unity 3D.docset"])
    {
        // Use localStorage because cookie storage doesn't work because UIWebView can't handle the file:// scheme with a
        // custom protocol so I'm forced to use the dash-tarix:// scheme, which causes UIWebView to ignore cookies because
        // dash-tarix:// URLs aren't really valid. I can't make dash-tarix:// URLs to be valid because I need them to work
        // like file:// URLs do (i.e. take advantage of relative paths)
        NSMutableString *content = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(content)
        {
            [content replaceOccurrencesOfString:@"localstorageSupport(){return false;" withString:@"localstorageSupport(){" options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
            data = (id)[content dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    if(!data && isHTML)
    {
        data = (id)[[NSString stringWithFormat:@"<html><head><meta name='viewport' content='width=device-width; initial-scale=1.0; user-scalable=1'/><style scoped>body title + .dashErrorDiv {display:none}</style><title>%@</title></head><body style='font-family: Helvetica Neue; font-weight:lighter;-webkit-user-select:none; padding:0px 5px; color:#333333'><div class='dashErrorDiv' style='position:absolute; right:0; left:0; top:0; bottom:0; width:300px; height:100px; margin:auto; text-align:center;'>%@</div></body></html>", (isTimeout) ? @"Error Loading" : @"Error Loading", (isTimeout) ? @"Request timed out." : @"Page not found."] dataUsingEncoding:NSUTF8StringEncoding];
    }
    return data;
}

- (void)stopLoading
{

}

@end
