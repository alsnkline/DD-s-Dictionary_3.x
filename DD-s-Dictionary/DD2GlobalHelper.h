//
//  DD2GlobalHelper.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOG_MORE NO                      // must be NO for ship
#define PROCESS_VERBOSELY NO              // must be NO for ship
#define LOG_PREDICATE_RESULTS NO          // must be NO for ship
#define LOG_ANALYTICS NO                  // must be NO for ship
#define FIND_MISSING_PRONUNCIATIONS NO    // must be NO for ship
#define FIND_DUPLICATE_WORDS NO           // must be NO for ship
#define PROCESS_ON_BUILD NO               // must be NO for ship

#define APPTIMIZE_NON_PRODUCTION YES         // must be NO for ship

#define NO_GA YES                            // must be NO for ship
#define LOG_VOICE_HINTS NO                    // should be NO for ship

#define ENABLE_VOICE_HINTS NO              // should be NO for ship (until feature is reimplemented) - only sets on first app launch

@interface DD2GlobalHelper : NSObject

+ (NSString*) version;
+ (NSString *) deviceType;
+ (NSArray *) alphabet;
+ (NSString *) getHexStringForColor:(UIColor *)color;
+ (NSUInteger) testWordPredicate:(NSPredicate *)predicate onWords:(id)words;
+ (NSURL *) archiveFileDirectory;
+ (NSURL *) wordlistJSONFileDirectory;
+ (NSURL *) fileURLForPronunciation:(NSString *)pronunciation;
+ (void) printVoiceHintSettings;

//Analytics Methods
+ (void)sendViewToGAWithViewName:(NSString *)screenName;
+ (void)sendEventToGAWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;

//Double Metophone Methods
+ (NSArray *)doubleMetaphoneCodesFor:(NSString *)spelling;
+ (NSString *)stringForDoubleMetaphoneCodesArray:(NSArray *)doubleMetaphoneCodes;

//LevenshteinDistance Method
+ (int)LevenshteinDistance:(NSString *)s and:(NSString *)t;
@end
