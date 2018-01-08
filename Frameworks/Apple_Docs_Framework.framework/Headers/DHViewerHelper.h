#import <Foundation/Foundation.h>

@interface DHViewerHelper : NSObject

+ (DHViewerHelper *)sharedViewerHelper;
- (NSString *)encodedTypeToHumanType:(NSString *)encodedType;
- (NSString *)encodedTypeToDashType:(NSString *)encodedType;
- (NSString *)htmlForLanguagePickerForLanguage:(NSString *)language;
- (NSString *)htmlForPlatformSidebarForPlatform:(NSDictionary *)platform viewer:(DHViewer *)viewer;
- (NSString *)htmlForSymbol:(NSDictionary *)symbol taskTitle:(NSString *)taskTitle viewer:(DHViewer *)viewer;
- (BOOL)shouldShowPreviewForSymbol:(NSDictionary *)symbol;
- (NSMutableArray *)fullInheritanceStartingWith:(NSArray *)inheritance indentLevel:(NSInteger)level;

@end
