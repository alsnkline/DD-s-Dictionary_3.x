//
//  DD2GlobalHelper.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PROCESS_VERBOSELY YES
#define LOG_PREDICATE_RESULTS YES       // must be NO for ship

#define TEST_APPINGTON_ON YES            // must be NO for ship

@interface DD2GlobalHelper : NSObject

+ (NSString*) version;
+ (NSString *) deviceType;
+ (NSString *) getHexStringForColor:(UIColor *)color;
+ (NSUInteger) testWordPredicate:(NSPredicate *)predicate onWords:(id)words;
+ (NSURL *) wordlistJSONFileDirectory;
+ (NSURL *) fileURLForPronunciation:(NSString *)pronunciation;

@end
