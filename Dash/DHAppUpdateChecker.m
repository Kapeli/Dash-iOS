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

#import "DHAppUpdateChecker.h"

#define DHAppUpdateCheckerLastCheckDate @"DHAppUpdateCheckerLastCheckDate"
#define DHAppUpdateCheckerScheduledUpdateVersion @"DHAppUpdateCheckerScheduledUpdateVersion"

@implementation DHAppUpdateChecker

+ (DHAppUpdateChecker *)sharedUpdateChecker
{
#ifdef APP_STORE
    return nil;
#endif
    static dispatch_once_t pred;
    static DHAppUpdateChecker *_checker = nil;
    
    dispatch_once(&pred, ^{
        _checker = [[DHAppUpdateChecker alloc] init];
    });
    return _checker;
}

- (void)backgroundCheckForUpdatesIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastDate = [defaults objectForKey:DHAppUpdateCheckerLastCheckDate];
    if(!lastDate || [[NSDate date] timeIntervalSinceDate:lastDate] > 60*60*24)
    {
        [defaults setObject:[NSDate date] forKey:DHAppUpdateCheckerLastCheckDate];
        dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
        dispatch_async(queue, ^{
            NSData *jsonData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[@"https://kapeli.com/dash_ios.json?bundle_id=" stringByAppendingString:[NSBundle mainBundle].bundleIdentifier]]];
            if(jsonData)
            {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                if(json)
                {
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    NSString *myVersion = [infoDict objectForKey:@"CFBundleVersion"];
                    if([myVersion integerValue] < [json[@"version"] integerValue])
                    {
                        [[NSUserDefaults standardUserDefaults] setObject:json[@"version"] forKey:DHAppUpdateCheckerScheduledUpdateVersion];
                    }
                }
            }
        });
    }
}

- (BOOL)alertIfUpdatesAreScheduled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *version = [defaults objectForKey:DHAppUpdateCheckerScheduledUpdateVersion];
    if(version)
    {
        [defaults removeObjectForKey:DHAppUpdateCheckerScheduledUpdateVersion];
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *myVersion = [infoDict objectForKey:@"CFBundleVersion"];
        if([version integerValue] > [myVersion integerValue])
        {
            [UIAlertView showWithTitle:@"Dash Update Available" message:@"A new version of Dash has been released. Would you like to update?" cancelButtonTitle:@"Maybe Later" otherButtonTitles:@[@"Update"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if(buttonIndex == alertView.firstOtherButtonIndex)
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://kapeli.com/dash_ios?ref=update#update"]];
                }
            }];
            return YES;
        }
    }
    return NO;
}

@end
