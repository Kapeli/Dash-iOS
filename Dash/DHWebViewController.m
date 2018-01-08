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

#import "DHWebViewController.h"
#import "DHWebViewController.h"
#import "DHNavigationAnimator.h"
#import "JGMethodSwizzler.h"
#import "DHDocsetManager.h"
#import "DHJavaScript.h"
#import "DHCSS.h"
#import "DHAppDelegate.h"
#import "DHUnarchiver.h"
#import "DHTocBrowser.h"
#import "DHJavaScriptBridge.h"
#import "DHRemoteProtocol.h"
#import "DHTypeBrowser.h"
#import "DHEntryBrowser.h"
#import "DHWebView.h"

@implementation DHWebViewController

static id singleton = nil;


- (void)viewDidLoad
{
    if([self callStackIsRestoring] && !self.isRestoring)
    {
        return;
    }
    [super viewDidLoad];
    if(self.didLoadOnce)
    {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForURLSearch:) name:DHPrepareForURLSearch object:nil];
    self.title = @"";
    self.webView.scrollView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.allowsInlineMediaPlayback = YES;
    self.webView.delegate = self;
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
    CGFloat progressBarHeight = 2.f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    self.progressView = [[DHWebProgressView alloc] initWithFrame:barFrame];
    [self.progressView setProgress:0.0f];
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

    [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
    self.splitViewController.presentsWithGesture = NO;
    
    if(isRegularHorizontalClass)
    {
        self.navigationController.delegate = self;
    }
    
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
    self.zoomOutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"zoomOut"] style:UIBarButtonItemStylePlain target:self action:@selector(zoomOut)];
    self.zoomInButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"zoomIn"] style:UIBarButtonItemStylePlain target:self action:@selector(zoomIn)];
//    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self.webView action:@selector(stopLoading)];
//    self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    
    [self updateBackForwardButtonState];
    
    self.toolbarItems = @[self.backButton, UIBarButtonWithFixedWidth(10), self.forwardButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], self.zoomOutButton, UIBarButtonWithFixedWidth(3), self.zoomInButton];
    [self updateStopReloadButtonState];
    self.didLoadOnce = YES;
}

- (void)goBack
{
    self.ignoreScroll = YES;
    [self.webView goBack];
    self.ignoreScroll = NO;
    [self performSelector:@selector(updateBackForwardButtonState) withObject:self afterDelay:0.01];
}

- (void)goForward
{
    self.ignoreScroll = YES;
    [self.webView goForward];
    self.ignoreScroll = NO;
    [self performSelector:@selector(updateBackForwardButtonState) withObject:self afterDelay:0.01];
}

- (void)zoomIn
{
    [[DHCSS sharedCSS] modifyTextSize:YES];
    [self refreshTextSize];
}

- (void)zoomOut
{
    [[DHCSS sharedCSS] modifyTextSize:NO];
    [self refreshTextSize];
}

- (void)refreshTextSize
{
    if(!isRegularHorizontalClass)
    {
        [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] zoomScriptWithFrame:self.webView.frame]];
    }
    NSString *js = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%@'", [[DHCSS sharedCSS] textSizeAdjust]];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)loadResult:(DHDBResult *)result
{
    NSString *webViewURL = result.webViewURL;
    if(webViewURL)
    {
        [self loadURL:webViewURL];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if(!self.didLoadInitialRequest && !self.isRestoring)
    {
        if(self.result)
        {
            [self loadResult:self.result];
            if([DHRemoteServer sharedServer].connectedRemote)
            {
                [[DHRemoteServer sharedServer] processRemoteTableOfContents];
            }
        }
        else if(self.urlToLoad)
        {
            [self loadURL:self.urlToLoad];
            self.urlToLoad = nil;
        }
        else
        {
            id masterViewController = [(UINavigationController*)[self.splitViewController.viewControllers firstObject] topViewController];
            if([masterViewController isKindOfClass:[DHTypeBrowser class]] || [masterViewController isKindOfClass:[DHEntryBrowser class]])
            {
                [self loadURL:[[masterViewController docset] indexFilePath]];
            }
            else
            {
                [self loadURL:[[NSBundle mainBundle] pathForResource:@"home" ofType:@"html"]];
            }
        }
        self.didLoadInitialRequest = YES;
    }
    self.jsContext[@"window"][@"dash"] = [DHJavaScriptBridge sharedBridge];
    [super viewWillAppear:animated];
    self.ignoreScroll = YES;
    if(![DHRemoteServer sharedServer].connectedRemote)
    {
        self.navigationController.toolbarHidden = NO;        
    }
    CGFloat progressBarHeight = 2.f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    [self.navigationController.navigationBar addSubview:self.progressView];
    [self.progressView setFrame:barFrame];
    [self traitCollectionDidChange:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if(previousTraitCollection)
    {
        [super traitCollectionDidChange:previousTraitCollection];
    }
    if(isRegularHorizontalClass)
    {
        UIBarButtonItem *expand = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"expand"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleSplitView:)];
        self.toggleSplitViewButton = expand;
        self.navigationItem.leftBarButtonItems = @[expand];
    }
    else
    {
        self.navigationItem.leftBarButtonItems = nil;
    }
    self.toolbarItems = @[self.backButton, UIBarButtonWithFixedWidth(10), self.forwardButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], self.zoomOutButton, UIBarButtonWithFixedWidth(3), self.zoomInButton];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.toolbar setHidden:YES];
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.jsContext[@"window"][@"dash"] = nil;
    self.ignoreScroll = YES;
    [self.progressView removeFromSuperview];
    if(!isRegularHorizontalClass)
    {
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.body.className = document.body.className+' dash_cleared'; document.title = \"%@\";", self.title]];
        self.title = @"";
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.ignoreScroll = NO;
    if(self.isDecoding)
    {
        [self.webView reload];
        self.isDecoding = NO;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//    self.title = @"Loading...";
    [self updateBackForwardButtonState];
    [self.progressView setProgress:0 animated:NO];
    [self.progressView fakeSetProgress:0.6];
}

- (void)webViewDidChangeLocationWithinPage
{
    if(!self.nextAnchorChangeNotCausedByUserNavigation && [DHRemoteServer sharedServer].connectedRemote)
    {
        [[DHRemoteServer sharedServer] sendWebViewURL:[self.webView stringByEvaluatingJavaScriptFromString:@"window.location.href"]];
    }
    self.nextAnchorChangeNotCausedByUserNavigation = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if([[request URL].absoluteString isEqualToString:@"about:blank"])
    {
        return NO;
    }
    BOOL isFrame = ![[[request URL] absoluteString] isEqualToString:[[request mainDocumentURL] absoluteString]];
    if(!isFrame)
    {
        self.lastLoadDate = [NSDate date];
        self.previousMainFrameURL = self.mainFrameURL;
        self.mainFrameURL = request.URL.absoluteString;
        if(!self.anchorChangeInProgress)
        {
            [self updateStopReloadButtonState];
            [self setToolbarHidden:NO];
        }
    }
    if(!self.anchorChangeInProgress && [[[request URL] scheme] isCaseInsensitiveEqual:@"file"])
    {
        BOOL isMain = [request.URL isEqual:request.mainDocumentURL];
        NSMutableURLRequest *mutRequest = (id)request;
        NSString *url = [[[request URL] absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@"dash-tarix://"];
        NSURL *newURL = [NSURL URLWithString:url];
        [mutRequest setURL:newURL];
        if(isMain)
        {
            [mutRequest setMainDocumentURL:newURL];
        }
        [self performSelector:@selector(updateBackForwardButtonState) withObject:self afterDelay:0.1];
        return YES;
    }
    if(navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted || navigationType == UIWebViewNavigationTypeFormResubmitted)
    {
        [[DHRemoteServer sharedServer] sendWebViewURL:[request URL].absoluteString];
    }
    [self performSelector:@selector(updateBackForwardButtonState) withObject:self afterDelay:0.1];
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if([self stopButtonIsShown])
    {
        [self updateStopReloadButtonState];
    }
    [self updateBackForwardButtonState];
    [self updateTitle];
    [self setUpScripts];
    [self setUpTOC];
    [self.progressView setProgress:1.0 animated:YES];
    if (self.isRestoreScroll) {
        [self.webView.scrollView setContentOffset:self.webViewOffset animated:NO];
        self.isRestoreScroll = NO;
    }
}

- (void)setUpTOC
{
    if([DHRemoteServer sharedServer].connectedRemote || [[self loadedURL] hasPrefix:@"dash-apple-api://"])
    {
        return;
    }
    self.lastTocBrowser = nil;
    NSString *path = [[[[[self loadedURL] substringFromString:@"://"] substringToString:@"#"] substringToString:@"?"] stringByReplacingPercentEscapes];
    NSString *tocPath = [path stringByAppendingString:@".dashtoc"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *jsonData = nil;
    if([fileManager fileExistsAtPath:tocPath])
    {
        jsonData = [NSData dataWithContentsOfFile:tocPath];
    }
    else
    {
        jsonData = [DHUnarchiver tarixReadFile:tocPath toFile:nil];
    }
    NSDictionary *json = (jsonData) ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil] : nil;
    if(json && [json isKindOfClass:[NSDictionary class]])
    {
        NSArray *methods = json[@"entries"];
        if([DHCSS activeAppleLanguage] == DHActiveAppleLanguageSwift && json[@"entries_swift"])
        {
            methods = json[@"entries_swift"];
        }
        NSMutableArray *actualMethods = [NSMutableArray array];
        for(NSDictionary *method in methods)
        {
            if([method[@"isSpacer"] boolValue])
            {
                continue;
            }
            [actualMethods addObject:method];
        }
        self.currentMethods = actualMethods;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tocMenu"] style:UIBarButtonItemStylePlain target:self action:@selector(tocButtonPressed:)];
        if(json[@"title"] && [[json[@"title"] trimWhitespace] length])
        {
            self.title = [json[@"title"] trimWhitespace];
        }
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)snippetUseButtonPressed:(id)sender
{
    [[DHRemoteServer sharedServer] sendObject:@{@"selector": @"useSnippet"} forRequestName:@"performWebSelector" encrypted:YES toMacName:[DHRemoteServer sharedServer].connectedRemote.name];
}

- (void)tocButtonPressed:(id)sender
{
    if(iPad && isRegularHorizontalClass)
    {
        if([self dismissMethodsPopoverIfVisible:YES])
        {
            return;
        }
        id tocBrowser = (self.lastTocBrowser && [self.lastTocBrowser isKindOfClass:[DHTocBrowser class]]) ? self.lastTocBrowser : [self.storyboard instantiateViewControllerWithIdentifier:@"DHTocBrowser"];
        if(self.lastTocBrowser != tocBrowser)
        {
            self.lastTocBrowser = tocBrowser;
            [self prepareTocBrowser:tocBrowser];
        }
        self.methodsPopover = [[UIPopoverController alloc] initWithContentViewController:tocBrowser];
        [tocBrowser setPreferredContentSize:CGSizeMake(400, 600)];
        [self.methodsPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        id tocBrowser = (self.lastTocBrowser && [self.lastTocBrowser isKindOfClass:[UINavigationController class]]) ? self.lastTocBrowser : [self.storyboard instantiateViewControllerWithIdentifier:@"DHTocBrowserNavigationController"];
        if(self.lastTocBrowser != tocBrowser)
        {
            self.lastTocBrowser = tocBrowser;
            [self prepareTocBrowser:(id)[tocBrowser topViewController]];
        }
        [self presentViewController:tocBrowser animated:YES completion:nil];
    }
}

- (void)prepareTocBrowser:(DHTocBrowser *)tocBrowser
{
    tocBrowser.title = self.title;
    NSMutableArray *sections = [NSMutableArray array];
    NSMutableArray *sectionTitles = [NSMutableArray array];
    for(NSDictionary *method in self.currentMethods)
    {
        if([method[@"isHeader"] boolValue])
        {
            [sectionTitles addObject:method[@"name"]];
            [sections addObject:[NSMutableArray array]];
        }
        else
        {
            [[sections lastObject] addObject:method];
        }
    }
    [tocBrowser setSections:sections];
    [tocBrowser setSectionTitles:sectionTitles];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if([self stopButtonIsShown])
    {
        [self updateStopReloadButtonState];
    }
    NSString *customMessage = nil;
    [self updateTitle];
    if([error code] == NSURLErrorCancelled || ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 204) || ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102 && ![[[error userInfo][NSURLErrorFailingURLStringErrorKey] substringFromString:@"://"] isCaseInsensitiveEqual:[self.mainFrameURL substringFromString:@"://"]]))
    {
        return;
    }
    else if([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)
    {
        customMessage = @"Invalid URL.";
    }
    self.mainFrameURL = self.previousMainFrameURL;
    [self.progressView setProgress:1.0 animated:YES];
    [[[UIAlertView alloc] initWithTitle:@"Error Loading Page" message:(customMessage) ? customMessage : error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (JSContext *)jsContext
{
    JSContext *ctx = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    return ctx;
}

- (void)setUpScripts
{
    self.jsContext[@"window"][@"alert"] = [DHJavaScriptBridge sharedBridge].alertBlock;
    self.jsContext[@"window"][@"dash"] = [DHJavaScriptBridge sharedBridge];
    [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] javaScriptInFile:@"scroll_to_current_anchor"]];
    [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] javaScriptInFile:@"hash_change_notifier"]];
    [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] javaScriptInFile:@"on_page_load"]];
    NSString *platform = nil;
    DHDocset *docset = nil;
    if([DHRemoteServer sharedServer].connectedRemote)
    {
        platform = [DHRemoteProtocol lastResponseUserInfo][@"platform"];
    }
    else
    {
        docset = [[DHDocsetManager sharedManager] docsetForDocumentationPage:self.mainFrameURL];
        platform = docset.platform;
    }
    if(!platform && [self.mainFrameURL contains:@"developer.apple.com"])
    {
        platform = @"osx";
    }
    if(platform)
    {
        if([platform isEqualToString:@"macosx"] || [platform isEqualToString:@"osx"] || [platform isEqualToString:@"iphoneos"] || [platform isEqualToString:@"ios"] || [platform isEqualToString:@"watchos"] || [platform isEqualToString:@"tvos"])
        {
            [self setUpCocoaScripts:docset];
        }
        else if([platform isEqualToString:@"apple"])
        {
            [self setUpAppleScripts:docset];
        }
        else if([platform isEqualToString:@"rails"])
        {
            [self setUpRailsScripts:docset];
        }
        else if([platform isEqualToString:@"ruby"])
        {
            [self setUpRubyScripts:docset];
        }
        else if([platform isEqualToString:@"net"])
        {
            [self setUpMSDNScripts:docset];
        }
        else if([platform isEqualToString:@"unity3d"])
        {
            [self setUpUnityScripts:docset];
        }
    }
    if([self.mainFrameURL hasCaseInsensitivePrefix:@"http"] && [self.mainFrameURL contains:@"developer.apple.com"])
    {
        [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] injectCSSScript]];
        [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] injectViewPortScript]];
    }
}

- (void)setUpAppleScripts:(DHDocset *)docset
{
    [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] javaScriptInFile:@"apple"]];
}

- (void)setUpCocoaScripts:(DHDocset *)docset
{
    [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] javaScriptInFile:@"cocoa"]];
}

- (void)setUpRailsScripts:(DHDocset *)docset
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"function toggleSource(e){var t=$('#'+e).toggle();var n=t.is(':visible');$('#l_'+e).html(n?'hide':'show')}$(function(){$('.description pre').each(function(){hljs.highlightBlock(this)})})"];
}

- (void)setUpRubyScripts:(DHDocset *)docset
{
    [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] javaScriptInFile:@"ruby"]];
}

- (void)setUpMSDNScripts:(DHDocset *)docset
{
//    [self.webView stringByEvaluatingJavaScriptFromString:[[DHJavaScript sharedJavaScript] javaScriptInFile:@"msdn"]];
}

- (void)setUpUnityScripts:(DHDocset *)docset
{
    NSString *prefLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"unitySelectedSnippetLanguage"];
    if(prefLanguage)
    {
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var uls=document.getElementsByClassName('cSelectWidth');var found=false;for(var i=0;i<uls.length;i++){var ul=uls[i];if(ul.nodeName=='UL'){for(var j=0;j<ul.children.length;j++){var li=ul.children[j];if(li.innerText=='%@'){jQuery(li).click();found=true;break}}}if(found){break}}", prefLanguage]];
    }
    [self.webView stringByEvaluatingJavaScriptFromString:@"console.log = function(s) { window.dash.unityConsoleLog(s)}"];
}

- (void)setToolbarHidden:(BOOL)hidden
{
    if(self.navigationController.toolbarHidden != hidden && [self isActive] && (![DHRemoteServer sharedServer].connectedRemote || hidden))
    {
        self.ignoreScroll = YES;
        [self.navigationController setToolbarHidden:hidden animated:YES];
        self.ignoreScroll = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(self.ignoreScroll)
    {
        return;
    }
    if(!self.navigationController.toolbarHidden && [scrollView.panGestureRecognizer translationInView:self.view].y < 0.0f && scrollView.contentSize.height > scrollView.frame.size.height && ![self stopButtonIsShown] && [[NSDate date] timeIntervalSinceDate:self.lastLoadDate] > 0.1)
    {
        [self setToolbarHidden:YES];
    }
    else if(self.navigationController.toolbarHidden && [scrollView.panGestureRecognizer translationInView:self.view].y > 0.0f && ![self stopButtonIsShown])
    {
        [self setToolbarHidden:NO];
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.ignoreScroll = YES;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.ignoreScroll = NO;
}

- (void)updateBackForwardButtonState
{
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
}

- (void)updateStopReloadButtonState
{
    if((self.webView.loading && ![self stopButtonIsShown]) || (!self.webView.loading && [self stopButtonIsShown]))
    {
        self.stopButtonIsShown = self.webView.loading;
//        NSMutableArray *items = [self.toolbarItems mutableCopy];
//        [items replaceObjectAtIndex:[items count]-1 withObject:(self.webView.loading) ? self.stopButton : self.reloadButton];
//        [self setToolbarItems:items animated:YES];
    }
}

- (void)loadURL:(NSString *)urlString
{
    NSString *anchor = [[urlString substringFromStringReturningNil:@"#"] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *urlWithoutAnchor = [[urlString substringToString:@"#"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlString = (anchor) ? [urlWithoutAnchor stringByAppendingFormat:@"#%@", anchor] : urlWithoutAnchor;
    
    if(![urlString hasCaseInsensitivePrefix:@"file://"] && [urlString hasPrefix:@"/"])
    {
        urlString = [@"dash-tarix://" stringByAppendingString:urlString];
        urlWithoutAnchor = [@"dash-tarix://" stringByAppendingString:urlWithoutAnchor];
    }
    urlString = [urlString stringByReplacingOccurrencesOfString:@"file://" withString:@"dash-tarix://"];
    urlWithoutAnchor = [urlWithoutAnchor stringByReplacingOccurrencesOfString:@"file://" withString:@"dash-tarix://"];
    NSURL *url = [NSURL URLWithString:urlString];
    if(!url && anchor.length)
    {
        urlString = [urlWithoutAnchor stringByAppendingFormat:@"#%@", [anchor stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        url = [NSURL URLWithString:urlString];
    }
    if(url)
    {
        if(!self.webView.isLoading && [[[[self.mainFrameURL substringFromString:@"://"] stringByDeletingPathFragment] stringByReplacingPercentEscapes] isCaseInsensitiveEqual:[[[urlString substringFromString:@"://"] stringByDeletingPathFragment] stringByReplacingPercentEscapes]] && ![self.mainFrameURL contains:@"dash-remote-snippet://"])
        {
            self.nextAnchorChangeNotCausedByUserNavigation = YES;
            self.anchorChangeInProgress = YES;
            self.ignoreScroll = YES;
            NSString *hash = [urlString pathFragment];
            if(hash && hash.length)
            {
                [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"if(window.location.hash == \"#%@\") { window.location.hash = ''; } window.location.href = \"#%@\"", hash, hash]];
            }
            else
            {
                [self.webView stringByEvaluatingJavaScriptFromString:@"scroll(0,0)"];
            }
            self.ignoreScroll = NO;
            [self removeDashClearedClass];
            self.anchorChangeInProgress = NO;
            if(self.navigationController.toolbarHidden && ![DHRemoteServer sharedServer].connectedRemote)
            {
                self.ignoreScroll = YES;
                [self.navigationController setToolbarHidden:NO animated:YES];
                self.ignoreScroll = NO;
            }
            return;
        }
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (void)removeDashClearedClass
{
    if([[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.className"] contains:@"dash_cleared"])
    {
        [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.className = document.body.className.replace(/\\bdash_cleared\\b/, \" \");"];
        self.title = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"] trimWhitespace];
    }
}

- (NSString *)loadedURL
{
    return self.webView.request.URL.absoluteString;
}

- (void)reload
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"location.reload(true)"];
}

- (void)updateTitle
{
    NSString *newTitle = self.pageTitle;
    if(![self.title isEqualToString:newTitle])
    {
        self.title = self.pageTitle;
        [self.actualTOCBrowser setTitle:self.title];
    }
}

- (DHTocBrowser *)actualTOCBrowser
{
    return [self.lastTocBrowser isKindOfClass:[DHTocBrowser class]] ? self.lastTocBrowser : [self.lastTocBrowser topViewController];
}

- (NSString *)pageTitle
{
    NSString *title = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"] trimWhitespace];
    if(!title.length && [[self loadedURL] contains:@"://"])
    {
        title = [[[[self mainFrameURL] stringByDeletingPathFragment] lastPathComponent] stringByDeletingPathExtension];
        title = (title.length) ? title : @"No Title";
    }
    return title;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController*)fromVC toViewController:(UIViewController*)toVC
{
    Class class = [DHWebViewController class];
    BOOL fromIs = ![fromVC isKindOfClass:class];
    BOOL toIs = ![toVC isKindOfClass:class];
    if((fromIs && !toIs) || (toIs && !fromIs))
    {
        return [[DHNavigationAnimator alloc] init];
    }
    else if(fromIs && toIs)
    {
        DHNavigationAnimator *animator = [[DHNavigationAnimator alloc] init];
        animator.noAnimation = YES;
        return animator;
    }
    return nil;
}

- (void)toggleSplitView:(id)sender
{
    [self.webView.window.rootViewController.view endEditing:YES];
    [UIView animateWithDuration:0.3 animations:^{
        if(self.splitViewController.preferredDisplayMode == UISplitViewControllerDisplayModePrimaryHidden)
        {
            [sender setImage:[UIImage imageNamed:@"expand"]];
            [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
        }
        else
        {
            [sender setImage:[UIImage imageNamed:@"collapse"]];
            [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModePrimaryHidden];
        }
    }];
}

- (BOOL)isLocalURL
{
    if(!self.mainFrameURL)
    {
        return NO;
    }
    if([[self mainFrameURL] rangeOfString:@"file://"].location != NSNotFound || [[self mainFrameURL] hasPrefix:@"dash-stack://"] || [[self mainFrameURL] hasPrefix:@"dash-apple-api://"] || [[self mainFrameURL] hasPrefix:@"dash-tarix://"])
    {
        return YES;
    }
    return NO;
}

- (void)prepareForURLSearch:(id)sender
{
    if(iPad && isRegularHorizontalClass)
    {
        [self dismissMethodsPopoverIfVisible:YES];
    }
    if(isRegularHorizontalClass)
    {
        if(self.splitViewController.preferredDisplayMode == UISplitViewControllerDisplayModePrimaryHidden)
        {
            [self.toggleSplitViewButton setImage:[UIImage imageNamed:@"expand"]];
            [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
        }
    }
}

- (BOOL)dismissMethodsPopoverIfVisible:(BOOL)animated
{
    if(self.methodsPopover.popoverVisible)
    {
        [self.methodsPopover dismissPopoverAnimated:animated];
        return YES;
    }
    return NO;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.webView.request.URL.absoluteString forKey:@"webViewURL"];
    [coder encodeObject:homePath forKey:@"homePath"];
    [coder encodeCGPoint:self.webView.scrollView.contentOffset forKey:@"webViewOffset"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    NSString *loadURL = [coder decodeObjectForKey:@"webViewURL"];
    NSString *lastHomePath = [coder decodeObjectForKey:@"homePath"];
    self.webViewOffset = [coder decodeCGPointForKey:@"webViewOffset"];
    if (lastHomePath) {
        loadURL = [[loadURL stringByReplacingOccurrencesOfString:lastHomePath withString:homePath] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    self.isRestoring = YES;
    [self viewDidLoad];
    self.isRestoring = NO;
    self.isDecoding = YES;
    [self loadURL:loadURL];
    if (isRegularHorizontalClass) {
        [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
    }
    self.isRestoreScroll = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

static inline UIBarButtonItem *UIBarButtonWithFixedWidth(CGFloat width)
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    button.width = width;
    return button;
}

+ (instancetype)sharedWebViewController
{
    if(singleton)
    {
        return singleton;
    }
    id webViewController = [[DHAppDelegate mainStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    return webViewController;
}

+ (id)alloc
{
    if(singleton)
    {
        return singleton;
    }
    return [super alloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(singleton)
    {
        return singleton;
    }
    self = [super initWithCoder:aDecoder];
    singleton = self;
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.navigationController.delegate = nil;
    self.webView.scrollView.delegate = nil;
    self.webView.delegate = nil;
    [self.webView loadHTMLString:@"" baseURL:nil];
    [self.webView stopLoading];
    [self.webView removeFromSuperview];
}

@end
