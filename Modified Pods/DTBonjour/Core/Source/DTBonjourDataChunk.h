//
//  DTBonjourDataChunk.h
//  DTBonjour
//
//  Created by Oliver Drobnik on 15.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DTBonjourDataConnection.h"


/**
 This class represents an object that is being transmitted as a chunk of data comprised of a header and the raw data.
 */

@interface DTBonjourDataChunk : NSObject

/**
 @name Creating Data Chunks
 */

/**
 Creates a data chunk meant for sending.
 @param object An object to be encoded and transmitted
 @param encoding The transport encoding to be used for encoding the object
 @param error An optional error output parameter for when the object cannot be encoded
 */
- (id)initWithObject:(id)object encoding:(DTBonjourDataConnectionContentType)encoding error:(NSError **)error;

/**
 Creates a data chunk meant for receiving.
 */
- (id)initForReading;

/**
 @name Getting Information
 */

/**
 @returns `YES` if all bytes have been written/read
 */
- (BOOL)isTransmissionComplete;

/**
 Number of bytes of the receiver
 */
@property (nonatomic, readonly) NSUInteger totalBytes;

/**
 Number of bytes that have been transferred already
 */
@property (nonatomic, readonly) NSUInteger numberOfTransferredBytes;

/**
 Sequence number of this chunk on the connection
*/
@property (nonatomic, readonly) NSUInteger sequenceNumber;

/**
 @name Reading/Writing
 */

/**
 Writes the as many bytes to the output stream as it would accept
 @param stream The output stream to write to
 @returns The number of bytes written. -1 means that there was an error.
 */
- (NSInteger)writeToOutputStream:(NSOutputStream *)stream;

/**
 Reads from the input stream and initializes the header and payload as the necessary data becomes available.
 @param stream The input stream to read from
 @returns The number of bytes read. -1 means that there was an error.
 */
- (NSInteger)readFromInputStream:(NSInputStream *)stream;

/**
 Decodes the object contained in the received data.
 
 Note: You should only call this method once transmission is complete.
 @see isTransmissionComplete
 */
- (id)decodedObject;


@end
