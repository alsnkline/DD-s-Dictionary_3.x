//
//  DD2GlobalHelper.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2GlobalHelper.h"
#import "GAITracker.h"

@implementation DD2GlobalHelper

+ (NSString*) version {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@ build %@", version, build];
}

+ (NSString *) deviceType {
    return [UIDevice currentDevice].model;
}

+ (NSArray *)alphabet
{
    NSMutableArray *alphabet = [NSMutableArray array];
    for (char a = 'a'; a <= 'z'; a++) {
        [alphabet addObject:[NSString stringWithFormat:@"%c", a]];
    }
    return [alphabet copy];
}

+ (NSString *)getHexStringForColor:(UIColor *)color {
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CGFloat r = roundf(red * 255.0);
    CGFloat g = roundf(green * 255.0);
    CGFloat b = roundf(blue * 255.0);
    
    NSString *hexColor = [NSString stringWithFormat:@"%02x%02x%02x", (int)r, (int)g, (int)b];
    
    return hexColor;
}

+ (NSUInteger) testWordPredicate:(NSPredicate *)predicate onWords:(id)words
{
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    
    if ([words isKindOfClass:[NSArray class]]) {
        NSArray *nsaWords = (NSArray *)words;
        NSArray *filteredWords = [NSArray arrayWithArray:[nsaWords filteredArrayUsingPredicate:predicate]];
        NSArray *sortedFilteredWords = [filteredWords sortedArrayUsingDescriptors:sortDescriptors];
        if (LOG_PREDICATE_RESULTS) {
            NSLog(@"number of matches = %d", [filteredWords count]);
            for (NSDictionary *word in sortedFilteredWords) {
                NSLog(@"found: %@", [word objectForKey:@"spelling"]);
            }
        }
        return [filteredWords count];
    }
    NSLog(@"words passed in for predicate check were not an NSArray");
    return 1;
    
}

+ (NSURL *)wordlistJSONFileDirectory
{
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSURL *bundleUrl = [[NSBundle mainBundle] bundleURL];
    NSURL *dirUrl = [NSURL URLWithString:@"resources.bundle/json/" relativeToURL:bundleUrl];
    NSLog(@"Wordlist Json file directory: %@", dirUrl);
    
    BOOL isDir = YES;
    [localFileManager fileExistsAtPath:[dirUrl path] isDirectory:&isDir];
    if (!isDir ) {
        NSLog(@"no JSON directory in resource files");
    }
    return dirUrl;
}

+ (NSURL *)fileURLForPronunciation:(NSString *)pronunciation
{

    NSString *pathComponentForBundle = [NSString stringWithFormat:@"resources.bundle"];
    NSString *pathForSoundName = [NSString pathWithComponents:[NSArray arrayWithObjects:pathComponentForBundle,@"audio",pronunciation, nil]];

    //NSLog(@"current pronunciation = %@", pronunciation);
    //NSLog(@"pathForSoundName = %@",pathForSoundName);
    NSString *soundName = [[NSBundle mainBundle] pathForResource:pathForSoundName ofType:@"m4a"];
    //NSLog(@"soundName = %@", soundName);
    
    
    NSURL *fileURL;
    if (soundName) {
        fileURL = [[NSURL alloc] initFileURLWithPath:soundName];
    }
    //NSLog(@"fileURL = %@", fileURL);
    
    // Get the paths and URL's right!
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    BOOL fileFound = [localFileManager fileExistsAtPath:[fileURL path]];
    if (PROCESS_VERBOSELY) NSLog(@"Pronunciation fileFound for %@: %@", pronunciation, fileFound ? @"YES" : @"NO");
    
    if (fileFound) {
        return fileURL;
    } else {
        return nil;
    }
}

#pragma mark - Analytics Methods

+ (void)sendViewToGAWithViewName:(NSString *)screenName {

    //track with GA manually avoid subclassing UIViewController
    id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    if (LOG_ANALYTICS) NSLog(@"GAsend ScreenNamed : %@", screenName);
    
}

+ (void)sendEventToGAWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value {
    //track event with GA
    id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:value] build]];
    if (value) {
        if (LOG_ANALYTICS) NSLog(@"GAsend Event c:%@, a:%@, l:%@, v:%@", category, action, label, value);
    } else {
        if (LOG_ANALYTICS) NSLog(@"GAsend Event c:%@, a:%@, l:%@", category, action, label);
    }
    
}

@end
