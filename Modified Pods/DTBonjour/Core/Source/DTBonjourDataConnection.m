//
//  DTBonjourDataConnection.m
//  DTBonjour
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import "DTBonjourDataConnection.h"
#import "DTBonjourDataChunk.h"
#import "NSScanner+DTBonjour.h"

#import <Foundation/NSJSONSerialization.h>

#define kDTBonjourQNetworkAdditionsCheckSEL NSSelectorFromString(@"netService:didAcceptConnectionWithInputStream:outputStream:")

NSTimeInterval DTBonjourDataConnectionDefaultTimeout = 60.0;
NSString * DTBonjourDataConnectionErrorDomain = @"DTBonjourDataConnection";

@interface NSNetService (QNetworkAdditions)
 
- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr 
    outputStream:(out NSOutputStream **)outputStreamPtr;
 
@end
 
@implementation NSNetService (QNetworkAdditions)
 
- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr 
    outputStream:(out NSOutputStream **)outputStreamPtr
    // The following works around three problems with 
    // -[NSNetService getInputStream:outputStream:]:
    //
    // o <rdar://problem/6868813> -- Currently the returns the streams with 
    //   +1 retain count, which is counter to Cocoa conventions and results in 
    //   leaks when you use it in ARC code.
    //
    // o <rdar://problem/9821932> -- If you create two pairs of streams from 
    //   one NSNetService and then attempt to open all the streams simultaneously, 
    //   some of the streams might fail to open.
    //
    // o <rdar://problem/9856751> -- If you create streams using 
    //   -[NSNetService getInputStream:outputStream:], start to open them, and 
    //   then release the last reference to the original NSNetService, the 
    //   streams never finish opening.  This problem is exacerbated under ARC 
    //   because ARC is better about keeping things out of the autorelease pool.
{
    BOOL                result;
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
 
    result = NO;
    
    readStream = NULL;
    writeStream = NULL;
    
    if ( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) ) {
        CFNetServiceRef     netService;
 
        netService = CFNetServiceCreate(
            NULL, 
            (__bridge CFStringRef) [self domain], 
            (__bridge CFStringRef) [self type], 
            (__bridge CFStringRef) [self name], 
            0
        );
        if (netService != NULL) {
            CFStreamCreatePairWithSocketToNetService(
                NULL, 
                netService, 
                ((inputStreamPtr  != nil) ? &readStream  : NULL), 
                ((outputStreamPtr != nil) ? &writeStream : NULL)
            );
            CFRelease(netService);
        }
        
        // We have failed if the client requested an input stream and didn't 
        // get one, or requested an output stream and didn't get one.  We also 
        // fail if the client requested neither the input nor the output 
        // stream, but we don't get here in that case.
        
        result = ! ((( inputStreamPtr != NULL) && ( readStream == NULL)) || 
                    ((outputStreamPtr != NULL) && (writeStream == NULL)));
    }
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
    
    return result;
}
 
@end

@interface DTBonjourDataConnection () <NSStreamDelegate>

@end

@interface DTBonjourDataChunk (private)

// make read-only property assignable
@property (nonatomic, assign) NSUInteger sequenceNumber;

@end

typedef enum
{
	DTBonjourDataConnectionExpectedDataTypeNothing,
	DTBonjourDataConnectionExpectedDataTypeHeader,
	DTBonjourDataConnectionExpectedDataTypeData
} DTBonjourDataConnectionExpectedDataType;

@implementation DTBonjourDataConnection
{
	NSInputStream *_inputStream;
	NSOutputStream *_outputStream;
	
	NSMutableArray *_outputQueue;
	DTBonjourDataChunk *_receivingChunk;

	NSUInteger _chunkSequenceNumber;
	
	__weak id <DTBonjourDataConnectionDelegate> _delegate;
}

- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle originAddress:(NSString *)originAddress
{
	self = [super init];
	
	if (self)
	{
        self.originAddress = originAddress;
		CFReadStreamRef readStream = NULL;
		CFWriteStreamRef writeStream = NULL;
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
		
		if (readStream && writeStream)
		{
			CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			
			_inputStream = (__bridge_transfer NSInputStream *)readStream;
			_outputStream = (__bridge_transfer NSOutputStream *)writeStream;
			
			_outputQueue = [[NSMutableArray alloc] init];
		}
		else
		{
			close(nativeSocketHandle);
			
			return nil;
		}
	}
	
	return self;
}

- (id)initWithService:(NSNetService *)service
{
	self = [super init];
	
	if (self)
	{
  	NSInputStream *in;
    NSOutputStream *out;

    if (![[service delegate] respondsToSelector:kDTBonjourQNetworkAdditionsCheckSEL])
    {
      // Older iOS/OSX versions need a patch for getting input and output
      // streams see the `QNetworkAdditions` above. (If the delegate does not
      // implement the `kDTBonjourQNetworkAdditionsCheck` selector, we can
      // simply use the patched version.
      if (![service qNetworkAdditions_getInputStream:&in outputStream:&out])
        return nil;
    }
    else
    {
      // iOS7/OSX10.9
      if (![service getInputStream:&in outputStream:&out])
        return nil;
    }

		_inputStream = in;
    _outputStream = out;
		_outputQueue = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (id)initWithInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream
{
	self = [super init];
	
	if (self)
	{
  	_inputStream = inStream;
    _outputStream = outStream;
		_outputQueue = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	_delegate = nil;
	[self close];
}

- (BOOL)openWithTimeout:(NSTimeInterval)timeout
{
	[_inputStream  setDelegate:self];
	[_outputStream setDelegate:self];
	[_inputStream  scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[_inputStream  open];
	[_outputStream open];
	
  __weak id weakSelf = self;
  double delayInSeconds = timeout;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    // No connection after timeout, closing.
    if (![weakSelf isOpen]) {
    	[weakSelf close];
    }
  });
  
	return YES;
}

- (BOOL)open
{
	return [self openWithTimeout:DTBonjourDataConnectionDefaultTimeout];
}

- (void)close
{
	if (!_inputStream&&!_outputStream)
	{
		return;
	}
	
	[_inputStream  setDelegate:nil];
	[_outputStream setDelegate:nil];
	[_inputStream  close];
	[_outputStream close];
	[_inputStream  removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	_inputStream = nil;
	_outputStream = nil;
	
	if ([_delegate respondsToSelector:@selector(connectionDidClose:)])
		[_delegate connectionDidClose:self];
}

- (BOOL)isOpen
{
	if (!_inputStream)
		return NO;
	
	NSStreamStatus inputStatus = [_inputStream streamStatus];
  NSStreamStatus outputStatus = [_outputStream streamStatus];
  
  if (NSStreamStatusOpen != inputStatus)
  	return NO;
  
  if (NSStreamStatusOpen != outputStatus)
  	return NO;
  
	return YES;
}

- (void)_startOutput
{
	if (![_outputQueue count])
	{
		return;
	}
	
	DTBonjourDataChunk *chunk = _outputQueue[0];
	
	if (0 == chunk.numberOfTransferredBytes)
	{
		// nothing sent yet
		if ([_delegate respondsToSelector:@selector(connection:willStartSendingChunk:)])
		{
			[_delegate connection:self willStartSendingChunk:chunk];
		}
	}
	
	NSInteger writtenBytes = [chunk writeToOutputStream:_outputStream];
	
	if (writtenBytes > 0)
	{
		if ([_delegate respondsToSelector:@selector(connection:didSendBytes:ofChunk:)])
		{
			[_delegate connection:self didSendBytes:writtenBytes ofChunk:chunk];
		}
		
		// If we didn't write all the bytes we'll continue writing them in response to the next
		// has-space-available event.
		
		if ([chunk isTransmissionComplete])
		{
			[_outputQueue removeObject:chunk];
			
			if ([_delegate respondsToSelector:@selector(connection:didFinishSendingChunk:)])
			{
				[_delegate connection:self didFinishSendingChunk:chunk];
			}
		}
	}
	else
	{
		// A non-positive result from -write:maxLength: indicates a failure of some form; in this
		// simple app we respond by simply closing down our connection.
		[self close];
	}
}

#pragma mark - Public Interface

- (BOOL)sendObject:(id)object error:(NSError **)error
{
	if (![self isOpen])
	{
		if (error)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Connection is not open"};
			*error = [NSError errorWithDomain:@"DTBonjourDataConnection" code:1 userInfo:userInfo];
		}
		
		return NO;
	}
	
	DTBonjourDataChunk *newChunk = [[DTBonjourDataChunk alloc]
  	initWithObject:object
    encoding:self.sendingContentType
    error:error];
	
	if (!newChunk)
		return NO;
	
	newChunk.sequenceNumber = _chunkSequenceNumber;

	BOOL queueWasEmpty = (![_outputQueue count]);
	
	[_outputQueue addObject:newChunk];
	
	if (queueWasEmpty && _outputStream.streamStatus == NSStreamStatusOpen)
	{
  	dispatch_async(dispatch_get_main_queue(), ^{
      [self _startOutput];
    });
	}

	return YES;
}

#pragma mark - NSStream Delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent
{
	switch(streamEvent)
	{
		case NSStreamEventOpenCompleted:
		{
    	if ([_delegate respondsToSelector:@selector(connectionDidOpen:)]) {
      	if ([self isOpen] && aStream == _outputStream) {
          [_delegate connectionDidOpen:self];
        }
      }
			break;
		}
			
		case NSStreamEventHasBytesAvailable:
		{
			if (!_receivingChunk)
			{
				// start reading a new chunk
				_receivingChunk = [[DTBonjourDataChunk alloc] initForReading];
                
                // nothing received yet
                if ([_delegate respondsToSelector:@selector(connection:willStartReceivingChunk:)])
                {
                    [_delegate connection:self willStartReceivingChunk:_receivingChunk];
                }
			}
			
			// continue reading
			NSInteger actuallyRead = [_receivingChunk readFromInputStream:_inputStream];
			
			if (actuallyRead<0)
			{
				[self close];
				break;
			}
            
            if ([_delegate respondsToSelector:@selector(connection:didReceiveBytes:ofChunk:)])
            {
                [_delegate connection:self didReceiveBytes:actuallyRead ofChunk:_receivingChunk];
            }
			
			if ([_receivingChunk isTransmissionComplete])
			{
                if ([_delegate respondsToSelector:@selector(connection:didFinishReceivingChunk:)])
                {
                    [_delegate connection:self didFinishReceivingChunk:_receivingChunk];
                }
                
				if ([_delegate respondsToSelector:@selector(connection:didReceiveObject:)])
				{
					id decodedObject = [_receivingChunk decodedObject];
					
					[_delegate connection:self didReceiveObject:decodedObject];
				}

				// we're done with this chunk
				_receivingChunk = nil;
			}
			
			break;
		}
			
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"Error occurred: %@", [aStream.streamError localizedDescription]);
  
      // Intentional fall-through.
		}
			
		case NSStreamEventEndEncountered:
		{
			[self close];
			
			break;
		}
			
		case NSStreamEventHasSpaceAvailable:
		{
			if ([_outputQueue count])
			{
				[self _startOutput];
			}
			
			break;
		}
			
		default:
		{
			// do nothing
			break;
		} 
	}
}


#pragma mark - Properties

@synthesize delegate = _delegate;

@end
