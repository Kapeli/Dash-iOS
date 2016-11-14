//
//  DTBonjourServer.m
//  DTBonjour
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import "DTBonjourServer.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>

#import <CoreFoundation/CoreFoundation.h>

#import "DTBonjourDataConnection.h"
#import "DTBonjourDataChunk.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface DTBonjourServer() <NSNetServiceDelegate, DTBonjourDataConnectionDelegate>

- (void)_acceptConnection:(CFSocketNativeHandle)nativeSocketHandle originAddress:(NSString *)originAddress;

@end

// call-back function for incoming connections
static void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
	DTBonjourServer *server = (__bridge DTBonjourServer *)info;
	
	const struct sockaddr *sa = (const struct sockaddr *)CFDataGetBytePtr(address);
	
	sa_family_t family = sa->sa_family;
	
	NSString *ipString = nil;
	NSString *familyString = nil;
	NSUInteger port = 0;
	
	if (family == AF_INET)
	{
		familyString = @"IPv4";
		
		struct sockaddr_in addr4;
		CFDataGetBytes(address, CFRangeMake(0, sizeof(addr4)), (void *)&addr4);
		
		char str[INET_ADDRSTRLEN];
		inet_ntop(AF_INET, &(addr4.sin_addr), str, INET_ADDRSTRLEN);
		ipString = [[NSString alloc] initWithBytes:str length:strlen(str) encoding:NSUTF8StringEncoding];
		
		port = ntohs(addr4.sin_port);
	}
	else if (family == AF_INET6)
	{
		familyString = @"IPv6";
		
		struct sockaddr_in6 addr6;
		CFDataGetBytes(address, CFRangeMake(0, sizeof(addr6)), (void *)&addr6);
		
		char str[INET6_ADDRSTRLEN];
		inet_ntop(AF_INET6, &(addr6.sin6_addr), str, INET6_ADDRSTRLEN);
		ipString = [[NSString alloc] initWithBytes:str length:strlen(str) encoding:NSUTF8StringEncoding];
		
		port = ntohs(addr6.sin6_port);
	}
	
	NSLog(@"Accepting %@ connection from %@ on port %d", familyString, ipString, (int)port);
	
	// For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
    [server _acceptConnection:*(CFSocketNativeHandle *)data originAddress:ipString];
}


@implementation DTBonjourServer
{
	NSNetService *_service;
	NSDictionary *_TXTRecord;
	
	CFSocketRef _ipv4socket;
	CFSocketRef _ipv6socket;
	
	NSUInteger _port; // used port, assigned during start
	
	NSMutableSet *_connections;
	NSString *_bonjourType;
	
	__weak id <DTBonjourServerDelegate> _delegate;
}

- (id)init
{
	self = [super init];
	
	if (self)
	{
		if (![_bonjourType length])
		{
			return nil;
		}
		
		_connections = [[NSMutableSet alloc] init];
		
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
	}
	
	return self;
}

- (id)initWithBonjourType:(NSString *)bonjourType
{
	if (!bonjourType)
	{
		return nil;
	}
	
	_bonjourType = bonjourType;
	
	self = [self init];
	
	if (self)
	{
		
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_delegate = nil;

	[self stop];
}

- (BOOL)start
{
    if(!(_ipv4socket == NULL && _ipv6socket == NULL))
    {
        return NO;
    }
	
	CFSocketContext socketCtxt = {0, (__bridge void *) self, NULL, NULL, NULL};
	_ipv4socket = CFSocketCreate(kCFAllocatorDefault, AF_INET,  SOCK_STREAM, 0, kCFSocketAcceptCallBack, &ListeningSocketCallback, &socketCtxt);
	_ipv6socket = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, 0, kCFSocketAcceptCallBack, &ListeningSocketCallback, &socketCtxt);
	
	if (NULL == _ipv4socket || NULL == _ipv6socket)
	{
		[self stop];
		return NO;
	}
	
	static const int yes = 1;
	(void) setsockopt(CFSocketGetNative(_ipv4socket), SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));
	(void) setsockopt(CFSocketGetNative(_ipv6socket), SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));
	
	// Set up the IPv4 listening socket; port is 0, which will cause the kernel to choose a port for us.
	struct sockaddr_in addr4;
	memset(&addr4, 0, sizeof(addr4));
	addr4.sin_len = sizeof(addr4);
	addr4.sin_family = AF_INET;
	addr4.sin_port = htons(0);
	addr4.sin_addr.s_addr = htonl(INADDR_ANY);
	
	if (kCFSocketSuccess != CFSocketSetAddress(_ipv4socket, (__bridge CFDataRef) [NSData dataWithBytes:&addr4 length:sizeof(addr4)]))
	{
		[self stop];
		return NO;
	}
	
	// Now that the IPv4 binding was successful, we get the port number
	// -- we will need it for the IPv6 listening socket and for the NSNetService.
	NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_ipv4socket);
	if(!([addr length] == sizeof(struct sockaddr_in)))
    {
        return NO;
    }
    _port = ntohs(((const struct sockaddr_in *)[addr bytes])->sin_port);
	
	// Set up the IPv6 listening socket.
	struct sockaddr_in6 addr6;
	memset(&addr6, 0, sizeof(addr6));
	addr6.sin6_len = sizeof(addr6);
	addr6.sin6_family = AF_INET6;
	addr6.sin6_port = htons(self.port);
	memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
	if (kCFSocketSuccess != CFSocketSetAddress(_ipv6socket, (__bridge CFDataRef) [NSData dataWithBytes:&addr6 length:sizeof(addr6)]))
	{
		[self stop];
		return NO;
	}
	
	// Set up the run loop sources for the sockets.
	CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
	CFRelease(source4);
	
	CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6socket, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source6, kCFRunLoopCommonModes);
	CFRelease(source6);
	
	if (_ipv6socket)
	{
		CFSocketInvalidate(_ipv6socket);
		CFRelease(_ipv6socket);
		_ipv6socket = NULL;
	}
	
	if(!(self.port > 0 && self.port < 65536))
    {
        return NO;
    }
	_service = [[NSNetService alloc] initWithDomain:@"" type:_bonjourType name:@"" port:(int)_port];
	_service.delegate = self;
	
	if (_TXTRecord)
	{
		[_service setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:_TXTRecord]];
	}
	
	[_service publishWithOptions:0];
	
	return YES;
}

/*
 // this is the way to create the sockets on the Posix-level
- (BOOL)start
{
	CFSocketContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
	
	// create IPv4 socket
	int fd4 = socket(AF_INET, SOCK_STREAM, 0);
	
	// allow for reuse of local address
	static const int yes = 1;
	int err = setsockopt(fd4, SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));
	
	// a structure for the socket address
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = AF_INET;
	sin.sin_len = sizeof(sin);
	sin.sin_port = htons(0);  // asks kernel for arbitrary port number
	
	err = bind(fd4, (const struct sockaddr *) &sin, sin.sin_len);
	
	socklen_t addrLen = sizeof(sin);
	err = getsockname(fd4, (struct sockaddr *)&sin, &addrLen);
	err = listen(fd4, 5);
	
	// should have a port number now
	_port = sin.sin_port;
	
	if (!_port)
	{
		return NO;
	}
	
	// create a CFSocket for the file descriptor
	_ipv4socket = CFSocketCreateWithNative(NULL, fd4, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
	
	// create IPv6 socket
	int fd6 = socket(AF_INET6, SOCK_STREAM, 0);
	
	int one = 1;
	err = setsockopt(fd6, IPPROTO_IPV6, IPV6_V6ONLY, &one, sizeof(one));
	err = setsockopt(fd6, SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));
	
	struct sockaddr_in sin6;
	memset(&sin6, 0, sizeof(sin6));
	sin6.sin_family = AF_INET6;
	sin6.sin_len = sizeof(sin6);
	sin6.sin_port = sin.sin_port;  // uses same port as IPv4
	
	err = bind(fd6, (const struct sockaddr *) &sin6, sin6.sin_len);
	
	err = listen(fd6, 5);
	
	// create a CFSocket for the file descriptor
	_ipv6socket = CFSocketCreateWithNative(NULL, fd6, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
	
	// Set up the run loop sources for the sockets.
	CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
	CFRelease(source4);
	
	CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6socket, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source6, kCFRunLoopCommonModes);
	CFRelease(source6);
	_service = [[NSNetService alloc] initWithDomain:@"" // use all available domains
															type:_bonjourType
															name:@"" // uses default name of system
															port:ntohs(_port)];
	
	[_service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	_service.delegate = self;
	
	[_service publish];

#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
	
	return YES;
}
 */

- (void)stop
{
	// stop the bonjour advertising
	[_service stop];
	_service = nil;
	
	// Closes all the open connections.  The EchoConnectionDidCloseNotification notification will ensure
	// that the connection gets removed from the self.connections set.  To avoid mututation under iteration
	// problems, we make a copy of that set and iterate over the copy.
	for (DTBonjourDataConnection *connection in [_connections copy])
	{
		[connection close];
	}
	
	if (_ipv4socket)
	{
		CFSocketInvalidate(_ipv4socket);
		CFRelease(_ipv4socket);
		_ipv4socket = NULL;
	}
	
	if (_ipv6socket)
	{
		CFSocketInvalidate(_ipv6socket);
		CFRelease(_ipv6socket);
		_ipv6socket = NULL;
	}
}

- (void)_acceptConnection:(CFSocketNativeHandle)nativeSocketHandle originAddress:(NSString *)originAddress
{
	DTBonjourDataConnection *newConnection = [[DTBonjourDataConnection alloc] initWithNativeSocketHandle:nativeSocketHandle originAddress:originAddress];
	
	//DTBonjourDataConnection *newConnection = [[DTBonjourDataConnection alloc] initWithService:service];
	
	newConnection.delegate = self;
	[newConnection open];
	[_connections addObject:newConnection];
	
	if ([_delegate respondsToSelector:@selector(bonjourServer:didAcceptConnection:)])
	{
		[_delegate bonjourServer:self didAcceptConnection:newConnection];
	}
}

- (void)broadcastObject:(id)object
{
	for (DTBonjourDataConnection *connection in _connections)
	{
		NSError *error;
		
		if (![connection sendObject:object error:&error])
		{
			NSLog(@"%@", [error localizedDescription]);
		}
	}
}

#pragma mark - NSNetService Delegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	NSLog(@"Error publishing: %@", errorDict);
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	NSLog(@"My name: %@ port: %d", [sender name], (int)sender.port);
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	NSLog(@"Bonjour Service shut down");
}

#pragma mark - DTBonjourDataConnection Delegate
- (void)connection:(DTBonjourDataConnection *)connection didReceiveObject:(id)object
{
	if ([_delegate respondsToSelector:@selector(bonjourServer:didReceiveObject:onConnection:)])
	{
		[_delegate bonjourServer:self didReceiveObject:object onConnection:connection];
	}
}

- (void)connectionDidClose:(DTBonjourDataConnection *)connection
{
    if([_delegate respondsToSelector:@selector(connectionDidClose:)])
    {
        [(id)_delegate connectionDidClose:connection];
    }
	[_connections removeObject:connection];
}

#pragma mark - Notifications

- (void)appDidEnterBackground:(NSNotification *)notification
{
	[self stop];
}

- (void)appWillEnterForeground:(NSNotification *)notification
{
	[self start];
}

#pragma mark - Properties

- (NSSet *)connections
{
	// make a copy to be non-mutable
	return [_connections copy];
}

- (void)setTXTRecord:(NSDictionary *)TXTRecord
{
	_TXTRecord = TXTRecord;

	// update service if it is running
	if (_service)
	{
		[_service setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:_TXTRecord]];
	}
}

@synthesize TXTRecord = _TXTRecord;
@synthesize delegate = _delegate;
@synthesize port = _port;

@end
