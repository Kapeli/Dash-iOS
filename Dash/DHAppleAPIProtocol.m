//
//  Copyright (C) 2018  Kapeli
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

#import "DHAppleAPIProtocol.h"
#import <Apple_Docs_Framework/Apple_Docs_Framework.h>
#import "DHDocsetManager.h"
#import "DHLatencyTester.h"
#import "DHWebViewController.h"
#import "DHTocBrowser.h"

@implementation DHAppleAPIProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if([[[request URL] scheme] isCaseInsensitiveEqual:@"dash-apple-api"])
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
    @autoreleasepool {
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request URL] MIMEType:@"text/html" expectedContentLength:-1 textEncodingName:nil];
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        NSString *url = [[self.request.URL absoluteString] substringToString:@"#"];
        if(![url contains:@"&language="])
        {
            url = [url stringByAppendingFormat:@"&language=%@", ([DHAppleActiveLanguage currentLanguage] == DHNewActiveAppleLanguageObjC) ? @"occ" : @"swift"];
        }
        DHDocset *docset = [[DHDocsetManager sharedManager] appleAPIReferenceDocset];
        NSString *toolPath = [docset.documentsPath stringByAppendingPathComponent:@"Apple Docs Helper"];
        NSData *data = [@"<html><head><title>Error</title></head><body>Error. Please reinstall the Apple API Reference docset.</body></html>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        if(toolPath.length)
        {
            @try {
                DHViewer *viewer = [DHViewer sharedViewer];
                DHCommandLineParser *parser = [DHCommandLineParser sharedParser];
                parser.ownPath = toolPath;
                NSString *bestMirror = [[DHLatencyTester sharedLatency].bestMirror stringByConvertingKapeliHttpURLToHttps];
                bestMirror = (bestMirror) ? bestMirror : @"https://kapeli.com/feeds/";
                viewer.isIOS = YES;
                parser.bestMirror = bestMirror;
                viewer.url = url;
                parser.dashBuildNumber = 450;
                data = [[viewer htmlOutput] dataUsingEncoding:NSUTF8StringEncoding];
                [self setUpTOC:viewer];
                [DHXcodeHelper cleanUp];
                [DHViewer cleanUp];
            }
            @catch(NSException *exception) { NSLog(@"%@ %@", exception, [exception callStackSymbols]); }
        }
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    }
}

- (void)setUpTOC:(DHViewer *)viewer
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        DHWebViewController *controller = [DHWebViewController sharedWebViewController];
        if(iPad && isRegularHorizontalClass)
        {
            if(controller.methodsPopover.popoverVisible)
            {
                [controller.methodsPopover dismissPopoverAnimated:YES];
            }
        }
        else
        {
            [[controller.actualTOCBrowser searchDisplayController] setActive:NO animated:NO];
            [[controller.actualTOCBrowser presentingViewController] dismissViewControllerAnimated:YES completion:nil];
        }
        controller.lastTocBrowser = nil;
        controller.currentMethods = viewer.tocEntries.count ? viewer.tocEntries : nil;
        controller.navigationItem.rightBarButtonItem = (viewer.tocEntries.count) ? [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tocMenu"] style:UIBarButtonItemStylePlain target:controller action:@selector(tocButtonPressed:)] : nil;
    });
}

- (void)stopLoading
{
}

@end
