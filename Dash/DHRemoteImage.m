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

#import "DHRemoteImage.h"

@implementation DHRemoteImage

- (id)initWithCoder:(NSCoder *)decoder
{
    UIImage *image = nil;
    if([decoder containsValueForKey:@"name"])
    {
        image = [UIImage imageNamed:[decoder decodeObjectForKey:@"name"]];
    }
    else if([decoder containsValueForKey:@"data"])
    {
        image = [UIImage imageWithData:[decoder decodeObjectForKey:@"data"]];
    }
    image = (image) ? image : [UIImage imageNamed:@"Other"];
    return (id)image;
}

@end
