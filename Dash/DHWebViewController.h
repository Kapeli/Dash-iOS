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

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "DHDBResult.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "DHWebProgressView.h"
@class DHWebView;

@class DHTocBrowser;
// WKNavigationDelegate Conformance implemented in a Swift file
@interface DHWebViewController : UIViewController <UISplitViewControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>

@property (strong) DHWebView *webView;
@property (strong) UIBarButtonItem *backButton;
@property (strong) UIBarButtonItem *forwardButton;
//@property (strong) UIBarButtonItem *stopButton;
//@property (strong) UIBarButtonItem *reloadButton;
@property (strong) UIBarButtonItem *zoomOutButton;
@property (strong) UIBarButtonItem *zoomInButton;
@property (strong) DHWebProgressView *progressView;
@property (strong) DHDBResult *result;
@property (assign) BOOL ignoreScroll;
@property (nullable, strong) NSString *mainFrameURL;
@property (strong) NSString *previousMainFrameURL;
@property (strong) NSArray *currentMethods;
@property (strong) UIPopoverController *methodsPopover;
@property (assign) BOOL anchorChangeInProgress;
@property (assign) BOOL visible;
@property (strong) id lastTocBrowser;
@property (weak) UIBarButtonItem *toggleSplitViewButton;
@property (assign) BOOL isRestoring;
@property (assign) BOOL isDecoding;
@property (strong) NSDate *lastLoadDate;
@property (assign) BOOL stopButtonIsShown;
@property (assign) BOOL nextAnchorChangeNotCausedByUserNavigation;
@property (assign) BOOL didLoadInitialRequest;
@property (assign) BOOL didLoadOnce;
@property (strong) NSString *urlToLoad;
@property (assign) BOOL isRestoreScroll;
@property (assign) CGPoint webViewOffset;

+ (instancetype)sharedWebViewController;
- (void)loadURL:(NSString *)urlString;
- (void)loadResult:(DHDBResult *)result;
- (BOOL)dismissMethodsPopoverIfVisible:(BOOL)animated;
- (BOOL)isLocalURL;
- (void)webViewDidChangeLocationWithinPage;
- (NSString *)loadedURL;
- (DHTocBrowser *)actualTOCBrowser;
- (void)updateBackForwardButtonState;
- (void)removeDashClearedClass;
- (void)snippetUseButtonPressed:(id)sender;
- (IBAction)tocButtonPressed:(id)sender;
- (void)reload;
// private
- (void)updateStopReloadButtonState;
- (void)setToolbarHidden:(BOOL)hidden;
- (void)updateTitle;
- (void)setUpScripts;
- (void)setUpTOC;

@end
