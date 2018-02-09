//
//  File.swift
//  KissXML
//
//  Created by David Chiles on 1/29/16.
//
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
    public typealias  NSXMLNode = DDXMLNode
    public typealias  NSXMLElement = DDXMLElement
    public typealias  NSXMLDocument = DDXMLDocument
    public let  NSXMLInvalidKind = DDXMLInvalidKind
    public let  NSXMLDocumentKind = DDXMLDocumentKind
    public let  NSXMLElementKind = DDXMLElementKind
    public let  NSXMLAttributeKind = DDXMLAttributeKind
    public let  NSXMLNamespaceKind = DDXMLNamespaceKind
    public let  NSXMLProcessingInstructionKind = DDXMLProcessingInstructionKind
    public let  NSXMLCommentKind = DDXMLCommentKind
    public let  NSXMLTextKind = DDXMLTextKind
    public let  NSXMLDTDKind = DDXMLDTDKind
    public let  NSXMLEntityDeclarationKind = DDXMLEntityDeclarationKind
    public let  NSXMLAttributeDeclarationKind = DDXMLAttributeDeclarationKind
    public let  NSXMLElementDeclarationKind = DDXMLElementDeclarationKind
    public let  NSXMLNotationDeclarationKind = DDXMLNotationDeclarationKind
    public let  NSXMLNodeOptionsNone = DDXMLNodeOptionsNone
    public let  NSXMLNodeExpandEmptyElement = DDXMLNodeExpandEmptyElement
    public let  NSXMLNodeCompactEmptyElement = DDXMLNodeCompactEmptyElement
    public let  NSXMLNodePrettyPrint = DDXMLNodePrettyPrint
#endif
