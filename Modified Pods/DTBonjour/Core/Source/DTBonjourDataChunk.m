//
//  DTBonjourDataChunk.m
//  DTBonjour
//
//  Created by Oliver Drobnik on 15.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTBonjourDataChunk.h"
#import "DTBonjourDataConnection.h"
#import "NSScanner+DTBonjour.h"

#import <Foundation/NSJSONSerialization.h>


@interface DTBonjourDataChunk ()

@property (nonatomic, assign) NSUInteger sequenceNumber;

@end

@implementation DTBonjourDataChunk
{
	NSMutableData *_data;
	
	NSUInteger _numberOfTransferredBytes;
	NSUInteger _totalBytes;
	NSUInteger _sequenceNumber;
	
	DTBonjourDataConnectionContentType _encoding;
	
	NSRange _rangeOfHeader;
	NSUInteger _contentLength;
}

- (id)initWithObject:(id)object encoding:(DTBonjourDataConnectionContentType)encoding error:(NSError **)error
{
	self = [super init];
	
	if (self)
	{
		_encoding = encoding;
		
		if (![self _encodeObject:object error:error])
		{
			return nil;
		}
	}
	
	return self;
}

- (id)initForReading
{
	self = [super init];
	
	if (self)
	{
		_data = [[NSMutableData alloc] initWithCapacity:1000];
	}
	
	return self;
}



- (BOOL)_encodeObject:(id)object error:(NSError **)error
{
	NSData *archivedData = nil;
	NSString *contentType = nil;
	
	switch (_encoding)
	{
		case DTBonjourDataConnectionContentTypeJSON:
		{
			// check if our sending encoding type permits this object
			if (![NSJSONSerialization isValidJSONObject:object])
			{
				if (error)
				{
					NSString *errorMsg = [NSString stringWithFormat:@"Object %@ is not a valid root object for JSON serialization", object];
					NSDictionary *userInfo = @{NSLocalizedDescriptionKey:errorMsg};
					*error = [NSError errorWithDomain:DTBonjourDataConnectionErrorDomain code:1 userInfo:userInfo];
				}
				
				return NO;
			}
			
			archivedData = [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
			
			if (!archivedData)
			{
				return NO;
			}
			
			contentType = @"application/json";
			
			break;
		}
			
		case DTBonjourDataConnectionContentTypeNSCoding:
		{
			// check if our sending encoding type permits this object
			if (![object conformsToProtocol:@protocol(NSCoding)])
			{
				if (error)
				{
					NSString *errorMsg = [NSString stringWithFormat:@"Object %@ does not conform to NSCoding", object];
					NSDictionary *userInfo = @{NSLocalizedDescriptionKey:errorMsg};
					*error = [NSError errorWithDomain:DTBonjourDataConnectionErrorDomain code:1 userInfo:userInfo];
				}
				
				return NO;
			}
			
			archivedData = [NSKeyedArchiver archivedDataWithRootObject:object];
			contentType = @"application/octet-stream";
			
			break;
		}
			
		default:
		{
			if (error)
			{
				NSString *errorMsg = [NSString stringWithFormat:@"Unknown encoding type %d", (int)_encoding];
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey:errorMsg};
				*error = [NSError errorWithDomain:DTBonjourDataConnectionErrorDomain code:1 userInfo:userInfo];
			}
			
			return NO;
		}
	}
	
	NSString *type = NSStringFromClass([object class]);
	NSString *header = [NSString stringWithFormat:@"PUT\r\nClass: %@\r\nContent-Type: %@\r\nSequence-Number: %ld\r\nContent-Length:%ld\r\n\r\n", type, contentType, (unsigned long)_sequenceNumber, (long)[archivedData length]];
	NSData *headerData = [header dataUsingEncoding:NSUTF8StringEncoding];

	_contentLength = [archivedData length];
	_rangeOfHeader = NSMakeRange(0, [headerData length]);
	
	_totalBytes = _rangeOfHeader.length + _contentLength;

	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:_totalBytes];
	
	[data appendData:headerData];
	[data appendData:archivedData];
	
	_data = data;
	
	return YES;
}

- (id)decodedObject
{
	if (!_totalBytes || [_data length] < _totalBytes)
	{
		NSLog(@"Insufficient data received yet for decoding object");
		return nil;
	}
	
	NSInteger indexAfterHeader = NSMaxRange(_rangeOfHeader);
	NSRange payloadRange = NSMakeRange(indexAfterHeader, _contentLength);
	NSData *payloadData = [_data subdataWithRange:payloadRange];
	
	// decode data
	id object = nil;
	
	if (_encoding == DTBonjourDataConnectionContentTypeJSON)
	{
		object = [NSJSONSerialization JSONObjectWithData:payloadData options:0 error:NULL];
	}
	else if (_encoding == DTBonjourDataConnectionContentTypeNSCoding)
	{
		object = [NSKeyedUnarchiver unarchiveObjectWithData:payloadData];
	}
	
	if (!object)
	{
		NSLog(@"Unable to decode object");
	}
	
	return object;
}


- (BOOL)_hasCompleteHeader
{
	// find end of header, \r\n\r\n
	NSData *headerEnd = [@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
	
	NSRange headerEndRange = [_data rangeOfData:headerEnd options:0 range:NSMakeRange(0, [_data length])];
	
	if (headerEndRange.location == NSNotFound)
	{
		// we don't have a complete header
		return NO;
	}
	
	// update the range
	_rangeOfHeader = NSMakeRange(0, headerEndRange.location + headerEndRange.length);
	
	return YES;
}

- (void)_decodeHeader
{
	NSAssert(_rangeOfHeader.length>0, @"Don't decode header if range is unknown yet");
	
	NSString *string = [[NSString alloc] initWithBytesNoCopy:(void *)[_data bytes] length:_rangeOfHeader.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
	
	if (!string)
	{
		NSLog(@"Error decoding header, not a valid NSString");
		return;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	if (![scanner scanString:@"PUT" intoString:NULL])
	{
		return;
	}
	
	NSDictionary *headers;
	if (![scanner scanBonjourConnectionHeaders:&headers])
	{
		return;
	}
	
	NSString *contentType = headers[@"Content-Type"];
	if ([contentType isEqualToString:@"application/json"])
	{
		_encoding = DTBonjourDataConnectionContentTypeJSON;
	}
	else if ([contentType isEqualToString:@"application/octet-stream"])
	{
		_encoding = DTBonjourDataConnectionContentTypeNSCoding;
	}
	else
	{
		NSLog(@"Unknown transport type: %@", contentType);
		return;
	}
	
	/*
	 // unused
	NSString *classString = headers[@"Class"];
	_receivingDataClass = NSClassFromString(classString);
	 */
	
	_sequenceNumber = [headers[@"Sequence-Number:"] unsignedIntegerValue];
	_contentLength = [[[NSNumberFormatter new] numberFromString:headers[@"Content-Length"]] unsignedIntegerValue];
	_totalBytes = _rangeOfHeader.length + _contentLength;
}

- (NSInteger)writeToOutputStream:(NSOutputStream *)stream
{
	// how many bytes there are still untransmitted
	NSUInteger maxLength = [_data length] - _numberOfTransferredBytes;
	
	if (!maxLength)
	{
		return 0;
	}

	// current write position
	const uint8_t *position = [_data bytes]+_numberOfTransferredBytes;
	
	NSInteger actuallyWritten = [stream write:position maxLength:maxLength];
	
	if (actuallyWritten>0)
	{
		_numberOfTransferredBytes += actuallyWritten;
	}
	
	return actuallyWritten;
}

- (NSInteger)readFromInputStream:(NSInputStream *)stream
{
	uint8_t buffer[2048*8];
	
	NSUInteger maxLength;

	BOOL readingHeader;
	
	if (!_rangeOfHeader.length)
	{
		maxLength = 1;
		readingHeader = YES;
	}
	else
	{
		maxLength = MIN(sizeof(buffer), (_totalBytes - _numberOfTransferredBytes));
		readingHeader = NO;
	}
	
	NSInteger actuallyRead = [stream read:(uint8_t *)buffer maxLength:maxLength];
	
	if (actuallyRead > 0)
	{
		[_data appendBytes:buffer length:actuallyRead];
		
		if (readingHeader)
		{
			if ([self _hasCompleteHeader])
			{
				[self _decodeHeader];
			}
		}
		
		_numberOfTransferredBytes += actuallyRead;
	}

	return actuallyRead;
}

- (BOOL)isTransmissionComplete
{
	if (!_totalBytes)
	{
		return NO;
	}
	
	return (_numberOfTransferredBytes == _totalBytes);
}

#pragma mark - Properties

@synthesize numberOfTransferredBytes = _numberOfTransferredBytes;
@synthesize totalBytes = _totalBytes;
@synthesize sequenceNumber = _sequenceNumber;
			  

@end
