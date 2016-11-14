//
//  NSScanner+DTBonjour.m
//  DTBonjour
//
//  Created by Oliver Drobnik on 15.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSScanner+DTBonjour.h"

@implementation NSScanner (DTBonjour)

- (BOOL)scanBonjourConnectionHeaders:(NSDictionary **)headers
{
	NSString *headerName;
	
	NSUInteger positionBeforeScanning = [self scanLocation];
	
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	while (!self.isAtEnd)
	{
		if (![self scanUpToString:@":" intoString:&headerName])
		{
			self.scanLocation = positionBeforeScanning;
			return NO;
		}
		
		// skip colon
		[self scanString:@":" intoString:NULL];
		
		NSString *headerValue;
		if ([self scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&headerValue])
		{
			tmpDict[headerName] = headerValue;
		}
	}
	
	if (headers)
	{
		*headers = [tmpDict copy];
	}
	
	return YES;
}

@end
