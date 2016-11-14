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

#import <Foundation/Foundation.h>
#import "DTBonjourServer.h"
#import "DHRemote.h"

@interface DHRemoteServer : NSObject <DTBonjourServerDelegate>

@property (strong) DTBonjourServer *server;
@property (strong) NSMutableDictionary *connections;
@property (strong) UIAlertView *shownAlert;
@property (assign) BOOL ignoreRequests;
@property (strong) NSMutableArray *remotes;
@property (strong) DHRemote *connectedRemote;
@property (strong) NSMutableDictionary *requestsQueue;
@property (retain) NSTimer *sendWebViewURLTimer;
@property (retain) NSArray *tableOfContentsMethods;
@property (assign) BOOL tableOfContentsIsSnippet;
@property (retain) NSMutableDictionary *lastDecryptFailDates;

+ (DHRemoteServer *)sharedServer;
- (void)sendObject:(id)object forRequestName:(NSString *)name encrypted:(BOOL)encrypted toMacName:(NSString *)macName;
- (void)sendWebViewURL:(NSString *)url;
- (void)processRemoteTableOfContents;

@end

#define DHRemotesChangedNotification @"DHRemotesChangedNotification"
