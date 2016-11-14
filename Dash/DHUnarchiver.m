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

#import "DHUnarchiver.h"
#import "archive.h"
#import "archive_entry.h"
#import "zlib.h"

@implementation DHUnarchiver

+ (BOOL)unpackTarixDocset:(NSString *)archivePath tarixPath:(NSString *)tarixPath delegate:(id)delegate
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = [tarixPath stringByDeletingLastPathComponent];
    BOOL success = NO;
    FMDatabase *db = [FMDatabase databaseWithPath:tarixPath];
    if([db openWithFlags:SQLITE_OPEN_READONLY])
    {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM toextract"];
        while([rs next])
        {
            success = YES;
            NSString *path = [rs stringForColumnIndex:0];
            NSString *hash = [rs stringForColumnIndex:1];
            NSString *fullPath = [folder stringByAppendingPathComponent:path];
            NSString *blockNumString = [hash substringToString:@" "];
            NSInteger blockNum = [blockNumString integerValue];
            hash = [hash substringFromString:@" "];
            NSString *offsetString = [hash substringToString:@" "];
            NSInteger offset = [offsetString integerValue];
            hash = [hash substringFromString:@" "];
            NSString *blockLengthString = [hash substringToString:@" "];
            NSInteger blockLength = [blockLengthString integerValue];

            [fileManager createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            if(![self tarixReadArchive:archivePath blockNum:blockNum offset:offset blockLength:blockLength toFile:fullPath])
            {
                success = NO;
                break;
            }
            if([delegate isCancelled])
            {
                success = NO;
                break;
            }
        }
    }
    [db close];
    return success;
}

+ (BOOL)unarchiveArchive:(NSString *)path delegate:(id)delegate
{
    [delegate setRightDetail:@"Extracting..."];
    chdir([[path stringByDeletingLastPathComponent] UTF8String]);
    if(extract([[path lastPathComponent] UTF8String], delegate) == 0)
    {
        return YES;
    }
    return NO;
}

// Only call this *after* the docset has been installed
+ (NSMutableData *)tarixReadFile:(NSString *)file toFile:(NSString *)outputPath
{
    NSString *hash = [DHTarixIndex hashForFile:file];
    if(hash)
    {
        NSArray *hashComponents = [hash componentsSeparatedByString:@" "];
        if(hash && hashComponents.count == 3)
        {
            long long blockNum = [hashComponents[0] longLongValue];
            long long offset = [hashComponents[1] longLongValue];
            long long blockLength = [hashComponents[2] longLongValue];
            NSString *archivePath = [[file substringToString:@".docset/Contents/Resources/"] stringByAppendingString:@".docset/Contents/Resources/tarix.tgz"];
            return [DHUnarchiver tarixReadArchive:archivePath blockNum:(unsigned long)blockNum offset:offset blockLength:(unsigned long)blockLength toFile:outputPath];
        }
    }
    return nil;
}

// Order in tarix file is 0 (file) or 5 (folder), blocknum, offset, blocklength
+ (NSMutableData *)tarixReadArchive:(NSString *)archive blockNum:(unsigned long)blockNum offset:(off_t)offset blockLength:(unsigned long)blockLength toFile:(NSString *)outputPath
{
    NSString *tarPath = [outputPath stringByAppendingString:@".tar"];
    NSOutputStream *stream = (tarPath) ? [NSOutputStream outputStreamToFileAtPath:tarPath append:NO] : nil;
    [stream open];
    NSMutableData *data = [[NSMutableData alloc] init];
    int tarFile = open([archive UTF8String], O_RDONLY);
    if(tarFile < 0)
    {
        NSLog(@"Couldn't open tarfile");
        return nil;
    }
    Bytef *inBuffer = nil;
    Bytef *outBuffer = nil;
    z_streamp zlibStream = calloc(1, sizeof(z_stream));
    @try {
        if(inflateInit2(zlibStream, -MAX_WBITS) != Z_OK)
        {
            NSLog(@"Couldn't init zlib stream");
            return nil;
        }
        if(lseek(tarFile, offset, SEEK_SET) < 0)
        {
            NSLog(@"Couldn't seek tarfile");
            return nil;
        }
        int blockSize = 512;
        inBuffer = malloc(blockSize*20);
        outBuffer = malloc(blockSize*20);
        NSInteger totalSizeRemaining = blockLength*blockSize;
        for(NSUInteger i = 0; i < blockLength && totalSizeRemaining > 0; i += 20)
        {
            zlibStream->next_in = inBuffer;
            NSInteger inLength = read(tarFile, inBuffer, (blockLength-i<20) ? blockSize*(blockLength-i) : blockSize*20);
            if(inLength < 0)
            {
                NSLog(@"Error reading tarfile");
                return nil;
            }
            zlibStream->avail_in = (uint)inLength;
            while(zlibStream->avail_in > 0 && totalSizeRemaining > 0)
            {
                zlibStream->next_out = outBuffer;
                zlibStream->avail_out = blockSize*20;
                int status = inflate(zlibStream, Z_SYNC_FLUSH);
                if(status != Z_OK && status != Z_STREAM_END)
                {
                    NSLog(@"Error inflating buffer");
                    return nil;
                }
                NSUInteger outLength = blockSize*20-zlibStream->avail_out;
                if(outLength > totalSizeRemaining)
                {
                    outLength = totalSizeRemaining;
                    totalSizeRemaining = 0;
                }
                totalSizeRemaining -= outLength;
                if(!stream)
                {
                    [data appendBytes:outBuffer length:outLength];
                }
                else
                {
                    [stream write:outBuffer maxLength:outLength];
                }
            }
        }
    }
    @finally {
        free(inBuffer);
        free(outBuffer);
        deflateEnd(zlibStream);
        free(zlibStream);
        close(tarFile);
        [stream close];
    }
    
    if(tarPath)
    {
        BOOL success = extract_single_file([tarPath UTF8String], outputPath) == 0;
        [[NSFileManager defaultManager] removeItemAtPath:tarPath error:nil];
        if(!success)
        {
            [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        }
        return (success) ? data : nil;
    }
    return extract_from_memory([data bytes], data.length);
}

static int copy_data(struct archive *ar, struct archive *aw)
{
    int r;
    const void *buff;
    size_t size;
    off_t offset;
    
    for (;;) {
        r = tk_archive_read_data_block(ar, &buff, &size, &offset);
        if (r == tk_archive_EOF)
            return (tk_archive_OK);
        if (r < tk_archive_OK)
            return (r);
        r = (int)tk_archive_write_data_block(aw, buff, size, offset);
        if (r < tk_archive_OK) {
            fprintf(stderr, "%s\n", tk_archive_error_string(aw));
            return (r);
        }
    }
}

off_t fsize(const char *filename) {
    struct stat st;
    
    if (stat(filename, &st) == 0)
        return st.st_size;
    
    return -1;
}

NSMutableData * extract_from_memory(const void * buff, size_t size)
{
    NSMutableData *data = [[NSMutableData alloc] init];
    struct archive *a;
    struct tk_archive_entry *entry;
    int r;
    
    a = tk_archive_read_new();
    tk_archive_read_support_format_tar(a);
    tk_archive_read_support_compression_none(a);
    
    if ((r = tk_archive_read_open_memory(a, (void*)buff, size)))
    {
        data = nil;
        goto cleanup;
    }
    for (;;) {
        r = tk_archive_read_next_header(a, &entry);
        if (r == tk_archive_EOF)
            break;
        if (r < tk_archive_OK)
            fprintf(stderr, "%s\n", tk_archive_error_string(a));
        if (r < tk_archive_WARN)
        {
            data = nil;
            goto cleanup;
        }
        if (tk_archive_entry_size(entry) > 0) {
            const void *readBuff;
            size_t readSize;
            off_t offset;
            
            for (;;) {
                r = tk_archive_read_data_block(a, &readBuff, &readSize, &offset);
                if (r == tk_archive_EOF)
                    break;
                if (r < tk_archive_OK)
                    break;
                [data appendBytes:readBuff length:readSize];
            }
            
            if (r < tk_archive_WARN)
            {
                data = nil;
                goto cleanup;
            }
        }
        if (r < tk_archive_WARN)
        {
            data = nil;
            goto cleanup;
        }
    }
cleanup:
    tk_archive_read_close(a);
    tk_archive_read_finish(a);
    return data;
}

static int extract_single_file(const char *filename, NSString *output_file)
{
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:output_file append:NO];
    [stream open];
    
    struct archive *a;
    struct tk_archive_entry *entry;
    int r = 0;
    int ret = 0;
    
    a = tk_archive_read_new();
    tk_archive_read_support_format_tar(a);
    tk_archive_read_support_compression_none(a);
    
    if ((r = tk_archive_read_open_filename(a, filename, 10240)))
    {
        ret = 1;
        goto cleanup;
    }
    for (;;) {
        r = tk_archive_read_next_header(a, &entry);
        if (r == tk_archive_EOF)
            break;
        if (r < tk_archive_OK)
            fprintf(stderr, "%s\n", tk_archive_error_string(a));
        if (r < tk_archive_WARN)
        {
            ret = 1;
            goto cleanup;
        }
        if (tk_archive_entry_size(entry) > 0) {
            const void *buff;
            size_t size;
            off_t offset;
            
            for (;;) {
                r = tk_archive_read_data_block(a, &buff, &size, &offset);
                if (r == tk_archive_EOF)
                    break;
                if (r < tk_archive_OK)
                    break;
                [stream write:buff maxLength:size];
            }
            
            if (r < tk_archive_WARN)
            {
                ret = 1;
                goto cleanup;
            }
        }
        if (r < tk_archive_WARN)
        {
            ret = 1;
            goto cleanup;
        }
    }
cleanup:
    tk_archive_read_close(a);
    tk_archive_read_finish(a);
    [stream close];
    return ret;
}

static int extract(const char *filename, id delegate)
{
    struct archive *a;
    struct archive *ext;
    struct tk_archive_entry *entry;
    int flags;
    int r;
    
    flags = tk_archive_EXTRACT_TIME;
    flags |= tk_archive_EXTRACT_PERM;
    flags |= tk_archive_EXTRACT_ACL;
    flags |= tk_archive_EXTRACT_FFLAGS;
    
    a = tk_archive_read_new();
    tk_archive_read_support_format_all(a);
    tk_archive_read_support_compression_all(a);
    
    ext = tk_archive_write_disk_new();
    tk_archive_write_disk_set_options(ext, flags);
    tk_archive_write_disk_set_standard_lookup(ext);
    int ret = 0;
    if ((r = tk_archive_read_open_filename(a, filename, 10240)))
    {
        ret = 1;
        goto cleanup;
    }
    off_t total = fsize(filename);
    __LA_INT64_T previousProgress = 0;
    double lastPercent = 0;
    for (;;) {
        if(total > 0)
        {
            __LA_INT64_T progress = tk_archive_position_compressed(a);
            if(previousProgress != progress)
            {
                double currentPercent = (double)progress/total;
                double delta = currentPercent - lastPercent;
                if(delta > 0.005f || delta < -0.005f || progress == total)
                {
                    lastPercent = currentPercent;
                    [delegate setUnarchiveProgress:currentPercent];
                }
                
            }
            previousProgress = progress;
        }
        if([delegate isCancelled])
        {
            goto cleanup;
        }
        
        r = tk_archive_read_next_header(a, &entry);
        if (r == tk_archive_EOF)
            break;
        if (r < tk_archive_OK)
            fprintf(stderr, "%s\n", tk_archive_error_string(a));
        if (r < tk_archive_WARN)
        {
            ret = 1;
            goto cleanup;
        }
        r = tk_archive_write_header(ext, entry);
        if (r < tk_archive_OK)
            fprintf(stderr, "%s\n", tk_archive_error_string(ext));
        else if (tk_archive_entry_size(entry) > 0) {
            r = copy_data(a, ext);
            if (r < tk_archive_OK)
                fprintf(stderr, "%s\n", tk_archive_error_string(ext));
            if (r < tk_archive_WARN)
            {
                ret = 1;
                goto cleanup;
            }
        }
        r = tk_archive_write_finish_entry(ext);
        if (r < tk_archive_OK)
            fprintf(stderr, "%s\n", tk_archive_error_string(ext));
        if (r < tk_archive_WARN)
        {
            ret = 1;
            goto cleanup;
        }
    }
cleanup:
    tk_archive_read_close(a);
    tk_archive_read_finish(a);
    tk_archive_write_close(ext);
    tk_archive_write_finish(ext);
    return ret;
}

- (void)setUnarchiveProgress:(double)progress
{
    
}

- (void)setRightDetail:(NSString *)detail
{
    
}

- (BOOL)isCancelled
{
    return NO;
}

@end
