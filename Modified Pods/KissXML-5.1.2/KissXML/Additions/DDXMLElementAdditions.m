#import "DDXMLElementAdditions.h"

@implementation DDXMLElement (DDAdditions)

/**
 * Quick method to create an element
**/
+ (DDXMLElement *)elementWithName:(NSString *)name xmlns:(NSString *)ns
{
	DDXMLElement *element = [DDXMLElement elementWithName:name];
	[element setXmlns:ns];
	return element;
}

/**
 * This method returns the first child element for the given name.
 * If no child element exists for the given name, returns nil.
**/
- (DDXMLElement *)elementForName:(NSString *)name
{
	NSArray *elements = [self elementsForName:name];
	if([elements count] > 0)
	{
		return [elements objectAtIndex:0];
	}
	else
	{
		// Note: If you port this code to work with Apple's NSXML, beware of the following:
		// 
		// There is a bug in the NSXMLElement elementsForName: method.
		// Consider the following XML fragment:
		// 
		// <query xmlns="jabber:iq:private">
		//   <x xmlns="some:other:namespace"></x>
		// </query>
		// 
		// Calling [query elementsForName:@"x"] results in an empty array!
		// 
		// However, it will work properly if you use the following:
		// [query elementsForLocalName:@"x" URI:@"some:other:namespace"]
		// 
		// The trouble with this is that we may not always know the xmlns in advance,
		// so in this particular case there is no way to access the element without looping through the children.
		// 
		// This bug was submitted to apple on June 1st, 2007 and was classified as "serious".
		// 
		// --!!-- This bug does NOT exist in DDXML --!!--
		
		return nil;
	}
}

/**
 * This method returns the first child element for the given name and given xmlns.
 * If no child elements exist for the given name and given xmlns, returns nil.
**/
- (DDXMLElement *)elementForName:(NSString *)name xmlns:(NSString *)xmlns
{
	NSArray *elements = [self elementsForLocalName:name URI:xmlns];
	if([elements count] > 0)
	{
		return [elements objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}

/**
 * Returns the common xmlns "attribute", which is only accessible via the namespace methods.
 * The xmlns value is often used in jabber elements.
**/
- (NSString *)xmlns
{
	return [[self namespaceForPrefix:@""] stringValue];
}

- (void)setXmlns:(NSString *)ns
{
	// If you use setURI: then the xmlns won't be displayed in the XMLString.
	// Adding the namespace this way works properly.
	// 
	// This applies to both Apple's NSXML and DDXML.
	
	[self addNamespace:[DDXMLNode namespaceWithName:@"" stringValue:ns]];
}

/**
 * Shortcut to get a pretty (formatted) string representation of the element.
**/
- (NSString *)prettyXMLString
{
	return [self XMLStringWithOptions:(DDXMLNodePrettyPrint | DDXMLNodeCompactEmptyElement)];
}

/**
 * Shortcut to get a compact string representation of the element.
**/
- (NSString *)compactXMLString
{
    return [self XMLStringWithOptions:DDXMLNodeCompactEmptyElement];
}

/**
 *	Shortcut to avoid having to manually create a DDXMLNode everytime.
**/
- (void)addAttributeWithName:(NSString *)name stringValue:(NSString *)string
{
	[self addAttribute:[DDXMLNode attributeWithName:name stringValue:string]];
}

/**
 * Returns all the attributes as a dictionary.
**/
- (NSDictionary *)attributesAsDictionary
{
	NSArray *attributes = [self attributes];
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[attributes count]];
	
	uint i;
	for(i = 0; i < [attributes count]; i++)
	{
		DDXMLNode *node = [attributes objectAtIndex:i];
		
		[result setObject:[node stringValue] forKey:[node name]];
	}
	return result;
}

@end
