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

#import "NSArray+DHUtils.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@implementation NSArray (DHUtils)

- (NSArray *)characterIndexTitles
{
    NSMutableOrderedSet *chars = [NSMutableOrderedSet orderedSet];
    for(id obj in self)
    {
        NSString *character = [([obj isKindOfClass:[NSString class]]) ? [obj firstChar] : [[obj stringValue] firstChar] uppercaseString];
        [chars addObject:character];
    }
    return [chars array];
}

- (NSInteger)indexOfFirstObjectThatStartsWithCharacter:(NSString *)aCharacter
{
    NSUInteger i = 0;
    for(id obj in self)
    {
        NSString *character = [([obj isKindOfClass:[NSString class]]) ? [obj firstChar] : [[obj stringValue] firstChar] uppercaseString];
        if([character isEqualToString:aCharacter])
        {
            return i;
        }
        ++i;
    }
    return NSNotFound;
}

- (BOOL)objectsContainString:(NSString *)string
{
    for(NSString *obj in self)
    {
        if([obj contains:string])
        {
            return YES;
        }
    }
    return NO;
}

+ (NSMutableArray *)currentIPAddresses
{
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

    NSMutableArray *addresses = [NSMutableArray array];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    [addresses addObject:@(addrBuf)];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return addresses;
}

@end
