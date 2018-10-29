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

#import "DHDocset.h"

@implementation DHDocset

@synthesize _icon = _iconCache;
@synthesize _path = _pathCache;

static NSConditionLock *_stepLock = nil;

- (void)grabUserDataFromDocset:(DHDocset *)docset
{
    self.isEnabled = docset.isEnabled;
}

+ (DHDocset *)docsetWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    DHDocset *docset = [[DHDocset alloc] init];
    docset.relativePath = dictionary[@"relativePath"];
    docset.name = dictionary[@"name"];
    docset.bundleIdentifier = dictionary[@"bundleIdentifier"];
    docset.platform = dictionary[@"platform"];
    docset.parseFamily = dictionary[@"parseFamily"];
    docset.nameShorteningFamily = dictionary[@"nameShorteningFamily"];
    docset.declaredInStyle = dictionary[@"declaredInStyle"];
    docset.isJavaScriptEnabled = [dictionary[@"isJavaScriptEnabled"] boolValue];
    docset.isEnabled = [dictionary[@"isEnabled"] boolValue];
    docset.blocksOnlineResources = [dictionary[@"blocksOnlineResources"] boolValue];
    docset.isDashDocset = [dictionary[@"isDashDocset"] boolValue];
    docset._indexFilePath = dictionary[@"indexFilePath"];
    docset.pluginKeyword = dictionary[@"pluginKeyword"];
    docset.suggestedKeyword = dictionary[@"suggestedKeyword"];
    docset.version = dictionary[@"version"];
    docset.hasCustomIcon = dictionary[@"hasCustomIcon"];
    docset.feedIdentifier = dictionary[@"feedIdentifier"];
    docset.repoIdentifier = dictionary[@"repoIdentifier"];
    return docset;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if(self.relativePath) { dictionary[@"relativePath"] = self.relativePath; }
    if(self.name) { dictionary[@"name"] = self.name; }
    if(self.bundleIdentifier) { dictionary[@"bundleIdentifier"] = self.bundleIdentifier; }
    if(self.platform) { dictionary[@"platform"] = self.platform; }
    if(self.parseFamily) { dictionary[@"parseFamily"] = self.parseFamily; }
    if(self.nameShorteningFamily) { dictionary[@"nameShorteningFamily"] = self.nameShorteningFamily; }
    if(self.declaredInStyle) { dictionary[@"declaredInStyle"] = self.declaredInStyle; }
    dictionary[@"isJavaScriptEnabled"] = @(self.isJavaScriptEnabled);
    dictionary[@"blocksOnlineResources"] = @(self.blocksOnlineResources);
    dictionary[@"isDashDocset"] = @(self.isDashDocset);
    dictionary[@"isEnabled"] = @(self.isEnabled);
    if(self._indexFilePath) { dictionary[@"indexFilePath"] = self._indexFilePath; }
    if(self.pluginKeyword) { dictionary[@"pluginKeyword"] = self.pluginKeyword; }
    if(self.suggestedKeyword) { dictionary[@"suggestedKeyword"] = self.suggestedKeyword; }
    if(self.version) { dictionary[@"version"] = self.version; }
    if(self.hasCustomIcon) { dictionary[@"hasCustomIcon"] = self.hasCustomIcon; }
    if(self.feedIdentifier) { dictionary[@"feedIdentifier"] = self.feedIdentifier; }
    if(self.repoIdentifier) { dictionary[@"repoIdentifier"] = self.repoIdentifier; }
    return dictionary;
}

- (NSDictionary *)plist
{
    return [NSDictionary dictionaryWithContentsOfFile:[self.path stringByAppendingPathComponent:@"Contents/Info.plist"]];
}

+ (DHDocset *)docsetAtPath:(NSString *)path
{
    DHDocset *docset = [[DHDocset alloc] init];
    docset.relativePath = [path substringFromString:[homePath stringByDeletingLastPathComponent]];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"Contents/Info.plist"]];
    if(!plist)
    {
        return nil;
    }
    NSString *bundle = plist[@"CFBundleIdentifier"];
    if(!bundle)
    {
        bundle = @"";
    }
    docset.bundleIdentifier = bundle;
    NSString *platform = plist[@"DocSetPlatformFamily"];
    if([platform isEqualToString:@"macosx"])
    {
        platform = @"osx";
    }
    else if([platform isEqualToString:@"iphoneos"])
    {
        platform = @"ios";
    }
    else if([platform isEqualToString:@"appletvos"])
    {
        platform = @"tvos";
    }
    docset.platform = platform ? platform : @"unknown";
    NSString *parseFamily = plist[@"DashDocSetFamily"];
    if(parseFamily)
    {
        docset.parseFamily = parseFamily;
    }
    NSString *nameShorteningFamily = plist[@"DashDocSetNameShorteningFamily"];
    if(nameShorteningFamily)
    {
        docset.nameShorteningFamily = nameShorteningFamily;
    }
    NSString *declaredInStyle = plist[@"DashDocSetDeclaredInStyle"];
    if(declaredInStyle)
    {
        docset.declaredInStyle = declaredInStyle;
    }
    NSNumber *isJavaScriptEnabled = plist[@"isJavaScriptEnabled"];
    BOOL isPlatformJavaScriptEnabled = [platform isEqualToString:@"doxy"] || [parseFamily isEqualToString:@"doxy"] || [platform isEqualToString:@"doxygen"] || [parseFamily isEqualToString:@"doxygen"];
    BOOL isJSEnabled = [isJavaScriptEnabled boolValue] || isPlatformJavaScriptEnabled;
    docset.isJavaScriptEnabled = isJSEnabled;
    NSNumber *blocksOnlineResources = plist[@"DashDocSetBlocksOnlineResources"];
    if(blocksOnlineResources)
    {
        docset.blocksOnlineResources = [blocksOnlineResources boolValue];
    }
    NSString *indexFilePath = plist[@"dashIndexFilePath"];
    if(indexFilePath.length)
    {
        docset._indexFilePath = indexFilePath;
    }
    NSString *pluginKeyword = plist[@"DashDocSetPluginKeyword"];
    if(pluginKeyword)
    {
        docset.pluginKeyword = pluginKeyword;
    }
    NSString *suggestedKeyword = plist[@"DashDocSetKeyword"];
    if(suggestedKeyword)
    {
        docset.suggestedKeyword = suggestedKeyword;
    }
    NSString *versionString = plist[@"DocSetPlatformVersion"];
    versionString = (versionString) ? versionString : plist[@"CFBundleVersion"];
    if(versionString)
    {
        NSNumber *version = @([versionString doubleValue]);
        if(version)
        {
            docset.version = version;
        }
        else
        {
            docset.version = @1.0f;
        }
    }
    else
    {
        docset.version = @1.0f;
    }
    NSString *name = plist[@"CFBundleName"];
    name = (name == nil) ? @"Unknown" : name;
    if([name hasSuffix:@" doc set"])
    {
        name = [name substringToLastOccurrenceOfString:@" doc set"];
    }
    else if([name hasSuffix:@" Documentation"])
    {
        name = [name substringToLastOccurrenceOfString:@" Documentation"];
    }
    if([platform isEqualToString:@"ios"] || [platform isEqualToString:@"osx"] || [platform isEqualToString:@"watchos"] || [platform isEqualToString:@"tvos"])
    {
        if([name hasCaseInsensitiveSuffix:@" library"])
        {
            name = [name substringToLastOccurrenceOfString:@" library"];
            name = [name substringToLastOccurrenceOfString:@" Library"];
        }
        name = [name stringByReplacingOccurrencesOfString:@"OS X v" withString:@"OS X "];
    }
    if([bundle isEqualToString:@"com.apple.adc.documentation"])
    {
        name = @"Apple Guides and Sample Code";
        docset.suggestedKeyword = @"apple";
    }
    docset.name = name;
    NSNumber *isDashNumber = plist[@"isDashDocset"];
    BOOL isDash = (isDashNumber) ? [isDashNumber boolValue] : NO;
    docset.isDashDocset = isDash;
    docset.isEnabled = YES;
    return docset;
}

+ (DHDocset *)firstDocsetInsideFolder:(NSString *)path
{
    if([[path pathExtension] isCaseInsensitiveEqual:@"docset"])
    {
        return [DHDocset docsetAtPath:path];
    }
    NSString *docset = [[NSFileManager defaultManager] firstFileWithExtension:@"docset" atPath:path ignoreHidden:YES];
    if(docset)
    {
        return [DHDocset docsetAtPath:[path stringByAppendingPathComponent:docset]];
    }
    return nil;
}

+ (void)initLock
{
    @synchronized([DHDocset class])
	{
		if(!_stepLock)
		{
			_stepLock = [[NSConditionLock alloc] initWithCondition:3];
		}
	}
}

+ (NSConditionLock *)stepLock
{
    if(!_stepLock)
    {
        [DHDocset initLock];
    }
    return _stepLock;
}

- (void)executeBlockWithinDocsetDBConnection:(void (^)(FMDatabase *db))block readOnly:(BOOL)readOnly lockCondition:(int)lockCondition optimisedIndex:(BOOL)optimisedIndex
{
    NSString *docsetSQLPath = (optimisedIndex) ? (self.tempOptimisedIndexPath) ? self.tempOptimisedIndexPath : self.optimisedIndexPath : self.sqlPath;
    if(!docsetSQLPath)
    {
        return;
    }
    NSConditionLock *lock = (lockCondition != DHLockDontLock) ? [DHDocset stepLock] : nil;
    [lock lockWhenCondition:lockCondition];
    FMDatabase *db = [FMDatabase databaseWithPath:docsetSQLPath];
    if((readOnly) ? [db openWithFlags:SQLITE_OPEN_READONLY] : [db open])
    {
        if(optimisedIndex)
        {
            [db registerFTSExtensions];
        }
        [lock unlockWithCondition:lockCondition];
        @try {
            block(db);
        }
        @catch (NSException *exception) {
            if([[exception name] isEqualToString:@"Indexing Interrupt"])
            {
                [NSException raise:@"Indexing Interrupt" format:@""];
            }
            else
            {
                NSLog(@"FIXME: Exception in executeBlockWithinDocsetDB: %@", exception);
                NSLog(@"%@", [NSThread callStackSymbols]);
            }
        }
        @finally {
            [lock lockWhenCondition:lockCondition];
            [db close];
            [lock unlockWithCondition:DHLockAllAllowed];
        }
    }
    else
    {
        [lock unlockWithCondition:DHLockAllAllowed];
    }
}

- (UIImage *)icon
{
    return (self._icon) ? : [self grabIcon];
}

- (UIImage *)grabIcon
{
    UIImage *icon = nil;
    if(!self.hasCustomIcon || [self.hasCustomIcon boolValue])
    {
        NSString *iconPath = [self.path stringByAppendingPathComponent:@"icon.png"];
        icon = [DHImageCache imageWithContentsOfFile:iconPath fullRefresh:!self.hasCustomIcon];
        if(!icon)
        {
            iconPath = [self.path stringByAppendingPathComponent:@"icon.tiff"];
            icon = [DHImageCache imageWithContentsOfFile:iconPath fullRefresh:!self.hasCustomIcon];
        }
        self.hasCustomIcon = [NSNumber numberWithBool:icon != nil];
    }
    if([self.bundleIdentifier isEqualToString:@"com.apple.adc.documentation"])
    {
        icon = [UIImage imageNamed:@"apple"];
    }
    if(!icon)
    {
        NSString *platform = (self.platform) ? self.platform : @"Other";
        if(self.parseFamily && [self.parseFamily isEqualToString:@"cheatsheet"])
        {
            platform = @"cheatsheet";
        }
        if([platform isEqualToString:@"macosx"] || [platform isEqualToString:@"osx"])
        {
            icon = [UIImage imageNamed:@"Mac"];
        }
        else if([platform isEqualToString:@"iphoneos"] || [platform isEqualToString:@"ios"])
        {
            icon = [UIImage imageNamed:@"iphone"];
        }
        else
        {
            icon = [UIImage imageNamed:platform];
            if(!icon)
            {
                icon = [UIImage imageNamed:@"Other"];
            }
        }
    }
    self._icon = icon;
    return icon;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Docset with name: %@, platform: %@, isDashDocset: %d", self.name, self.platform, self.isDashDocset];
}

- (NSString *)contentsPath
{
    return [self.path stringByAppendingPathComponent:@"Contents"];
}

- (NSString *)resourcesPath
{
    return [self.path stringByAppendingPathComponent:@"Contents/Resources"];
}

- (NSString *)documentsPath
{
    return [self.path stringByAppendingPathComponent:@"Contents/Resources/Documents"];
}

- (NSString *)tarixPath
{
    return [self.path stringByAppendingPathComponent:@"Contents/Resources/tarix.tgz"];
}

- (NSString *)tarixIndexPath
{
    return [self.path stringByAppendingPathComponent:@"Contents/Resources/tarixIndex.db"];
}

- (BOOL)isEqual:(DHDocset *)object
{
    return [self.path isCaseInsensitiveEqual:[object path]];
}

- (NSString *)path
{
    if(!self._path)
    {
        self._path = [[homePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:self.relativePath];
    }
    return self._path;
}

- (NSString *)sqlPath
{
    return [self.path stringByAppendingPathComponent:@"Contents/Resources/docSet.dsidx"];
}

- (NSString *)optimisedIndexPath
{
    return [self.path stringByAppendingPathComponent:@"Contents/Resources/optimisedIndex.dsidx"];
}

- (NSString *)indexFilePath
{
    NSString *indexFile = self._indexFilePath;
    NSString *docsetPath = self.documentsPath;
    NSString *platform = self.platform;
    NSString *parseFamily = self.parseFamily;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(indexFile)
    {
        if(indexFile.length > 0)
        {
            if([indexFile hasPrefix:@"http://"] || [indexFile hasPrefix:@"https://"] || [indexFile hasPrefix:@"dash-apple-api://"])
            {
                return indexFile;
            }
            if([platform isEqualToString:@"apple"] && [DHAppleActiveLanguage currentLanguage] == DHNewActiveAppleLanguageObjC)
            {
                indexFile = [indexFile stringByReplacingOccurrencesOfString:@".html" withString:@"1742.html"];
            }
            NSString *fullPath = [docsetPath stringByAppendingPathComponent:[indexFile substringToString:@"#"]];
            if([fileManager fileExistsAtPathOrInIndex:fullPath])
            {
                if([indexFile contains:@"#"])
                {
                    fullPath = [fullPath stringByAppendingFormat:@"#%@", [indexFile substringFromString:@"#"]];
                }
                return fullPath;
            }
        }
    }
    NSMutableArray *pathsToTry = [NSMutableArray arrayWithObjects:@"dash-browse-index.html", @"prototypejs/index.html", @"sqlite/index.html", @"documentation/Cocoa/Reference/Foundation/ObjC_classic/_index.html", @"documentation/ToolsLanguages/Conceptual/Xcode_User_Guide/000-About_Xcode/about.html", @"documentation/IDEs/Conceptual/xcode_quick_start/index.html", @"package-detail.html", @"docs/reference/packages.html", @"Arduino/index.html", @"output/en.cppreference.com/w/cpp.html", @"output/en/cpp.html", @"clojure/api-index.html", @"developer.anscamobile.com/reference/index.html", @"docs.coronalabs.com/api/index.html", @"developer.mozilla.org/en/CSS/CSS_Reference.html",  @"developer.mozilla.org/en-US/docs/CSS/CSS_Reference.html", @"api/overview-summary.html", @"haskell/index.html", @"developer.mozilla.org/en/HTML/HTML5.html", @"developer.mozilla.org/en/JavaScript/Reference.html", @"developer.mozilla.org/en/JavaScript/Reference.html", @"www.lua.org/manual/5.2/index.html", @"www.lua.org/manual/5.1/index.html", @"www.lua.org/manual/5.3/index.html", @"nodejs/api/documentation.html", @"nodejs/api/api/documentation.html", @"perldoc-html/index-functions-by-cat.html", @"res/index.html", @"genindex-all.html", @"topics/introduction.html", @"introduction.html", @"api.rubyonrails.org/files/RDOC_MAIN_rdoc.html", @"scala/package.html", @"akka/package.html", @"docs/welcome.html", @"developer.mozilla.org/en/XSLT/Elements.html", @"developer.mozilla.org/en/XUL_Reference.html", @"genindex.html", @"html/classes.html", @"html/qtdoc/classes.html", @"api.jquery.com/index.html", @"helphelp.html", @"partials/guide/index.html", @"elisp/index.html", @"docs/right-pane.html", @"doc/man_index.html", @"docs.go-mono.com/monoroot.html", @"api/index.html", @"mongo/genindex.html", @"HyperSpec/HyperSpec/Front/index.htm", @"api.jqueryui.com/category/all/index.html", @"golang.org/ref/index.html", @"documentation/ToolsLanguages/Conceptual/Xcode_Overview/About_Xcode/about.html", @"documentation/Cocoa/Reference/Foundation/ObjC_classic/index.html", @"documentation/ToolsLanguages/Conceptual/Xcode_Overview/index.html", nil];
    if([platform isEqualToString:@"c"])
    {
        [pathsToTry removeObject:@"output/en/cpp.html"];
        [pathsToTry removeObject:@"output/en.cppreference.com/w/cpp.html"];
        [pathsToTry addObject:@"output/en/c.html"];
        [pathsToTry addObject:@"output/en.cppreference.com/w/c.html"];
    }
    NSArray *firstIndexPlatforms = @[@"cappuccino", @"cocos2dx", @"underscore", @"backbone", @"coffee", @"appledoc", @"doxy", @"doxygen", @"gl2", @"gl3", @"gl4", @"sparrow", @"cocos2d", @"codeigniter", @"django", @"joomla", @"symfony", @"kobold2d", @"mysql", @"psql", @"typo3", @"twisted", @"zend", @"glib"];
    if([firstIndexPlatforms containsObject:platform] || (parseFamily && [firstIndexPlatforms containsObject:parseFamily]))
    {
        [pathsToTry insertObject:@"index.html" atIndex:0];
    }
    for(NSString *path in pathsToTry)
    {
        NSString *dashIndexPath = [docsetPath stringByAppendingPathComponent:path];
        if([fileManager fileExistsAtPathOrInIndex:dashIndexPath])
        {
            self._indexFilePath = path;
            return dashIndexPath;
        }
    }
    self._indexFilePath = @"";
    return [[NSBundle mainBundle] pathForResource:@"home" ofType:@"html"];
}

@end
