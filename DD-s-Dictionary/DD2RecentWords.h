//
//  DD2RecentWords.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 10/8/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSUserDefaultKeys.h"

@interface DD2RecentWords : NSObject

@property (nonatomic, strong) NSArray *recentlyViewedWords; //model for this Brain

+ (void) viewingWordNow:(NSDictionary *)word;
+ (NSArray *) currentRecentlyViewedWordList;

@end
