#import <Foundation/Foundation.h>

@interface DHTester : NSObject

@property (assign) BOOL isIOS;

+ (DHTester *)sharedTester;
- (void)test;

@end
