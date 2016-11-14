#import <Foundation/Foundation.h>

@class DDXMLDocument;

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

enum {
	DDXMLInvalidKind                = 0,
	DDXMLDocumentKind,
	DDXMLElementKind,
	DDXMLAttributeKind,
	DDXMLNamespaceKind,
	DDXMLProcessingInstructionKind,
	DDXMLCommentKind,
	DDXMLTextKind,
	DDXMLDTDKind,
	DDXMLEntityDeclarationKind,
	DDXMLAttributeDeclarationKind,
	DDXMLElementDeclarationKind,
	DDXMLNotationDeclarationKind
};
typedef NSUInteger DDXMLNodeKind;

enum {
	DDXMLNodeOptionsNone            = 0,
	DDXMLNodeExpandEmptyElement     = 1 << 1,
	DDXMLNodeCompactEmptyElement    = 1 << 2,
	DDXMLNodePrettyPrint            = 1 << 17,
};


NS_ASSUME_NONNULL_BEGIN
@interface DDXMLNode : NSObject <NSCopying>

//- (instancetype)initWithKind:(DDXMLNodeKind)kind;

//- (instancetype)initWithKind:(DDXMLNodeKind)kind options:(NSUInteger)options;

//+ (instancetype)document;

//+ (instancetype)documentWithRootElement:(DDXMLElement *)element;

+ (id)elementWithName:(NSString *)name;

+ (id)elementWithName:(NSString *)name URI:(NSString *)URI;

+ (id)elementWithName:(NSString *)name stringValue:(NSString *)string;

+ (id)elementWithName:(NSString *)name children:(nullable NSArray<DDXMLNode *> *)children attributes:(nullable NSArray<DDXMLNode *> *)attributes;

+ (id)attributeWithName:(NSString *)name stringValue:(NSString *)stringValue;

+ (id)attributeWithName:(NSString *)name URI:(NSString *)URI stringValue:(NSString *)stringValue;

+ (id)namespaceWithName:(NSString *)name stringValue:(NSString *)stringValue;

+ (id)processingInstructionWithName:(NSString *)name stringValue:(NSString *)stringValue;

+ (id)commentWithStringValue:(NSString *)stringValue;

+ (id)textWithStringValue:(NSString *)stringValue;

//+ (instancetype)DTDNodeWithXMLString:(NSString *)string;

#pragma mark --- Properties ---

@property (readonly) DDXMLNodeKind kind;

@property (nullable, copy) NSString *name;

//- (void)setObjectValue:(id)value;
//- (instancetype)objectValue;

@property (nullable, copy) NSString *stringValue;

//- (void)setStringValue:(NSString *)string resolvingEntities:(BOOL)resolve;

#pragma mark --- Tree Navigation ---

@property (readonly) NSUInteger index;
@property (readonly) NSUInteger level;

@property (nullable, readonly, retain) DDXMLDocument *rootDocument;

@property (nullable, readonly, copy) DDXMLNode *parent;
@property (readonly) NSUInteger childCount;
@property (nullable, readonly, copy) NSArray<DDXMLNode *> *children;
- (nullable DDXMLNode *)childAtIndex:(NSUInteger)index;

@property (nullable, readonly, copy) DDXMLNode *previousSibling;
@property (nullable, readonly, copy) DDXMLNode *nextSibling;

@property (nullable, readonly, copy) DDXMLNode *previousNode;
@property (nullable, readonly, copy) DDXMLNode *nextNode;

- (void)detach;

@property (nullable, readonly, copy) NSString *XPath;

#pragma mark --- QNames ---

@property (nullable, readonly, copy) NSString *localName;
@property (nullable, readonly, copy) NSString *prefix;

@property (nullable, copy) NSString *URI; //primitive

+ (NSString *)localNameForName:(NSString *)name;
+ (nullable NSString *)prefixForName:(NSString *)name;
//+ (DDXMLNode *)predefinedNamespaceForPrefix:(NSString *)name;

#pragma mark --- Output ---

@property (readonly, copy) NSString *description;
@property (readonly, copy) NSString *XMLString;
- (nonnull NSString *)XMLStringWithOptions:(NSUInteger)options;
//- (NSString *)canonicalXMLStringPreservingComments:(BOOL)comments;

#pragma mark --- XPath/XQuery ---

- (nullable NSArray<__kindof DDXMLNode *> *)nodesForXPath:(NSString *)xpath error:(NSError **)error;
//- (NSArray *)objectsForXQuery:(NSString *)xquery constants:(NSDictionary *)constants error:(NSError **)error;
//- (NSArray *)objectsForXQuery:(NSString *)xquery error:(NSError **)error;

@end
NS_ASSUME_NONNULL_END