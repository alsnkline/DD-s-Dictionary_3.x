//
//  Apptimize+Compatibility.h
//  Apptimize (v2.9.1)
//
//  Copyright (c) 2014 Apptimize, Inc. All rights reserved.
//
//  WARNING: Methods and Constants in this file should not be used in new code!
//

#ifndef __deprecated_msg
#define __deprecated_msg(_msg) __deprecated
#endif

// The following are compatibility aliases that will likely be deprecated at some point in the future and should not be used in new code.
@interface Apptimize (CompatibilityAliases)

/** @name Compatibility Aliases */

/**
 This is a compatability alias. You should prefer runTest:withBaseline:andVariations: for all new code.
 @see runExperiment:withBaseline:variations:options:
 */
+ (void)runExperiment:(NSString *)experimentName withBaseline:(void (^)(void))baselineBlock andVariations:(NSDictionary *)variations;

/**
 This is a compatability alias. You should prefer runTest:withBaseline:variations:options: for all new code.
 @see runExperiment:withBaseline:variations:options:
 */
+ (void)runExperiment:(NSString *)experimentName withBaseline:(void (^)(void))baselineBlock variations:(NSDictionary *)variations options:(NSDictionary *)options; // You should prefer runTest: for all new code.

/**
 This is a compatability alias. You should prefer metricAchieved: for all new code.
 @see metricAchieved:
 */
+ (void)goalAchieved:(NSString *)goalName;

@end



// The following constants and methods are deprecated and will be removed in a future release.

extern NSString *const ApptimizeGestureRecognizerOption __deprecated;

@interface Apptimize (Deprecated)

/**
 @deprecated Deprecated in favor of zero-line installation.
 @see http://apptimize.com/docs/getting-started-ios/step-1-installation-ios/
 */
+ (void)setUpWithApplicationKey:(NSString *)applicationKey __deprecated_msg("This method should be removed in favor of Zero-Line Installation. See http://apptimize.com/docs/getting-started-ios/step-1-installation-ios/ for more information.");
/**
 @deprecated Deprecated in favor of zero-line installation.
 @see http://apptimize.com/docs/getting-started-ios/step-1-installation-ios/
 */
+ (void)setUpWithApplicationKey:(NSString *)applicationKey options:(NSDictionary *)options __deprecated_msg("This method should be removed in favor of Zero-Line Installation. See http://apptimize.com/docs/getting-started-ios/step-1-installation-ios/ for more information.");

/**
 @deprecated Use `+[Apptimize libraryVersion]` for all new code.
 @see libraryVersion
 */
+ (NSString *)version __deprecated_msg("libraryVersion should be used for all new code.");

/**
 @deprecated Deprecated in favor of dynamic variable tests.
 @see http://apptimize.com/docs/advanced-functionality/dynamic-variables#deprecation
 */
+ (NSString *)stringForTest:(NSString *)testName defaultString:(NSString *)defaultString __deprecated_msg("This method should be removed in favor of dynamic variable tests. See http://apptimize.com/docs/advanced-functionality/dynamic-variables#deprecation for more information.");

/**
 @deprecated Deprecated in favor of dynamic variable tests.
 @see http://apptimize.com/docs/advanced-functionality/dynamic-variables#deprecation
 */
+ (NSInteger)integerForTest:(NSString *)testName defaultInteger:(NSInteger)defaultInteger __deprecated_msg("This method should be removed in favor of dynamic variable tests. See http://apptimize.com/docs/advanced-functionality/dynamic-variables#deprecation for more information.");

/**
 @deprecated Deprecated in favor of dynamic variable tests.
 @see http://apptimize.com/docs/advanced-functionality/dynamic-variables#deprecation
 */
+ (double)doubleForTest:(NSString *)testName defaultDouble:(double)defaultDouble __deprecated_msg("This method should be removed in favor of dynamic variable tests. See http://apptimize.com/docs/advanced-functionality/dynamic-variables#deprecation for more information.");

/**
 @deprecated Deprecated in favour of +track:.
 */
+ (void)metricAchieved:(NSString *)metricName __deprecated_msg("This method should be replaced with track:");

/**
 @deprecated Deprecated in favour of +track:value:.
 */
+ (void)setMetric:(NSString*)metricName toValue:(double)value __deprecated_msg("This method should be replaced with track:value:");

/**
 @deprecated Deprecated in favour of +track:value:.
 */
+ (void)addToMetric:(NSString*)metricName value:(double)value __deprecated_msg("This method should be replaced with track:value:");;

@end
