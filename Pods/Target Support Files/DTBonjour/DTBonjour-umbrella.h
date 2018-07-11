#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DTBonjourDataChunk.h"
#import "DTBonjourDataConnection.h"
#import "DTBonjourServer.h"
#import "NSScanner+DTBonjour.h"

FOUNDATION_EXPORT double DTBonjourVersionNumber;
FOUNDATION_EXPORT const unsigned char DTBonjourVersionString[];

