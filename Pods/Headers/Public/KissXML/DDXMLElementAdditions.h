#import <Foundation/Foundation.h>
#import "DDXML.h"

// These methods are not part of the standard NSXML API.
// But any developer working extensively with XML will likely appreciate them.

NS_ASSUME_NONNULL_BEGIN
@interface DDXMLElement (DDAdditions)

+ (nullable DDXMLElement *)elementWithName:(NSString *)name xmlns:(NSString *)ns;

- (nullable DDXMLElement *)elementForName:(NSString *)name;
- (nullable DDXMLElement *)elementForName:(NSString *)name xmlns:(NSString *)xmlns;

- (nullable NSString *)xmlns;
- (void)setXmlns:(NSString *)ns;

- (NSString *)prettyXMLString;
- (NSString *)compactXMLString;

- (void)addAttributeWithName:(NSString *)name stringValue:(NSString *)string;

- (NSDictionary<NSString*,NSString*> *)attributesAsDictionary;

@end
NS_ASSUME_NONNULL_END