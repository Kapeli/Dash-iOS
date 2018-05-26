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

#import "NSString+DHUtils.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString *const DHPBoardType = @"DashPBoard";

@implementation NSString (DHUtils)

- (NSString *)stringByDeletingPathFragment
{
    NSRange fragment = [self rangeOfString:@"#" options:NSBackwardsSearch];
    if(fragment.location != NSNotFound) 
    {
        NSString *newPath = [self substringToDashIndex:fragment.location];
        return newPath;
    } 
    else 
    {
        return self;
    }
}

- (NSString *)pathFragment
{
    NSRange fragment = [self rangeOfString:@"#" options:NSBackwardsSearch];
    if(fragment.location != NSNotFound && fragment.location+1 < self.length)
    {
        NSString *pathFragment = [self substringFromDashIndex:fragment.location+fragment.length];
        return pathFragment;
    }
    else
    {
        return nil;
    }
}

- (NSString *)FTSPrefix
{
    if(self.length <= 1)
    {
        return @"";
    }
    return [[self substringToIndex:self.length-1] stringByReplacingSpecialFTSCharacters];
}

- (NSString *)allFTSSuffixes
{
    if(self.length <= 1)
    {
        return @"";
    }
    NSMutableString *string = [NSMutableString string];
    BOOL firstLoop = YES;
    for(NSUInteger i = 1; i < self.length; i++)
    {
        if(!firstLoop)
        {
            [string appendString:@" "];
        }
        firstLoop = NO;
        [string appendString:[self substringWithRange:NSMakeRange(i, self.length-i)]];
    }
    return [string stringByReplacingSpecialFTSCharacters];
}

- (NSString *)stringByRemovingCharactersInSet:(NSCharacterSet *)aSet
{
    NSMutableString *string = [[NSMutableString alloc] initWithString:self];
    NSRange range;
    while((range = [string rangeOfCharacterFromSet:aSet]).location != NSNotFound)
    {
        [string replaceCharactersInRange:range withString:@""];
    }
    return string;
}

- (NSString *)stringByRemovingWhitespaces
{
    return [self stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (NSString *)stringByReplacingSpecialFTSCharacters
{
    NSString *string = [self lowercaseString];
    NSUInteger length = [string length];
    if(length == 0)
    {
        return string;
    }
    NSMutableString *finalString = [NSMutableString string];
    NSMutableData *data2 = [NSMutableData dataWithCapacity:sizeof(unichar) * length];
    
    const unichar *buffer = CFStringGetCharactersPtr((CFStringRef)string);
    if(!buffer)
    {
        NSMutableData *data = [NSMutableData dataWithLength:length * sizeof(UniChar)];
        if (!data)
        {
            return nil;
        }
        [string getCharacters:[data mutableBytes]];
        buffer = [data bytes];
    }
    
    if(!buffer || !data2)
    {
        return nil;
    }
    
    unichar *buffer2 = (unichar *)[data2 mutableBytes];
    
    NSUInteger buffer2Length = 0;
    
    for (NSUInteger i = 0; i < length; ++i)
    {
        if(!(buffer[i]>='a' && buffer[i]<='z') && buffer[i] != ' ' && !(buffer[i]>='0' && buffer[i]<='9'))
        {
            if(buffer2Length)
            {
                CFStringAppendCharacters((CFMutableStringRef)finalString,
                                         buffer2,
                                         buffer2Length);
                buffer2Length = 0;
            }
            if(buffer[i] == L'❤')
            {
                [finalString appendFormat:@"`%d`", ' '];
            }
            else
            {
                [finalString appendFormat:@"`%d`", buffer[i]];
            }
        }
        else
        {
            buffer2[buffer2Length] = buffer[i];
            buffer2Length += 1;
        }
    }
    if(buffer2Length)
    {
        CFStringAppendCharacters((CFMutableStringRef)finalString,
                                 buffer2,
                                 buffer2Length);
    }
    return finalString;
}

- (NSString *)docsetPath
{
    NSRange docsetRange = [self rangeOfString:@".docset/Contents/Resources/Documents/"];
    if(docsetRange.location != NSNotFound)
    {
        return [self substringToDashIndex:docsetRange.location+@".docset".length];
    }
    return nil;
}

- (NSString *)docsetPlatform
{
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:[[NSURL URLWithString:self] URLByAppendingPathComponent:@"Contents/Info.plist"]];
    NSString *platform = plist[@"DocSetPlatformFamily"];
    if([platform isEqualToString:@"iphoneos"] || [platform isEqualToString:@"ios"])
    {
        return @"iOS";
    }
    else if([platform isEqualToString:@"macosx"] || [platform isEqualToString:@"osx"])
    {
        return @"Mac";
    }
    return @"Unknown Platform";
}

+ (NSString *)randomStringWithLength:(int)len
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    int letterCount = (int)letters.length;
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    for (int i=0; i<len; i++)
    {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random_uniform(letterCount) % letterCount]];
    }
    
    return randomString;
}

- (NSString *)stringByDeletingPathToDocset
{
    NSMutableArray *newComponents = [NSMutableArray array];
    BOOL docsetFound = NO;
    for(NSString *component in [self pathComponents])
    {
        if([component rangeOfString:@".docset"].location != NSNotFound)
        {
            docsetFound = YES;
        }
        if(docsetFound)
        {
            [newComponents addObject:component];
        }
    }
    if(!docsetFound || [newComponents count] < 2)
    {
        return nil;
    }
    return [NSString pathWithComponents:newComponents];
}

- (NSString *)firstComponentSeparatedByWhitespace
{
    NSArray *components = [self componentsSeparatedByString:@" "];
    if([components count])
    {
        return components[0];
    }
    return self;
}

- (float)distanceFromString:(NSString *)stringB
{
    // normalize strings
    NSString * stringA = [NSString stringWithString: self];
    [stringA stringByTrimmingCharactersInSet:
     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [stringB stringByTrimmingCharactersInSet:
     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    stringA = [stringA lowercaseString];
    stringB = [stringB lowercaseString];
    
    
    // Step 1
    int k, i, j, cost, * d, distance;
    
    NSUInteger n = [stringA length];
    NSUInteger m = [stringB length];	
    
    if( n++ != 0 && m++ != 0 ) {
        
        d = malloc( sizeof(int) * m * n );
        
        // Step 2
        for( k = 0; k < n; k++)
            d[k] = k;
        
        for( k = 0; k < m; k++)
            d[ k * n ] = k;
        
        // Step 3 and 4
        for( i = 1; i < n; i++ )
            for( j = 1; j < m; j++ ) {
                
                // Step 5
                if( [stringA characterAtIndex: i-1] == 
                   [stringB characterAtIndex: j-1] )
                    cost = 0;
                else
                    cost = 1;
                
                // Step 6
                d[ j * n + i ] = [self smallestOf: d [ (j - 1) * n + i ] + 1
                                            andOf: d[ j * n + i - 1 ] +  1
                                            andOf: d[ (j - 1) * n + i -1 ] + cost ];
            }
        
        distance = d[ n * m - 1 ];
        
        free( d );
        
        return distance;
    }
    return 0.0;
}

- (float)distanceFromString:(NSString *)stringB withDummyLimit:(NSInteger)limit
{
    NSInteger delta = self.length-stringB.length;
    if(delta >= limit || delta <= -limit)
    {
        return 99;
    }
    return [self distanceFromString:stringB];
}


// return the minimum of a, b and c
- (int)smallestOf:(int)a andOf:(int)b andOf:(int)c
{
    int min = a;
    if ( b < min )
        min = b;
    
    if( c < min )
        min = c;
    
    return min;
}

// Find the tag represented by the tag query string (i.e. in the case of "t:thisIsATag" return "thisIsATag")
- (NSString *)tagFromTagQuery
{
    return [self substringFromDashIndex:2];
}

// Find the character before the given suffix
- (NSString *)characterBeforeSuffix:(NSString *)suffix
{
    if([self length] < [suffix length])
    {
        return nil;
    }
    if([self hasSuffix:suffix])
    {
        if([self length] > [suffix length])
        {
            if(suffix.length > 1)
            {
                return [self substringWithDashRange:NSMakeRange(self.length-suffix.length-1, 2)];
            }
            return [self substringWithDashRange:NSMakeRange(self.length-suffix.length-1, 1)];
        }
        return @"";
    }
    return nil;
}

// Test if the strings share the same last characters
- (BOOL)hasSameLastCharactersWithString:(NSString *)string charToCompare:(NSString *)character
{
    NSString *compareChar;
    NSString *lastChar = [self substringFromDashIndex:self.length-1];
    if([lastChar rangeOfString:character options:NSCaseInsensitiveSearch].location != 0)
    {
        return NO;
    }
    for(int i=1; i < self.length; i++)
    {
        if(i > string.length)
        {
            return YES;
        }
        lastChar = [self substringWithDashRange:NSMakeRange(self.length-i, 1)];
        compareChar = [string substringWithDashRange:NSMakeRange(string.length-i, 1)];
        if([lastChar rangeOfString:character options:NSCaseInsensitiveSearch].location == NSNotFound)
        {
            if([compareChar rangeOfString:character options:NSCaseInsensitiveSearch].location == 0)
            {
                return NO;
            }
            return YES;
        }
    }
    return YES;
}

- (NSUInteger)countOccurrencesOfString:(NSString *)aString options:(NSStringCompareOptions)options
{
    NSRange range = NSMakeRange(0, 0);
    NSUInteger count = 0;
    do {
        range = [self rangeOfString:aString options:options range:NSMakeRange(NSMaxRange(range), self.length-NSMaxRange(range))];
        if(range.location != NSNotFound)
        {
            ++count;
        }
        else
        {
            break;
        }
    } while (1);
    return count;
}

// Count the number of lines the string contains
- (NSUInteger)countNewLines
{
    return [self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].count;
}

- (CGSize) attributedSizeWithFont:(UIFont*) font {
    return [self attributedSizeWithFont:font maxWidth:CGFLOAT_MAX];
}

- (CGSize) attributedSizeWithFont:(UIFont*) font maxWidth:(CGFloat) width {
    
    NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self
                                                                         attributes:@{ NSFontAttributeName:font,
                                                                                       NSForegroundColorAttributeName:[UIColor blackColor],
                                                                                       NSParagraphStyleAttributeName:style }];
    
    CGRect textRect = [attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                   options:(NSStringDrawingUsesLineFragmentOrigin)
                                                   context:nil];
    CGSize size = textRect.size;
    size.height = ceilf(size.height);
    size.width  = ceilf(size.width);
    
    return size;
}

+ (NSString *)stringByFormattingDownloadProgress:(long long)downloadedBytes totalBytes:(long long)totalBytes
{
    double convertedTotal = totalBytes / 1024.0;
    double convertedDownloaded = downloadedBytes / 1024.0;
    int multiplyFactor = 0;
    if(convertedTotal <= 0)
    {
        return @"0/0 KB";
    }
    
    NSArray *tokens = @[@"KB",@"MB",@"GB",@"TB"];
    
    while(convertedTotal > 999.99 && multiplyFactor < tokens.count)
    {
        convertedTotal /= 1024;
        multiplyFactor++;
    }
    
    for(int i = 0; i < multiplyFactor; i++)
    {
        convertedDownloaded /= 1024;
    }
    return [NSString stringWithFormat:@"%4.2f/%4.2f %@", convertedDownloaded, convertedTotal, tokens[multiplyFactor]];
}

// Backwards Limit the number of lines that the string has
- (NSString *)stringByBackwardsLimitingLinesTo:(NSUInteger)limit
{
    NSArray *lines = [self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if([lines count] <= limit)
    {
        return self;
    }
    NSMutableArray *mLines = [NSMutableArray arrayWithArray:lines];
    while([mLines count] > limit)
    {
        [mLines removeObjectAtIndex:0];
    }
    return [mLines componentsJoinedByString:@"\n"];
}

// Limit the lines that the string has
- (NSString *)stringByLimitingLinesTo:(NSUInteger)limit
{
    NSArray *lines = [self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if([lines count] <= limit)
    {
        return self;
    }
    NSMutableArray *mLines = [NSMutableArray arrayWithArray:lines];
    while([mLines count] > limit)
    {
        [mLines removeLastObject];
    }
    return [mLines componentsJoinedByString:@"\n"];
}

- (NSString *) URLEncodedString_ch {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[self UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

- (BOOL)isPackageType
{
    return ([self isEqualToString:@"Category"] || [self isEqualToString:@"Library"] || [self isEqualToString:@"Package"] || [self isEqualToString:@"Module"] || [self isEqualToString:@"File"] || [self isEqualToString:@"Namespace"]);
}

- (BOOL)isClassType
{
    return [self isEqualToString:@"Class"] || [self isEqualToString:@"Element"] || [self isEqualToString:@"Tag"] || [self isEqualToString:@"Trait"] || [self isEqualToString:@"Object"];
}

- (NSString *)lastPackageComponent:(NSString *)delimiter
{
    NSRange argsStart = [self rangeOfString:@"("];
    if(argsStart.location != NSNotFound)
    {
        return [[[self substringToDashIndex:argsStart.location] lastPackageComponent:delimiter] stringByAppendingString:[self substringFromDashIndex:argsStart.location]];
    }
    NSArray *components = [self componentsSeparatedByString:delimiter];
    for(NSInteger i=components.count-1; i >= 0; i--)
    {
        NSString *component = [components[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(component.length)
        {
            if([delimiter isEqualToString:@"."])
            {
                NSInteger delta = components.count - i - 1;
                for(NSInteger j = 0; j < delta; j++)
                {
                    component = [component stringByAppendingString:delimiter];
                }
            }
            return component;
        }
    }
    return self;
}

- (NSString *)stringByRemovingSymbols
{
    return [self stringByRemovingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
}

- (BOOL)containsAny:(NSArray *)strings
{
    for(NSString *string in strings)
    {
        if([self contains:string])
        {
            return YES;
        }
    }
    return NO;
}

- (NSString *)lastTwoPackageComponents:(NSString *)delimiter
{
    NSRange argsStart = [self rangeOfString:@"("];
    if(argsStart.location != NSNotFound)
    {
        return [[[self substringToDashIndex:argsStart.location] lastTwoPackageComponents:delimiter] stringByAppendingString:[self substringFromDashIndex:argsStart.location]];
    }
    NSArray *components = [self componentsSeparatedByString:@"."];
    if(components.count > 1)
    {
        return [NSString stringWithFormat:@"%@%@%@", components[components.count-2], delimiter, [components lastObject]];
    }
    return self;
}

- (NSString *)packageComponentsDependingOnPackage:(NSString *)package
{
    if(!package)
    {
        return self;
    }
    NSRange range = [self rangeOfString:package options:NSCaseInsensitiveSearch];
    if(range.location != 0)
    {
        return self;
    }
    if(range.length+1 >= self.length)
    {
        return self;
    }
    return [self substringFromDashIndex:range.length+1];
}

- (NSString *)stringByDeletingLastPackageComponent:(NSString *)delimiter
{
    NSMutableArray *components = [NSMutableArray arrayWithArray:[self componentsSeparatedByString:delimiter]];
    if(components.count <= 1)
    {
        return nil;
    }
    [components removeLastObject];
    return [components componentsJoinedByString:delimiter];
}

+ (NSString *)commonPackageInStringArray:(NSArray *)strings delimiter:(NSString *)delimiter
{
    if(!strings.count)
    {
        return nil;
    }
    else
    {
        NSString *package = [strings lastObject];
        if(strings.count == 1)
        {
            return [package stringByDeletingLastPackageComponent:delimiter];
        }
        for(NSString *string in strings)
        {
            while(package)
            {
                NSRange range = [string rangeOfString:package options:NSCaseInsensitiveSearch];
                if(range.location != 0 || range.length >= string.length || ![[string substringWithDashRange:NSMakeRange(range.length, 1)] isEqualToString:delimiter])
                {
                    package = [package stringByDeletingLastPackageComponent:delimiter];
                }
                else
                {
                    break;
                }
            }
            if(!package)
            {
                return nil;
            }
        }
        NSString *first = strings[0];
        NSString *last = [strings lastObject];
        if([package rangeOfString:delimiter].location != NSNotFound && ([first rangeOfString:package options:NSCaseInsensitiveSearch].length == [first length] || [[first packageComponentsDependingOnPackage:package] rangeOfString:delimiter].location != NSNotFound) && [[last packageComponentsDependingOnPackage:package] rangeOfString:delimiter].location == NSNotFound)
        {
            package = [package stringByDeletingLastPackageComponent:delimiter];
        }
        return package;
    }
}

- (NSString *)shortenJavaMethod
{
    NSRange argsStart = [self rangeOfString:@"("];
    if(argsStart.location == NSNotFound)
    {
        return self;
    }
    NSString *method = [self substringToDashIndex:argsStart.location];
    NSString *args = [self substringFromDashIndex:argsStart.location];
    if(args.length <= 2)
    {
        return self;
    }
    args = [args substringWithDashRange:NSMakeRange(1, args.length-2)];
    NSInteger length = 0;
    while(args.length != length)
    {
        length = args.length;
        
        NSRange listStart = [args rangeOfString:@"<"];
        if(listStart.location == NSNotFound)
        {
            break;
        }
        NSRange listEnd = [args rangeOfString:@">"];
        if(listEnd.location == NSNotFound)
        {
            args = [args substringToDashIndex:listStart.location];
        }
        else
        {
            if(listStart.location > listEnd.location)
            {
                args = [args stringByReplacingCharactersInRange:listEnd withString:@""];
            }
            else if(args.length > listEnd.location+1)
            {
                args = [[args substringToDashIndex:listStart.location] stringByAppendingString:[args substringFromDashIndex:listEnd.location+1]];
            }
            else
            {
                args = [args substringToDashIndex:listStart.location];
            }
        }
    }
    args = [args stringByReplacingOccurrencesOfString:@">" withString:@""];
    NSString *trimmedArgs = @"(";
    for(NSString *arg in [args componentsSeparatedByString:@","])
    {
        NSString *trimmed = [arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        trimmed = [trimmed lastPackageComponent:@"."];
        if(trimmed.length)
        {
            trimmedArgs = [trimmedArgs stringByAppendingFormat:@"%@, ", trimmed];
        }
    }
    if(trimmedArgs.length >= 3)
    {
        trimmedArgs = [trimmedArgs substringToDashIndex:trimmedArgs.length-2];
    }
    return [NSString stringWithFormat:@"%@%@)", method, trimmedArgs];
}

- (BOOL)hasCaseInsensitivePrefix:(NSString *)prefix
{
    if(!prefix.length)
    {
        return NO;
    }
    return ([self rangeOfString:prefix options:NSAnchoredSearch | NSCaseInsensitiveSearch].location != NSNotFound);
}

- (BOOL)hasCaseInsensitiveSuffix:(NSString *)suffix
{
    if(!suffix.length)
    {
        return NO;
    }
    return ([self rangeOfString:suffix options:NSAnchoredSearch | NSCaseInsensitiveSearch | NSBackwardsSearch].location != NSNotFound);
}

- (NSString *)stringByAddingWildcardsEverywhere:(NSString *)escapeChar
{
    NSMutableString *mutable = [NSMutableString string];
    [mutable appendString:@"%"];
    for(NSInteger i = 0; i < self.length; i++)
    {
        NSString *currentChar = [self substringWithDashRange:NSMakeRange(i, 1)];
        if([currentChar isEqualToString:escapeChar] && i+1 < self.length)
        {
            [mutable appendString:currentChar];
            [mutable appendString:[self substringWithDashRange:NSMakeRange(i+1, 1)]];
            [mutable appendString:@"%"];
            ++i;
        }
        else
        {
            [mutable appendString:currentChar];
            [mutable appendString:@"%"];
        }
    }
    return mutable;
}

- (NSString *)formatPlural:(NSInteger)count
{
    if(count == 1)
    {
        return self;
    }
    return [self stringByAppendingString:@"s"];
}


- (NSUInteger)lineStartForRange:(NSRange)diveInRange 
{
    NSUInteger lineStartIndex = 0;
    [self getLineStart:&lineStartIndex
                   end:NULL
           contentsEnd:NULL
              forRange:diveInRange];
    return lineStartIndex;
}

- (NSRange)rangeOfWhitespaceStringAtBeginningOfLineForRange:(NSRange)range {
    return [self rangeOfWhitespaceStringAtBeginningOfLineForRange:range
                                                        substring:nil];
}

- (NSRange)rangeOfWhitespaceStringAtBeginningOfLineForRange:(NSRange)range substring:(NSString**)outString 
{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    NSUInteger lineStart = [self lineStartForRange:range];
    if (lineStart != NSNotFound && lineStart < self.length) {
        unichar firstCharOfLine = [self characterAtIndex:lineStart];
        if ([whitespace characterIsMember:firstCharOfLine]) {
            // first char is whitespace, so let's find the full range
            return [self rangeOfCharactersFromSet:whitespace
                                    afterLocation:lineStart
                                        substring:outString];
        }
    }
    return NSMakeRange(NSNotFound, 0);
}

- (NSRange)rangeOfCharactersFromSet:(NSCharacterSet*)characterSet afterLocation:(NSUInteger)startLocation substring:(NSString**)outString 
{
    NSRange searchRange = NSMakeRange(startLocation, self.length - startLocation);
    NSRange range = [self rangeOfCharactersFromSet:characterSet
                                           options:NSLiteralSearch
                                             range:searchRange];
    if (outString && range.location != NSNotFound)
        *outString = [self substringWithDashRange:range];
    return range;
}

-(NSRange)rangeOfCharactersFromSet:(NSCharacterSet*)aSet
                           options:(NSStringCompareOptions)mask
                             range:(NSRange)range {
    NSInteger start, curr, end, step=1;
    if (mask & NSBackwardsSearch) {
        step = -1;
        start = range.location + range.length - 1;
        end = range.location-1;
    } else {
        start = range.location;
        end = start + range.length;
    }
    if (!(mask & NSAnchoredSearch)) {
        // find first character in set
        for (;start != end; start += step) {
            if ([aSet characterIsMember:[self characterAtIndex:start]]) {
                goto found;
            }
        }
        return (NSRange){NSNotFound, 0u};
    }
    if (![aSet characterIsMember:[self characterAtIndex:start]]) {
        // no characters found within given range
        return (NSRange){NSNotFound, 0u};
    }
    
found:
    for (curr = start; curr != end; curr += step) {
        if (![aSet characterIsMember:[self characterAtIndex:curr]]) {
            break;
        }
    }
    if (curr < start) {
        // search was backwards
        range.location = curr+1;
        range.length = start - curr;
    } else {
        range.location = start;
        range.length = curr - start;
    }
    return range;
}

- (unichar*)copyOfCharactersInRange:(NSRange)range {
    unichar *buf = (unichar*)malloc(range.length * sizeof(unichar));
    [self getCharacters:buf range:range];
    return buf;
}

+ (void)dhEnumerateLinesOfCharacters:(const unichar*)characters
                             ofLength:(NSUInteger)characterCount
                            withBlock:(void(^)(NSRange lineRange))block {
    NSUInteger i = 0;
    NSRange lineRange = {0, 0};
    while (i < characterCount) {
        unichar ch = characters[i++];
        //DLOG("characters[%lu] '%C' (%d)", i, ch, (int)ch);
        if (ch == '\r') {
            // CR
            if (i < characterCount-1 && characters[i+1] == '\n') {
                // advance past LF in a CR LF sequence
                ++i;
            }
        } else if (ch != '\n' && ch != '\x0b' && ch != '\x0c' &&
                   i < characterCount) {
            // NEITHER: line feed OR vertical tab OR form feed OR not end
            continue;
        }
        // if we got here, a new line just begun
        lineRange.length = i - lineRange.location;
        
        // invoke block
        block(lineRange);
        
        // begin new line
        lineRange.location = i;
    }
}

- (NSString *)substringFromDashIndex:(NSUInteger)from
{
    if(from >= self.length)
    {
        return @"";
    }
    if(from <= 0)
    {
        return self;
    }
    return [self substringFromIndex:from];
}

- (NSString *)substringToDashIndex:(NSUInteger)to
{
    if(to <= 0)
    {
        return @"";
    }
    if(to >= self.length)
    {
        return self;
    }
    return [self substringToIndex:to];
}

- (NSString *)substringWithDashRange:(NSRange)range
{
    if(!self.length)
    {
        return @"";
    }
    NSRange myRange = NSMakeRange(0, self.length);
    NSRange intersect = NSIntersectionRange(myRange, range);
    if(!NSEqualRanges(range, intersect))
    {
        NSLog(@"substringWithRange exception:%@ - %@ for %@", NSStringFromRange(range), NSStringFromRange(intersect), self);
    }
    if(intersect.length)
    {
        return [self substringWithRange:intersect];
    }
    return @"";
}

- (NSString *)substringBetweenString:(NSString *)start andString:(NSString *)end
{
    return [self substringBetweenString:start andString:end options:NSCaseInsensitiveSearch];
}

- (NSString *)substringBetweenString:(NSString *)start andString:(NSString *)end options:(NSStringCompareOptions)options
{
    NSInteger startLocation = 0;
    NSInteger endLocation = 0;
    return [self substringBetweenString:start andString:end startLocation:&startLocation endLocation:&endLocation options:options];
}

- (NSString *)stringByConvertingKapeliHttpURLToHttps
{
    NSString *newString = [self stringByConvertingKapeliHttpURLToHttpsReturningNil];
    return (newString) ? newString : self;
}

- (NSString *)stringByConvertingKapeliHttpURLToHttpsReturningNil
{
    if([self contains:@"http://kapeli.com/"] || ([self contains:@".kapeli.com/"] && [self contains:@"http://"]))
    {
        NSString *https = [self stringByReplacingOccurrencesOfString:@"http://" withString:@"https://" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.length)];
        if([NSURL URLWithString:https])
        {
            return https;
        }
        return nil;
    }
    return nil;
}

- (NSString *)substringBetweenString:(NSString *)start andString:(NSString *)end startLocation:(NSInteger *)startLocation endLocation:(NSInteger *)endLocation options:(NSStringCompareOptions)options
{
    NSRange startRange = [self rangeOfString:start options:options|NSCaseInsensitiveSearch];
    if(startRange.location != NSNotFound)
    {
        *startLocation = startRange.location;
        if(end == nil)
        {
            return [self substringFromDashIndex:startRange.location+startRange.length];
        }
        NSRange endRange = [self rangeOfString:end options:NSCaseInsensitiveSearch range:NSMakeRange(startRange.location+startRange.length, self.length-startRange.location-startRange.length)];
        if(endRange.location != NSNotFound)
        {
            *endLocation = endRange.location+endRange.length;
            return [self substringWithDashRange:NSMakeRange(startRange.location+startRange.length, endRange.location-startRange.location-startRange.length)];
        }
    }
    return nil;
}

- (NSString *)substringBeginningAtString:(NSString *)start stoppingAtTag:(NSString *)tag startLocation:(NSInteger *)startLocation endLocation:(NSInteger *)endLocation
{
    NSRange startRange = [self rangeOfString:start options:NSCaseInsensitiveSearch];
    if(startRange.location != NSNotFound)
    {
        *startLocation = startRange.location;
        NSString *startTag = [@"<" stringByAppendingString:tag];
        NSString *endTag = [@"</" stringByAppendingString:tag];
        NSRange endTagRange;
        NSRange endTagScanRange = NSMakeRange(startRange.location+startRange.length, self.length-startRange.location-startRange.length);
        NSInteger endTags = 0;
        while((endTagRange = [self rangeOfString:endTag options:NSCaseInsensitiveSearch range:endTagScanRange]).location != NSNotFound)
        {
            endTagScanRange = NSMakeRange(endTagRange.location+endTagRange.length, self.length-endTagRange.location-endTagRange.length);
            NSRange startTagRange;
            NSRange startTagScanRange = NSMakeRange(startRange.location+startRange.length, endTagRange.location-startRange.location-startRange.length);
            NSInteger startTags = 0;
            while((startTagRange = [self rangeOfString:startTag options:NSCaseInsensitiveSearch range:startTagScanRange]).location != NSNotFound)
            {
                ++startTags;
                startTagScanRange = NSMakeRange(startTagRange.location+startTagRange.length, endTagRange.location-startTagRange.location-startTagRange.length);
                if(startTags > 10)
                {
                    return nil;
                }
            }
            if(startTags == endTags)
            {
                *endLocation = endTagRange.location;
                return [self substringWithDashRange:NSMakeRange(startRange.location+startRange.length, endTagRange.location-startRange.location-startRange.length)];
            }
            if(endTags > 10)
            {
                return nil;
            }
            ++endTags;
        }
    }
    return nil;
}

- (NSString *)stringByClearingCharactersFromSet:(NSCharacterSet *)charSet startingAtLocation:(NSInteger)location
{
    NSString *string = self;
    while(location < string.length)
    {
        if([[string substringWithRange:NSMakeRange(location, 1)] rangeOfCharacterFromSet:charSet].location == 0)
        {
            string = [string stringByReplacingCharactersInRange:NSMakeRange(location, 1) withString:@""];
        }
        else
        {
            return string;
        }
    }
    return string;
}

- (NSString *)substringToStringReturningNil:(NSString *)string
{
    NSRange range = [self rangeOfString:string];
    if(range.location != NSNotFound)
    {
        return [self substringToDashIndex:range.location];
    }
    return nil;
}

- (NSString *)substringFromStringReturningNil:(NSString *)string
{
    NSRange range = [self rangeOfString:string];
    if(range.location != NSNotFound)
    {
        return [self substringFromDashIndex:range.location+range.length];
    }
    return nil;
}

- (BOOL)contains:(NSString *)otherString
{
    return [self rangeOfString:otherString options:NSCaseInsensitiveSearch].location != NSNotFound;
}

- (NSArray *)allOccurrencesOfSubstringsBetweenString:(NSString *)from andString:(NSString *)to
{
    NSMutableArray *matches = [NSMutableArray array];
    NSString *string = self;
    while(1)
    {
        NSString *match = [string substringBetweenString:from andString:to options:NSLiteralSearch];
        if(match)
        {
            [matches addObject:match];
        }
        else
        {
            break;
        }
        string = [string substringFromStringReturningNil:[NSString stringWithFormat:@"%@%@%@", from, match, to]];
    }
    return matches;
}

- (NSString *)substringToString:(NSString *)string
{
    NSRange range = [self rangeOfString:string];
    if(range.location != NSNotFound)
    {
        return [self substringToDashIndex:range.location];
    }
    return self;
}

- (NSString *)stringByIntersectingWithString:(NSString *)otherString
{
    for(NSInteger i = otherString.length; i > 0; i--)
    {
        NSString *prefix = [otherString substringWithDashRange:NSMakeRange(0, i)];
        if([self hasSuffix:prefix])
        {
            return prefix;
        }
    }
    return @"";
}

- (NSString *)stringByFormingUnionWithString:(NSString *)otherString
{
    NSString *intersect = [self stringByIntersectingWithString:otherString];
    if(intersect.length)
    {
        return [[self substringToLastOccurrenceOfString:intersect] stringByAppendingString:otherString];
    }
    return [self stringByAppendingString:otherString];
}

+ (NSString *)stringWithContentsOfURLString:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    if(url)
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:90.0f];
        NSURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        if(data)
        {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            return string;
        }
    }
    return nil;
}

- (NSString *)substringToLastOccurrenceOfString:(NSString *)string
{
    NSRange range = [self rangeOfString:string options:NSBackwardsSearch];
    if(range.location != NSNotFound)
    {
        return [self substringToDashIndex:range.location];
    }
    return self;
}

- (NSString *)capitalizeFirstWord
{
    NSString *firstWord = [self substringToString:@" "];
    NSString *rest = [self substringFromStringReturningNil:@" "];
    return [[[firstWord capitalizedString] stringByAppendingString:(rest) ? @" " : @""] stringByAppendingString:(rest) ? rest : @""];
}

- (NSString *)substringFromLastOccurrenceOfString:(NSString *)string
{
    NSRange range = [self rangeOfString:string options:NSBackwardsSearch];
    if(range.location != NSNotFound)
    {
        return [self substringFromDashIndex:range.location+range.length];
    }
    return self;
}

- (NSString *)substringFromLastOccurrenceOfStringReturningNil:(NSString *)string
{
    NSRange range = [self rangeOfString:string options:NSBackwardsSearch];
    if(range.location != NSNotFound)
    {
        return [self substringFromDashIndex:range.location+range.length];
    }
    return nil;
}

- (NSString *)substringFromString:(NSString *)string
{
    NSRange range = [self rangeOfString:string];
    if(range.location != NSNotFound)
    {
        return [self substringFromDashIndex:range.location+range.length];
    }
    return self;
}

- (NSString *)httpDomain
{
    NSString *domain = [[self substringFromStringReturningNil:@"://"] substringToString:@"/"];
    return (domain) ? domain : self;
}

- (NSArray *)rangesOfString:(NSString *)aString
{
    NSMutableArray *ranges = [NSMutableArray array];
    NSRange range = [self rangeOfString:aString options:NSCaseInsensitiveSearch];
    while(range.location != NSNotFound)
    {
        [ranges addObject:[NSValue valueWithRange:range]];
        range = [self rangeOfString:aString options:NSCaseInsensitiveSearch range:NSMakeRange(range.location+range.length, self.length-range.location-range.length)];
    }
    return ranges;
}

- (NSString *)stringByDeletingCharactersInSet:(NSCharacterSet *)aSet removedRanges:(NSMutableArray *)removedRanges
{
    NSRange charRange = NSMakeRange(self.length, 0);
    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    while((charRange = [self rangeOfCharacterFromSet:aSet options:NSBackwardsSearch range:NSMakeRange(0, charRange.location)]).location != NSNotFound)
    {
        if(removedRanges)
        {
            [removedRanges addObject:[NSValue valueWithRange:charRange]];            
        }
        [mutableString replaceCharactersInRange:charRange withString:@""];
    }
    if(removedRanges && removedRanges.count > 0)
    {
        NSUInteger i = 0;
        NSUInteger j = [removedRanges count] - 1;
        while (i < j)
        {
            [removedRanges exchangeObjectAtIndex:i withObjectAtIndex:j];
            i++;
            j--;
        }
    }
    return mutableString;
}

- (NSString *)stringByDeletingCharactersInSet:(NSCharacterSet *)aSet
{
    return [self stringByDeletingCharactersInSet:aSet removedRanges:nil];
}

- (NSString *)stringByDeletingSymbols
{
    return [self stringByDeletingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
}

- (void)enumerateLettersUsingBlock:(void (^)(NSString *letter))block
{
    for(NSUInteger i = 0; i < self.length; i++)
    {
        NSString *letter = [self substringWithRange:NSMakeRange(i, 1)];
        block(letter);
    }
}

- (void)reverseEnumerateLettersUsingBlock:(void (^)(NSString *letter))block
{
    for(NSInteger i = self.length-1; i >= 0; i--)
    {
        NSString *letter = [self substringWithRange:NSMakeRange(i, 1)];
        block(letter);
    }
}

- (NSString *)firstChar
{
    return [self substringToDashIndex:1];
}

- (BOOL)isLowercase
{
    return [[self lowercaseString] isEqualToString:self];
}

- (BOOL)isUppercase
{
    return [[self uppercaseString] isEqualToString:self];
}

- (BOOL)firstCharIsUppercase
{
    NSString *firstChar = [self firstChar];
    return [[firstChar uppercaseString] isEqualToString:firstChar];
}

- (BOOL)firstCharIsLowercase
{
    NSString *firstChar = [self firstChar];
    return [[firstChar lowercaseString] isEqualToString:firstChar];
}

- (BOOL)isCaseInsensitiveEqual:(NSString *)object
{
    if(!object)
    {
        return NO;
    }
    return [self caseInsensitiveCompare:object] == NSOrderedSame;
}

- (NSString *)stringByMakingFirstCharUppercase
{
    if(!self.length)
    {
        return self;
    }
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[self substringToDashIndex:1] uppercaseString]];
}

- (NSString *)trimWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)trimNewline
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)removePrefixIfExists:(NSString *)aPrefix
{
    if([self hasPrefix:aPrefix])
    {
        return [self substringFromDashIndex:aPrefix.length];
    }
    return self;
}

- (NSString *)stringByReplacingPercentEscapes
{
    NSString *string = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(!string)
    {
        string = self;
        NSDictionary *percents = @{@"%21": @"!", @"%2A": @"*", @"%27": @"'", @"%28": @"(", @"%29": @")", @"%3B": @";", @"%3A": @":", @"%40": @"@", @"%26": @"&", @"%3D": @"=", @"%2B": @"+", @"%24": @"$", @"%2C": @",", @"%2F": @"/", @"%3F": @"?", @"%23": @"#", @"%5B": @"[", @"%5D": @"]", @"%20": @" ", @"%25": @"%", @"2D": @"-", @"%22": @"\"", @"%5C": @"\\"};
        for(NSString *key in [percents allKeys])
        {
            string = [string stringByReplacingOccurrencesOfString:key withString:percents[key]];
        }
    }
    return (string) ? string : self;
}

- (NSString *)stringByEscapingRegExSpecialCharacters
{
//    {}[]()^$.|*+?
    NSString *string = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    for(NSString *character in @[@"{", @"}", @"[", @"]", @"(", @")", @"^", @"$", @".", @"|", @"*", @"+", @"?"])
    {
        string = [string stringByReplacingOccurrencesOfString:character withString:[@"\\" stringByAppendingString:character]];
    }
    return string;
}

- (NSInteger)countOfCharactersInSet:(NSCharacterSet *)set
{
    NSInteger count = 0;
    NSInteger location = 0;
    NSRange range;
    while((range = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:NSMakeRange(location, self.length-location)]).location != NSNotFound)
    {
        location = range.location+1;
        ++count;
    }
    return count;
}

+ (NSString *)mimeTypeForPathExtension:(NSString *)pathExtension
{
    if(!pathExtension || !pathExtension.length)
    {
        return @"application/octet-stream";
    }
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return (__bridge_transfer NSString *)mimeType;
}

@end
