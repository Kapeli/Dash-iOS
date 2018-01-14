
#import <Foundation/Foundation.h>

@interface DHDocsetBrowserViewModel : NSObject
@property (nonatomic, strong, readonly) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *keyDocsets;
@property (nonatomic, strong) NSArray<DHDocset *> *shownDocsets;
@property (nonatomic, readonly) BOOL canMoveRows;
- (void)updateSectionsForEditing:(BOOL)editing andSearching:(BOOL)searching;
- (NSArray<DHDocset *> *)docsetsForEditing:(BOOL)editing;
@end
