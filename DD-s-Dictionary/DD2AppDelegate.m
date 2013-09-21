//
//  DD2AppDelegate.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>  //for system sounds
#import <AVFoundation/AVFoundation.h> //for audioPlayer

//core data framework, systemConfiguration framework, libz.dylib added for Google Analytics

@implementation DD2AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelInfo];
        //    Log level options
        //        kGAILogLevelNone = 0,
        //        kGAILogLevelError = 1,
        //        kGAILogLevelWarning = 2,
        //        kGAILogLevelInfo = 3,
        //        kGAILogLevelVerbose = 4

    
    // Initialize tracker.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-37793922-2"];  //use -1 for any production releases
//    [[GAI sharedInstance] setOptOut:YES];       //uncomment to disable GA across entire app.
    [[GAI sharedInstance] setDryRun:YES];       //stop data from being sent to cloud, set to NO for production ship
    
    [DD2GlobalHelper sendViewToGAWithViewName:@"DD's Dictionary launched"];
    
    
    // Setting up audioSession
    [self setupAudioSession];
    [self setAudioSessionCategoryToPlayback];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)setupAudioSession
{
    //setting up the AVAudioSession and activating it.
    NSError *activationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    if (!success) {
        NSLog(@"AVAudioSession not setup %@", activationError);
    }
}

-(void)setAudioSessionCategoryToPlayback
{
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) {
        NSLog(@"AVAudioSessionCategory not set %@", setCategoryError);
    }
}


@end
