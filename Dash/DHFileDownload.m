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

#import "DHFileDownload.h"
#import "DHFeedResult.h"

@implementation DHFileDownload

+ (BOOL)downloadItemAtURL:(NSURL *)url toFile:(NSString *)localPath error:(NSError **)error delegate:(id)delegate identifier:(id)identifier
{
    NSString *newURL = [[url absoluteString] stringByConvertingKapeliHttpURLToHttpsReturningNil];
    if(newURL.length)
    {
        url = [NSURL URLWithString:newURL];
    }
    if(![NSURL URLIsFound:[url absoluteString] timeoutInterval:120.0 checkForRedirect:NO])
    {
        return NO;
    }
    DHFileDownload *fileDownload = [[DHFileDownload alloc] init];
    if(identifier && [identifier isKindOfClass:[DHFeedResult class]])
    {
        [identifier setExpectedContentLength:0];
        [identifier setReceivedContentLength:0];
        [identifier setFileDownload:fileDownload];
    }
    
    fileDownload.identifier = identifier;
    fileDownload.delegate = delegate;
    fileDownload.filePath = localPath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:localPath])
    {
        [fileManager removeItemAtPath:localPath error:nil];
    }
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"%@%u", [url absoluteString], arc4random() % 100000]];
    configuration.timeoutIntervalForRequest = 900;
    configuration.HTTPAdditionalHeaders = @{@"User-Agent": [[NSBundle mainBundle] bundleIdentifier]};
    fileDownload.session = [NSURLSession sessionWithConfiguration:configuration delegate:fileDownload delegateQueue:nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:900.0];
    fileDownload.downloadTask = [fileDownload.session downloadTaskWithRequest:request];
    [fileDownload.downloadTask resume];

    
    while(!fileDownload.isDone)
    {
        [NSThread sleepForTimeInterval:0.1f];
    }
    
    if(identifier && [identifier isKindOfClass:[DHFeedResult class]])
    {
        [identifier setFileDownload:nil];
    }
    fileDownload.identifier = nil;
    fileDownload.delegate = nil;
    fileDownload.downloadTask = nil;
    if(fileDownload.error != nil)
    {
        if(error != nil)
        {
            *error = fileDownload.error;
        }
        [fileDownload.session invalidateAndCancel];
        fileDownload.session = nil;
        return NO;
    }
    [fileDownload.session invalidateAndCancel];
    fileDownload.session = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        [identifier setDownloadProgress:1.0 receivedBytes:-1 outOf:-1];
    });
    return YES;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if(totalBytesExpectedToWrite > 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.identifier setDownloadProgress:(double)totalBytesWritten/totalBytesExpectedToWrite receivedBytes:totalBytesWritten outOf:totalBytesExpectedToWrite];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    if(downloadURL && [downloadURL path] && [[NSFileManager defaultManager] fileExistsAtPath:[downloadURL path]])
    {
        [[NSFileManager defaultManager] moveItemAtPath:[downloadURL path] toPath:self.filePath error:nil];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"resumed at offset!?");
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    self.isDone = YES;
    if(error)
    {
        if(!self.cancelled)
        {
            self.error = error;
        }
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{

}

- (void)cancelDownload
{
    self.cancelled = YES;
    self.error = [NSError errorWithDomain:@"com.kapeli.dash" code:DHDownloadCancelled userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%d", DHDownloadCancelled]}];
    [self.identifier setExpectedContentLength:0];
    [self.identifier setReceivedContentLength:0];
    self.isDone = YES;
    [self.downloadTask cancel];
}

@end
