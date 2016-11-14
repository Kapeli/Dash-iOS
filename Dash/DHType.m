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

#import "DHType.h"

@implementation DHType

@synthesize humanType;
@synthesize humanTypePlural;
@synthesize aliases;

+ (DHType *)typeWithHumanType:(NSString *)aHumanType humanPlural:(NSString *)aHumanTypePlural aliases:(id)someAliases
{
    DHType *type = [[DHType alloc] initWithHumanType:aHumanType humanPlural:aHumanTypePlural];
    [type setAliases:([someAliases isKindOfClass:[NSArray class]]) ? someAliases : @[someAliases]];
    return type;
}

+ (DHType *)typeWithHumanType:(NSString *)aHumanType humanPlural:(NSString *)aHumanTypePlural
{
    return [[DHType alloc] initWithHumanType:aHumanType humanPlural:aHumanTypePlural];
}

- (id)initWithHumanType:(NSString *)aHumanType humanPlural:(NSString *)aHumanTypePlural
{
    self = [super init];
    if(self)
    {
        self.humanType = aHumanType;
        self.humanTypePlural = aHumanTypePlural;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@ - %@", humanType, humanTypePlural, aliases];
}

@end
