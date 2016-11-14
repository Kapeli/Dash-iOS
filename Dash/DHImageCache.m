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

#import "DHImageCache.h"

@implementation DHImageCache

+ (DHImageCache *)sharedCache
{
    static dispatch_once_t pred;
    static DHImageCache *_imageCache = nil;

    dispatch_once(&pred, ^{
        _imageCache = [[DHImageCache alloc] init];
        _imageCache.filesCache = [NSMutableDictionary dictionary];
    });
    return _imageCache;
}

+ (UIImage *)imageWithContentsOfFile:(NSString *)path fullRefresh:(BOOL)fullRefresh
{
    if(!path || !path.length)
    {
        return nil;
    }
    DHImageCache *cache = [DHImageCache sharedCache];
    if(fullRefresh)
    {
        [cache.filesCache removeObjectForKey:path];
    }
    id image = (cache.filesCache)[path];
    if(image == [NSNull null])
    {
        return nil;
    }
    else if(image)
    {
        return image;
    }
    else
    {
        BOOL exists = NO;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *retinaPath = [[path stringByDeletingPathExtension] stringByAppendingString:@"@2x.png"];
        if([[path pathExtension] isEqualToString:@"png"] && [fileManager fileExistsAtPath:retinaPath])
        {
            exists = YES;
            path = retinaPath;
        }
        if(exists || [fileManager fileExistsAtPath:path])
        {
            image = [UIImage imageWithContentsOfFile:path];            
        }
        if(image)
        {
            (cache.filesCache)[path] = image;
        }
        else
        {
            (cache.filesCache)[path] = [NSNull null];
        }
        return image;
    }
    return nil;
}

@end
