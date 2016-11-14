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

#import "DHRemote.h"

@implementation DHRemote

+ (instancetype)remoteWithName:(NSString *)name icon:(UIImage *)icon
{
    DHRemote *remote = [[self alloc] init];
    remote.name = name;
    remote.icon = icon;
    return remote;
}

- (BOOL)isEqual:(id)object
{
    return [self.name isEqualToString:[object name]];
}

- (void)connect
{
    [DHRemoteServer sharedServer].connectedRemote = self;
    [[DHRemoteServer sharedServer] sendObject:nil forRequestName:@"connect" encrypted:YES toMacName:self.name];
}

- (void)disconnect
{
    [DHRemoteServer sharedServer].requestsQueue = [NSMutableDictionary dictionary];
    [[DHRemoteServer sharedServer] sendObject:nil forRequestName:@"disconnect" encrypted:YES toMacName:self.name];
    [DHRemoteServer sharedServer].connectedRemote = nil;
}

@end
