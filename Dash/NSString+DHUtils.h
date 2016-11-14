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

// Convenience NSString methods used throughout
@interface NSString (DHUtils) {
    
}

- (NSString *)stringByDeletingPathFragment;
- (NSString *)pathFragment;
- (NSString *)docsetPath;
- (NSString *)docsetPlatform;
- (NSString *)stringByDeletingPathToDocset;
- (NSString *)firstComponentSeparatedByWhitespace;
- (NSArray *)allOccurrencesOfSubstringsBetweenString:(NSString *)from andString:(NSString *)to;
- (float)distanceFromString:(NSString *)stringB;
- (float)distanceFromString:(NSString *)stringB withDummyLimit:(NSInteger)limit;
- (int)smallestOf:(int)a andOf:(int)b andOf:(int)c;
- (NSString *)tagFromTagQuery;
- (NSString *)characterBeforeSuffix:(NSString *)suffix;
- (BOOL)hasSameLastCharactersWithString:(NSString *)string charToCompare:(NSString *)character;
- (NSUInteger)countNewLines;
- (NSString *)FTSPrefix;
- (NSString *)allFTSSuffixes;
- (NSString *)stringByConvertingKapeliHttpURLToHttps;
- (NSString *)substringFromLastOccurrenceOfStringReturningNil:(NSString *)string;
- (NSString *)stringByConvertingKapeliHttpURLToHttpsReturningNil;
- (NSString *)stringByRemovingWhitespaces;
- (NSString *)stringByReplacingSpecialFTSCharacters;
- (NSString *)stringByBackwardsLimitingLinesTo:(NSUInteger)limit;
- (NSString *)stringByLimitingLinesTo:(NSUInteger)limit;
- (NSString *)lastPackageComponent:(NSString *)delimiter;
- (NSString *)lastTwoPackageComponents:(NSString *)delimiter;
- (NSString *)packageComponentsDependingOnPackage:(NSString *)package;
- (NSString *)stringByDeletingLastPackageComponent:(NSString *)delimiter;
+ (NSString *)commonPackageInStringArray:(NSArray *)strings delimiter:(NSString *)delimiter;
- (NSString *)shortenJavaMethod;
- (BOOL)hasCaseInsensitivePrefix:(NSString *)prefix;
- (BOOL)hasCaseInsensitiveSuffix:(NSString *)suffix;
- (BOOL)isPackageType;
- (BOOL)isClassType;
- (NSString *)stringByAddingWildcardsEverywhere:(NSString *)escapeChar;
- (NSString *)formatPlural:(NSInteger)count;
- (NSUInteger)lineStartForRange:(NSRange)diveInRange;
- (NSRange)rangeOfWhitespaceStringAtBeginningOfLineForRange:(NSRange)range substring:(NSString**)outString;
- (unichar*)copyOfCharactersInRange:(NSRange)range;
+ (void)dhEnumerateLinesOfCharacters:(const unichar*)characters ofLength:(NSUInteger)characterCount withBlock:(void(^)(NSRange lineRange))block;
- (NSRange)rangeOfWhitespaceStringAtBeginningOfLineForRange:(NSRange)range;
- (NSString *)substringFromDashIndex:(NSUInteger)from;
- (NSString *)substringToDashIndex:(NSUInteger)to;
- (NSString *)substringWithDashRange:(NSRange)range;
- (NSString *)substringBetweenString:(NSString *)start andString:(NSString *)end;
- (NSString *)substringBetweenString:(NSString *)start andString:(NSString *)end options:(NSStringCompareOptions)options;
- (NSString *)substringBetweenString:(NSString *)start andString:(NSString *)end startLocation:(NSInteger *)startLocation endLocation:(NSInteger *)endLocation options:(NSStringCompareOptions)options;
- (NSString *)substringBeginningAtString:(NSString *)start stoppingAtTag:(NSString *)tag startLocation:(NSInteger *)startLocation endLocation:(NSInteger *)endLocation;
+ (NSString *)stringWithContentsOfURLString:(NSString *)urlString;
- (NSString *)stringByClearingCharactersFromSet:(NSCharacterSet *)charSet startingAtLocation:(NSInteger)location;
- (NSString *)substringToStringReturningNil:(NSString *)string;
- (BOOL)contains:(NSString *)otherString;
- (NSString *)substringFromStringReturningNil:(NSString *)string;
- (NSString *)substringToString:(NSString *)string;
- (NSString *)substringToLastOccurrenceOfString:(NSString *)string;
- (NSString *)substringFromString:(NSString *)string;
- (NSString *)substringFromLastOccurrenceOfString:(NSString *)string;
- (NSString *)httpDomain;
- (NSString *)stringByRemovingSymbols;
- (NSString *)stringByRemovingCharactersInSet:(NSCharacterSet *)aSet;
- (NSArray *)rangesOfString:(NSString *)aString;
- (void)enumerateLettersUsingBlock:(void (^)(NSString *letter))block;
- (NSString *)stringByDeletingCharactersInSet:(NSCharacterSet *)aSet removedRanges:(NSMutableArray *)removedRanges;
- (NSString *)stringByDeletingCharactersInSet:(NSCharacterSet *)aSet;
- (NSString *)trimWhitespace;
+ (NSString *)stringByFormattingDownloadProgress:(long long)downloadedBytes totalBytes:(long long)totalBytes;
- (NSUInteger)countOccurrencesOfString:(NSString *)aString options:(NSStringCompareOptions)options;
- (NSString *)URLEncodedString_ch;
+ (NSString *)randomStringWithLength:(int)len;
- (NSString *)capitalizeFirstWord;
- (NSString *)removePrefixIfExists:(NSString *)aPrefix;
- (NSString *)stringByDeletingSymbols;
- (NSString *)stringByReplacingPercentEscapes;
- (BOOL)firstCharIsUppercase;
- (CGSize) attributedSizeWithFont:(UIFont*) font;
- (BOOL)firstCharIsLowercase;
- (NSString *)stringByFormingUnionWithString:(NSString *)otherString;
- (NSString *)stringByIntersectingWithString:(NSString *)otherString;
- (NSString *)firstChar;
- (NSString *)stringByEscapingRegExSpecialCharacters;
- (NSString *)stringByMakingFirstCharUppercase;
- (NSString *)trimNewline;
- (BOOL)isLowercase;
- (BOOL)isUppercase;
- (BOOL)isCaseInsensitiveEqual:(NSString *)object;
- (BOOL)containsAny:(NSArray *)strings;
+ (NSString *)mimeTypeForPathExtension:(NSString *)pathExtension;
- (NSInteger)countOfCharactersInSet:(NSCharacterSet *)set;

@end
