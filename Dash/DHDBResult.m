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

#import "DHDBResult.h"
#import "DHAppDelegate.h"
#import "DHCSS.h"

@implementation DHDBResult

static NSSet *commonDeclaredInStylePlatforms;
static NSDictionary *highlightDictionary;

+ (DHDBResult *)resultWithDocset:(DHDocset *)docset resultSet:(FMResultSet *)rs
{
    return [[DHDBResult alloc] initWithDocset:docset resultSet:rs];
}

- (id)initWithDocset:(DHDocset *)docset resultSet:(FMResultSet *)rs
{
    self = [super init];
    if(self)
    {
        self.docset = docset;
        self.platform = self.docset.platform;
        self.isSO = [self.platform isEqualToString:@"soonline"] || [self.platform isEqualToString:@"sooffline"];
        self.path = [rs stringForColumnIndex:0];
        if(!self.path.length)
        {
            return nil;
        }
        NSRange anchorRange = [self.path rangeOfString:@"#"];
        if(anchorRange.location != NSNotFound && anchorRange.location+1 < self.path.length)
        {
            self.anchor = [self.path substringFromDashIndex:anchorRange.location+1];
            self.path = [self.path substringToDashIndex:anchorRange.location];
        }
        
        if([self.platform isEqualToString:@"apple"])
        {
            NSInteger activeLanguage = [DHAppleActiveLanguage currentLanguage];
            if([self.anchor contains:@"<dash_entry_language=objc>"] || [self.anchor contains:@"<dash_entry_language=occ>"])
            {
                if(activeLanguage == DHNewActiveAppleLanguageSwift)
                {
                    return nil;
                }
                self.appleLanguage = DHNewActiveAppleLanguageObjC;
                self.anchor = [self.anchor stringByReplacingOccurrencesOfString:@"<dash_entry_language=objc>" withString:@""];
                self.anchor = [self.anchor stringByReplacingOccurrencesOfString:@"<dash_entry_language=occ>" withString:@""];
            }
            else if([self.anchor contains:@"<dash_entry_language=swift>"])
            {
                if(activeLanguage == DHNewActiveAppleLanguageObjC)
                {
                    return nil;
                }
                self.appleLanguage = DHNewActiveAppleLanguageSwift;
                self.anchor = [self.anchor stringByReplacingOccurrencesOfString:@"<dash_entry_language=swift>" withString:@""];
            }
        }
        BOOL isOSX = ([self.platform isEqualToString:@"macosx"] || [self.platform isEqualToString:@"osx"]);
        if(self.anchor && isOSX && [self.anchor rangeOfString:@"java" options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            return nil;
        }
        
        self.type = [rs stringForColumnIndex:2];
        if(!self.type.length)
        {
            return nil;
        }
        
        self.isApple = (isOSX || [[self platform] isEqualToString:@"ios"] || [[self platform] isEqualToString:@"iphoneos"] || [self.platform isEqualToString:@"watchos"] || [self.platform isEqualToString:@"tvos"]);
        if(self.isApple)
        {
            if([self.anchor hasSuffix:@"-dash-swift-hack"])
            {
                self.linkIsSwift = YES;
                self.anchor = [self.anchor substringToIndex:self.anchor.length-16];
            }
            self.linkIsSwift = self.linkIsSwift || [self.anchor contains:@"apple_ref/swift/"];
            int active = [DHCSS activeAppleLanguage];
            if(active == DHActiveAppleLanguageObjC && ![docset.name contains:@"Xcode"])
            {
                if(self.linkIsSwift)
                {
                    return nil;
                }
            }
            else if(active == DHActiveAppleLanguageSwift)
            {
                BOOL isObjC = [self.anchor contains:@"apple_ref/occ"];
                if(isObjC)
                {
                    return nil;
                }
            }
        }
        
        BOOL isOnlineGuide = NO;
        if([self.type isEqualToString:@"Guide"] || [self.type isEqualToString:@"Sample"])
        {
            if([self.path hasPrefix:@"gfile://"])
            {
                self.isAGuide = YES;
                self.path = [self.path substringFromDashIndex:8];
                self.fullPath = self.path;
                self.relativePath = self.path;
            }
            else if([self.path hasPrefix:@"ghttp://"] || [self.path hasPrefix:@"ghttps://"])
            {
                self.isAGuide = YES;
                isOnlineGuide = YES;
                self.path = [self.path substringFromDashIndex:8];
                self.fullPath = self.path;
                self.relativePath = self.path;
            }
        }
        
        if(!isOnlineGuide)
        {
            if([self.path hasPrefix:@"http://"] || [self.path hasPrefix:@"https://"] || self.isSO || [self.path hasPrefix:@"dash-apple-api://"])
            {
                self.isHTTP = YES;
                self.fullPath = self.path;
                if([self.platform isEqualToString:@"sooffline"])
                {
                    self.fullPath = [self.fullPath stringByAppendingFormat:@"?dbPath=%@", [self.docset.sqlPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }
            }
            else
            {
                self.fullPath = [@"file://" stringByAppendingString:[[self.docset.path stringByAppendingPathComponent:@"Contents/Resources/Documents"] stringByAppendingPathComponent:self.path]];
            }
            self.fullPath = (self.anchor) ? [self.fullPath stringByAppendingFormat:@"#%@", self.anchor] : self.fullPath;
            self.relativePath = (self.anchor) ? [self.path stringByAppendingFormat:@"#%@", self.anchor] : self.path;
        }
        self.name = [rs stringForColumnIndex:1];
        if(!self.name.length)
        {
            return nil;
        }
        self.originalName = self.name;
        self.similarResults = [NSMutableArray array];
        [self prepareName];
    }
    return self;
}

- (void)prepareName
{
    if(self.isSO)
    {
        if([self.anchor hasPrefix:@"dash-score-"])
        {
            self.score = [[self.anchor substringFromIndex:11] integerValue];
        }
    }
    if(self.isApple)
    {
        self.isApple = YES;
    }
    if([self.platform isEqualToString:@"unity3d"])
    {
        self.name = [self.name stringByReplacingOccurrencesOfString:@"%47" withString:@"/"];
        self.originalName = [self.originalName stringByReplacingOccurrencesOfString:@"%47" withString:@"/"];
    }
    if([self.platform isEqualToString:@"go"] || [self.platform isEqualToString:@"godoc"])
    {
        self.isGo = YES;
    }
    
    NSString *shorteningFamily = self.docset.nameShorteningFamily;
    NSString *parseFamily = (shorteningFamily) ? shorteningFamily : self.docset.parseFamily;
    parseFamily = (parseFamily && parseFamily.length) ? parseFamily : self.platform;
    if(([parseFamily isEqualToString:@"python"] || [parseFamily isEqualToString:@"flask"] || [parseFamily isEqualToString:@"scipy"] || [parseFamily isEqualToString:@"numpy"] || [parseFamily isEqualToString:@"pandas"] || [parseFamily isEqualToString:@"sqlalchemy"] || [parseFamily isEqualToString:@"tornado"] || [parseFamily isEqualToString:@"matplotlib"] || [parseFamily isEqualToString:@"salt"] || [parseFamily isEqualToString:@"jinja"] || ([self.platform isEqualToString:@"ocaml"] && ([self.type isEqualToString:@"Type"] || [self.type isEqualToString:@"Value"])) || [parseFamily isEqualToString:@"mono"] || [parseFamily isEqualToString:@"xamarin"] || [parseFamily isEqualToString:@"sencha"] || [parseFamily isEqualToString:@"extjs"] || [parseFamily isEqualToString:@"titanium"] || [parseFamily isEqualToString:@"twisted"] || [parseFamily isEqualToString:@"unity3d"] || [parseFamily isEqualToString:@"django"] || ([parseFamily isEqualToString:@"javascript"] && ![self.type isEqualToString:@"Function"] && ![self.type isEqualToString:@"Keyword"]) || [parseFamily isEqualToString:@"actionscript"] || [parseFamily isEqualToString:@"yui"] || [parseFamily isEqualToString:@"vsphere"] || ([self.platform isEqualToString:@"SproutCore"] && ![self.type isClassType] && ![self.type isEqualToString:@"Protocol"] && ![self.type isEqualToString:@"Delegate"])) && ![self.type isPackageType])
    {
        self.name = [self.name lastPackageComponent:@"."];
    }
    else if([parseFamily isEqualToString:@"apple"])
    {
        self.name = [self.name substringFromLastOccurrenceOfString:@"."];
    }
    else if([parseFamily isEqualToString:@"jQuery"] || [parseFamily isEqualToString:@"jqueryui"])
    {
        if([self.name hasPrefix:@"."])
        {
            self.name = [self.name substringFromDashIndex:1];
        }
        else if([self.name hasPrefix:@":"])
        {
            self.name = [self.name substringFromDashIndex:1];
        }
        else if([self.name hasCaseInsensitivePrefix:@"jQuery."])
        {
            self.name = [self.name substringFromDashIndex:@"jQuery.".length];
        }
    }
    else if([self.platform isEqualToString:@"net"] && ![@[@"Class", @"Delegate", @"Interface", @"Namespace", @"Constructor", @"Enum", @"Struct", @"Conversion"] containsObject:self.type])
    {
        self.name = [self.name substringFromString:@"."];
    }
    else if([self.platform isEqualToString:@"matlab"])
    {
        if([self.type isEqualToString:@"Class"])
        {
            self.name = [self.name lastPackageComponent:@"."];
        }
    }
    else if([self.platform isEqualToString:@"handlebars"])
    {
        if([self.type isEqualToString:@"Method"])
        {
            self.name = [self.name substringFromLastOccurrenceOfString:@"."];
        }
    }
    else if([parseFamily isEqualToString:@"lodash"])
    {
        if([self.name hasPrefix:@"_."])
        {
            self.name = [self.name substringFromIndex:2];
        }
    }
    else if([parseFamily isEqualToString:@"jquerym"])
    {
        if([self.name hasCaseInsensitivePrefix:@"jQuery.mobile."])
        {
            self.name = [self.name substringFromDashIndex:@"jQuery.mobile.".length];
        }
    }
    else if([parseFamily isCaseInsensitiveEqual:@"smarty"])
    {
        self.name = [self.name substringFromString:@"->"];
    }
    else if(([parseFamily isEqualToString:@"scala"] || [parseFamily isEqualToString:@"scaladoc"] || [parseFamily isEqualToString:@"playscala"] || [parseFamily isEqualToString:@"akka"]) && ![self.type isPackageType])
    {
        self.name = [self.name lastPackageComponent:@"."];
    }
    else if([parseFamily isEqualToString:@"ember"] && ![self.type isPackageType] && ![self.type isClassType] && ![self.type isEqualToString:@"Guide"])
    {
        self.name = [self.name lastPackageComponent:@"."];
    }
    else if([self.platform isEqualToString:@"erlang"] || [parseFamily isEqualToString:@"erlang_shortening"])
    {
        self.name = [self.name lastPackageComponent:@":"];
        NSInteger location = [self.name rangeOfString:@"/"].location;
        if(location != NSNotFound && location != 0)
        {
            self.name = [self.name substringToDashIndex:location];
        }
    }
    else if([self.platform isEqualToString:@"elixir"] || [self.platform isEqualToString:@"hex"] || [parseFamily isEqualToString:@"elixir_shortening"])
    {
        if(![@[@"Exception", @"Protocol", @"Module"] containsObject:self.type] && ![self.type isPackageType] && ![self.type isClassType] && ![self.type isEqualToString:@"Guide"])
        {
            self.name = [self.name lastPackageComponent:@"."];
            self.name = [self.name substringToLastOccurrenceOfString:@"/"];
        }
    }
    else if(([self.platform isEqualToString:@"dartlang"] || [parseFamily isEqualToString:@"dartlang"] || [self.platform isEqualToString:@"polymerdart"] || [self.platform isEqualToString:@"angulardart"]) && ![self.type isPackageType])
    {
        if([self.type isEqualToString:@"Constructor"])
        {
            if([[self.name substringFromLastOccurrenceOfString:@"."] firstCharIsLowercase])
            {
                self.name = [self.name lastTwoPackageComponents:@"."];
            }
            else
            {
                self.name = [self.name substringFromLastOccurrenceOfString:@"."];
            }
        }
        else
        {
            self.name = [self.name substringFromLastOccurrenceOfString:@"."];
        }
    }
    else if((([parseFamily isEqualToString:@"go"] || [self.platform isEqualToString:@"godoc"]) && ![self.type isEqualToString:@"Package"]) || ([self.platform isEqualToString:@"zepto"] && ![self.type isEqualToString:@"Module"]))
    {
        self.name = [self.name substringFromString:@"."];
    }
    else if(([parseFamily isEqualToString:@"compass"] && ![self.type isEqualToString:@"Module"]) || [parseFamily isEqualToString:@"dojo"])
    {
        self.name = [self.name lastPackageComponent:@"/"];
    }
    else if([self.platform isEqualToString:@"ee"])
    {
        self.name = [self.name substringFromString:@"::"];
    }
    else if([parseFamily isEqualToString:@"cappuccino"] || [self.platform isEqualToString:@"cvcpp"] || [self.platform isEqualToString:@"drupal"] || [self.platform isEqualToString:@"zend"] || [self.platform isEqualToString:@"cocos2dx"] || [self.platform isEqualToString:@"doxy"] || [self.platform isEqualToString:@"doxygen"] || [parseFamily isEqualToString:@"doxy"] || [parseFamily isEqualToString:@"doxygen"])
    {
        self.name = [self.name lastPackageComponent:@"::"];
    }
    else if([self.platform isEqualToString:@"php"])
    {
        self.name = [self.name lastPackageComponent:@"::"];
        self.isPHP = YES;
    }
    else if([self.platform isEqualToString:@"rust"])
    {
        if(![self.type isEqualToString:@"Module"])
        {
            self.name = [self.name lastPackageComponent:@"::"];
        }
        self.isRust = YES;
    }
    else if([self.platform isEqualToString:@"swift"])
    {
        if([@[@"Method", @"Variable", @"Constant", @"Alias"] containsObject:self.type])
        {
            self.name = [self.name substringFromString:@"."];
        }
        self.isSwift = YES;
    }
    else if([self.platform isEqualToString:@"wordpress"] && [self.type isEqualToString:@"Method"]&& [self.name contains:@"::"])
    {
        self.name = [self.name substringFromLastOccurrenceOfString:@"::"];
    }
    else if([parseFamily isEqualToString:@"prototype"] && [self.type isEqualToString:@"Constructor"] && [self.name hasCaseInsensitivePrefix:@"new "])
    {
        self.name = [self.name substringFromDashIndex:4];
    }
    else if([parseFamily isEqualToString:@"cpp"] || [parseFamily isEqualToString:@"cocos2dx"])
    {
        self.name = [[self.name lastPackageComponent:@"::"] stringByUnescapingFromHTML];
        self.originalName = [self.originalName stringByUnescapingFromHTML];
    }
    else if([self.platform isEqualToString:@"awsjs"])
    {
        if(![@[@"Guide", @"Section", @"Sample"] containsObject:self.type])
        {
            if(![self.type isPackageType] && ![self.type isClassType])
            {
                self.name = [self.name substringFromString:@"."];
            }
        }
    }
    else if([parseFamily isEqualToString:@"ruby"] || [parseFamily isEqualToString:@"rubyGems"] || [parseFamily isEqualToString:@"rails"])
    {
        if([parseFamily isEqualToString:@"rails"])
        {
            self.name = [self.name stringByUnescapingFromHTML];
            self.originalName = [self.originalName stringByUnescapingFromHTML];
        }
        if(![@[@"Guide", @"Section", @"Sample"] containsObject:self.type])
        {
            if([self.name contains:@"::"])
            {
                self.name = [self.name lastPackageComponent:@"::"];
            }
            if(![self.type isPackageType] && ![self.type isClassType])
            {
                if([self.name contains:@"#"])
                {
                    self.name = [self.name substringFromString:@"#"];
                }
                else
                {
                    self.name = [self.name substringFromString:@"."];
                }
            }
        }
    }
    else if([self.platform isEqualToString:@"laravel"] || [self.platform isEqualToString:@"phpp"] || [parseFamily isEqualToString:@"phpShortening"] || [self.platform isEqualToString:@"joomla"] || [self.platform isEqualToString:@"symfony"] || [self.platform isEqualToString:@"cakephp"] || [self.platform isEqualToString:@"typo3"])
    {
        if(![self.type isPackageType] && ![self.type isEqualToString:@"Function"])
        {
            self.name = [self.name lastPackageComponent:@"\\"];
            self.name = [self.name lastPackageComponent:@"::"];
        }
    }
    else if(([parseFamily isEqualToString:@"yard"] || [parseFamily isEqualToString:@"qt"] || [parseFamily isEqualToString:@"yii"]) && [self.name rangeOfString:@"::"].location != NSNotFound)
    {
        self.name = [self.name lastPackageComponent:@"::"];
    }
    else if([parseFamily isEqualToString:@"manPages"])
    {
        NSInteger loc = [self.name rangeOfString:@"(" options:NSBackwardsSearch].location;
        if(loc != NSNotFound)
        {
            self.name = [self.name substringToDashIndex:loc];
        }
    }
    else if([parseFamily isEqualToString:@"java"] || [parseFamily isEqualToString:@"playjava"] || [parseFamily isEqualToString:@"javafx"] || [parseFamily isEqualToString:@"groovy"])
    {
        self.name = [self.name stringByUnescapingFromHTML];
        self.originalName = self.name;
    }
    
    if([self.fullPath contains:@"<dash_entry_name="])
    {
        NSString *newName = [[self.fullPath substringBetweenString:@"<dash_entry_name=" andString:@">"] stringByReplacingPercentEscapes];
        if(newName.length)
        {
            self.name = newName;
        }
    }
    if([self.fullPath contains:@"<dash_entry_originalName="])
    {
        NSString *newOriginalName = [[self.fullPath substringBetweenString:@"<dash_entry_originalName=" andString:@">"] stringByReplacingPercentEscapes];
        if(newOriginalName.length)
        {
            self.originalName = newOriginalName;
        }
    }
    if([self.fullPath contains:@"<dash_entry_menuDescription="])
    {
        NSString *newMenuDescription = [[self.fullPath substringBetweenString:@"<dash_entry_menuDescription=" andString:@">"] stringByReplacingPercentEscapes];
        if(newMenuDescription.length)
        {
            self.menuDescription = newMenuDescription;
        }
    }
    if([self.fullPath contains:@"<dash_entry_objcPath="])
    {
        NSString *objcPath = [[self.fullPath substringBetweenString:@"<dash_entry_objcPath=" andString:@">"] stringByReplacingPercentEscapes];
        if(objcPath.length)
        {
            self.appleObjCPath = objcPath;
        }
    }
    if([self.fullPath contains:@"<dash_entry_swiftPath="])
    {
        NSString *swift = [[self.fullPath substringBetweenString:@"<dash_entry_swiftPath=" andString:@">"] stringByReplacingPercentEscapes];
        if(swift.length)
        {
            self.appleSwiftPath = swift;
        }
    }
    while([self.fullPath contains:@"<dash_entry_"])
    {
        NSString *toRemove = [self.fullPath substringBetweenString:@"<dash_entry_" andString:@">"];
        if(toRemove.length)
        {
            toRemove = [NSString stringWithFormat:@"<dash_entry_%@>", toRemove];
            self.fullPath = [self.fullPath stringByReplacingOccurrencesOfString:toRemove withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.fullPath.length)];
            self.relativePath = [self.relativePath stringByReplacingOccurrencesOfString:toRemove withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.relativePath.length)];
            self.path = [self.path stringByReplacingOccurrencesOfString:toRemove withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.path.length)];
        }
        else
        {
            break;
        }
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Name: %@, Full Path: %@, Platform: %@, Type: %@, Similars: %@", self.name, self.fullPath, self.platform, self.type, self.similarResults];
}

- (BOOL)isEqual:(DHDBResult *)someResult
{
    NSString *myFamily = self.docset.parseFamily;
    NSString *theirFamily = someResult.docset.parseFamily;
    if(self.isSO && someResult.isSO)
    {
        return [self.path isEqualToString:someResult.path];
    }
    return ([self.name isEqualToString:someResult.name] && [self.type isEqualToString:someResult.type] && ([self.platform isEqualToString:someResult.platform] || (myFamily.length && [myFamily isEqualToString:@"cheatsheet"] && theirFamily.length && [myFamily isEqualToString:theirFamily])));
}

- (UIImage *)typeImage
{
    if(self._typeImage)
    {
        return self._typeImage;
    }
    UIImage *image = [UIImage imageNamed:self.type];
    return image;
}

- (UIImage *)platformImage
{
    if(self._platformImage)
    {
        return self._platformImage;
    }
    return self.docset.icon;
}

- (NSString *)declaredInPage
{
    if(self._declaredInPage)
    {
        return self._declaredInPage;
    }
    if(self.menuDescription)
    {
        self._declaredInPage = [@" - " stringByAppendingString:self.menuDescription];
        return self._declaredInPage;
    }
    if(self.isAGuide)
    {
        NSString *toAppend = self.originalName;
        for(NSString *token in @[@"/Conceptual/", @"/GettingStarted/", @"/General/", @"releasenotes/", @"samplecode/", @"featuredarticles/", @"technotes/", @"documentation/", @"/"])
        {
            NSRange tokenRange = [self.path rangeOfString:token];
            if(tokenRange.location != NSNotFound)
            {
                NSString *guideName = [[self.path substringFromDashIndex:NSMaxRange(tokenRange)] substringToString:@"/"];
                guideName = [guideName removePrefixIfExists:@"DevPedia-"];
                guideName = [guideName removePrefixIfExists:@"xcode_guide-"];
                guideName = [guideName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                toAppend = [guideName stringByAppendingFormat:@" - %@", self.originalName];
                break;
            }
        }
        self._declaredInPage = [@" - " stringByAppendingString:toAppend];
        return self._declaredInPage;
    }
    if([self.platform isEqualToString:@"lisp"])
    {
        self._declaredInPage = [@" - " stringByAppendingString:[self.path lastPathComponent]];
        return self._declaredInPage;
    }
    if([self.platform isEqualToString:@"ee"] && [self.originalName contains:@"::"])
    {
        self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
        return self._declaredInPage;
    }
    if([self.platform isEqualToString:@"net"])
    {
        NSString *fqn = [self.relativePath substringFromStringReturningNil:@"#dashFQN"];
        if(fqn && fqn.length)
        {
            fqn = [fqn stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            self._declaredInPage = [@" - " stringByAppendingString:fqn];
            return self._declaredInPage;
        }
        else
        {
            self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
            return self._declaredInPage;
        }
    }
    if([self.platform isEqualToString:@"moo"])
    {
        if([[[[self.path lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathFragment] contains:@"-"])
        {
            self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
            return self._declaredInPage;
        }
    }
    NSString *declaredInStyle = self.docset.declaredInStyle;
    NSString *parseFamily = self.docset.parseFamily;
    parseFamily = (declaredInStyle) ? declaredInStyle : parseFamily;
    if([[DHDBResult commonDeclaredInStylePlatforms] containsObject:self.platform] || ([self.platform isEqualToString:@"wordpress"] && [self.originalName contains:@"::"] && [self.type isEqualToString:@"Method"]) || ([self.platform isEqualToString:@"matlab"] && [self.type isEqualToString:@"Class"]) || ([self.platform isEqualToString:@"actionscript"] && ![self.type isEqualToString:@"Class"]) || ([self.platform isEqualToString:@"grails"] && [self.type isEqualToString:@"Guide"]) || [parseFamily isEqualToString:@"cheatsheet"] || [parseFamily isEqualToString:@"originalName"])
    {
        self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
        return self._declaredInPage;
    }
    else if([self.platform isEqualToString:@"cappuccino"] || [self.platform isEqualToString:@"zend"] || [self.platform isEqualToString:@"typo3"] || [self.platform isEqualToString:@"cocos2dx"] || [self.platform isEqualToString:@"doxy"] || [self.platform isEqualToString:@"doxygen"] || [parseFamily isEqualToString:@"doxy"] || [parseFamily isEqualToString:@"doxygen"])
    {
        if([self.type isClassType] || [self.type isPackageType] || [self.type isEqualToString:@"Interface"] || [self.type isEqualToString:@"Exception"] || [self.type isEqualToString:@"Union"] || [self.type isEqualToString:@"Struct"] || [self.type isEqualToString:@"Guide"] || [self.type isEqualToString:@"Sample"] || [self.type isEqualToString:@"Protocol"] || [self.type isEqualToString:@"Delegate"])
        {
            self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
            return self._declaredInPage;
        }
        NSString *filename = [[[self.path lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathFragment];
        if([filename hasCaseInsensitivePrefix:@"dir_"])
        {
            self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
            return self._declaredInPage;
        }
        if(filename.length == 128)
        {
            filename = [filename substringToDashIndex:96];
            NSRange alphaRange = [filename rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet] options:NSBackwardsSearch];
            if(alphaRange.location != NSNotFound)
            {
                filename = [filename substringToDashIndex:alphaRange.location+1];
                filename = [filename stringByAppendingString:@"..."];
            }
            else
            {
                self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
                return self._declaredInPage;
            }
        }
        if([filename hasCaseInsensitivePrefix:@"group_"])
        {
            filename = [filename substringFromDashIndex:6];
        }
        if([filename hasCaseInsensitivePrefix:@"category"])
        {
            filename = [filename substringFromDashIndex:8];
        }
        else if([filename hasCaseInsensitivePrefix:@"interface"])
        {
            filename = [filename substringFromDashIndex:9];
        }
        else if([filename hasCaseInsensitivePrefix:@"class"])
        {
            filename = [filename substringFromDashIndex:5];
        }
        else if([filename hasCaseInsensitivePrefix:@"namespace"])
        {
            filename = [filename substringFromDashIndex:9];
        }
        else if([filename hasCaseInsensitivePrefix:@"struct"])
        {
            filename = [filename substringFromDashIndex:6];
        }
        else if([filename hasCaseInsensitivePrefix:@"union"])
        {
            filename = [filename substringFromDashIndex:5];
        }
        NSString *declaredName = [[[[[[[[[[[[[[[[[[[[[[[[filename stringByReplacingOccurrencesOfString:@"_1" withString:@":"] stringByReplacingOccurrencesOfString:@"_2" withString:@"/"] stringByReplacingOccurrencesOfString:@"_3" withString:@"<"] stringByReplacingOccurrencesOfString:@"_4" withString:@">"] stringByReplacingOccurrencesOfString:@"_5" withString:@"*"] stringByReplacingOccurrencesOfString:@"_6" withString:@"&"] stringByReplacingOccurrencesOfString:@"_7" withString:@"|"] stringByReplacingOccurrencesOfString:@"_9" withString:@"!"] stringByReplacingOccurrencesOfString:@"_00" withString:@","] stringByReplacingOccurrencesOfString:@"_01" withString:@" "] stringByReplacingOccurrencesOfString:@"_02" withString:@"{"] stringByReplacingOccurrencesOfString:@"_03" withString:@"}"] stringByReplacingOccurrencesOfString:@"_04" withString:@"?"] stringByReplacingOccurrencesOfString:@"_05" withString:@"^"] stringByReplacingOccurrencesOfString:@"_06" withString:@"%"] stringByReplacingOccurrencesOfString:@"_07" withString:@"("] stringByReplacingOccurrencesOfString:@"_08" withString:@")"] stringByReplacingOccurrencesOfString:@"_09" withString:@"+"] stringByReplacingOccurrencesOfString:@"_0A" withString:@"="] stringByReplacingOccurrencesOfString:@"_0B" withString:@"$"] stringByReplacingOccurrencesOfString:@"_0C" withString:@"\\"] stringByReplacingOccurrencesOfString:@"_8" withString:@"."] stringByReplacingOccurrencesOfString:@"__" withString:@" "] stringByReplacingOccurrencesOfString:@"::" withString:@"\\"];
        NSRange underRange = [declaredName rangeOfString:@"_"];
        while(underRange.location != NSNotFound)
        {
            if(underRange.location+2 <= declaredName.length)
            {
                declaredName = [declaredName stringByReplacingCharactersInRange:NSMakeRange(underRange.location, 2) withString:[[declaredName substringWithDashRange:NSMakeRange(underRange.location+1, 1)] uppercaseString]];
                underRange = [declaredName rangeOfString:@"_"];
            }
            else
            {
                break;
            }
        }
        if(declaredName.length)
        {
            self._declaredInPage = [NSString stringWithFormat:@" - %@ > %@", [declaredName stringByReplacingOccurrencesOfString:@" " withString:@"_"], self.originalName];
            return self._declaredInPage;
        }
        self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
        return self._declaredInPage;
    }
    else if([self.platform isEqualToString:@"manPages"])
    {
        NSInteger anchorLoc = [self.fullPath rangeOfString:@"#"].location;
        if(anchorLoc != NSNotFound && anchorLoc+1 < self.fullPath.length)
        {
            self._declaredInPage = [@" - " stringByAppendingString:[self.fullPath substringFromDashIndex:anchorLoc+1]];
            return self._declaredInPage;
        }
        self._declaredInPage = [@" - " stringByAppendingString:self.originalName];
        return self._declaredInPage;
    }
    NSString *thePath = self.path;
    if([self.platform isEqualToString:@"clojure"])
    {
        thePath = [thePath stringByReplacingOccurrencesOfString:@"-api.html" withString:@".html"];
    }
    else if([@[@"ios", @"osx", @"macosx", @"iphoneos", @"watchos", @"tvos"] containsObject:self.platform])
    {
        thePath = [thePath stringByReplacingOccurrencesOfString:@"Swift/Reference/Swift_" withString:@"Swift/Reference/"];
        thePath = [thePath stringByReplacingOccurrencesOfString:@"Reference/Reference.html" withString:@"index.html"];
        thePath = [thePath stringByReplacingOccurrencesOfString:@"Introduction/Introduction.html" withString:@"index.html"];
    }
    if([self.platform isEqualToString:@"android"])
    {
        if([thePath hasCaseInsensitivePrefix:@"docs/"])
        {
            thePath = [thePath substringFromDashIndex:@"docs/".length];
        }
        else if([thePath hasCaseInsensitivePrefix:@"google_play_services_docs/"])
        {
            thePath = [thePath substringFromDashIndex:@"google_play_services_docs/".length];
        }
    }
    NSArray *reverseObjects = [[[thePath pathComponents] reverseObjectEnumerator] allObjects];
    int i = 0;
    for(__strong NSString *reverseObject in reverseObjects)
    {
        if([self.platform isEqualToString:@"wordpress"])
        {
            reverseObject = [reverseObject stringByReplacingOccurrencesOfString:@"---" withString:@"/"];
        }
        if(![reverseObject isCaseInsensitiveEqual:@"reference"] && ![reverseObject isCaseInsensitiveEqual:@"index.html"] && ![reverseObject isCaseInsensitiveEqual:@"description"] && ![reverseObject isCaseInsensitiveEqual:@"Introduction"] && ![reverseObject hasCaseInsensitiveSuffix:@"_h"] && ![reverseObject isCaseInsensitiveEqual:@"package-summary.html"] && ![reverseObject isCaseInsensitiveEqual:@"rdoc"])
        {
            NSRange anchorRange = [reverseObject rangeOfString:@"#"];
            if(anchorRange.location != NSNotFound && anchorRange.location != 0)
            {
                reverseObject = [reverseObject substringToDashIndex:anchorRange.location];
            }
            reverseObject = [reverseObject stringByReplacingOccurrencesOfString:@".html" withString:@""];
            if(![self.platform isEqualToString:@"wordpress"] && ![self.platform isEqualToString:@"nginx"])
            {
                reverseObject = [[reverseObject stringByReplacingOccurrencesOfString:@"_" withString:@" "] stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
            }
            if(([self.platform isEqualToString:@"android"] || [self.platform isEqualToString:@"java"] || (parseFamily && [parseFamily isEqualToString:@"java"]) || [self.platform isEqualToString:@"playjava"] || [self.platform isEqualToString:@"groovy"] || [self.platform isEqualToString:@"corona"] || [self.platform isEqualToString:@"javafx"] || [self.platform isEqualToString:@"rubymotion"]) && (i == reverseObjects.count || [reverseObjects[i] isCaseInsensitiveEqual:@"Documents"]))
            {
                break;
            }
            if(self._declaredInPage.length > 0)
            {
                self._declaredInPage = [reverseObject stringByAppendingFormat:@"%@%@", ([self.platform isEqualToString:@"rubymotion"]) ? @"::" : @".", self._declaredInPage];
            }
            else
            {
                self._declaredInPage = reverseObject;
            }
            if(![self.platform isEqualToString:@"corona"] && ![self.platform isEqualToString:@"android"] && !(parseFamily && [parseFamily isEqualToString:@"java"]) && ![self.platform isEqualToString:@"java"] && ![self.platform isEqualToString:@"playjava"] && ![self.platform isEqualToString:@"groovy"] && ![self.platform isEqualToString:@"javafx"] && ![self.platform isEqualToString:@"actionscript"] && ![self.platform isEqualToString:@"rubymotion"])
            {
                break;
            }
        }
        ++i;
    }
    if(self._declaredInPage.length > 0)
    {
        if([self.platform isEqualToString:@"corona"])
        {
            self._declaredInPage = [self._declaredInPage substringFromString:@"."];
            self._declaredInPage = [self._declaredInPage substringFromString:@"."];
        }
        else if([self.platform isEqualToString:@"haskell"] || [self.platform isEqualToString:@"hackage"])
        {
            self._declaredInPage = [self._declaredInPage stringByReplacingOccurrencesOfString:@"_" withString:@"."];
        }
        else if([self.platform isEqualToString:@"elisp"] || [self.platform isEqualToString:@"d3"])
        {
            self._declaredInPage = [self._declaredInPage stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        }
        else if([self.platform isEqualToString:@"glib"])
        {
            if([self._declaredInPage hasCaseInsensitivePrefix:@"glib_"])
            {
                self._declaredInPage = [self._declaredInPage substringFromDashIndex:@"glib_".length];
            }
            self._declaredInPage = [self._declaredInPage stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        }
        self._declaredInPage = [@" - " stringByAppendingString:self._declaredInPage];
        return self._declaredInPage;
    }
    self._declaredInPage = @"";
    return @"";
}

- (NSString *)duplicateHash
{
    if(self.isApple)
    {
        return [NSString stringWithFormat:@"%@%@%@", [[[self.originalName stringByReplacingOccurrencesOfString:@"(_" withString:@""] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""], self.type, [self.fullPath substringToString:@"#"]];
    }
    return nil;
}

- (NSString *)browserDuplicateHash
{
    NSString *pathHack = self.fullPath;
    if(self.isApple)
    {
        pathHack = self.path;
    }
    return [NSString stringWithFormat:@"%@%@%@", self.originalName, self.type, pathHack];
}

- (void)highlightLabel:(UILabel *)label
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
    if(self.highlightRanges.count)
    {
        for(NSValue *aValue in self.highlightRanges)
        {
            NSRange range = [aValue rangeValue];
            [string addAttributes:[DHDBResult highlightDictionary] range:range];
        }
    }
    else
    {
        // This is needed when the name is not contained within originalName, like the C++ docset
        // It's a basic workaround that only covers the easiest case
        NSRange queryRange = [self.name rangeOfString:self.query options:NSCaseInsensitiveSearch];
        if(queryRange.location != NSNotFound)
        {
            [string addAttributes:[DHDBResult highlightDictionary] range:queryRange];
        }
    }
    label.attributedText = string;
}

- (void)highlightWithQuery:(NSString *)aQuery
{
    self.query = aQuery;
    self.highlightRanges = [NSMutableArray array];
    if(self.query && [self.query length] > 0)
    {
        if((self.matchesQueryAtAll || self.originalMatchesQueryAtAll) && !self.whitespaceMatch)
        {
            self.fragmentation = -1;
            NSString *toHighlight = self.query;
            NSRange range;
            NSInteger offset = 0;
            NSString *substring = [NSString stringWithString:self.originalName];
            NSRange nameRange = [self.originalName rangeOfString:self.name options:NSCaseInsensitiveSearch|NSBackwardsSearch];
            while((range = [substring rangeOfString:toHighlight options:NSCaseInsensitiveSearch]).location != NSNotFound)
            {
                NSRange originalRange = NSMakeRange(range.location+offset, range.length);
                NSRange intersectionRange = NSIntersectionRange(originalRange, nameRange);
                if(intersectionRange.length > 0)
                {
                    intersectionRange.location -= nameRange.location;
                    [self.highlightRanges addObject:[NSValue valueWithRange:intersectionRange]];
                }
                substring = [substring substringFromDashIndex:range.location+range.length];
                offset += range.location+range.length;
            }
        }
        else
        {
            // check if whitespace match
            if([self.originalName rangeOfString:@" "].location != NSNotFound)
            {
                NSMutableCharacterSet *checkSet = [NSMutableCharacterSet characterSetWithCharactersInString:@" "];
                for(int i = 0; i < 3; i++)
                {
                    // for is needed so that matches like "ftp&" work with results like "FTP & SFTP" (Vagrant docset)
                    if(i == 1)
                    {
                        [checkSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
                    }
                    else if(i == 2)
                    {
                        [checkSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
                    }
                    NSMutableArray *removedRanges = [NSMutableArray array];
                    NSString *strippedOriginalName = [self.originalName stringByDeletingCharactersInSet:checkSet removedRanges:removedRanges];
                    NSString *strippedQuery = [self.query stringByDeletingCharactersInSet:checkSet];
                    
                    NSRange queryRange = [strippedOriginalName rangeOfString:strippedQuery options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
                    if(queryRange.location != NSNotFound)
                    {
                        for(NSValue *removedRangeValue in removedRanges)
                        {
                            NSRange removedRange = [removedRangeValue rangeValue];
                            if(removedRange.location <= queryRange.location)
                            {
                                queryRange.location += removedRange.length;
                            }
                            else if(NSIntersectionRange(removedRange, queryRange).length == removedRange.length)
                            {
                                queryRange.length += removedRange.length;
                            }
                        }
                        if([[self.originalName substringWithDashRange:queryRange] contains:@" "])
                        {
                            [self setHighlightRanges:[NSMutableArray arrayWithObject:[NSValue valueWithRange:queryRange]] relativeToNameRange:[self.originalName rangeOfString:self.name options:NSCaseInsensitiveSearch|NSBackwardsSearch]];
                            self.fragmentation = -1;
                            return;
                        }
                    }
                }
            }
            
            // find all occurences of letters in query
            NSMutableDictionary *letters = [NSMutableDictionary dictionary];
            [self.query enumerateLettersUsingBlock:^(NSString *letter) {
                if(!letters[letter])
                {
                    letters[letter] = [self.originalName rangesOfString:letter];
                }
            }];
            
            // initial seed: add occurences of first letter
            NSMutableArray *matches = [NSMutableArray array];
            NSString *firstLetter = [self.query substringWithRange:NSMakeRange(0, 1)];
            for(NSValue *rangeValue in letters[firstLetter])
            {
                [matches addObject:[NSMutableArray arrayWithObject:rangeValue]];
            }
            
            // spread initial seeds to cover all possible occurences of all letters
            [[self.query substringFromIndex:1] enumerateLettersUsingBlock:^(NSString *letter) {
                NSArray *letterRangeValues = letters[letter];
                for(NSMutableArray *match in [NSArray arrayWithArray:matches])
                {
                    for(NSValue *letterRangeValue in letterRangeValues)
                    {
                        NSRange letterRange = [letterRangeValue rangeValue];
                        if(NSMaxRange([[match lastObject] rangeValue]) < NSMaxRange(letterRange))
                        {
                            NSMutableArray *matchSpread = [NSMutableArray arrayWithArray:match];
                            [matchSpread addObject:letterRangeValue];
                            [matches addObject:matchSpread];
                            if(matches.count >= 80)
                            {
                                break;
                            }
                        }
                    }
                    [matches removeObjectIdenticalTo:match];
                }
            }];
            
            // remove matches that do not have all letters matched
            for(NSMutableArray *match in [NSArray arrayWithArray:matches])
            {
                if(match.count < self.query.length)
                {
                    [matches removeObjectIdenticalTo:match];
                }
            }
            
            // merge ranges
            for(NSMutableArray *match in matches)
            {
                NSRange lastRange = NSMakeRange(NSNotFound, 0);
                for(NSUInteger index = 0; index < match.count; index++)
                {
                    NSRange range = [match[index] rangeValue];
                    if(NSMaxRange(lastRange) == range.location)
                    {
                        range = NSMakeRange(lastRange.location, lastRange.length+range.length);
                        match[index-1] = [NSValue valueWithRange:range];
                        [match removeObjectAtIndex:index];
                        --index;
                    }
                    lastRange = range;
                }
            }
            
            // remove matches for which the first matched letter is not one of the following: first letter of self.name, preceded by a char in allowedChars, preceded by lowercase and is uppercase, is uppercase and the first match group contains a lowercase letter
            NSRange nameRange = [self.originalName rangeOfString:self.name options:NSCaseInsensitiveSearch|NSBackwardsSearch];
            NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:@".%_#-\\/:$@!*&+()~^=,<>'\"{}[]| "];
            for(NSMutableArray *match in [NSArray arrayWithArray:matches])
            {
                BOOL found = NO;
                for(NSValue *rangeValue in match)
                {
                    NSRange range = [rangeValue rangeValue];
                    if(range.location <= nameRange.location && NSMaxRange(range) >= nameRange.location+1)
                    {
                        found = YES;
                        break;
                    }
                }
                if(!found)
                {
                    BOOL shouldContinue = NO;
                    for(NSValue *rangeValue in match)
                    {
                        NSRange firstRange = [rangeValue rangeValue];
                        if(NSIntersectionRange(nameRange, firstRange).length > 0)
                        {
                            if(firstRange.location >= nameRange.location && firstRange.location+firstRange.length <= nameRange.location+nameRange.length && firstRange.location > 0)
                            {
                                NSString *previousChar = [self.originalName substringWithRange:NSMakeRange(firstRange.location-1, 1)];
                                if([previousChar rangeOfCharacterFromSet:allowedChars].location != NSNotFound)
                                {
                                    shouldContinue = YES;
                                    break;
                                }
                                NSString *matchedChar = [self.originalName substringWithRange:NSMakeRange(firstRange.location, 1)];
                                BOOL matchedIsUpper = [matchedChar isUppercase];
                                BOOL previousIsUpper = [previousChar isUppercase];
                                if(matchedIsUpper && !previousIsUpper)
                                {
                                    shouldContinue = YES;
                                    break;
                                }
                                if(matchedIsUpper && [[self.originalName substringWithRange:firstRange] rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].location != NSNotFound)
                                {
                                    shouldContinue = YES;
                                    break;
                                }
                            }
                            break;
                        }
                    }
                    if(shouldContinue)
                    {
                        continue;
                    }
                    [matches removeObjectIdenticalTo:match];
                }
            }
            
            // check if camel case
            for(NSMutableArray *match in matches)
            {
                NSRange firstRange = [match[0] rangeValue];
                NSRange lastRange = [[match lastObject] rangeValue];
                if(firstRange.location < nameRange.location || NSMaxRange(lastRange) > NSMaxRange(nameRange))
                {
                    continue;
                }
                BOOL isCamel = YES;
                for(NSValue *rangeValue in match)
                {
                    NSRange range = [rangeValue rangeValue];
                    if(range.location == nameRange.location)
                    {
                        continue;
                    }
                    else
                    {
                        NSString *previousLetter = [self.originalName substringWithRange:NSMakeRange(range.location-1, 1)];
                        if([previousLetter isEqualToString:@" "])
                        {
                            isCamel = NO;
                            break;
                        }
                        NSString *myLetter = [self.originalName substringWithRange:NSMakeRange(range.location, 1)];
                        BOOL myLetterUpper = [[myLetter uppercaseString] isEqualToString:myLetter];
                        BOOL myLetterLower = [[myLetter lowercaseString] isEqualToString:myLetter];
                        BOOL previousLetterUpper = [[previousLetter uppercaseString] isEqualToString:previousLetter];
                        BOOL previousLetterLower = [[previousLetter lowercaseString] isEqualToString:previousLetter];
                        if(!((myLetterUpper && !myLetterLower && previousLetterLower) || (!myLetterUpper && myLetterLower && previousLetterLower && previousLetterUpper)))
                        {
                            isCamel = NO;
                            break;
                        }
                    }
                }
                if(isCamel)
                {
                    self.fuzzyCamel = YES;
                    [self setHighlightRanges:match relativeToNameRange:nameRange];
                    return;
                }
            }
            
            // find largest length (relative to self.name) matches
            NSInteger largestLength = 0;;
            NSMutableArray *largestLengthMatches = [NSMutableArray array];
            for(NSMutableArray *match in matches)
            {
                NSInteger currentLength = 0;
                for(NSValue *rangeValue in match)
                {
                    currentLength += NSIntersectionRange(nameRange, [rangeValue rangeValue]).length;
                }
                if(currentLength > largestLength)
                {
                    largestLength = currentLength;
                    [largestLengthMatches removeAllObjects];
                }
                if(currentLength == largestLength)
                {
                    [largestLengthMatches addObject:match];
                }
            }
            [matches removeAllObjects];
            [matches addObjectsFromArray:largestLengthMatches];
            
            // find match with lowest fragmentation
            NSInteger lowestPerceivedFragmentation = NSIntegerMax;
            NSInteger lowestFragmentation = NSIntegerMax;
            NSMutableArray *bestMatch = nil;
            for(NSMutableArray *match in matches)
            {
                NSInteger currentFragmentation = match.count;
                NSInteger currentPerceivedFragmentation = 0;
                NSRange previousRange = NSMakeRange(NSNotFound, 0);
                for(NSValue *rangeValue in match)
                {
                    NSRange range = [rangeValue rangeValue];
                    if(previousRange.location != NSNotFound)
                    {
                        NSString *between = [self.originalName substringWithRange:NSMakeRange(NSMaxRange(previousRange), range.location-NSMaxRange(previousRange))];
                        if([between rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound)
                        {
                            --currentFragmentation;
                            continue;
                        }
                    }
                    if(range.length == 1 && [self.query length] > 2)
                    {
                        ++currentPerceivedFragmentation;
                    }
                    previousRange = range;
                }
                if(currentFragmentation == lowestFragmentation)
                {
                    if(currentPerceivedFragmentation < lowestPerceivedFragmentation)
                    {
                        lowestPerceivedFragmentation = currentPerceivedFragmentation;
                        bestMatch = match;
                    }
                }
                else if(currentFragmentation < lowestFragmentation)
                {
                    lowestFragmentation = currentFragmentation;
                    lowestPerceivedFragmentation = currentPerceivedFragmentation;
                    bestMatch = match;
                }
            }
            BOOL isSnippet = NO; //[self isKindOfClass:[DHDBSnippetResult class]];
            if(!isSnippet && (lowestPerceivedFragmentation > 1 || lowestFragmentation > 4 || !bestMatch))
            {
                self.fuzzyShouldIgnore = YES;
            }
            else if(bestMatch)
            {
                [self setHighlightRanges:bestMatch relativeToNameRange:nameRange];
                self.fragmentation = lowestPerceivedFragmentation;
                self.actualFragmentation = lowestFragmentation;
                if(lowestPerceivedFragmentation <= 1 && lowestFragmentation <= 2)
                {
                    self.fuzzyPerfect = YES;
                }
                else
                {
                    self.fuzzy = YES;
                }
            }
        }
    }
}

- (void)setHighlightRanges:(NSMutableArray *)bestRanges relativeToNameRange:(NSRange)nameRange
{
    for(NSValue *rangeValue in bestRanges)
    {
        NSRange range = [rangeValue rangeValue];
        NSRange intersection = NSIntersectionRange(range, nameRange);
        if(intersection.length > 0)
        {
            [self.highlightRanges addObject:[NSValue valueWithRange:NSMakeRange(intersection.location-nameRange.location, intersection.length)]];
        }
    }
}

- (NSComparisonResult)compare:(DHDBResult *)aResult
{
    if(self.matchesQueryAtAll && aResult.matchesQueryAtAll)
    {
        if(self.whitespaceMatch && !aResult.whitespaceMatch)
        {
            return NSOrderedDescending;
        }
        else if(!self.whitespaceMatch && aResult.whitespaceMatch)
        {
            return NSOrderedAscending;
        }
    }
    if(self.score > aResult.score)
    {
        return NSOrderedAscending;
    }
    else if(self.score < aResult.score)
    {
        return NSOrderedDescending;
    }
    if(self.queryIsPrefix && aResult.queryIsPrefix)
    {
        return [self levenshteinCompare:aResult];
    }
    if(self.queryIsSuffix && aResult.queryIsSuffix)
    {
        if(self.highlightRanges.count)
        {
            if(aResult.highlightRanges.count)
            {
                NSRange myFirstRange = [(self.highlightRanges)[0] rangeValue];
                NSRange theirFirstRange = [(aResult.highlightRanges)[0] rangeValue];
                if(myFirstRange.location < theirFirstRange.location)
                {
                    return NSOrderedAscending;
                }
                else if(myFirstRange.location > theirFirstRange.location)
                {
                    return NSOrderedDescending;
                }
                else if(self.name.length < aResult.name.length)
                {
                    return NSOrderedAscending;
                }
                else if(self.name.length > aResult.name.length)
                {
                    return NSOrderedDescending;
                }
                else
                {
                    return [self.name localizedCaseInsensitiveCompare:[aResult name]];
                }
            }
            else
            {
                return NSOrderedAscending;
            }
        }
        return [self levenshteinCompare:aResult];
    }
    else
    {
        if(self.matchesQueryAtAll)
        {
            if(aResult.matchesQueryAtAll)
            {
                return [self.name localizedCaseInsensitiveCompare:[aResult name]];
            }
            else
            {
                return NSOrderedAscending;
            }
        }
        else if(aResult.matchesQueryAtAll)
        {
            return NSOrderedDescending;
        }
    }
    return [self.name localizedCaseInsensitiveCompare:[aResult name]];
}

- (NSComparisonResult)levenshteinCompare:(DHDBResult *)aResult
{
    if(self.matchesQueryAtAll && aResult.matchesQueryAtAll)
    {
        if(self.whitespaceMatch && !aResult.whitespaceMatch)
        {
            return NSOrderedDescending;
        }
        else if(!self.whitespaceMatch && aResult.whitespaceMatch)
        {
            return NSOrderedAscending;
        }
    }
    float myDistance = [self levenshteinDistance];
    float theirDistance = [aResult levenshteinDistance];
    if(myDistance < theirDistance)
    {
        return NSOrderedAscending;
    }
    else if(myDistance == theirDistance)
    {
        return [self.name localizedCaseInsensitiveCompare:[aResult name]];
    }
    else
    {
        return NSOrderedDescending;
    }
}

- (float)levenshteinDistance
{
    if(self.distanceFromQuery != nil)
    {
        return [self.distanceFromQuery floatValue];
    }
    float distance = [self.name distanceFromString:self.query];
    self.distanceFromQuery = @(distance);
    return distance;
}

- (NSComparisonResult)compareFuziness:(DHDBResult *)aResult
{
    if(self.fragmentation == -1 || aResult.fragmentation == -1)
    {
        NSInteger resultSortOrder = [self compareResultSortOrder:aResult];
        if(resultSortOrder != NSOrderedSame)
        {
            return resultSortOrder;
        }
        return [self compare:aResult];
    }
    if(self.highlightRanges.count > aResult.highlightRanges.count)
    {
        return NSOrderedDescending;
    }
    else if(self.highlightRanges.count < aResult.highlightRanges.count)
    {
        return NSOrderedAscending;
    }
    else
    {
        NSInteger resultSortOrder = [self compareResultSortOrder:aResult];
        if(resultSortOrder != NSOrderedSame)
        {
            return resultSortOrder;
        }
        if(self.score > aResult.score)
        {
            return NSOrderedAscending;
        }
        else if(self.score < aResult.score)
        {
            return NSOrderedDescending;
        }
        return [self levenshteinCompare:aResult];
    }
}

- (NSComparisonResult)compareResultSortOrder:(DHDBResult *)aResult
{
    DHDBResultSorter *sorter = [DHDBResultSorter sharedSorter];
    NSInteger myRank = [sorter rankForResult:self];
    NSInteger otherRank = [sorter rankForResult:aResult];
    if(myRank < otherRank)
    {
        return NSOrderedDescending;
    }
    else if(myRank > otherRank)
    {
        return NSOrderedAscending;
    }
    return NSOrderedSame;
}

- (NSString *)sortType
{
    if(self.isPHP && [self.type isEqualToString:@"Function"])
    {
        return @"Class";
    }
    else if(self.isRust && [self.type isEqualToString:@"_Struct"])
    {
        return @"Class";
    }
    else if(self.isSwift && [self.type isEqualToString:@"Type"])
    {
        return @"Class";
    }
    else if(self.isGo && [self.type isEqualToString:@"Type"])
    {
        return @"Class";
    }
    else if(self.isApple && self.linkIsSwift && [self.type isEqualToString:@"Struct"] && [self.path contains:@"/Swift/Reference/"])
    {
        return @"Class";
    }
    return self.type;
}

+ (NSSet *)commonDeclaredInStylePlatforms
{
    if(!commonDeclaredInStylePlatforms)
    {
        commonDeclaredInStylePlatforms = [NSSet setWithObjects:@"apache", @"python", @"zepto", @"cvp", @"cvc", @"mongodb", @"cvcpp", @"vagrant", @"cf", @"ansible", @"ocaml", @"twig", @"smarty", @"chef", @"php", @"express", @"bash", @"swift", @"extjs", @"titanium", @"sencha", @"markdown", @"latex", @"bourbon", @"cmake", @"awesome", @"jade", @"SproutCore", @"neat", @"moment", @"elasticsearch", @"xojo", @"lodash", @"statamic", @"drupal", @"phonegap", @"cordova", @"laravel", @"compass", @"haml", @"sass", @"bootstrap", @"ember", @"jasmine", @"perl", @"jquerym", @"jQuery", @"css", @"dartlang", @"phpunit", @"polymerdart", @"angulardart", @"xul", @"xslt", @"javascript", @"arduino",  @"angularjs", @"emmet", @"chai", @"mongoose", @"react", @"grunt", @"sooffline", @"soonline", @"rust", @"flask", @"numpy", @"pandas",  @"sqlalchemy", @"tornado", @"matplotlib", @"salt", @"jinja", @"require", @"scipy", @"go", @"godoc", @"prototype", @"puppet", @"stylus", @"sinon", @"gl2", @"gl3", @"gl4", @"jqueryui", @"underscore", @"backbone", @"marionette", @"coffee", @"yii", @"mono", @"xamarin", @"yui", @"tcl", @"erlang", @"vsphere", @"twisted", @"phpp", @"joomla", @"symfony", @"cakephp", @"scala", @"scaladoc", @"playscala", @"akka", @"sqlite", @"boost", @"unity3d", @"django", @"cpp", @"c", @"qt", @"rails", @"codeigniter", @"yard", @"ruby", @"awsjs", @"rubyGems",  @"foundation", @"lua", @"dojo", @"elixir", @"knockout", @"meteor", nil];
    }
    return commonDeclaredInStylePlatforms;
}

+ (NSDictionary *)highlightDictionary
{
    if(!highlightDictionary)
    {
        highlightDictionary = @{NSForegroundColorAttributeName: [[DHAppDelegate sharedDelegate].window.rootViewController.view.tintColor colorWithAlphaComponent:0.8]};
    }
    return highlightDictionary;
}

- (NSUInteger)indexOfActiveItem
{
    if([self isActive])
    {
        return 0;
    }
    else
    {
        int index = 1;
        for(DHDBResult *result in self.similarResults)
        {
            if([result isActive])
            {
                return index;
            }
            ++index;
        }
    }
    [self setIsActive:YES];
    return 0;
}

- (void)setActiveItemByIndex:(NSUInteger)index
{
    self.isActive = (index == 0) ? YES : NO;
    int i = 1;
    for(DHDBResult *result in self.similarResults)
    {
        result.isActive = (i == index) ? YES : NO;
        ++i;
    }
}

- (DHDBResult *)activeResult
{
    if(self.isActive)
    {
        return self;
    }
    for(DHDBResult *result in self.similarResults)
    {
        if(result.isActive)
        {
            return result;
        }
    }
    return self;
}

- (NSString *)webViewURL
{
    NSString *fullPath = nil;
    if(self.isRemote)
    {
        if(self.remoteResultURL)
        {
            fullPath = self.remoteResultURL;
        }
        return fullPath;
    }
    fullPath = self.fullPath;
    NSInteger currentLanguage = [DHAppleActiveLanguage currentLanguage];
    if(fullPath.length && [self.platform isEqualToString:@"apple"] && currentLanguage != self.appleLanguage)
    {
        if(currentLanguage == DHNewActiveAppleLanguageObjC && self.appleObjCPath.length)
        {
            return [@"file://" stringByAppendingString:[[self.docset.path stringByAppendingPathComponent:@"Contents/Resources/Documents"] stringByAppendingPathComponent:self.appleObjCPath]];
        }
        else if(currentLanguage == DHNewActiveAppleLanguageSwift && self.appleSwiftPath.length)
        {
            return [@"file://" stringByAppendingString:[[self.docset.path stringByAppendingPathComponent:@"Contents/Resources/Documents"] stringByAppendingPathComponent:self.appleSwiftPath]];
        }
        NSString *delimiter = self.docset.plist[@"DashDocSetAppleObjCDelimiter"];
        NSString *delimiterWithExtension = [delimiter stringByAppendingString:@".html"];
        if(delimiter.length)
        {
            NSString *currentPath = [[fullPath substringFromStringReturningNil:@"://"] substringToString:@"#"];
            if(currentLanguage == DHNewActiveAppleLanguageObjC && ![currentPath contains:delimiterWithExtension] && [[NSFileManager defaultManager] fileExistsAtPathOrInIndex:[[currentPath stringByDeletingPathExtension] stringByAppendingString:delimiterWithExtension]])
            {
                NSString *currentAnchor = [fullPath substringFromLastOccurrenceOfStringReturningNil:@"#"];
                NSString *newPath = [fullPath substringToLastOccurrenceOfString:@"#"];
                NSRange extensionRange = [newPath rangeOfString:@".html" options:NSCaseInsensitiveSearch|NSBackwardsSearch];
                if(extensionRange.location != NSNotFound)
                {
                    newPath = [newPath stringByReplacingCharactersInRange:extensionRange withString:delimiterWithExtension];
                    if(currentAnchor.length)
                    {
                        newPath = [newPath stringByAppendingFormat:@"#%@", currentAnchor];
                    }
                    return newPath;
                }
            }
            if(currentLanguage == DHNewActiveAppleLanguageSwift && [currentPath contains:delimiterWithExtension] && [[NSFileManager defaultManager] fileExistsAtPathOrInIndex:[currentPath stringByReplacingOccurrencesOfString:delimiterWithExtension withString:@".html"]])
            {
                return [fullPath stringByReplacingOccurrencesOfString:delimiterWithExtension withString:@".html"];
            }
        }

    }
    return fullPath;
}

@end
