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

#import "DHAppleActiveLanguage.h"

@implementation DHAppleActiveLanguage

+ (DHAppleActiveLanguage *)sharedActiveLanguage
{
    static dispatch_once_t pred;
    static DHAppleActiveLanguage *_singleton = nil;
    
    dispatch_once(&pred, ^{
        _singleton = [[DHAppleActiveLanguage alloc] init];
        [_singleton setUp];
    });
    return _singleton;
}

- (void)setUp
{
    self.activeLanguage = [[NSUserDefaults standardUserDefaults] integerForKey:DHNewAppleActiveLanguageKey];
}

+ (NSInteger)currentLanguage
{
    return [[DHAppleActiveLanguage sharedActiveLanguage] activeLanguage];
}

+ (void)setLanguage:(NSInteger)language
{
    [[NSUserDefaults standardUserDefaults] setInteger:language forKey:DHNewAppleActiveLanguageKey];
    [DHAppleActiveLanguage sharedActiveLanguage].activeLanguage = language;
}

@end
