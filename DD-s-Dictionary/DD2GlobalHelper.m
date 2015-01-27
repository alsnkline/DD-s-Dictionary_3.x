//
//  DD2GlobalHelper.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2GlobalHelper.h"
#import "GAITracker.h"
#import "double_metaphone.h"

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
            NSLog(@"number of matches = %lu", (unsigned long)[filteredWords count]);
            for (NSDictionary *word in sortedFilteredWords) {
                NSLog(@"found: %@", [word objectForKey:@"spelling"]);
            }
        }
        return [filteredWords count];
    }
    NSLog(@"words passed in for predicate check were not an NSArray");
    return 1;
    
}

+ (NSURL *)archiveFileDirectory
{
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSArray *possibleUrls = [localFileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL *cacheDir = [possibleUrls lastObject];
    // NSLog(@"Caches file directory: %@", cacheDir);
    return cacheDir;
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

+ (void)voiceHintDefaultSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"Voice Hint default values:");
    NSLog(@"   VOICE_HINT_AVAILABLE: %@", [defaults boolForKey:VOICE_HINT_AVAILABLE]? @"Yes" : @"No");
    NSLog(@"   NOT_USE_VOICE_HINTS: %@", [defaults boolForKey:NOT_USE_VOICE_HINTS]? @"Yes" : @"No");
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

#pragma mark - Double Metaphone Methods

+ (NSArray *)doubleMetaphoneCodesFor:(NSString *)spelling
{
    char *primarycode;
    char *secondarycode;
    DoubleMetaphone([spelling UTF8String], &primarycode, &secondarycode);
    if (PROCESS_VERBOSELY) NSLog(@"doubleMetaphone code = %s, %s", primarycode, secondarycode);
    
    NSMutableArray *doubleMetaphoneCodes = [NSMutableArray arrayWithCapacity:2];
    
    [doubleMetaphoneCodes addObject:[NSString stringWithUTF8String:primarycode]];
    
    if(![[NSString stringWithUTF8String:primarycode] isEqualToString:[NSString stringWithUTF8String:secondarycode]])
    {
        [doubleMetaphoneCodes addObject:[NSString stringWithUTF8String:secondarycode]];
        if (PROCESS_VERBOSELY) NSLog(@"doubleMetaphoneCodes ARE different");
    }
    
    return doubleMetaphoneCodes;
}

+ (NSString *)stringForDoubleMetaphoneCodesArray:(NSArray *)doubleMetaphoneCodes
{
    NSString *rtnString;
    if ([doubleMetaphoneCodes count] >1) {
        rtnString = [NSString stringWithFormat:@"%@, %@", [doubleMetaphoneCodes objectAtIndex:0],[doubleMetaphoneCodes objectAtIndex:1]];
    } else {
        rtnString = [NSString stringWithFormat:@"%@", [doubleMetaphoneCodes objectAtIndex:0]];
    }
    return rtnString;
}

+ (int)LevenshteinDistance:(NSString *)s and:(NSString *)t
{
    // http://en.wikipedia.org/wiki/Levenshtein_distance
    // ref 8 http://www.codeproject.com/Articles/13525/Fast-memory-efficient-Levenshtein-algorithm
    // licensed under http://www.codeproject.com/info/cpol10.aspx
    // degenerate cases
    if (s == t) return 0;
    if (s.length == 0) return (int)t.length;
    if (t.length == 0) return (int)s.length;
    
    // create two work vectors of integer distances
    // using plain old C arrays to avoid object type issues with NSNumber and Interger http://stackoverflow.com/questions/3340153/making-an-array-of-integers-in-objective-c
    NSInteger v0[t.length+1];
    NSInteger v1[t.length+1];
    
    // initialize v0 (the previous row of distances)
    // this row is A[0][i]: edit distance for an empty s
    // the distance is just the number of characters to delete from t
    
    for (int i = 0; i < t.length+1; i++) {
        v0[i] = i;
    }
    
    for (int i = 0; i < s.length; i++) {
        // calculate v1 (current row distances) from the previous row v0
        // first element of v1 is A[i+1][0]
        //   edit distance is delete (i+1) chars from s to match empty t
        v1[0] = i+1;
        
        // use formula to fill in the rest of the row
        for (int j = 0; j < t.length; j++) {
            int cost = ([s characterAtIndex:i] == [t characterAtIndex:j]) ? 0 : 1;
            //NSLog(@"after character compare cost = %i", cost);
            
            v1[j+1] = MIN(MIN(v1[j] + 1, v0[j+1] +1), v0[j] + cost);
            //NSLog(@"new v1[%i] = %i", j+1, v1[j+1]);
        }
        
        // copy v1 (current row) to v0 (previous row) for next iteration
        for (int j = 0; j < t.length+1; j++) {
            v0[j] = v1[j];
        }
    }
    
    //NSLog(@"Levenshtein distance between %@ and %@ = %i", s, t, v1[t.length]);
    return (int)v1[t.length];
        
}

@end
