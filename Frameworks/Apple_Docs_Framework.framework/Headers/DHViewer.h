#import <Foundation/Foundation.h>

@interface DHViewer : NSObject

@property (strong) NSString *url;
@property (strong) NSString *desiredLanguage;
@property (strong) NSString *requestKey;
@property (strong) NSMutableDictionary *json;
@property (strong) NSMutableString *output;
@property (strong) NSString *currentLanguage;
@property (strong) NSMutableDictionary *references;
@property (strong) NSMutableArray *tocEntries;
@property (strong) NSMutableArray *inheritances;
@property (assign) BOOL isTesting;
@property (assign) BOOL isDumping;
@property (assign) BOOL isPreviewing;
@property (strong) NSMutableSet *previewedSymbolIds;
@property (strong) NSString *type;
@property (assign) BOOL isIOS;

+ (DHViewer *)sharedViewer;
- (NSString *)htmlOutput;
- (NSString *)previewHTMLOutput;
- (NSString *)renderText:(NSString *)textValue;
- (NSString *)renderContentXML:(id)contentXML;
- (NSString *)renderDisplayNameXML:(NSString *)displayNameXML;
- (NSString *)convertDashLinkToLocalDumpIfAppropriate:(NSString *)dashLink;
- (NSMutableDictionary *)grabJSON;
+ (void)cleanUp;

@end

#ifndef DHXMLOptions
#define DHXMLOptions NSXMLNodePreserveNamespaceOrder|NSXMLNodePreserveAttributeOrder|NSXMLNodePreserveEntities|NSXMLNodePreservePrefixes|NSXMLNodePreserveCDATA|NSXMLNodePreserveEmptyElements|NSXMLNodePreserveQuotes|NSXMLNodePreserveWhitespace|NSXMLNodePreserveDTD
#endif

// Also add these to encodedToHumanJSONMappings!

#define kAbstract @"a"
#define kAdopted_By @"ab"
#define kAlternative_Text @"al"
#define kApp_Extension @"ae"
#define kAttributes @"at"
#define kBeta @"b"
#define kCategory @"cg"
#define kChildren @"c"
#define kCode_Listing @"cl"
#define kConformance @"co"
#define kConstraints @"cs"
#define kContainer_ID @"cd"
#define kCurrent @"cr"
#define kDeclaration @"d"
#define kDeprecated @"de"
#define kDeprecation_Summary @"ds"
#define kReferences @"f"
#define kGenerics @"g"
#define kHeight @"h"
#define kId @"i"
#define kImport_Statement @"im"
#define kInheritance @"in"
#define kIntroduced @"ir"
#define kDefault_Implementations @"di"
#define kIds @"is"
#define kTypedef @"it"
#define kKind @"k"
#define kLanguage @"l"
#define kLanguages @"ls"
#define kModule @"md"
#define kName @"nm"
#define kMedia_Output @"mp"
#define kMessage @"ms"
#define kDisplay_Name @"n"
#define kNested_Types @"nt"
#define kDiscussion @"o"
#define kHierarchy @"hi"
#define kRelated_Project @"rp"
#define kRelated_Project_Link @"du"
#define kOperator_Fixity @"of"
#define kOptional @"op"
#define kRequired @"rq"
#define kPlatform @"p"
#define kParent @"pa"
#define kProtocol_Implementation @"pm"
#define kParameters @"pr"
#define kPlatforms @"ps"
#define kPaths @"pt"
#define kProtocol_Extension @"px"
#define kRole @"r"
#define kRead_Only @"ro"
#define kReturn_Value @"rv"
#define kSymbols @"s"
#define kSee_Also @"sa"
#define kTitle @"t"
#define kTable @"tb"
#define kUSR @"u"
#define kURL @"ur"
#define kHasDefaultImplementation @"dc"
#define kReallyHasDefaultImplementation @"hc"
#define kApp_Extension_Availability @"v"
#define kValue @"vl"
#define kWidth @"w"
#define kContent @"x"
#define kAvailability @"y"
#define k1x_Scale @"1x"
#define k1x_DarkScale @"d1x"
#define k2x_Scale @"2x"
#define k2x_DarkScale @"d2x"
#define kMissing_Paths @"xp"
#define kAvailabilityConstraints @"availabilityConstraints"
#define kNewAvailabilityConstraints @"yc"
#define kPageType @"rg"
#define kPossible_Values @"av"
#define kProperty_List_Declaration @"atd"
#define kProperty_List_Declaration_Type @"bt"
