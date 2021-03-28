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

#import "GZIP.h"
#import "NSData+GZIP.h"

FOUNDATION_EXPORT double GZIPVersionNumber;
FOUNDATION_EXPORT const unsigned char GZIPVersionString[];

