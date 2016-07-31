//
//  DD2AppDelegate.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2AppDelegate.h"
#import "DD2SettingsTableViewController.h"
#import <AudioToolbox/AudioToolbox.h>  //for system sounds
#import <AVFoundation/AVFoundation.h> //for audioPlayer
#import <Apptimize/Apptimize.h>

//core data framework, systemConfiguration framework, libz.dylib added for Google Analytics
//CFNetwork and security framework for Apptimize
//coreTelephony framework and libsqlite3.dylib added for Appington

@interface DD2AppDelegate ()
@property (strong, nonatomic) NSTimer *tipPlayTimer;
@end


@implementation DD2AppDelegate
@synthesize tipPlayTimer = _tipPlayTimer;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   // Override point for customization after application launch.
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {    // in iOS7
        [DD2SettingsTableViewController manageWindowTintColor];
    }
    
    //Google Analytics
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

    
    // Initialize GA tracker.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-37793922-1"];  //use -1 for any production releases
    if (NO_GA) {
        [[GAI sharedInstance] setOptOut:YES];   //run statement to disable GA across entire app. Comment out for SHIP
    }
    [[GAI sharedInstance] setDryRun:NO_GA];       //stop data from being sent to cloud, set to NO for production ship
    //end GA setup
    
    //track screen with GA for App launch.
    [DD2GlobalHelper sendViewToGAWithViewName:@"DD's Dictionary launched"];

    
    //setting up Apptimize
    if (APPTIMIZE_NON_PRODUCTION) {
        [Apptimize startApptimizeWithApplicationKey:@"CMF7bsBFzh95sQgtwgeQXheHamsdeAs"];
    } else {
        [Apptimize startApptimizeWithApplicationKey:@"CMF7bsBFzh95sQgtwgeQXheHamsdeAs"];
    }
    
    //Setting up audioSession
    [self setupAudioSession];
    [self setAudioSessionCategoryToPlayback];
    
    //Voice hints
    //VOICE_HINT_AVAILABLE controls if voice hints are available in the app.
    //availability via VOICE_HINT_AVAILABLE was controled by a notification from Appington since Kiuas the key notification doesn't come, so app stopped showing the voice hint button early in 2014.
    //setting voice hints availability now no appington
    BOOL voiceHintAvailable = [[NSUserDefaults standardUserDefaults] boolForKey:VOICE_HINT_AVAILABLE];
    BOOL notUseVoiceHints = [[NSUserDefaults standardUserDefaults] boolForKey:NOT_USE_VOICE_HINTS];
    if (!voiceHintAvailable && !notUseVoiceHints) {
        //set up the default for the first time
        NSLog(@"defaulting Voice_Hint_Available to: %@", ENABLE_VOICE_HINTS ? @"Yes" : @"No");
        [[NSUserDefaults standardUserDefaults] setBool:ENABLE_VOICE_HINTS forKey:VOICE_HINT_AVAILABLE];
        [[NSUserDefaults standardUserDefaults] setBool:!ENABLE_VOICE_HINTS forKey:NOT_USE_VOICE_HINTS];
        //turn off hints if feature isn't available and on if it is
        NSLog(@"defaulting Not_Use_Voice_Hints to: %@", !ENABLE_VOICE_HINTS ? @"Yes" : @"No");
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if (LOG_VOICE_HINTS) [DD2GlobalHelper printVoiceHintSettings];
    
    //default behavior is on
    if(![[NSUserDefaults standardUserDefaults] boolForKey:NOT_USE_VOICE_HINTS]) {
        // play welcome voice message (files AK_dds_1_1.m4a, AK_dds_1_2.m4a)
        // appington id 1
        if (LOG_VOICE_HINTS) NSLog(@"Play welcome voice message");
    }
    
    //timer for tip controls
    self.tipPlayTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(playTip) userInfo:Nil repeats:NO];
    
    return YES;
}

- (void)playTip
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:NOT_USE_VOICE_HINTS]) {
        // play tip voice message (placement id 27) file one of the 2's or 7_1 about the fun tab?
        // appington id 27
        if (LOG_VOICE_HINTS) NSLog(@"Play start up tip voice message");
    }
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
