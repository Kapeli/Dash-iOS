#import <Foundation/Foundation.h>

@interface NSString (GTM)

- (NSString *)stringByUnescapingFromHTML;
+ (NSString *)unescapeString:(NSString *)string;
- (NSString *)stringByEscapingForAsciiHTML;
- (NSString *)gtm_stringByEscapingHTMLUsingTable:(void*)table ofSize:(NSUInteger)size escapingUnicode:(BOOL)escapeUnicode;
- (NSString *)stringByEscapingForHTML;

@end