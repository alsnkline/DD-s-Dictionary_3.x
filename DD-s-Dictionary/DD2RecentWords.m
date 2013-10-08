//
//  DD2RecentWords.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 10/8/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2RecentWords.h"

@implementation DD2RecentWords

@synthesize recentlyViewedWords = _recentlyViewedWords;

- recentlyViewedWords {
    if (_recentlyViewedWords == nil) _recentlyViewedWords = [[NSArray alloc] init];
    return _recentlyViewedWords;
}

+ (void) viewingWordNow:(NSDictionary *)word{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *recentWords = [[defaults objectForKey:RECENTLY_VIEWED_WORDS_KEY] mutableCopy];
    if (!recentWords) recentWords = [NSMutableArray array];
    NSLog(@"word passed in: %@", word);
    
    if ([recentWords containsObject:word]) {
        NSLog(@"already a recent word");
        [recentWords removeObject:word];
    }
    [recentWords insertObject:word atIndex:0];
    if ([recentWords count] > 100) [recentWords removeLastObject];
    
    [defaults setObject:recentWords forKey:RECENTLY_VIEWED_WORDS_KEY];
    [defaults synchronize];
    
}


+ (NSArray *) currentRecentlyViewedWordList {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *recentlyViewedWords = [defaults objectForKey:RECENTLY_VIEWED_WORDS_KEY];
    return recentlyViewedWords;
}

@end
