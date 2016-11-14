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

#import "DHTarixIndex.h"
#import "FMDatabase.h"

@implementation DHTarixIndex

+ (NSString *)hashForFile:(NSString *)path
{
    NSString *hash = nil;
    NSString *docsetPath = [[path substringToStringReturningNil:@".docset"] stringByAppendingString:@".docset"];
    NSString *filePath = [[docsetPath lastPathComponent] stringByAppendingPathComponent:[path substringFromStringReturningNil:@".docset"]];
    if(filePath.length && docsetPath.length)
    {
        NSString *indexPath = [docsetPath stringByAppendingPathComponent:@"Contents/Resources/tarixIndex.db"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:indexPath])
        {
            @synchronized([DHTarixIndex class])
            {
                FMDatabase *db = [FMDatabase databaseWithPath:indexPath];
                if([db openWithFlags:SQLITE_OPEN_READONLY])
                {
                    FMResultSet *rs = [db executeQuery:@"SELECT hash FROM tarindex WHERE path = ?", filePath];
                    if([rs next])
                    {
                        hash = [rs stringForColumnIndex:0];
                        if(!hash.length)
                        {
                            hash = nil;
                        }
                    }
                    [db close];
                }
            }
        }
    }
    return hash;
}

@end
