//
//  DHAppleAPISchemeHandler.m
//  Dash
//
//  Created by chenhaoyu.1999 on 2021/3/28.
//  Copyright © 2021 Kapeli. All rights reserved.
//

#import "DHAppleAPISchemeHandler.h"
#import <Apple_Docs_Framework/Apple_Docs_Framework.h>
#import "DHDocsetManager.h"
#import "DHLatencyTester.h"
#import "DHWebViewController.h"
#import "DHTocBrowser.h"

@implementation DHAppleAPISchemeHandler

- (void)webView:(nonnull WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    @autoreleasepool {
        NSURLRequest *request = urlSchemeTask.request;
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[request URL] MIMEType:@"text/html" expectedContentLength:-1 textEncodingName:nil];
        [urlSchemeTask didReceiveResponse:response];
        NSString *url = [[request.URL absoluteString] substringToString:@"#"];
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
        [urlSchemeTask didReceiveData:data];
        [urlSchemeTask didFinish];
    }
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    
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

@end
