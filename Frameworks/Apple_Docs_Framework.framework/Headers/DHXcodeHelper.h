#import <Foundation/Foundation.h>

@class FMDatabase;

@interface DHXcodeHelper : NSObject

@property (strong) NSString *xcodePath;
@property (strong) NSString *xcodeDocsPath;
@property (strong) FMDatabase *cacheDB;
@property (strong) FMDatabase *mapDB;
@property (strong) FMDatabase *docsetDB;
@property (strong) NSDictionary *encodedToHumanJSONMappings;
@property (strong) NSMutableDictionary *requestKeyReferencePathCache;
@property (strong) NSMutableDictionary *usrCache;
@property (strong) NSMutableDictionary *nameCache;
@property (strong) NSMutableDictionary *inheritancesCache;
@property (strong) NSMutableDictionary *dataCache;
@property (strong) NSMutableDictionary *topicIdCache;
@property (strong) NSNumber *_isXcode9;
@property (strong) NSNumber *_usrInSearchIndex;

+ (DHXcodeHelper *)sharedXcodeHelper;
- (NSString *)xcodeDocsVersion;
- (void)enumerateLinesOfSearchIndex:(NSString *)indexName usingBlock:(void(^)(NSString *line, BOOL *stop))block;
- (NSMutableDictionary *)jsonForHref:(NSString *)href;
- (NSData *)cacheDataForHref:(NSString *)href;
- (id)makeJSONHumanReadable:(id)json;
- (NSString *)requestKeyForTopicId:(NSString *)topicId language:(NSString *)language;
- (NSDictionary *)mapRowForRequestKey:(NSString *)requestKey;
- (NSArray *)allRequestKeys;
- (NSArray *)inheritancesForRequestKey:(NSString *)requestKey;
- (NSString *)requestKeyForReferencePath:(NSString *)referencePath language:(NSString *)language;
- (NSString *)imageBase64StringForHref:(NSString *)href;
- (NSString *)nameForRequestKey:(NSString *)requestKey;
- (NSString *)requestKeyForUSR:(NSString *)usr;
- (NSString *)xcodeCacheDBPath;
- (NSString *)cacheDBPath;
- (NSString *)mapDBPath;
- (NSString *)xcodeMapDBPath;
- (void)addIndexesToDatabasesAtPath:(NSString *)path;
- (NSString *)fsFolderPath;
- (NSString *)xcodeFSFolderPath;
+ (void)cleanUp;
- (BOOL)isXcode9;

@end
