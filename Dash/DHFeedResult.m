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

#import "DHFeedResult.h"
#import "DHFeed.h"
#import "DHTransferFeed.h"

@implementation DHFeedResult

- (void)setUnarchiveProgress:(double)progress
{
    if(![self isCancelled])
    {
        progress = (self.hasTarix) ? 0.75 : 0.4+progress/2.0/1.25;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.feed setProgress:progress];
            [[[self.feed cell] progressView] setProgress:progress animated:YES];
        });
    }
}

- (void)setIndexingProgress:(double)progress
{
    if(![self isCancelled])
    {
        progress = ([self.feed isKindOfClass:[DHTransferFeed class]]) ? progress : (self.hasTarix) ? 0.75 + progress/4 : 0.8+progress/5;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.feed setProgress:progress];
            [[[self.feed cell] progressView] setProgress:progress animated:YES];
        });
    }
}

- (void)setDownloadProgress:(double)progress receivedBytes:(long long)length outOf:(long long)expectedLength
{
    if(![self isCancelled])
    {
        double unalteredProgress = progress;
        progress = (self.hasTarix) ? progress/2*1.5 : progress/2/1.25;
        [self.feed setProgress:progress];
        [[[self.feed cell] progressView] setProgress:progress animated:YES];
        if(expectedLength != -1)
        {
            NSDate *lastNameUpdate = self.lastDownloadProgressUpdate;
            NSDate *now = [NSDate date];
            if(!lastNameUpdate || [now timeIntervalSinceDate:lastNameUpdate] > 1.0 || fabs(self.lastProgress - unalteredProgress) > 0.05 || unalteredProgress == 1.0)
            {
                if(!lastNameUpdate)
                {
                    NSString *maxString = [NSString stringByFormattingDownloadProgress:expectedLength totalBytes:expectedLength];
                    CGFloat maxWidth = [DHRightDetailLabel calculateMaxDetailWidthBasedOnLongestPossibleString:maxString];
                    [self.feed setMaxRightDetailWidth:maxWidth];
                    [(DHFeed*)self.feed setSize:[maxString substringFromString:@"/"]];
                    [[[self.feed cell] titleLabel] setMaxRightDetailWidth:maxWidth];
                }
                self.lastDownloadProgressUpdate = now;
                self.lastProgress = unalteredProgress;
                if(expectedLength > 0)
                {
                    NSString *progressString = [NSString stringByFormattingDownloadProgress:length totalBytes:expectedLength];
                    [self setRightDetail:progressString];
                }
            }            
        }
    }
}

- (void)setRightDetail:(NSString *)rightDetail
{
    if(![NSThread isMainThread])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setRightDetail:rightDetail];
        });
        return;
    }
    [self.feed setDetailString:rightDetail];
    [self.feed cell].titleLabel.rightDetailText = rightDetail;
}

- (BOOL)isCancelled
{
    return ![self.feed installing] || [self.feed feedResult] != self;
}

@end
