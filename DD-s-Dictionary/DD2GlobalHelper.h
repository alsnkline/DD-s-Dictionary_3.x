//
//  DD2GlobalHelper.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PROCESS_VERBOSELY NO
#define LOG_PREDICATE_RESULTS NO          // must be NO for ship
#define TEST_APPINGTON_ON NO              // must be NO for ship
#define LOG_ANALYTICS NO                  // must be NO for ship
#define FIND_MISSING_PRONUNCIATIONS NO    // must be NO for ship
#define FIND_DUPLICATE_WORDS NO           // must be NO for ship

@interface DD2GlobalHelper : NSObject

+ (NSString*) version;
+ (NSString *) deviceType;
+ (NSArray *) alphabet;
+ (NSString *) getHexStringForColor:(UIColor *)color;
+ (NSUInteger) testWordPredicate:(NSPredicate *)predicate onWords:(id)words;
+ (NSURL *) wordlistJSONFileDirectory;
+ (NSURL *) fileURLForPronunciation:(NSString *)pronunciation;

//Analytics Methods
+ (void)sendViewToGAWithViewName:(NSString *)screenName;
+ (void)sendEventToGAWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;

//Double Metophone Methods
+ (NSArray *)doubleMetaphoneCodesFor:(NSString *)spelling;
+ (NSString *)stringForDoubleMetaphoneCodesArray:(NSArray *)doubleMetaphoneCodes;
@end
