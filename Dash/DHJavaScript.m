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

#import "DHJavaScript.h"
#import "DHCSS.h"
#import "Dash-Swift.h"
#import "DHWebViewController.h"

@implementation DHJavaScript

+ (DHJavaScript *)sharedJavaScript
{
    static dispatch_once_t pred;
    static DHJavaScript *_javaScript = nil;
    
    dispatch_once(&pred, ^{
        _javaScript = [[DHJavaScript alloc] init];
        _javaScript.javaScripts = [[NSMutableDictionary alloc] init];
    });
    return _javaScript;
}

- (NSString *)javaScriptInFile:(NSString *)file
{
    if(self.javaScripts[file])
    {
        return self.javaScripts[file];
    }
    NSString *javaScript = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:file ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
    self.javaScripts[file] = javaScript;
    return javaScript;
}

- (NSString *)zoomScriptWithFrame:(CGRect)frame
{
    return [NSString stringWithFormat:@"document.getElementById('dash_viewport').setAttribute('content', 'width=%ld, initial-scale=1');", (long)frame.size.width];
}

- (NSString *)injectCSSScript
{
    NSString *css = [DHCSS currentCSSStringWithTextModifier];
    css = [[css stringByReplacingOccurrencesOfString:@"\n" withString:@"\\\n"] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    return [NSString stringWithFormat:@"var style = document.createElement('style'); style.innerText = '%@'; document.head.insertBefore(style, document.head.childNodes[0]);", css];
}

- (NSString *)injectViewPortScript
{
    return [NSString stringWithFormat:@"var surogate = document.createElement('div'); surogate.innerHTML = \"<meta id='dash_viewport' name='viewport' content='%@'/>\"; var meta = surogate.childNodes[0]; document.head.appendChild(meta);", [DHWebView viewportContent:[DHWebViewController sharedWebViewController].webView.frame]];
}

@end
