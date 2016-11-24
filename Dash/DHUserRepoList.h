#import <Foundation/Foundation.h>
#import "DHFeed.h"

@interface DHUserRepoList : NSObject

@property (retain) NSDictionary *json;
@property (retain) NSDate *lastLoad;

+ (DHUserRepoList *)sharedUserRepoList;
- (NSMutableArray *)allUserDocsets;
- (NSString *)versionForEntry:(DHFeed *)entry;
- (NSString *)downloadURLForEntry:(DHFeed *)entry;
- (void)reload;
- (NSMutableArray *)allVersionsForEntry:(DHFeed *)entry;
- (NSString *)downloadURLForVersionedEntry:(DHFeed *)versionedEntry parentEntry:(DHFeed *)parentEntry;
- (UIImage *)imageForEntry:(DHFeed *)entry;

@end
