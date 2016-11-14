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
#import <JavaScriptCore/JavaScriptCore.h>

@protocol DHJavaScriptBridgeExport <JSExport>

- (void)switchAppleLanguage:(JSValue *)value;
- (void)newSwitchAppleLanguage:(JSValue *)nameValue;
- (void)log:(JSValue *)value;
- (void)coffeeScriptOpenLink_:(NSString *)string;
- (void)unityConsoleLog:(NSString *)message;
- (void)showFallbackExplanation;
- (void)loadFallbackURL_:(JSValue *)suppressButtonChecked;
- (void)openDownloads;
- (void)openDocsets;
- (void)openProfiles;
- (void)openGuide;
- (void)openIOSLink;
- (void)webViewDidChangeLocationWithinPage;

@end

@interface DHJavaScriptBridge : NSObject <DHJavaScriptBridgeExport>

@property (nonatomic, copy) void (^alertBlock)(JSValue *message);

+ (DHJavaScriptBridge *)sharedBridge;

@end
