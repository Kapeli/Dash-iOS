//
//  Copyright (C) 2016  Kapeli
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "DHTypes.h"
#import "DHType.h"

@implementation DHTypes

static DHTypes *_types = nil;

@synthesize orderedTypeObjects;
@synthesize orderedTypes;
@synthesize encodedToSingular;
@synthesize encodedToPlural;
@synthesize orderedHeaders;

+ (DHTypes *)sharedTypes
{
    @synchronized([DHTypes class])
	{
		if(!_types)
		{
			_types = [[DHTypes alloc] init];
            [_types setUp];
		}
	}
	return _types;
}

- (void)setUp
{
    self.orderedTypeObjects = [NSMutableArray array];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Snippet" humanPlural:@"Snippets"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Class" humanPlural:@"Classes" aliases:@[@"cl", @"tmplt", @"specialization"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"_Struct" humanPlural:@"_Structs"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Tag" humanPlural:@"Tags"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Trait" humanPlural:@"Traits"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Database" humanPlural:@"Databases"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Protocol" humanPlural:@"Protocols" aliases:@"intf"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Delegate" humanPlural:@"Delegates"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Interface" humanPlural:@"Interfaces"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Template" humanPlural:@"Templates"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Indirection" humanPlural:@"Indirections"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Object" humanPlural:@"Objects"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Schema" humanPlural:@"Schemas"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Category" humanPlural:@"Categories" aliases:@[@"cat", @"Groups", @"Pages"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Collection" humanPlural:@"Collections"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Framework" humanPlural:@"Frameworks"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Module" humanPlural:@"Modules"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Library" humanPlural:@"Libraries"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Namespace" humanPlural:@"Namespaces" aliases:@"ns"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Package" humanPlural:@"Packages"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Exception" humanPlural:@"Exceptions"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Struct" humanPlural:@"Structs" aliases:@[@"Data Structures", @"struct"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Type" humanPlural:@"Types" aliases:@[@"tag", @"tdef", @"Public Types", @"Protected Types", @"Private Types", @"Typedefs", @"Package Types", @"Data Types"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Diagram" humanPlural:@"Diagrams"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Table" humanPlural:@"Tables"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Query" humanPlural:@"Queries"]];

    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Component" humanPlural:@"Components"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Constructor" humanPlural:@"Constructors" aliases:@[@"Public Constructors"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Element" humanPlural:@"Elements"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Resource" humanPlural:@"Resources"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Directive" humanPlural:@"Directives"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Extension" humanPlural:@"Extensions"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Plugin" humanPlural:@"Plugins"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Filter" humanPlural:@"Filters"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Service" humanPlural:@"Services"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Provider" humanPlural:@"Providers"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Decorator" humanPlural:@"Decorators"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Method" humanPlural:@"Methods" aliases:@[@"instm", @"intfm", @"clm", @"intfcm", @"Class Methods", @"Instance Methods", @"Public Methods", @"Inherited Methods", @"Private Methods", @"Protected Methods", @"instctr", @"intfctr", @"enumm", @"intfsub", @"enumcm", @"structctr", @"structcm", @"enumctr", @"instsub", @"structsub", @"structm"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Property" humanPlural:@"Properties" aliases:@[@"intfp", @"instp", @"Protected Properties", @"Public Properties", @"Inherited Properties", @"Private Properties", @"structp", @"enump", @"intfdata", @"cldata"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Field" humanPlural:@"Fields" aliases:@[@"Data Fields"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Attribute" humanPlural:@"Attributes" aliases:@[@"XML Attributes", @"Public Attributes", @"Static Public Attributes", @"Protected Attributes", @"Static Protected Attributes", @"Private Attributes", @"Static Private Attributes", @"Package Attributes", @"Static Package Attributes"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Index" humanPlural:@"Indexes"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Mixin" humanPlural:@"Mixins"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Event" humanPlural:@"Events" aliases:@[@"event", @"Public Events", @"Inherited Events", @"Private Events"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Binding" humanPlural:@"Bindings" aliases:@"binding"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Foreign Key" humanPlural:@"Foreign Keys"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"View" humanPlural:@"Views"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Special Form" humanPlural:@"Special Forms"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Record" humanPlural:@"Records"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Report" humanPlural:@"Reports"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Modifier" humanPlural:@"Modifiers"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Shortcut" humanPlural:@"Shortcuts"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Trigger" humanPlural:@"Triggers"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Helper" humanPlural:@"Helpers"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Pipe" humanPlural:@"Pipes"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Relationship" humanPlural:@"Relationships"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Column" humanPlural:@"Columns"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Function" humanPlural:@"Functions" aliases:@[@"func", @"ffunc", @"signal", @"slot", @"dcop", @"Public Member Functions", @"Static Public Member Functions", @"Protected Member Functions", @"Static Protected Member Functions", @"Private Member Functions", @"Static Private Member Functions", @"Package Functions", @"Static Package Functions", @"Functions/Subroutines", @"Function Prototypes", @"Public Slots", @"Signals", @"Protected Slots", @"Private Slots", @"Members", @"grammar"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Expression" humanPlural:@"Expressions"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Hook" humanPlural:@"Hooks"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Procedure" humanPlural:@"Procedures"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Subroutine" humanPlural:@"Subroutines"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Builtin" humanPlural:@"Builtins"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Word" humanPlural:@"Words"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Callback" humanPlural:@"Callbacks"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Handler" humanPlural:@"Handlers"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Control Structure" humanPlural:@"Control Structures"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Annotation" humanPlural:@"Annotations"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"File" humanPlural:@"Files"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Error" humanPlural:@"Errors"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Enum" humanPlural:@"Enums" aliases:@[@"Enumerations", @"enum"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Tactic" humanPlural:@"Tactics"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Environment" humanPlural:@"Environments"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Command" humanPlural:@"Commands"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Provisioner" humanPlural:@"Provisioners"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Axiom" humanPlural:@"Axioms"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Lemma" humanPlural:@"Lemmas"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Inductive" humanPlural:@"Inductives"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Instance" humanPlural:@"Instances"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Global" humanPlural:@"Globals"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Union" humanPlural:@"Unions" aliases:@[@"union"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Variable" humanPlural:@"Variables" aliases:@[@"var", @"Class Variable"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Member" humanPlural:@"Members"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Block" humanPlural:@"Blocks"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Constant" humanPlural:@"Constants" aliases:@[@"clconst", @"econst", @"data", @"Notifications", @"enumelt", @"structdata", @"enumdata", @"writerid"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Macro" humanPlural:@"Macros" aliases:@"macro"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Value" humanPlural:@"Values"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Variant" humanPlural:@"Variants"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Define" humanPlural:@"Defines"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Iterator" humanPlural:@"Iterators"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Literal" humanPlural:@"Literals"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Widget" humanPlural:@"Widgets"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Keyword" humanPlural:@"Keywords"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Instruction" humanPlural:@"Instructions"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Request" humanPlural:@"Requests"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Message" humanPlural:@"Messages"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Option" humanPlural:@"Options"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Setting" humanPlural:@"Settings"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Style" humanPlural:@"Styles"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Script" humanPlural:@"Scripts"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Notation" humanPlural:@"Notations"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Abbreviation" humanPlural:@"Abbreviations"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Projection" humanPlural:@"Projection"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Parameter" humanPlural:@"Parameters"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Syntax" humanPlural:@"Syntaxes"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Signature" humanPlural:@"Signatures"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Conversion" humanPlural:@"Conversions"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Pattern" humanPlural:@"Patterns"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Test" humanPlural:@"Tests"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Operator" humanPlural:@"Operators" aliases:@[@"opfunc"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Statement" humanPlural:@"Statements"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Role" humanPlural:@"Roles"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Register" humanPlural:@"Registers"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"State" humanPlural:@"States"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Alias" humanPlural:@"Aliases"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Device" humanPlural:@"Devices"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Kind" humanPlural:@"Kinds"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Node" humanPlural:@"Nodes"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Flag" humanPlural:@"Flags"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Sender" humanPlural:@"Senders"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Data Source" humanPlural:@"Data Sources"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Reference" humanPlural:@"References"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Guide" humanPlural:@"Guides" aliases:@[@"doc"]]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Sample" humanPlural:@"Samples"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Section" humanPlural:@"Sections"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Entry" humanPlural:@"Entries"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Glossary" humanPlural:@"Glossaries"]];
    [orderedTypeObjects addObject:[DHType typeWithHumanType:@"Unknown" humanPlural:@"Unknown"]];
    self.orderedTypes = [NSMutableArray array];
    self.encodedToSingular = [NSMutableDictionary dictionary];
    self.encodedToPlural = [NSMutableDictionary dictionary];
    self.orderedHeaders = [NSMutableArray array];
    for(DHType *type in orderedTypeObjects)
    {
        [orderedTypes addObject:type.humanType];
        encodedToSingular[type.humanType] = type.humanType;
        encodedToSingular[type.humanTypePlural] = type.humanType;
        encodedToPlural[type.humanType] = type.humanTypePlural;
        [orderedHeaders addObject:type.humanTypePlural];
        for(NSString *alias in type.aliases)
        {
            encodedToSingular[alias] = type.humanType;
            encodedToPlural[alias] = type.humanTypePlural;
            [orderedHeaders addObject:alias];
        }
    }
    [orderedHeaders addObject:@"See also"];
}

+ (NSString *)singularFromEncoded:(NSString *)encodedType notFoundReturn:(NSString *)notFound
{
    NSString *singular = [[DHTypes sharedTypes] encodedToSingular][encodedType];
    if(!singular)
    {
        return notFound;
    }
    return singular;
}

+ (NSString *)pluralFromEncoded:(NSString *)encodedType
{
    if([encodedType isEqualToString:@"_Struct"])
    {
        return @"Structs";
    }
    if([encodedType isEqualToString:@"_Type"])
    {
        return @"Types";
    }
    NSString *plural = [[DHTypes sharedTypes] encodedToPlural][encodedType];
    if(!plural)
    {
        return @"Unknown";
    }
    return plural;
}

- (NSString *)typeFromScalaType:(NSString*)scalaType
{
    if([scalaType hasSuffix:@"new"])
    {
        return @"Constructor";
    }
    else if([scalaType hasSuffix:@"def"])
    {
        return @"Function";
    }
    else if([scalaType hasSuffix:@"val"])
    {
        return @"Constant";
    }
    else if([scalaType hasSuffix:@"var"])
    {
        return @"Variable";
    }
    else if([scalaType hasSuffix:@"trait"])
    {
        return @"Trait";
    }
    else if([scalaType hasSuffix:@"class"])
    {
        return @"Class";
    }
    else if([scalaType hasSuffix:@"type"])
    {
        return @"Type";
    }
    else if([scalaType hasSuffix:@"object"])
    {
        return @"Object";
    }
    else if([scalaType hasSuffix:@"package"])
    {
        return @"Package";
    }
    return nil;
}

- (NSString *)unifiedSQLiteOrder:(BOOL)isDashDocset platform:(NSString *)platform
{
    BOOL isPHP = [platform isEqualToString:@"php"];
    BOOL isSwift = [platform isEqualToString:@"swift"];
    BOOL isGo = [platform isEqualToString:@"go"] || [platform isEqualToString:@"godoc"];
    NSMutableString *query = [NSMutableString stringWithString:@"ORDER BY (CASE "];
    NSUInteger count = 1;
    NSMutableArray *arrayToUse = (isPHP || isGo || isSwift) ? [NSMutableArray arrayWithArray:self.orderedTypeObjects] : self.orderedTypeObjects;
    if(isPHP)
    {
        for(DHType *type in [NSArray arrayWithArray:arrayToUse])
        {
            if([type.humanType isEqualToString:@"Function"])
            {
                [arrayToUse removeObjectIdenticalTo:type];
                [arrayToUse insertObject:type atIndex:0];
                break;
            }
        }
    }
    if(isGo)
    {
        for(DHType *type in [NSArray arrayWithArray:arrayToUse])
        {
            if([type.humanType isEqualToString:@"Type"])
            {
                [arrayToUse removeObjectIdenticalTo:type];
                [arrayToUse insertObject:type atIndex:0];
                break;
            }
        }
    }
    if(isSwift)
    {
        for(DHType *type in [NSArray arrayWithArray:arrayToUse])
        {
            if([type.humanType isEqualToString:@"Type"])
            {
                [arrayToUse removeObjectIdenticalTo:type];
                [arrayToUse insertObject:type atIndex:0];
                break;
            }
        }
    }
    for(DHType *type in arrayToUse)
    {
        NSMutableArray *toAppend = [NSMutableArray array];
        [toAppend addObject:type.humanType];
        for(NSString *alias in type.aliases)
        {
            [toAppend addObject:alias];
        }
        for(NSString *append in toAppend)
        {
            [query appendFormat:(isDashDocset) ? @"WHEN type = '%@' THEN %ld " : @"WHEN ty.ZTYPENAME = '%@' THEN %ld ", append, (unsigned long)count];
        }
        ++count;
    }
    [query appendFormat:@"ELSE %ld END)", (unsigned long)count];
    [query appendString:(isDashDocset) ? @", LENGTH(name) ASC;" : @", LENGTH(t.ZTOKENNAME) ASC;"];
    return query;
}

@end
