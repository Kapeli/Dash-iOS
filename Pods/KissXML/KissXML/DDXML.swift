//
//  DDXML.swift
//  KissXML
//
//  Created by David Chiles on 1/29/16.
//
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
    public typealias  XMLNode = DDXMLNode
    public typealias  XMLElement = DDXMLElement
    public typealias  XMLDocument = DDXMLDocument
    public let  XMLInvalidKind = DDXMLInvalidKind
    public let  XMLDocumentKind = DDXMLDocumentKind
    public let  XMLElementKind = DDXMLElementKind
    public let  XMLAttributeKind = DDXMLAttributeKind
    public let  XMLNamespaceKind = DDXMLNamespaceKind
    public let  XMLProcessingInstructionKind = DDXMLProcessingInstructionKind
    public let  XMLCommentKind = DDXMLCommentKind
    public let  XMLTextKind = DDXMLTextKind
    public let  XMLDTDKind = DDXMLDTDKind
    public let  XMLEntityDeclarationKind = DDXMLEntityDeclarationKind
    public let  XMLAttributeDeclarationKind = DDXMLAttributeDeclarationKind
    public let  XMLElementDeclarationKind = DDXMLElementDeclarationKind
    public let  XMLNotationDeclarationKind = DDXMLNotationDeclarationKind
    public let  XMLNodeOptionsNone = DDXMLNodeOptionsNone
    public let  XMLNodeExpandEmptyElement = DDXMLNodeExpandEmptyElement
    public let  XMLNodeCompactEmptyElement = DDXMLNodeCompactEmptyElement
    public let  XMLNodePrettyPrint = DDXMLNodePrettyPrint
#endif
