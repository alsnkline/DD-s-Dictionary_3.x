//
//  DD2TalkToUsViewController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 10/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2TalkToUsViewController.h"
#import <MessageUI/MessageUI.h>

@interface DD2TalkToUsViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation DD2TalkToUsViewController

@synthesize customBackgroundColor = _customBackgroundColor;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:@"Talk To Us Shown"];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // call Appington
    [Appington control:@"placement" andValues:@{@"id": @"26"}];
}

- (IBAction) rateInStore:(id)sender
{
    static NSString *const iOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@";
    static NSString *const iOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@";
    
    NSString * appStoreID = @"590239077";
    
    NSURL *urlToOpen = [NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? iOS7AppStoreURLFormat: iOSAppStoreURLFormat, appStoreID]];
    // Would contain the right link
    
    [[UIApplication sharedApplication] openURL:urlToOpen];
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:[NSString stringWithFormat:@"RateApp triggered"]];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_RateAppTriggered"];
    [Flurry logEvent:logEventString withParameters:@{@"Button Pressed" : @"Review us"}];
    
    // call Appington
    [Appington control:@"conversion" andValues:@{@"id": @"26"}];
}

#pragma mark - Sending an Email

- (IBAction) sendEmail: (id) sender
{
	BOOL	bCanSendMail = [MFMailComposeViewController canSendMail];
    //    BOOL	bCanSendMail = NO; //for testing the no email alert
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:[NSString stringWithFormat:@"SendEmail triggered"]];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_SendEmailTriggered"];
    [Flurry logEvent:logEventString withParameters:@{@"Button Pressed" : @"Email us"}];
    
	if (!bCanSendMail)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"No Email Account"
                                                        message: @"You must set up an email account for your device before you can send mail."
                                                       delegate: nil
                                              cancelButtonTitle: nil
                                              otherButtonTitles: @"OK", nil];
		[alert show];
	}
	else
	{
		MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        
		picker.mailComposeDelegate = self;
        
		[picker setToRecipients: [NSArray arrayWithObject: @"dydifeedback@gmail.com"]];
		[picker setSubject: @"DD's Dictionary Feedback"];
		[picker setMessageBody: [NSString stringWithFormat:@"What do you like about DD's Dictionary? \r\n\r\n What would you like to see improved? \r\n\r\n How did you find the App? \r\n\r\n Any other thoughts? \r\n\r\n\r\n\r\n Thank you so much for taking the time to give us your feedback.\r\n\r\n Best regards Alison.\r\n (from Version: %@ on an %@)",[DD2GlobalHelper version], [DD2GlobalHelper deviceType]] isHTML: NO];
        
		[self presentModalViewController: picker animated: YES];
	}
}

- (void) mailComposeController: (MFMailComposeViewController *) controller
           didFinishWithResult: (MFMailComposeResult) result
                         error: (NSError *) error
{
	[self dismissModalViewControllerAnimated: YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.view setOpaque:NO];
    self.view.backgroundColor = self.customBackgroundColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
