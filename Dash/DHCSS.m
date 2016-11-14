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

#import "DHCSS.h"

@implementation DHCSS

static int _activeAppleLanguage;
static long _textSizeAdjust;

+ (DHCSS *)sharedCSS
{
    static dispatch_once_t pred;
    static DHCSS *_css = nil;
    
    dispatch_once(&pred, ^{
        _css = [[DHCSS alloc] init];
        [_css setUp];
    });
    return _css;
}

- (void)setUp
{
    self.bothCSS = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"style" ofType:@"css"] encoding:NSUTF8StringEncoding error:nil];
    self.objcCSS = [self.bothCSS stringByAppendingString:@"body.jazz #bashful #language #obj_c + label, body.jazz #bashful #language #objective_c + label {background: rgba(0,136,204,1) !important;color: rgba(255,255,255,1) !important;border-radius: 2px !important;cursor: default !important;} body#reference.jazz:not(.swift) .Swift { display: none !important; } body#reference.jazz:not(.java_script) .code-sample .Swift:only-child {display:inline-block !important} body#reference.jazz:not(.swift) .height-container .z-module-import {display:none !important}"];
    self.swiftCSS = [self.bothCSS stringByAppendingString:@"body.jazz #bashful #language #swift + label {background: rgba(0,136,204,1) !important;color: rgba(255,255,255,1) !important;border-radius: 2px !important;cursor: default !important;} body#reference.jazz:not(.java_script) .Objective-C { display: none !important; } body#reference.jazz:not(.java_script) .code-sample .Objective-C:only-child {display:inline-block !important} body#reference.jazz:not(.java_script) .obj-c-only .height-container { display:none !important; } body#reference.jazz:not(.java_script) .obj-c-only .task-group-term a { display:block !important; text-decoration: line-through !important; -webkit-text-stroke-color: rgba(163,21,21,1) !important; -webkit-text-stroke-width: .0000000001px !important; } body.jazz:not(.java_script) .obj-c-only .task-group-term::after {content: '(Not available in Swift)' !important; color:rgba(163,21,21,1) !important; font-size:.8em !important; margin-left:5px !important; } body.jazz p.para.Swift {display:block !important} body.jazz .Swift { display: inline-block !important; } body.jazz #metadata_table .Swift { display: block !important; } body.jazz .task-group-term a.Swift, body.jazz #jump_to .Swift { display: block !important; } body.jazz .declaration .Swift { display: block !important; }"];
    self.bothCSS = [self.bothCSS stringByAppendingString:@"body.jazz #bashful #language #both + label {background: rgba(0,136,204,1) !important;color: rgba(255,255,255,1) !important;border-radius: 2px !important;cursor: default !important;}"];
    [self refreshActiveCSS];
    [self refreshTextSize];
}

- (void)refreshActiveCSS
{
    NSString *active = [[NSUserDefaults standardUserDefaults] objectForKey:DHActiveAppleLanguageKey];
    if([active isEqualToString:@"swift"])
    {
        _activeAppleLanguage = DHActiveAppleLanguageSwift;
    }
    else if([active isEqualToString:@"obj_c"] || [active isEqualToString:@"objective_c"])
    {
        _activeAppleLanguage = DHActiveAppleLanguageObjC;
    }
    else
    {
        _activeAppleLanguage = DHActiveAppleLanguageBoth;
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

+ (NSString *)currentCSSString
{
    DHCSS *css = [DHCSS sharedCSS];
    if(_activeAppleLanguage == DHActiveAppleLanguageBoth)
    {
        return css.bothCSS;
    }
    else if(_activeAppleLanguage == DHActiveAppleLanguageObjC)
    {
        return css.objcCSS;
    }
    else if(_activeAppleLanguage == DHActiveAppleLanguageSwift)
    {
        return css.swiftCSS;
    }
    return css.bothCSS;
}

+ (NSString *)currentCSSStringWithTextModifier
{
    return [NSString stringWithFormat:@"%@%@", [DHCSS currentCSSString], ([[DHCSS sharedCSS] shouldModifyTextSize]) ? [NSString stringWithFormat:@"\n\nbody {-webkit-text-size-adjust: %@}", [[DHCSS sharedCSS] textSizeAdjust]] : @""];
}

+ (int)activeAppleLanguage
{
    return _activeAppleLanguage;
}

- (void)refreshTextSize
{
    _textSizeAdjust = [[NSUserDefaults standardUserDefaults] integerForKey:@"DHTextSizeAdjust"];
}

- (NSString *)textSizeAdjust
{
    return [NSString stringWithFormat:@"%ld%%", 100+_textSizeAdjust];
}

- (BOOL)shouldModifyTextSize
{
    return _textSizeAdjust != 0;
}

- (void)modifyTextSize:(BOOL)increase
{
    if(increase)
    {
        _textSizeAdjust += 5;
    }
    else
    {
        _textSizeAdjust -= 5;
    }
    if(_textSizeAdjust < -70)
    {
        _textSizeAdjust = -70;
    }
    else if(_textSizeAdjust > 70)
    {
        _textSizeAdjust = 70;
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSLog(@"Text size adjust set to %ld", _textSizeAdjust);
    [[NSUserDefaults standardUserDefaults] setInteger:_textSizeAdjust forKey:@"DHTextSizeAdjust"];
}

@end
