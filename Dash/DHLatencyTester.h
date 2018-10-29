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

@interface DHLatencyTester : NSObject

@property (retain) NSMutableArray *results;
@property (retain) NSOperationQueue *queue;
@property (retain) NSMutableArray *defaultResults;
@property (retain) NSMutableArray *resultsAllowedInUserDefaults;

+ (DHLatencyTester *)sharedLatency;
- (BOOL)performTests:(BOOL)forcePerform;
- (void)saveDefaults;
- (void)sortURLsBasedOnLatency:(NSMutableArray *)urls;
- (void)checkExtraMirrors:(NSMutableArray *)mirrors;
- (NSString *)bestMirrorReturningNil;
- (NSString *)bestMirror;
- (NSString *)secondBestMirror;
- (NSMutableArray *)sortedTestResults;

@end
