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

#import "NSObject+DHUtils.h"
#import "DHJavaScriptBridge.h"

@implementation NSObject (DHUtils)

- (BOOL)callStackIsRestoring
{
    return NO;
    return [[NSArray arrayWithArray:[NSThread callStackSymbols]] objectsContainString:@"restoreState"];
}

- (void)webView:(id)unused didCreateJavaScriptContext:(JSContext*)ctx forFrame:(id)frame
{
    ctx[@"window"][@"dash"] = [DHJavaScriptBridge sharedBridge];
}

- (NSString *)getNSString {
    if ([self isKindOfClass:NSString.class]) {
        return (NSString *)self;
    } else {
        return nil;
    }
}
@end
