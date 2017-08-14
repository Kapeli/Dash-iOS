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

#import "DHWebView.h"
#import "DHCSS.h"

@implementation DHWebView

- (void)layoutSubviews
{
    [super layoutSubviews];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateViewPortContent:self.frame];
    });
}

- (void)updateViewPortContent:(CGRect)frame
{
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('dash_viewport').setAttribute('content', '%@');", [DHWebView viewportContent:frame]]];
}

+ (NSString *)viewportContent:(CGRect)frame
{
    NSString *content = [NSString stringWithFormat:@"width=%ld", (long)frame.size.width];
    return [content stringByAppendingString:@", initial-scale=1"];
}

- (void)setHasHistory:(BOOL)hasHistory
{
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id documentView = [self performSelector:NSSelectorFromString(@"_documentView")];
        id webView = [documentView performSelector:NSSelectorFromString(@"webView")];
        SEL selector = NSSelectorFromString(@"setMaintainsBackForwardList:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[webView methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:webView];
        [invocation setArgument:&hasHistory atIndex:2];
        [invocation invoke];
#pragma clang diagnostic pop
    }
    @catch(NSException *exception) { NSLog(@"%@ %@", exception, [exception callStackSymbols]); }
}

- (void)resetHistory
{
    [self setHasHistory:NO];
    [self setHasHistory:YES];
}

@end
