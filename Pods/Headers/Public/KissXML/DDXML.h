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

#import "DDXMLNode.h"
#import "DDXMLElement.h"
#import "DDXMLDocument.h"

#if TARGET_OS_IPHONE

// Since KissXML is a drop in replacement for NSXML,
// it may be desireable (when writing cross-platform code to be used on both Mac OS X and iOS)
// to use the NSXML prefixes instead of the DDXML prefix.
//
// This way, on Mac OS X it uses NSXML, and on iOS it uses KissXML.

#ifndef NSXMLNode
  #define NSXMLNode DDXMLNode
#endif
#ifndef NSXMLElement
  #define NSXMLElement DDXMLElement
#endif
#ifndef NSXMLDocument
  #define NSXMLDocument DDXMLDocument
#endif

#ifndef NSXMLInvalidKind
  #define NSXMLInvalidKind DDXMLInvalidKind
#endif
#ifndef NSXMLDocumentKind
  #define NSXMLDocumentKind DDXMLDocumentKind
#endif
#ifndef NSXMLElementKind
  #define NSXMLElementKind DDXMLElementKind
#endif
#ifndef NSXMLAttributeKind
  #define NSXMLAttributeKind DDXMLAttributeKind
#endif
#ifndef NSXMLNamespaceKind
  #define NSXMLNamespaceKind DDXMLNamespaceKind
#endif
#ifndef NSXMLProcessingInstructionKind
  #define NSXMLProcessingInstructionKind DDXMLProcessingInstructionKind
#endif
#ifndef NSXMLCommentKind
  #define NSXMLCommentKind DDXMLCommentKind
#endif
#ifndef NSXMLTextKind
  #define NSXMLTextKind DDXMLTextKind
#endif
#ifndef NSXMLDTDKind
  #define NSXMLDTDKind DDXMLDTDKind
#endif
#ifndef NSXMLEntityDeclarationKind
  #define NSXMLEntityDeclarationKind DDXMLEntityDeclarationKind
#endif
#ifndef NSXMLAttributeDeclarationKind
  #define NSXMLAttributeDeclarationKind DDXMLAttributeDeclarationKind
#endif
#ifndef NSXMLElementDeclarationKind
  #define NSXMLElementDeclarationKind DDXMLElementDeclarationKind
#endif
#ifndef NSXMLNotationDeclarationKind
  #define NSXMLNotationDeclarationKind DDXMLNotationDeclarationKind
#endif

#ifndef NSXMLNodeOptionsNone
  #define NSXMLNodeOptionsNone DDXMLNodeOptionsNone
#endif
#ifndef NSXMLNodeExpandEmptyElement
  #define NSXMLNodeExpandEmptyElement DDXMLNodeExpandEmptyElement
#endif
#ifndef NSXMLNodeCompactEmptyElement
  #define NSXMLNodeCompactEmptyElement DDXMLNodeCompactEmptyElement
#endif
#ifndef NSXMLNodePrettyPrint
  #define NSXMLNodePrettyPrint DDXMLNodePrettyPrint
#endif

#endif // #if TARGET_OS_IPHONE



// KissXML has rather straight-forward memory management:
// https://github.com/robbiehanson/KissXML/wiki/MemoryManagementThreadSafety
//
// There are 3 important concepts to keep in mind when working with KissXML:
//
//
// 1.) KissXML provides a light-weight wrapper around libxml.
//
// The parsing, creation, storage, etc of the xml tree is all done via libxml.
// This is a fast low-level C library that's been around for ages, and comes pre-installed on Mac OS X and iOS.
// KissXML provides an easy-to-use Objective-C library atop libxml.
// So a DDXMLNode, DDXMLElement, or DDXMLDocument are simply objective-c objects
// with pointers to the underlying libxml C structure.
// Then only time you need to be aware of any of this is when it comes to equality.
// In order to maximize speed and provide read-access thread-safety,
// the library may create multiple DDXML wrapper objects that point to the same underlying xml node.
// So don't assume you can test for equality with "==".
// Instead use the isEqual method (as you should generally do with objects anyway).
//
//
// 2.) XML is implicitly a tree heirarchy, and the XML API's are designed to allow traversal up & down the tree.
//
// The tree heirarchy and API contract have an implicit impact concerning memory management.
//
// <starbucks>
//   <latte/>
// </starbucks>
//
// Imagine you have a DDXMLNode corresponding to the starbucks node,
// and you have a DDXMLNode corresponding to the latte node.
// Now imagine you release the starbucks node, but you retain a reference to the latte node.
// What happens?
// Well the latte node is a part of the xml tree heirarchy.
// So if the latte node is still around, the xml tree heirarchy must stick around as well.
// So even though the DDXMLNode corresponding to the starbucks node may get deallocated,
// the underlying xml tree structure won't be freed until the latte node gets dealloacated.
//
// In general, this means that KissXML remains thread-safe when reading and processing a tree.
// If you traverse a tree and fork off asynchronous tasks to process subnodes,
// the tree will remain properly in place until all your asynchronous tasks have completed.
// In other words, it just works.
//
// However, if you parse a huge document into memory, and retain a single node from the giant xml tree...
// Well you should see the problem this creates.
// Instead, in this situation, copy or detach the node if you want to keep it around.
// Or just extract the info you need from it.
//
//
// 3.) KissXML is read-access thread-safe, but write-access thread-unsafe (designed for speed).
//
// <starbucks>
//   <latte/>
// </starbucks>
//
// Imagine you have a DDXMLNode corresponding to the starbucks node,
// and you have a DDXMLNode corresponding to the latte node.
// What happens if you invoke [starbucks removeChildAtIndex:0]?
// Well the undelying xml tree will remove the latte node, and release the associated memory.
// And what if you still have a reference to the DDXMLNode that corresponds to the latte node?
// Well the short answer is that you shouldn't use it. At all.
// This is pretty obvious when you think about it from the context of this simple example.
// But in the real world, you might have multiple threads running in parallel,
// and you might accidently modify a node while another thread is processing it.
//
// To completely fix this problem, and provide write-access thread-safety, would require extensive overhead.
// This overhead is completely unwanted in the majority of cases.
// Most XML usage patterns are heavily read-only.
// And in the case of xml creation or modification, it is generally done on the same thread.
// Thus the KissXML library is write-access thread-unsafe, but provides speedier performance.
//
// However, when such a bug does creep up, it produces horrible side-effects.
// Essentially the pointer to the underlying xml structure becomes a dangling pointer,
// which means that accessing the dangling pointer might give you the correct results, or completely random results.
// And attempting to make modifications to non-existant xml nodes via the dangling pointer might do nothing,
// or completely corrupt your heap and cause un-explainable crashes in random parts of your library.
// Heap corruption is one of the worst problems to track down.
// So to help out, the library provides a debugging macro to track down these problems.
// That is, if you invalidate the write-access thread-unsafe rule,
// this macro will tell you when you're trying to access a now-dangling pointer.
//
// How does it work?
// Well everytime a DDXML wrapper object is created atop a libxml structure,
// it marks the linkage in a table.
// And everytime a libxml structure is freed, it destorys all corresponding linkages in the table.
// So everytime a DDXML wrapper objects is about to dereference it's pointer,
// it first ensures the linkage still exists in the table.
//
// Set to 1 to enable
// Set to 0 to disable (this is the default)
//
// The debugging macro adds a significant amount of overhead, and should NOT be enabled on production builds.

#if DEBUG
  #define DDXML_DEBUG_MEMORY_ISSUES 0
#else
  #define DDXML_DEBUG_MEMORY_ISSUES 0 // Don't change me!
#endif
