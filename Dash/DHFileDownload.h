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

@interface DHFileDownload : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionTask *downloadTask;
@property (retain) NSError *error;
@property (retain) NSString *filePath;
@property (assign) BOOL isDone;
@property (retain) id delegate;
@property (retain) id identifier;
@property (assign) BOOL cancelled;

+ (BOOL)downloadItemAtURL:(NSURL *)url toFile:(NSString *)localPath error:(NSError **)error delegate:(id)delegate identifier:(id)identifier;
- (void)cancelDownload;

@end

#define DHDownloadCancelled 2481939
