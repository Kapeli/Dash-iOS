#import "DDXMLPrivate.h"
#import "NSString+DDXML.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

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

@implementation DDXMLElement

/**
 * Returns a DDXML wrapper object for the given primitive node.
 * The given node MUST be non-NULL and of the proper type.
**/
+ (instancetype)nodeWithElementPrimitive:(xmlNodePtr)node owner:(DDXMLNode *)owner
{
	return [[DDXMLElement alloc] initWithElementPrimitive:node owner:owner];
}

- (instancetype)initWithElementPrimitive:(xmlNodePtr)node owner:(DDXMLNode *)inOwner
{
	self = [super initWithPrimitive:(xmlKindPtr)node owner:inOwner];
	return self;
}

+ (instancetype)nodeWithPrimitive:(xmlKindPtr)kindPtr owner:(DDXMLNode *)owner
{
	// Promote initializers which use proper parameter types to enable compiler to catch more mistakes
	NSAssert(NO, @"Use nodeWithElementPrimitive:owner:");
	
	return nil;
}

- (instancetype)initWithPrimitive:(xmlKindPtr)kindPtr owner:(DDXMLNode *)inOwner
{
	// Promote initializers which use proper parameter types to enable compiler to catch more mistakes.
	NSAssert(NO, @"Use initWithElementPrimitive:owner:");
	
	return nil;
}

- (instancetype)initWithName:(NSString *)name
{
	// Note: Make every guarantee that genericPtr is not null
	
	xmlNodePtr node = xmlNewNode(NULL, [name xmlChar]);
	if (node == NULL)
	{
		return nil;
	}
	
	return [self initWithElementPrimitive:node owner:nil];
}

- (instancetype)initWithName:(NSString *)name URI:(NSString *)URI
{
	// Note: Make every guarantee that genericPtr is not null
	
	xmlNodePtr node = xmlNewNode(NULL, [name xmlChar]);
	if (node == NULL)
	{
		return nil;
	}
	
	DDXMLElement *result = [self initWithElementPrimitive:node owner:nil];
	[result setURI:URI];
	
	return result;
}

- (instancetype)initWithName:(NSString *)name stringValue:(NSString *)string
{
	// Note: Make every guarantee that genericPtr is not null
	
	xmlNodePtr node = xmlNewNode(NULL, [name xmlChar]);
	if (node == NULL)
	{
		return nil;
	}
	
	DDXMLElement *result = [self initWithElementPrimitive:node owner:nil];
	[result setStringValue:string];
	
	return result;
}

- (instancetype)initWithXMLString:(NSString *)string error:(NSError **)error
{
	DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:string options:0 error:error];
	if (doc == nil)
	{
		return nil;
	}
	
	DDXMLElement *result = [doc rootElement];
	[result detach];
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Elements by name
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Helper method elementsForName and elementsForLocalName:URI: so work isn't duplicated.
 * The name parameter is required, all others are optional.
**/
- (NSArray *)_elementsForName:(NSString *)name
                    localName:(NSString *)localName
                       prefix:(NSString *)prefix
                          uri:(NSString *)uri
{
	// This is a private/internal method
	
	// Rule : !uri             => match: name
	// Rule : uri && hasPrefix => match: name || (localName && uri)
	// Rule : uri && !hasPefix => match: name && uri
	
	xmlNodePtr node = (xmlNodePtr)genericPtr;
	
	NSMutableArray *result = [NSMutableArray array];
	
	BOOL hasPrefix = [prefix length] > 0;
	
	const xmlChar *xmlName      = [name xmlChar];
	const xmlChar *xmlLocalName = [localName xmlChar];
	const xmlChar *xmlUri       = [uri xmlChar];
	
	xmlNodePtr child = node->children;
	while (child)
	{
		if (IsXmlNodePtr(child))
		{
			BOOL match = NO;
			
			if (uri == nil)
			{
				match = xmlStrEqual(child->name, xmlName);
			}
			else
			{
				BOOL nameMatch      = xmlStrEqual(child->name, xmlName);
				BOOL localNameMatch = xmlStrEqual(child->name, xmlLocalName);
				
				BOOL uriMatch = NO;
				if (child->ns)
				{
					uriMatch = xmlStrEqual(child->ns->href, xmlUri);
				}
				
				if (hasPrefix)
					match = nameMatch || (localNameMatch && uriMatch);
				else
					match = nameMatch && uriMatch;
			}
			
			if (match)
			{
				[result addObject:[DDXMLElement nodeWithElementPrimitive:child owner:self]];
			}
		}
		
		child = child->next;
	}
	
	return result;
}

/**
 * Returns the child element nodes (as DDXMLElement objects) of the receiver that have a specified name.
 * 
 * If name is a qualified name, then this method invokes elementsForLocalName:URI: with the URI parameter set to
 * the URI associated with the prefix. Otherwise comparison is based on string equality of the qualified or
 * non-qualified name.
**/
- (NSArray *)elementsForName:(NSString *)name
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	if (name == nil) return [NSArray array];
	
	// We need to check to see if name has a prefix.
	// If it does have a prefix, we need to figure out what the corresponding URI is for that prefix,
	// and then search for any elements that have the same name (including prefix) OR have the same URI.
	// Otherwise we loop through the children as usual and do a string compare on the name
	
	NSString *prefix;
	NSString *localName;
	
	[DDXMLNode getPrefix:&prefix localName:&localName forName:name];
	
	if ([prefix length] > 0)
	{
		xmlNodePtr node = (xmlNodePtr)genericPtr;
		
		// Note: We use xmlSearchNs instead of resolveNamespaceForName: because
		// we want to avoid creating wrapper objects when possible.
		
		xmlNsPtr ns = xmlSearchNs(node->doc, node, [prefix xmlChar]);
		if (ns)
		{
			NSString *uri = [NSString stringWithUTF8String:((const char *)ns->href)];
			return [self _elementsForName:name localName:localName prefix:prefix uri:uri];
		}
	}
	
	return [self _elementsForName:name localName:localName prefix:prefix uri:nil];
}

- (NSArray *)elementsForLocalName:(NSString *)localName URI:(NSString *)uri
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	if (localName == nil) return [NSArray array];
	
	// We need to figure out what the prefix is for this URI.
	// Then we search for elements that are named prefix:localName OR (named localName AND have the given URI).
	
	NSString *prefix = [self _recursiveResolvePrefixForURI:uri atNode:(xmlNodePtr)genericPtr];
	if (prefix)
	{
		NSString *name = [NSString stringWithFormat:@"%@:%@", prefix, localName];
		
		return [self _elementsForName:name localName:localName prefix:prefix uri:uri];
	}
	else
	{
		NSString *prefix;
		NSString *realLocalName;
		
		[DDXMLNode getPrefix:&prefix localName:&realLocalName forName:localName];
		
		return [self _elementsForName:localName localName:realLocalName prefix:prefix uri:uri];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Attributes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)_hasAttributeWithName:(NSString *)name
{
	// This is a private/internal method
	
	xmlAttrPtr attr = ((xmlNodePtr)genericPtr)->properties;
	if (attr)
	{
		const xmlChar *xmlName = [name xmlChar];
		do
		{
			if (xmlStrEqual(attr->name, xmlName))
			{
				return YES;
			}
			attr = attr->next;
			
		} while (attr);
	}
	
	return NO;
}

- (void)_removeAttributeForName:(NSString *)name
{
	// This is a private/internal method
	
	xmlAttrPtr attr = ((xmlNodePtr)genericPtr)->properties;
	if (attr)
	{
		const xmlChar *xmlName = [name xmlChar];
		do
		{
			if (xmlStrEqual(attr->name, xmlName))
			{
				[DDXMLNode removeAttribute:attr];
				return;
			}
			attr = attr->next;
			
		} while(attr);
	}
}

- (void)addAttribute:(DDXMLNode *)attribute
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	// NSXML version uses this same assertion
	DDXMLAssert([attribute _hasParent] == NO, @"Cannot add an attribute with a parent; detach or copy first");
	DDXMLAssert(IsXmlAttrPtr(attribute->genericPtr), @"Not an attribute");
	
	[self _removeAttributeForName:[attribute name]];
	
	// xmlNodePtr xmlAddChild(xmlNodePtr parent, xmlNodePtr cur)
	// Add a new node to @parent, at the end of the child (or property) list merging
	// adjacent TEXT nodes (in which case @cur is freed). If the new node is ATTRIBUTE, it is added
	// into properties instead of children. If there is an attribute with equal name, it is first destroyed.
	
	xmlAddChild((xmlNodePtr)genericPtr, (xmlNodePtr)attribute->genericPtr);
	
	// The attribute is now part of the xml tree heirarchy
	attribute->owner = self;
}

- (void)removeAttributeForName:(NSString *)name
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	[self _removeAttributeForName:name];
}

- (NSArray *)attributes
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	NSMutableArray *result = [NSMutableArray array];
	
	xmlAttrPtr attr = ((xmlNodePtr)genericPtr)->properties;
	while (attr != NULL)
	{
		[result addObject:[DDXMLAttributeNode nodeWithAttrPrimitive:attr owner:self]];
		
		attr = attr->next;
	}
	
	return result;
}

- (DDXMLNode *)attributeForName:(NSString *)name
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	xmlAttrPtr attr = ((xmlNodePtr)genericPtr)->properties;
	if (attr)
	{
		const xmlChar *xmlName = [name xmlChar];
		do
		{
			if (attr->ns && attr->ns->prefix)
			{
				// If the attribute name was originally something like "xml:quack",
				// then attr->name is "quack" and attr->ns->prefix is "xml".
				// 
				// So if the user is searching for "xml:quack" we need to take the prefix into account.
				// Note that "xml:quack" is what would be printed if we output the attribute.
				
				if (xmlStrQEqual(attr->ns->prefix, attr->name, xmlName))
				{
					return [DDXMLAttributeNode nodeWithAttrPrimitive:attr owner:self];
				}
			}
			else
			{
				if (xmlStrEqual(attr->name, xmlName))
				{
					return [DDXMLAttributeNode nodeWithAttrPrimitive:attr owner:self];
				}
			}
			
			attr = attr->next;
			
		} while (attr);
	}
	return nil;
}

/**
 * Sets the list of attributes for the element.
 * Any previously set attributes are removed.
**/
- (void)setAttributes:(NSArray *)attributes
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	[DDXMLNode removeAllAttributesFromNode:(xmlNodePtr)genericPtr];
	
	NSUInteger i;
	for (i = 0; i < [attributes count]; i++)
	{
		DDXMLNode *attribute = [attributes objectAtIndex:i];
		[self addAttribute:attribute];
		
		// Note: The addAttributes method properly sets the freeOnDealloc ivar.
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Namespaces
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)_removeNamespaceForPrefix:(NSString *)name
{
	xmlNodePtr node = (xmlNodePtr)genericPtr;
	
	// If name is nil or the empty string, the user is wishing to remove the default namespace
	const xmlChar *xmlName = [name length] > 0 ? [name xmlChar] : NULL;
	
	xmlNsPtr ns = node->nsDef;
	while (ns != NULL)
	{
		if (xmlStrEqual(ns->prefix, xmlName))
		{
			[DDXMLNode removeNamespace:ns fromNode:node];
			break;
		}
		ns = ns->next;
	}
	
	// Note: The removeNamespace method properly handles the situation where the namespace is the default namespace
}

- (void)_addNamespace:(DDXMLNode *)namespace
{
	// NSXML version uses this same assertion
	DDXMLAssert([namespace _hasParent] == NO, @"Cannot add a namespace with a parent; detach or copy first");
	DDXMLAssert(IsXmlNsPtr(namespace->genericPtr), @"Not a namespace");
	
	xmlNodePtr node = (xmlNodePtr)genericPtr;
	xmlNsPtr ns = (xmlNsPtr)namespace->genericPtr;
	
	// Beware: [namespace prefix] does NOT return what you might expect.  Use [namespace name] instead.
	
	NSString *namespaceName = [namespace name];
	
	[self _removeNamespaceForPrefix:namespaceName];
	
	xmlNsPtr currentNs = node->nsDef;
	if (currentNs == NULL)
	{
		node->nsDef = ns;
	}
	else
	{
		while (currentNs->next != NULL)
		{
			currentNs = currentNs->next;
		}
		
		currentNs->next = ns;
	}
	
	// The namespace is now part of the xml tree heirarchy
	namespace->owner = self;
	
	if ([namespace isKindOfClass:[DDXMLNamespaceNode class]])
	{
		DDXMLNamespaceNode *ddNamespace = (DDXMLNamespaceNode *)namespace;
		
		// The xmlNs structure doesn't contain a reference to the parent, so we manage our own reference
		[ddNamespace _setNsParentPtr:node];
	}
	
	// Did we just add a default namespace
	if ([namespaceName isEqualToString:@""])
	{
		node->ns = ns;
		
		// Note: The removeNamespaceForPrefix method above properly handled removing any previous default namespace
	}
}

- (void)addNamespace:(DDXMLNode *)namespace
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	[self _addNamespace:namespace];
}

- (void)removeNamespaceForPrefix:(NSString *)name
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	[self _removeNamespaceForPrefix:name];
}

- (NSArray *)namespaces
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	NSMutableArray *result = [NSMutableArray array];
	
	xmlNsPtr ns = ((xmlNodePtr)genericPtr)->nsDef;
	while (ns != NULL)
	{
		[result addObject:[DDXMLNamespaceNode nodeWithNsPrimitive:ns nsParent:(xmlNodePtr)genericPtr owner:self]];
		
		ns = ns->next;
	}
	
	return result;
}

- (DDXMLNode *)namespaceForPrefix:(NSString *)prefix
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	// If the prefix is nil or the empty string, the user is requesting the default namespace
	
	if ([prefix length] == 0)
	{
		// Requesting the default namespace
		xmlNsPtr ns = ((xmlNodePtr)genericPtr)->ns;
		if (ns != NULL)
		{
			return [DDXMLNamespaceNode nodeWithNsPrimitive:ns nsParent:(xmlNodePtr)genericPtr owner:self];
		}
	}
	else
	{
		xmlNsPtr ns = ((xmlNodePtr)genericPtr)->nsDef;
		if (ns)
		{
			const xmlChar *xmlPrefix = [prefix xmlChar];
			do
			{
				if (xmlStrEqual(ns->prefix, xmlPrefix))
				{
					return [DDXMLNamespaceNode nodeWithNsPrimitive:ns nsParent:(xmlNodePtr)genericPtr owner:self];
				}
				ns = ns->next;
				
			} while (ns);
		}
	}
	
	return nil;
}

- (void)setNamespaces:(NSArray *)namespaces
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	[DDXMLNode removeAllNamespacesFromNode:(xmlNodePtr)genericPtr];
	
	NSUInteger i;
	for (i = 0; i < [namespaces count]; i++)
	{
		DDXMLNode *namespace = [namespaces objectAtIndex:i];
		[self _addNamespace:namespace];
		
		// Note: The addNamespace method properly sets the freeOnDealloc ivar.
	}
}

/**
 * Recursively searches the given node for the given namespace
**/
- (DDXMLNode *)_recursiveResolveNamespaceForPrefix:(NSString *)prefix atNode:(xmlNodePtr)nodePtr
{
	// This is a private/internal method
	
	if (nodePtr == NULL) return nil;
	
	xmlNsPtr ns = nodePtr->nsDef;
	if (ns)
	{
		const xmlChar *xmlPrefix = [prefix xmlChar];
		do
		{
			if (xmlStrEqual(ns->prefix, xmlPrefix))
			{
				return [DDXMLNamespaceNode nodeWithNsPrimitive:ns nsParent:nodePtr owner:self];
			}
			ns = ns->next;
			
		} while(ns);
	}
	
	return [self _recursiveResolveNamespaceForPrefix:prefix atNode:nodePtr->parent];
}

/**
 * Returns the namespace node with the prefix matching the given qualified name.
 * Eg: You pass it "a:dog", it returns the namespace (defined in this node or parent nodes) that has the "a" prefix.
**/
- (DDXMLNode *)resolveNamespaceForName:(NSString *)name
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	// If the user passes nil or an empty string for name, they're looking for the default namespace.
	if ([name length] == 0)
	{
		return [self _recursiveResolveNamespaceForPrefix:nil atNode:(xmlNodePtr)genericPtr];
	}
	
	NSString *prefix = [[self class] prefixForName:name];
	
	if ([prefix length] > 0)
	{
		// Unfortunately we can't use xmlSearchNs because it returns an xmlNsPtr.
		// This gives us mostly what we want, except we also need to know the nsParent.
		// So we do the recursive search ourselves.
		
		return [self _recursiveResolveNamespaceForPrefix:prefix atNode:(xmlNodePtr)genericPtr];
	}
	
	return nil;
}

/**
 * Recursively searches the given node for a namespace with the given URI, and a set prefix.
**/
- (NSString *)_recursiveResolvePrefixForURI:(NSString *)uri atNode:(xmlNodePtr)nodePtr
{
	// This is a private/internal method
	
	if (nodePtr == NULL) return nil;
	
	xmlNsPtr ns = nodePtr->nsDef;
	if (ns)
	{
		const xmlChar *xmlUri = [uri xmlChar];
		do
		{
			if (xmlStrEqual(ns->href, xmlUri))
			{
				if (ns->prefix != NULL)
				{
					return [NSString stringWithUTF8String:((const char *)ns->prefix)];
				}
			}
			ns = ns->next;
			
		} while (ns);
	}
	
	return [self _recursiveResolvePrefixForURI:uri atNode:nodePtr->parent];
}

/**
 * Returns the prefix associated with the specified URI.
 * Returns a string that is the matching prefix or nil if it finds no matching prefix.
**/
- (NSString *)resolvePrefixForNamespaceURI:(NSString *)namespaceURI
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	// We can't use xmlSearchNsByHref because it will return xmlNsPtr's with NULL prefixes.
	// We're looking for a definitive prefix for the given URI.
	
	return [self _recursiveResolvePrefixForURI:namespaceURI atNode:(xmlNodePtr)genericPtr];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Children
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)addChild:(DDXMLNode *)child
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	// NSXML version uses these same assertions
	DDXMLAssert([child _hasParent] == NO, @"Cannot add a child that has a parent; detach or copy first");
	DDXMLAssert(IsXmlNodePtr(child->genericPtr),
	            @"Elements can only have text, elements, processing instructions, and comments as children");
	
	xmlAddChild((xmlNodePtr)genericPtr, (xmlNodePtr)child->genericPtr);
	
	// The node is now part of the xml tree heirarchy
	child->owner = self;
}

- (void)insertChild:(DDXMLNode *)child atIndex:(NSUInteger)index
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	// NSXML version uses these same assertions
	DDXMLAssert([child _hasParent] == NO, @"Cannot add a child that has a parent; detach or copy first");
	DDXMLAssert(IsXmlNodePtr(child->genericPtr),
	            @"Elements can only have text, elements, processing instructions, and comments as children");
	
	NSUInteger i = 0;
	
	xmlNodePtr childNodePtr = ((xmlNodePtr)genericPtr)->children;
	while (childNodePtr != NULL)
	{
		// Ignore all but element, comment, text, or processing instruction nodes
		if (IsXmlNodePtr(childNodePtr))
		{
			if (i == index)
			{
				xmlAddPrevSibling(childNodePtr, (xmlNodePtr)child->genericPtr);
				
				child->owner = self;
				
				return;
			}
			
			i++;
		}
		childNodePtr = childNodePtr->next;
	}
	
	if (i == index)
	{
		xmlAddChild((xmlNodePtr)genericPtr, (xmlNodePtr)child->genericPtr);
		
		child->owner = self;
		
		return;
	}
	
	// NSXML version uses this same assertion
	DDXMLAssert(NO, @"index (%u) beyond bounds (%u)", (unsigned)index, (unsigned)++i);
}

- (void)removeChildAtIndex:(NSUInteger)index
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	NSUInteger i = 0;
	
	xmlNodePtr child = ((xmlNodePtr)genericPtr)->children;
	while (child != NULL)
	{
		// Ignore all but element, comment, text, or processing instruction nodes
		if (IsXmlNodePtr(child))
		{
			if (i == index)
			{
				[DDXMLNode removeChild:child];
				return;
			}
			
			i++;
		}
		child = child->next;
	}
}

- (void)setChildren:(NSArray *)children
{
#if DDXML_DEBUG_MEMORY_ISSUES
	DDXMLNotZombieAssert();
#endif
	
	[DDXMLNode removeAllChildrenFromNode:(xmlNodePtr)genericPtr];
	
	NSUInteger i;
	for (i = 0; i < [children count]; i++)
	{
		DDXMLNode *child = [children objectAtIndex:i];
		[self addChild:child];
		
		// Note: The addChild method properly sets the freeOnDealloc ivar.
	}
}

@end
