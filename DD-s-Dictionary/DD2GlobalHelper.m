//
//  DD2GlobalHelper.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2GlobalHelper.h"

@implementation DD2GlobalHelper

+ (NSString*) version {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@ build %@", version, build];
}

+ (NSString *) deviceType {
    return [UIDevice currentDevice].model;
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


+ (NSString *) pronunciationFromSpelling:(NSString *)spelling
{
    //turn spaces into _
    NSString *cleanString = [spelling stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    // remove apostrophe and periods sign characters
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"'."];
    NSString *cleanerString = [[cleanString componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    
    NSLog(@"clean string = %@",cleanerString);
    return [NSString stringWithString:cleanerString];
}

+ (NSSet *) pronunciationsForWord:(NSDictionary *)word;
{
    NSSet *pronunciations = [word objectForKey:@"pronunciations"];
    if (!pronunciations) {
        pronunciations = [NSSet setWithObject:[DD2GlobalHelper pronunciationFromSpelling:[word objectForKey:@"spelling"]]];
    }
    return pronunciations;
}

+ (NSSet *) homophonesForPronunciationFromWord:(NSDictionary *)word;
{
    NSSet *homophones = [word objectForKey:@"homophones"];
    
    return homophones;
}

+ (NSUInteger) testWordPredicate:(NSPredicate *)predicate onWords:(id)words
{
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    
    if ([words isKindOfClass:[NSArray class]]) {
        NSArray *nsaWords = (NSArray *)words;
        NSArray *filteredWords = [NSArray arrayWithArray:[nsaWords filteredArrayUsingPredicate:predicate]];
        NSArray *sortedFilteredWords = [filteredWords sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptors]];
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
    NSURL *bundleUrl = [[NSBundle mainBundle] bundleURL];
    NSLog(@"bundleUrl %@", bundleUrl);
    NSURL *dirUrl = [NSURL URLWithString:@"resources.bundle/audio/" relativeToURL:bundleUrl];
    NSLog(@"dirUrl = %@", dirUrl);
    NSString *pathForDirectory = dirUrl.path;
    
    //NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"wordlist.json"] relativeToURL:[DD2GlobalHelper wordlistJSONFileDirectory]];
    NSString *pathComponentForBundle = [NSString stringWithFormat:@"%@.bundle",@"resources"];
    NSString *pathForSoundName = [NSString pathWithComponents:[NSArray arrayWithObjects:pathComponentForBundle,@"audio",pronunciation, nil]];
    
    //NSString *pathForSoundName = [NSString pathWithComponents:[NSArray arrayWithObjects:pathForDirectory,pronunciation, nil]];
    NSLog(@"current pronunciation = %@", pronunciation);
    NSLog(@"pathForSoundName = %@",pathForSoundName);
    NSString *soundName = [[NSBundle mainBundle] pathForResource:pathForSoundName ofType:@"m4a"];
    NSLog(@"soundName = %@", soundName);
    
    
    NSURL *fileURL;
    if (soundName) {
        fileURL = [[NSURL alloc] initFileURLWithPath:soundName];
    }
    NSLog(@"fileURL = %@", fileURL);
    
    // Get the paths and URL's right!
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    BOOL fileFound = [localFileManager fileExistsAtPath:[fileURL path]];
    NSLog(@"fileFound for URL: %@", fileFound ? @"YES" : @"NO");
    
    if (fileFound) {
        return fileURL;
    } else {
        return nil;
    }
}

@end
