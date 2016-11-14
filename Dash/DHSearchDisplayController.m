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

#import "DHSearchDisplayController.h"
#import "DHNestedViewController.h"
#import "JGMethodSwizzler.h"

@interface UISearchDisplayController (DHUtils)

- (void)navigationControllerWillShowViewController:(id)navigationController;

@end

@implementation UISearchDisplayController (DHUtils)

@end

@implementation DHSearchDisplayController

- (void)navigationControllerWillShowViewController:(id)navigationController
{
    if(isRegularHorizontalClass)
    {
        SEL selector = NSSelectorFromString(@"_deselectAllNonMultiSelectRowsAnimated:notifyDelegate:");
        if([self.searchResultsTableView respondsToSelector:selector])
        {
            [self.searchResultsTableView swizzleMethod:selector withReplacement:JGMethodReplacementProviderBlock {
                return JGMethodReplacement(void, UITableView *, BOOL animated, BOOL notifyDelegate) {
                    
                };
            }];
        }
    }
    [super navigationControllerWillShowViewController:navigationController];
    if(isRegularHorizontalClass)
    {
        [self.searchResultsTableView deswizzle];        
    }
}

@end
