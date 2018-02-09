
#import "DHDocsetBrowserViewModel.h"
#import "DHDocsetManager.h"
#import "DHDocsetDownloader.h"

@interface DHDocsetBrowserViewModel ()
@property (nonatomic, strong) NSArray *sections;
@end

@implementation DHDocsetBrowserViewModel

- (BOOL)alphabetizing {
    return [NSUserDefaults.standardUserDefaults boolForKey:DHDocsetDownloader.defaultsAlphabetizingKey];
}

- (BOOL)canMoveRows {
    return !self.alphabetizing;
}

- (NSArray *)sort:(NSArray *)array {
    if (self.alphabetizing) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        array = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    }
    return array;
}

- (NSArray<DHDocset *> *)docsetsForEditing:(BOOL)editing {
    NSArray<DHDocset *> *docsets = (editing) ? [DHDocsetManager sharedManager].docsets : (self.keyDocsets) ? self.keyDocsets : [DHDocsetManager sharedManager].enabledDocsets;
    return [self sort:docsets];
}

- (void)updateSectionsForEditing:(BOOL)editing andSearching:(BOOL)searching
{
    NSMutableArray *sections = [NSMutableArray array];
    if([DHRemoteServer sharedServer].remotes.count)
    {
        if(!editing && !searching)
        {
            [sections addObject:[self sort:DHRemoteServer.sharedServer.remotes]];
        }
    }
    NSArray<DHDocset *> *docsets = [self docsetsForEditing:editing];
    self.shownDocsets = docsets;
    if(docsets.count)
    {
        [sections addObject:docsets];
    }
    self.sections = sections;
}

@end
