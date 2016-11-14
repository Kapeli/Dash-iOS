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
#import "DHFileDownload.h"

@interface DHFeedResult : NSObject

@property (strong) NSArray *downloadURLs;
@property (strong) NSString *version;
@property (assign) NSUInteger expectedContentLength;
@property (assign) NSUInteger receivedContentLength;
@property (strong) DHFileDownload *fileDownload;
@property (weak) id feed;
@property (strong) NSDate *lastDownloadProgressUpdate;
@property (assign) double lastProgress;
@property (assign, nonatomic) BOOL hasTarix;

- (BOOL)isCancelled;
- (void)setUnarchiveProgress:(double)progress;
- (void)setIndexingProgress:(double)progress;
- (void)setDownloadProgress:(double)progress receivedBytes:(long long)length outOf:(long long)expectedLength;
- (void)setRightDetail:(NSString *)rightDetail;

@end
