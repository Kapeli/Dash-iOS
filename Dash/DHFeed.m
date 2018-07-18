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

#import "DHFeed.h"

@implementation DHFeed

// For Dash provided feeds only
+ (instancetype)feedWithFeed:(NSString *)aFeed icon:(NSString *)aIcon aliases:(id)someAliases doesNotHaveVersions:(BOOL)doesNotHaveVersions
{
    DHFeed *feed = [[DHFeed alloc] init];
    feed.detailString = @"";
    feed.feed = aFeed;
    feed.iconName = aIcon;
    NSString *feedURL = [@"http://kapeli.com/feeds/" stringByAppendingString:aFeed];
    if([aFeed isEqualToString:@"SproutCore.xml"])
    {
        feed.isCustom = YES;
        feedURL = [@"http://docs.sproutcore.com/feeds/" stringByAppendingString:aFeed];
    }
    feed.feedURL = feedURL;
    feed.aliases = ([someAliases isKindOfClass:[NSArray class]]) ? someAliases : (someAliases) ? @[someAliases] : nil;
    feed.doesNotHaveVersions = doesNotHaveVersions;
    return feed;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"feed"] = self.feed ?: @"";
    dictionary[@"feedURL"] = self.feedURL ?: @"";
    dictionary[@"icon"] = self.iconName ?: @"";
    dictionary[@"size"] = self.size ?: @"";
    dictionary[@"aliases"] = self.aliases ?: @[];
    dictionary[@"doesNotHaveVersions"] = self.doesNotHaveVersions ? @YES : @NO;
    dictionary[@"installed"] = self.installed ? @YES : @NO;
    dictionary[@"isCustom"] = self.isCustom ? @YES : @NO;
    if(self.installedVersion) { dictionary[@"installedVersion"] = self.installedVersion; }
    return dictionary;
}

/** DmytriE 2018-07-17: Create the desired dictionary representation of the
 *  information.
 *  @param  dictionary:
 *  @return feed: The feed with all of the information
 */
+ (DHFeed *)feedWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    DHFeed *feed = [[DHFeed alloc] init];
    feed.detailString = @"";
    feed.feed = dictionary[@"feed"];
    feed.feedURL = dictionary[@"feedURL"];
    feed.size = dictionary[@"size"];
    feed.iconName = dictionary[@"icon"];
    feed.aliases = dictionary[@"aliases"];
    feed.doesNotHaveVersions = [dictionary[@"doesNotHaveVersions"] boolValue];
    feed.installed = [dictionary[@"installed"] boolValue];
    feed.installedVersion = dictionary[@"installedVersion"];
    feed.isCustom = [dictionary[@"isCustom"] boolValue];
    return feed;
}

/** DmytriE 2018-07-16:
 *  @param withVersion:
 *  @return NSString which contains the docset name
 */
- (NSString *)docsetNameWithVersion:(BOOL)withVersion
{
    NSString *docsetName = [NSString stringWithFormat:@"%@", [[[[self.feedURL lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    if([docsetName isEqualToString:@"NET Framework"])
    {
        docsetName = @".NET Framework";
    }
    else if([docsetName isEqualToString:@"Angular.dart"])
    {
        docsetName = @"AngularDart";
    }
    else if([docsetName isEqualToString:@"MatPlotLib"])
    {
        docsetName = @"Matplotlib";
    }
    else if([docsetName isEqualToString:@"Lo-Dash"])
    {
        docsetName = @"Lodash";
    }
    if(withVersion && self.installed)
    {
        NSString *version = self.installedVersion;
        version = [version substringToString:@"/"];
        if([version length])
        {
            if([self isMajorVersioned:self.feedURL])
            {
                docsetName = [docsetName stringByAppendingFormat:@"%@", version];
            }
            else
            {
                docsetName = [docsetName stringByAppendingFormat:@" %@", version];
            }
        }
    }
    return docsetName;
}

- (BOOL)isMajorVersioned:(NSString *)feedURL
{
    return  [feedURL isEqualToString:@"http://kapeli.com/feeds/Drupal_7.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Drupal_8.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Zend_Framework_1.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Zend_Framework_2.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Zend_Framework_3.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Bootstrap_2.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Bootstrap_3.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Bootstrap_4.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Python_2.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Python_3.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Java_SE6.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Java_SE7.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Java_SE8.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Ruby_on_Rails_3.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Ruby_on_Rails_4.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Ruby_on_Rails_5.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Qt_4.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Qt_5.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Lua_5.1.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Lua_5.2.xml"] ||
            [feedURL isEqualToString:@"http://kapeli.com/feeds/Ruby_2.xml"];
}

- (NSString *)sortName
{
    NSString *name = [self docsetNameWithVersion:YES];
    if([name hasPrefix:@"Angular.dart"])
    {
        return [name stringByReplacingOccurrencesOfString:@"Angular.dart" withString:@"Angularz.dart"];
    }
    return name;
}

- (NSString *)stringValue
{
    return [self docsetNameWithVersion:NO];
}

/** DmytriE 2018-07-17: Preparing the cell with the appropriate images, including,
 *  (Download / Uninstall / Checkmark / DocSet Image).
 *  @param  cell: DocSet table cell to prepare
 *  @return NONE
 */
- (void)prepareCell:(DHRepoTableViewCell *)cell
{
    self.cell = cell;
    if(self.progressShown) // Display progress indicator
    {
        cell.progressView.alpha = 1.0;
        cell.downloadButton.alpha = 0.0;
        cell.uninstallButton.alpha = 0.0;
        cell.checkmark.alpha = 0.0;
        cell.progressView.progress = self.progress;
    }
    else
    {
        cell.progressView.alpha = 0.0;
        if(self.installed) // Display Uninstall and Checkmark
        {
            cell.downloadButton.alpha = 0.0;
            cell.uninstallButton.alpha = 1.0;
            cell.checkmark.alpha = 1.0;
        }
        else // Display Download button
        {
            cell.downloadButton.alpha = 1.0;
            cell.uninstallButton.alpha = 0.0;
            cell.checkmark.alpha = 0.0;
        }
    }
    if(self.error.length && !self.installing && !self.installed)
    {
        cell.errorButton.alpha = 1.0;
    }
    else
    {
        cell.errorButton.alpha = 0.0;
    }
    [self adjustTitleLabelWidthBasedOnButtonsShown];
}

/** DmytriE 2018-07-17:
 *  @param  NONE
 *  @return NONE
 */
- (void)adjustTitleLabelWidthBasedOnButtonsShown
{
    CGFloat endX = self.cell.downloadButton.frame.origin.x;
    if(self.cell.errorButton.alpha > 0.0)
    {
        endX = self.cell.errorButton.frame.origin.x;
    }
    else if(self.cell.uninstallButton.alpha > 0.0)
    {
        int offset = (isRegularHorizontalClass) ? 3 : 0;
        endX = self.cell.errorButton.frame.origin.x+offset;
    }
    endX -= 6;
    CGRect frame = self.cell.titleLabel.frame;
    self.cell.titleLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, endX-frame.origin.x, frame.size.height);
}

- (UIImage *)icon
{
    return [UIImage imageNamed:self.iconName];
}

- (BOOL)isEqual:(id)object
{
    return [self.feedURL isEqualToString:[object feedURL]];
}


- (NSString *)uniqueIdentifier // Used to find a corresponding feed from a installed docset
{
    return self.feedURL;
}

@end
