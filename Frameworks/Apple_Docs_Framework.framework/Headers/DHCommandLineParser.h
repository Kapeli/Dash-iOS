#import <Foundation/Foundation.h>

@interface DHCommandLineParser : NSObject

@property (strong) NSString *ownPath;
@property (strong) NSString *bestMirror;
@property (strong) NSString *dashPath; // can be nil, added in Dash build number >250 (Dash 3.4.1)
@property (assign) NSInteger dashBuildNumber; // can be 0, added in Dash build number >250 (Dash 3.4.1)

+ (DHCommandLineParser *)sharedParser;

@end
