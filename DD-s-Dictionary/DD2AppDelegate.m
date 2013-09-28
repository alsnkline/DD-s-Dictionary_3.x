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

//core data framework, systemConfiguration framework, libz.dylib added for Google Analytics
//systemConfiguration framework and security framework (as we have v4.2.3), for Flurry
//coreTelephony framework and libsqlite3.dylib added for Appington

@implementation DD2AppDelegate

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
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-37793922-2"];  //use -1 for any production releases
    //[[GAI sharedInstance] setOptOut:YES];       //uncomment to disable GA across entire app.
    [[GAI sharedInstance] setDryRun:NO];       //stop data from being sent to cloud, set to NO for production ship
    //end GA setup
    
    //track screen with GA for App launch.
    [DD2GlobalHelper sendViewToGAWithViewName:@"DD's Dictionary launched"];
    
    
    //Flurry Analytics
    [Flurry setCrashReportingEnabled:NO];  //using GA for now
    //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
    [Flurry startSession:@"2SF8TKQGW6Q6D2BYXR4T"];
    //end Flurry
    
    //track app duration and active session with Flurry
    [Flurry logEvent:@"App_duration" timed:YES];
    [Flurry logEvent:@"App_initial_active" timed:YES];
    
    //Setting up audioSession
    [self setupAudioSession];
    [self setAudioSessionCategoryToPlayback];

    //Initializing Appington
    [Appington start:@"c492b8fa-0e3c-46d9-82c0-3806c0046c70"];
    
    //Register for Appington notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppingtonNotification:)
                                                 name:nil object:[Appington notificationObject]];
    
    [Appington control:@"placement" andValues:@{@"id": @"1"}];
    
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
    //track app duration with Flurry
    [Flurry endTimedEvent:@"App_initial_active" withParameters:nil];
    [Flurry endTimedEvent:@"App_active" withParameters:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //track app active session with Flurry
    [Flurry logEvent:@"App_active" timed:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    //track app duration with Flurry
    [Flurry endTimedEvent:@"App_duration" withParameters:nil];
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

- (void) onAppingtonNotification:(NSNotification*)notification {
    //NSLog(@"Appington NR: %@", [notification name]);
    NSLog(@"%@",notification);
    if ([[notification name] isEqualToString:@"audio_end"])
    {
        //track event with GA
        NSString *descriptionForNotificationObject = [[notification object] description];
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Appington" action:@"audio_end" label:descriptionForNotificationObject value:nil];
        
    }
    if ([[notification name] isEqualToString:@"audio_start"])
    {
        //track event with GA
        NSString *descriptionForNotificationObject = [[notification object] description];
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Appington" action:@"audio_start" label:descriptionForNotificationObject value:nil];
    }
    if ([[notification name] isEqualToString:@"prompts"])
    {
        NSDictionary *values=notification.userInfo;
        //NSLog(@"values coming with the notification %@", values);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        BOOL vForChangeable = [[values objectForKey:@"changeable"] boolValue];
        NSLog(@"value for 'changeable' in notification object %@", [values objectForKey:@"changeable"]);
        [defaults setBool:vForChangeable forKey:VOICE_HINT_AVAILABLE];
        
        
        BOOL vForEnabled = [[values objectForKey:@"enabled"] boolValue]; //could be used to control switch setting, currently just testing for similarity.
        NSLog(@"value for 'enable' in notification object %@", [values objectForKey:@"enabled"]);
        [defaults setBool:!vForEnabled forKey:NOT_USE_VOICE_HINTS];
        //inverting switch logic to get default behavior to be ON (although appington is controlling that, so I don't have to tell them about a default setting. Could revert to USE_VOICE_HINTS !
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
