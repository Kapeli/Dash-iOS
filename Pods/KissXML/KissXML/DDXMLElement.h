#import <Foundation/Foundation.h>
#import "DDXMLNode.h"

/**
 * Welcome to KissXML.
 * 
 * The project page has documentation if you have questions.
 * https://github.com/robbiehanson/KissXML
 * 
 * If you're new to the project you may wish to read the "Getting Started" wiki.
 * https://github.com/robbiehanson/KissXML/wiki/GettingStarted
 * 
 * KissXML provides a drop-in replacement for Apple's NSXML class cluster.
 * The goal is to get the exact same behavior as the NSXML classes.
 * 
 * For API Reference, see Apple's excellent documentation,
 * either via Xcode's Mac OS X documentation, or via the web:
 * 
 * https://github.com/robbiehanson/KissXML/wiki/Reference
**/

NS_ASSUME_NONNULL_BEGIN
@interface DDXMLElement : DDXMLNode
{
}

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name URI:(nullable NSString *)URI;
- (instancetype)initWithName:(NSString *)name stringValue:(nullable NSString *)string;
- (nullable instancetype)initWithXMLString:(NSString *)string error:(NSError **)error;

#pragma mark --- Elements by name ---

- (NSArray<DDXMLElement *> *)elementsForName:(NSString *)name;
- (NSArray<DDXMLElement *> *)elementsForLocalName:(NSString *)localName URI:(nullable NSString *)URI;

#pragma mark --- Attributes ---

- (void)addAttribute:(DDXMLNode *)attribute;
- (void)removeAttributeForName:(NSString *)name;
@property (nullable, copy) NSArray<DDXMLNode *> *attributes;
//- (void)setAttributesAsDictionary:(NSDictionary *)attributes;
- (nullable DDXMLNode *)attributeForName:(NSString *)name;
//- (DDXMLNode *)attributeForLocalName:(NSString *)localName URI:(NSString *)URI;

#pragma mark --- Namespaces ---

- (void)addNamespace:(DDXMLNode *)aNamespace;
- (void)removeNamespaceForPrefix:(NSString *)name;
@property (nullable, copy) NSArray<DDXMLNode *> *namespaces; //primitive
- (nullable DDXMLNode *)namespaceForPrefix:(NSString *)prefix;
- (nullable DDXMLNode *)resolveNamespaceForName:(NSString *)name;
- (nullable NSString *)resolvePrefixForNamespaceURI:(NSString *)namespaceURI;

#pragma mark --- Children ---

- (void)insertChild:(DDXMLNode *)child atIndex:(NSUInteger)index;
//- (void)insertChildren:(NSArray *)children atIndex:(NSUInteger)index;
- (void)removeChildAtIndex:(NSUInteger)index;
- (void)setChildren:(nullable NSArray<DDXMLNode *> *)children;
- (void)addChild:(DDXMLNode *)child;
//- (void)replaceChildAtIndex:(NSUInteger)index withNode:(DDXMLNode *)node;
//- (void)normalizeAdjacentTextNodesPreservingCDATA:(BOOL)preserve;

@end
NS_ASSUME_NONNULL_END
