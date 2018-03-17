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

#import "DHBlockProtocol.h"
#import "DHWebViewController.h"
#import "DHDocsetManager.h"
#import "DHRemoteProtocol.h"

@implementation DHBlockProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
#ifdef DEBUG
    if([[[request URL] scheme] isCaseInsensitiveEqual:@"http"])
    {
        NSLog(@"HTTP URL load detected: %@", request);
    }
#endif
    DHWebViewController *webController = [DHWebViewController sharedWebViewController];
    NSString *url = [[request URL] absoluteString];
    NSString *mainFrameURL = webController.mainFrameURL;
    if([url isEqualToString:@"about:blank"])
    {
        return YES;
    }
    if([url contains:@"kapeli.com/"])
    {
        return NO;
    }
    if([[[request URL] scheme] hasCaseInsensitivePrefix:@"http"])
    {
        if(![[[request URL] host] length] || [[[request URL] host] hasSuffix:@"."])
        {
            return YES;
        }
    }
    NSString *lastPathComponent = [url lastPathComponent];
    if([lastPathComponent contains:@"xcode"] && [[lastPathComponent pathExtension] isCaseInsensitiveEqual:@"css"])
    {
        return YES;
    }
    if([webController isLocalURL] || ([mainFrameURL contains:@"developer.apple.com"] && [mainFrameURL contains:@"/documentation/"]))
    {
        if([url rangeOfString:@"disqus.com/" options:NSCaseInsensitiveSearch].location != NSNotFound || [url contains:@"lloogg.com/"] || [url rangeOfString:@"google-analytics.com/" options:NSCaseInsensitiveSearch].location != NSNotFound || [url contains:@"adzerk.net"] || [url contains:@"ghbtns.com"] || [url contains:@"platform.twitter.com/widgets.js"] || [url contains:@"analytics.twitter.com"] || [url contains:@"login.persona.org"] || [url contains:@"omtrdc.net"] || [url contains:@"google.com/cse/"] || [url contains:@"jashkenas.s3.amazonaws.com/images/a_documentcloud_project.png"] || [url contains:@"media.mongodb.org"] || [url contains:@"googleusercontent.com/beacon"] || [url contains:@"carbonads.com/"] || [url contains:@"facebook.com/plugins"] || [url contains:@"fbcdn.net"] || [url contains:@"http://nodejs.org/images/platform-icons.png"] || [url contains:@"apis.google.com/js/plusone.js"] || ([url contains:@"community.adobe.com"] && [url hasCaseInsensitiveSuffix:@".css"]))
        {
            return YES;
        }
        if(([url contains:@"codeclimate.com"]  || [url contains:@"coveralls.io"] || [url contains:@"travis-ci.org"]) && [mainFrameURL rangeOfString:@"/Ruby%20DocSets/"].location == NSNotFound && [mainFrameURL rangeOfString:@"/Cocoa%20DocSets/"].location == NSNotFound && [mainFrameURL rangeOfString:@"/Cocoa%20DocSets/"].location == NSNotFound && [mainFrameURL rangeOfString:@"/Hex%20DocSets/"].location == NSNotFound && ([mainFrameURL rangeOfString:@"/Versioned%20DocSets/"].location == NSNotFound || [mainFrameURL rangeOfString:@"DHDocsetDownloader/"].location != NSNotFound) && ![url hasPrefix:@"file://"])
        {
            return YES;
        }
        
        BOOL isJSEnabled = NO;
        BOOL blockOnlineResources = NO;
        NSString *platform = nil;
        BOOL isHTTPRequest = ([url hasCaseInsensitivePrefix:@"http"]);
        BOOL isJSRequest = [[[url stringByDeletingPathFragment] pathExtension] rangeOfString:@"js"].location != NSNotFound;
        if(isHTTPRequest || isJSRequest)
        {
            if([DHRemoteServer sharedServer].connectedRemote)
            {
                NSDictionary *userInfo = [DHRemoteProtocol lastResponseUserInfo];
                platform = userInfo[@"platform"];
                isJSEnabled = [userInfo[@"javaScriptEnabled"] boolValue];
                blockOnlineResources = [userInfo[@"blocksOnline"] boolValue];
            }
            else
            {
                DHDocset *docset = [[DHDocsetManager sharedManager] docsetForDocumentationPage:mainFrameURL];
                platform = docset.platform;
                isJSEnabled = docset.isJavaScriptEnabled;
                blockOnlineResources = docset.blocksOnlineResources;
            }
        }
        
        if(([mainFrameURL containsAny:@[@"SciPy.docset", @"NumPy.docset"]]) && isHTTPRequest)
        {
            if(![url contains:@"mathjax"])
            {
                return YES;
            }
        }
        if(([mainFrameURL containsAny:@[@"SQLAlchemy.docset", @"RequireJS.docset", @"Tornado.docset"]] || blockOnlineResources) && isHTTPRequest)
        {
            if([mainFrameURL containsAny:@[@"Julia.docset"]] && [url contains:@"mathjax"])
            {
                return NO;
            }
            return YES;
        }
        if([mainFrameURL contains:@"jQuery%20UI.docset"] || [mainFrameURL contains:@"jQuery%20Mobile.docset"] || [mainFrameURL contains:@"jQuery.docset"] || [mainFrameURL contains:@"Foundation.docset"])
        {
            return NO;
        }
        if(isJSRequest)
        {
            if([url contains:@"Sass.docset"] || [url rangeOfString:@"UnderscoreJS.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"BackboneJS.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"Bootstrap.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url contains:@"CSS.docset"] || [url contains:@"HTML.docset"] || [url contains:@"XSLT.docset"] || [url contains:@"XUL.docset"] || [url contains:@"SVG.docset"] || [url contains:@"JavaScript.docset"])
            {
                return NO;
            }
            if([url contains:@"Dojo.docset"] || [url contains:@"Elixir.docset"] || [url contains:@"KnockoutJS.docset"] || [url contains:@"PhoneGap.docset"] || [url contains:@"MarionetteJS.docset"])
            {
                return NO;
            }
            if([url contains:@"Bourbon.docset"] || [url contains:@"Puppet.docset"] || [url contains:@"Neat.docset"] || [url contains:@"Xojo.docset"] || [url contains:@"Redis.docset"] || [url contains:@"sproutcore.docset"])
            {
                return NO;
            }
            if([url rangeOfString:@"Compass.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url contains:@"Processing.docset"])
            {
                return NO;
            }
            if([url contains:@"Laravel.docset"])
            {
                return NO;
            }
            if([url contains:@"Sencha%20Touch.docset"] || [url contains:@"ExtJS.docset"] || [url contains:@"Appcelerator%20Titanium.docset"])
            {
                return NO;
            }
            if([url rangeOfString:@"Zend_Framework.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([mainFrameURL contains:@"AngularJS.docset"] || [url rangeOfString:@"PrototypeJS.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"Go.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"RubyMotion.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"Ruby.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"Ruby%20on%20Rails.docset" options:NSCaseInsensitiveSearch].location != NSNotFound && ![[url lastPathComponent] isEqualToString:@"main.js"])
            {
                return NO;
            }
            if([url rangeOfString:@"Cappuccino.docset" options:NSCaseInsensitiveSearch].location != NSNotFound && ([url hasSuffix:@"jquery.js"] || [url hasSuffix:@"dynsections.js"]))
            {
                return NO;
            }
            if([url rangeOfString:@"Unity%203D.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"CoffeeScript.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"Yii.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"Scala.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"Akka.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url contains:@"/dash_scaladoc/"])
            {
                return NO;
            }
            if([url rangeOfString:@"YUI.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"Haskell.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"Android.docset" options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return NO;
            }
            if([url rangeOfString:@"Drupal.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"CodeIgniter.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"Joomla.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"Symfony.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"TYPO3.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"Cocos2D-X.docset" options:NSCaseInsensitiveSearch].location != NSNotFound || [url rangeOfString:@"Zend_Framework.docset"].location != NSNotFound)
            {
                return NO;
            }
            if(isJSEnabled)
            {
                return NO;
            }
            if([platform isEqualToString:@"java"] || [platform isEqualToString:@"playjava"] || [platform isEqualToString:@"groovy"] || [platform isEqualToString:@"javafx"] || [platform isEqualToString:@"scaladoc"])
            {
                return NO;
            }
            if([[request mainDocumentURL] isEqual:[request URL]])
            {
                return NO;
            }
            return YES;
        }
        if([url rangeOfString:@"://developer.mozilla.org"].location != NSNotFound || [url rangeOfString:@"google.com/jsapi"].location != NSNotFound)
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
    NSString *path = [[self.request URL] path];
    NSString *extension = [path pathExtension];
    NSString *mimeType = [NSString mimeTypeForPathExtension:extension];
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request URL]
                                                        MIMEType:mimeType
                                           expectedContentLength:-1
                                                textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)stopLoading
{

}

@end
