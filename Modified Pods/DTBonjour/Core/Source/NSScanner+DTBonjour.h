//
//  NSScanner+DTBonjour.h
//  DTBonjour
//
//  Created by Oliver Drobnik on 15.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 Category extension for `NSScanner` to deal with scanning the headers used by DTBonjour
 */

@interface NSScanner (DTBonjour)

/**
 The receiver scans for DTBonjour headers.
 @param headers The output dictionary with the scanned headers
 @returns `YES` if successfully scanned the headers
 */
- (BOOL)scanBonjourConnectionHeaders:(NSDictionary **)headers;

@end
