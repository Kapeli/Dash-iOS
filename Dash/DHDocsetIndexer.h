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

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const kDHDocsetIndexerDashSearchScheme;

FOUNDATION_EXPORT NSString * const kDHDocsetIndexerDashSearchItemIdentifier;

FOUNDATION_EXPORT NSString * const kDHDocsetIndexerDashSearchItemRequestKey;

@interface DHDocsetIndexer : NSObject

@property (weak) id delegate;
@property (strong) DHDocset *docset;
@property (assign) BOOL hasV2Guides;
@property (assign) NSInteger progressCount;
@property (assign) NSInteger currentProgress;
@property (assign) double lastDisplayedPercent;

+ (DHDocsetIndexer *)indexerForDocset:(DHDocset *)docset delegate:(id)delegate;

@end
