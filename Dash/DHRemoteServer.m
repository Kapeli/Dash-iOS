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

#import "DHRemoteServer.h"
#import "SAMKeychain.h"
#import "DHDocsetManager.h"
#import "DHRemoteImage.h"
#import "Reachability.h"
#import "DHDBResult.h"
#import "DHRemoteBrowser.h"
#import "DHNestedViewController.h"
#import "DHRemoteProtocol.h"
#import "DHCSS.h"
#import "DHTocBrowser.h"

@implementation DHRemoteServer

+ (DHRemoteServer *)sharedServer
{
    static dispatch_once_t pred;
    static DHRemoteServer *_server = nil;
    
    dispatch_once(&pred, ^{
        _server = [[DHRemoteServer alloc] init];
        [_server setUp];
    });
    return _server;
}

- (void)setUp
{
    [NSKeyedUnarchiver setClass:[DHDBResult class] forClassName:@"DHDBSnippetResult"];
    [NSKeyedUnarchiver setClass:[DHDBResult class] forClassName:@"DHSearchEngineResult"];
    [NSKeyedUnarchiver setClass:[DHDBResult class] forClassName:@"DHDBUnifiedResult"];
    self.requestsQueue = [NSMutableDictionary dictionary];
    self.remotes = [NSMutableArray array];
    self.connections = [NSMutableDictionary dictionary];
    self.lastDecryptFailDates = [NSMutableDictionary dictionary];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startServer];
    });
    
    Reachability *reach = [Reachability reachabilityForLocalWiFi];
    reach.reachableOnWWAN = NO;
    reach.reachableBlock = ^(Reachability *theReach) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopServer];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startServer];
            });
        });
    };
    [reach startNotifier];
}

- (void)startServer
{
    if(self.server)
    {
        return;
    }
    self.server = [[DTBonjourServer alloc] initWithBonjourType:@"_dash._tcp"];
    [self.server setDelegate:self];
    if(![self.server start])
    {
        NSLog(@"Failed to start Bonjour server");
        self.server = nil;
        [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(startServer) userInfo:nil repeats:NO];
    }
}

- (void)stopServer
{
    self.server.delegate = nil;
    [self.server stop];
    self.server = nil;
    for(DTBonjourDataConnection *connection in [self.connections allValues])
    {
        [self connectionDidClose:connection];
    }
}

- (void)connectionDidClose:(DTBonjourDataConnection *)connection
{
    for(NSString *key in self.connections.allKeys)
    {
        if(self.connections[key] == connection)
        {
            DHRemote *remote = [DHRemote remoteWithName:key icon:nil];
            NSInteger index = [self.remotes indexOfObject:remote];
            if(index != NSNotFound)
            {
                [self.remotes removeObjectAtIndex:index];
                [[NSNotificationCenter defaultCenter] postNotificationName:DHRemotesChangedNotification object:nil];
            }
            [self.connections removeObjectForKey:key];
        }
    }
}

- (void)sendWebViewURL:(NSString *)url
{
    self.sendWebViewURLTimer = [self.sendWebViewURLTimer invalidateTimer];
    if(self.connectedRemote)
    {
        url = [url stringByReplacingOccurrencesOfString:@"dash-tarix://" withString:@"file://"];
        self.sendWebViewURLTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 block:^{
            [self sendObject:@{@"url": url} forRequestName:@"syncWebViewURL" encrypted:YES toMacName:self.connectedRemote.name];
        } repeats:NO];
    }
}

- (void)processRemoteTableOfContents
{
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
    controller.currentMethods = (self.tableOfContentsMethods.count) ? self.tableOfContentsMethods : nil;
    controller.navigationItem.rightBarButtonItem = (self.tableOfContentsMethods.count) ? [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tocMenu"] style:UIBarButtonItemStylePlain target:controller action:@selector(tocButtonPressed:)] : (self.tableOfContentsIsSnippet) ? [[UIBarButtonItem alloc] initWithTitle:@"Use" style:UIBarButtonItemStylePlain target:controller action:@selector(snippetUseButtonPressed:)] : nil;
}

- (BOOL)shouldIgnoreDueToDecryptFlood:(NSString *)macName
{
    NSDate *date = self.lastDecryptFailDates[macName];
    if(date && [[NSDate date] timeIntervalSinceDate:date] < 0.5)
    {
        return YES;
    }
    [self.lastDecryptFailDates removeObjectForKey:macName];
    return NO;
}

- (void)bonjourServer:(DTBonjourServer *)server didReceiveObject:(NSDictionary *)dict onConnection:(DTBonjourDataConnection *)connection
{
    @try {
        NSString *macName = dict[@"name"];
        NSString *requestName = dict[@"requestName"];
        NSDictionary *userInfo = dict[@"userInfo"];
        BOOL isEncrypted = [dict[@"encrypted"] boolValue];
        NSArray *encryptedCheck = dict[@"encryptedCheck"];
        if(!macName || !requestName || (isEncrypted && !encryptedCheck))
        {
            NSLog(@"Remote object receive failed validation");
            return;
        }
        if(isEncrypted)
        {
            NSString *password = [SAMKeychain passwordForService:@"Dash Remote" account:macName];
            BOOL success = NO;
            if(password && password.length)
            {
                if(!connection.originAddress || !connection.originAddress.length)
                {
                    success = YES;
                }
                else
                {
                    for(NSData *data in encryptedCheck)
                    {
                        NSData *ipAddressData = [data AES256DecryptWithKey:password];
                        NSString *ipAddress = (ipAddressData) ? [[NSString alloc] initWithData:ipAddressData encoding:NSUTF8StringEncoding] : nil;
                        if(ipAddress && ipAddress.length && [ipAddress isCaseInsensitiveEqual:connection.originAddress])
                        {
                            success = YES;
                            break;
                        }
                    }
                }
                if(success && userInfo)
                {
                    userInfo = (NSDictionary*)[(NSData*)userInfo AES256DecryptWithKey:password];
                    if(!userInfo)
                    {
                        success = NO;
                    }
                }
            }
            if(!success)
            {
                self.lastDecryptFailDates[macName] = [NSDate date];
                NSLog(@"decryption failed!");
                return;
            }
        }
        if([dict[@"gzipped"] boolValue])
        {
            userInfo = (userInfo) ? (id)[(id)userInfo gunzippedData] : nil;
        }
        userInfo = (userInfo) ? [NSKeyedUnarchiver unarchiveObjectWithData:(NSData*)userInfo] : nil;
        
        NSLog(@"received %@", requestName);
#pragma mark Start handling requests
        
        
#pragma mark Enforce encrypted routes
        NSArray *allowedUnencrypted = @[@"pairRequest", @"loadRequestResponse"];
        if(!isEncrypted && ![allowedUnencrypted containsObject:requestName])
        {
            NSLog(@"Request %@ failed because not allowed without encryption", requestName);
            return;
        }
        else if([self shouldIgnoreDueToDecryptFlood:macName])
        {
#ifdef DEBUG
            NSLog(@"Request %@ failed due to flood", requestName);
#endif
            return;
        }
        
        self.connections[macName] = connection;

#pragma mark Route: pairRequest
        if([requestName isEqualToString:@"pairRequest"] && !self.shownAlert.isVisible)
        {
            if(self.ignoreRequests)
            {
                return;
            }
            @try {
                [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
            }
            @catch(NSException *exception) { NSLog(@"%@ %@", exception, [exception callStackSymbols]); }
            self.shownAlert = [UIAlertView showWithTitle:@"Pair Request Received" message:[NSString stringWithFormat:@"Dash on \"%@\" requested to pair with you. If you would like to pair, please enter the pair code:", macName] style:UIAlertViewStylePlainTextInput cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Pair", @"Ignore Future Requests"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if(buttonIndex == 1)
                {
                    NSString *code = [[alertView textFieldAtIndex:0] text];
                    code = (code) ? : @"";
                    NSError *error = nil;
                    if(![SAMKeychain setPassword:code forService:@"Dash Remote" account:macName error:&error])
                    {
                        NSLog(@"Couldn't save remote password in keychain: %@", error);
                    }
                    [self sendObject:nil forRequestName:@"pairComplete" encrypted:YES toMacName:macName];
                }
                else if(buttonIndex == 2)
                {
                    self.ignoreRequests = YES;
                }
            }];
        }
        
#pragma mark Route: pairHello
        if([requestName isEqualToString:@"pairHello"])
        {
            [self sendObject:nil forRequestName:@"pairHello" encrypted:YES toMacName:macName];
        }
        
#pragma mark Route: readyToConnect
        if([requestName isEqualToString:@"readyToConnect"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:userInfo[@"icon"]];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                remote = self.connectedRemote;
                [remote connect];
            }
            if(![self.remotes containsObject:remote])
            {
                [self.remotes addObject:remote];
                [[NSNotificationCenter defaultCenter] postNotificationName:DHRemotesChangedNotification object:nil];
            }
        }
        
#pragma mark Route: unpair
        if([requestName isEqualToString:@"unpair"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                self.connectedRemote = nil;
            }
            if([self.remotes containsObject:remote])
            {
                [self.remotes removeObject:remote];
                [[NSNotificationCenter defaultCenter] postNotificationName:DHRemotesChangedNotification object:nil];
            }
        }
        
#pragma mark Route: syncResults
        if([requestName isEqualToString:@"syncResults"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                DHRemoteBrowser *browser = self.connectedRemote.browser;
                browser.results = userInfo[@"results"];
                NSString *query = [[userInfo[@"searchQuery"] substringToString:@" "] trimWhitespace];
                browser.title = [query length] ? query : self.connectedRemote.name;
                [browser.tableView reloadData];
                NSInteger row = [userInfo[@"selectedRow"] integerValue];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                if(isRegularHorizontalClass || browser.navigationController.visibleViewController != browser)
                {
                    [browser.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                if(![userInfo[@"isFuzzyAppend"] boolValue])
                {
                    if(isRegularHorizontalClass || browser.navigationController.visibleViewController != browser)
                    {
                        [browser.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
                    }
                    [browser popNestedViewControllers];
                }
            }
        }
        
#pragma mark Route: syncSelectedRow
        if([requestName isEqualToString:@"syncSelectedRow"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                DHRemoteBrowser *browser = self.connectedRemote.browser;
                NSInteger row = [userInfo[@"selectedRow"] integerValue];
                NSInteger indexOfActiveItem = [userInfo[@"indexOfActiveItem"] integerValue];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                if([browser.tableView numberOfRowsInSection:0] > row && browser.results.count > row)
                {
                    if(![browser.tableView.indexPathForSelectedRow isEqual:indexPath])
                    {
                        if(isRegularHorizontalClass || browser.navigationController.visibleViewController != browser)
                        {
                            [browser.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                            [browser.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
                        }
                        [browser popNestedViewControllers];
                    }
                    DHDBResult *result = (browser.results)[row];
                    if(result.indexOfActiveItem != indexOfActiveItem)
                    {
                        [result setActiveItemByIndex:indexOfActiveItem];
                        DHNestedViewController *nestedController = [browser nestedViewController];
                        if(nestedController.result == result)
                        {
                            NSIndexPath *nestedIndexPath = [NSIndexPath indexPathForRow:indexOfActiveItem inSection:0];
                            if(isRegularHorizontalClass || nestedController.navigationController.visibleViewController != nestedController)
                            {
                                [nestedController.tableView selectRowAtIndexPath:nestedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                                [nestedController.tableView scrollToRowAtIndexPath:nestedIndexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
                            }
                        }
                    }
                }
            }
        }
        
#pragma mark Route: syncWebViewURL
        if([requestName isEqualToString:@"syncWebViewURL"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                NSString *url = userInfo[@"url"];
                NSString *hash = [url substringFromStringReturningNil:@"#"];
                url = [url substringToString:@"#"];
                url = [url stringByReplacingPercentEscapes];
                if(hash && hash.length)
                {
                    url = [url stringByAppendingFormat:@"#%@", hash];
                }
                DHWebViewController *webViewController = [DHWebViewController sharedWebViewController];
                if([webViewController isViewLoaded])
                {
                    [webViewController loadURL:url];
                }
                else
                {
                    webViewController.result.remoteResultURL = url;
                }
            }
        }
        
#pragma mark Route: loadRequestResponse
        if([requestName isEqualToString:@"loadRequestResponse"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                NSString *identifier = userInfo[@"identifier"];
                if(identifier && self.requestsQueue[identifier])
                {
                    NSMutableData *data = userInfo[@"data"];
                    if([userInfo[@"gzipped"] boolValue])
                    {
                        data = (id)[data gunzippedData];
                    }
                    [self.requestsQueue[identifier] receivedData:data userInfo:userInfo[@"responseUserInfo"] isTimeout:NO];
                }
            }
        }
        
#pragma mark Route: syncAppleLanguage
        if([requestName isEqualToString:@"syncAppleLanguage"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                NSString *language = userInfo[@"language"];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if(![[defaults objectForKey:DHActiveAppleLanguageKey] isEqualToString:language])
                {
                    [defaults setObject:language forKey:DHActiveAppleLanguageKey];
                    [[DHCSS sharedCSS] refreshActiveCSS];
                    [[DHWebViewController sharedWebViewController] reload];
                }
            }
        }
        
        
#pragma mark Route: syncNewAppleLanguage
        if([requestName isEqualToString:@"syncNewAppleLanguage"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                [DHAppleActiveLanguage setLanguage:[userInfo[@"language"] integerValue]];
            }
        }
        
#pragma mark Route: syncTableOfContents
        if([requestName isEqualToString:@"syncTableOfContents"])
        {
            DHRemote *remote = [DHRemote remoteWithName:macName icon:nil];
            if(self.connectedRemote && [self.connectedRemote isEqual:remote])
            {
                self.tableOfContentsMethods = userInfo[@"methods"];
                self.tableOfContentsIsSnippet = [userInfo[@"isSnippet"] boolValue];
                [self processRemoteTableOfContents];
            }
        }
    }
    @catch(NSException *exception) {
        NSLog(@"Remote receive object exception: %@ %@", exception, [exception callStackSymbols]);
    }
}

- (void)sendObject:(id)object forRequestName:(NSString *)name encrypted:(BOOL)encrypted toMacName:(NSString *)macName
{
    if(!macName)
    {
        return;
    }
    DTBonjourDataConnection *connection = self.connections[macName];
    if(connection && connection.isOpen)
    {
        NSLog(@"sent %@", name);
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"requestName"] = name;
        if(object)
        {
            object = [NSKeyedArchiver archivedDataWithRootObject:object];
            NSData *gzipped = [object gzippedDataWithCompressionLevel:0.7];
            object = (gzipped) ? gzipped : object;
            if(gzipped)
            {
                dict[@"gzipped"] = @YES;
            }
        }
        if(encrypted)
        {
            dict[@"encrypted"] = @(encrypted);
            NSString *password = [self passwordForMacName:macName];
            NSMutableArray *encryptedCheck = [NSMutableArray array];
            dict[@"encryptedCheck"] = encryptedCheck;
            for(NSString *host in [NSArray currentIPAddresses])
            {
                NSData *encryptedHost = [[[host substringToString:@"%"] dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:password];
                if(encryptedHost)
                {
                    [encryptedCheck addObject:encryptedHost];
                }
            }
            if(object)
            {
                object = [object AES256EncryptWithKey:password];
            }
        }
        if(object)
        {
            dict[@"userInfo"] = object;
        }
        [connection sendObject:dict error:nil];
    }
}

- (NSString *)passwordForMacName:(NSString *)macName
{
    return [SAMKeychain passwordForService:@"Dash Remote" account:macName];
}

@end
