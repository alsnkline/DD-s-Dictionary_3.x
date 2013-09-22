//
//  SettingsTableViewController.m
//  DDPrototype
//
//  Created by Alison Kline on 8/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "NSUserDefaultKeys.h"
#import <MessageUI/MessageUI.h>
#import "htmlPageViewController.h"

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UISlider *spellingVariantSlider;
@property (weak, nonatomic) IBOutlet UISwitch *playOnSelectionSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *useVoiceHints;
@property (weak, nonatomic) IBOutlet UISwitch *useDyslexieFont;
@property (weak, nonatomic) IBOutlet UISlider *backgroundHueSlider;
@property (weak, nonatomic) IBOutlet UISlider *backgroundSaturationSlider;
@property (weak, nonatomic) IBOutlet UILabel *versionLable;
@property (weak, nonatomic) IBOutlet UILabel *customBackgroundColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *customSpellingVariantLabel;
@property (nonatomic, strong) NSString *spellingVariant;
@property (weak, nonatomic) IBOutlet UITableViewCell *voiceHintsTableCell;
@property (nonatomic) BOOL voiceHintsAvailable;
@property (nonatomic, strong) NSIndexPath *selectedCellIndexPath;
@property (nonatomic, strong) NSNumber *customBackgroundColorHue;
@property (nonatomic, strong) NSNumber *customBackgroundColorSaturation;
@property (nonatomic, strong) UIColor *customBackgroundColor;

@end

@implementation SettingsTableViewController
@synthesize spellingVariantSlider = _spellingVariantSlider;
@synthesize playOnSelectionSwitch = _playOnSelectionSwitch;
@synthesize useVoiceHints =_useVoiceHints;
@synthesize useDyslexieFont = _useDyslexieFont;
@synthesize backgroundHueSlider = _backgroundHueSlider;
@synthesize backgroundSaturationSlider = _backgroundSaturationSlider;
@synthesize versionLable = _versionLable;
@synthesize customBackgroundColorLabel = _customBackgroundColorLabel;
@synthesize customSpellingVariantLabel = _customSpellingVariantLabel;
@synthesize spellingVariant = _spellingVariant;
@synthesize selectedCellIndexPath = _selectedCellIndexPath;
@synthesize customBackgroundColorHue = _customBackgroundColorHue;
@synthesize customBackgroundColorSaturation = _customBackgroundColorSaturation;
@synthesize customBackgroundColor = _backgroundColor;

#define SATURATION_MULTIPLIER 10
//Saturation slider runs from 0-2 to allow me to use interger rounding - storage and UIColor calulations assume a 0-1 range, so need to / and * where appropriate by a factor to deliver two levels.

- (void)viewDidAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.spellingVariant = [defaults stringForKey:SPELLING_VARIANT];
    
    if ([self.spellingVariant isEqualToString:@"US"]) {
        self.spellingVariantSlider.value = 0.0;
    } else {
        self.spellingVariantSlider.value = 1.0;
    }
    [self manageSpellingVariantLable];
    
    self.playOnSelectionSwitch.on = [defaults boolForKey:PLAY_WORDS_ON_SELECTION];
    self.useDyslexieFont.on = [defaults boolForKey:USE_DYSLEXIE_FONT];
    
    bool useVoiceHints = ![defaults boolForKey:NOT_USE_VOICE_HINTS]; //inverting switch logic to get default behavior to be ON
    self.useVoiceHints.on = useVoiceHints;
    
    self.customBackgroundColorHue = [NSNumber numberWithFloat:[defaults floatForKey:BACKGROUND_COLOR_HUE]];
    self.customBackgroundColorSaturation = [NSNumber numberWithFloat:[defaults floatForKey:BACKGROUND_COLOR_SATURATION]];
    
    self.backgroundHueSlider.value = [self.customBackgroundColorHue floatValue];
    self.backgroundSaturationSlider.value = [self.customBackgroundColorSaturation floatValue]*SATURATION_MULTIPLIER;
    
    self.customBackgroundColor = [UIColor colorWithHue:[self.customBackgroundColorHue floatValue]  saturation:[self.customBackgroundColorSaturation floatValue] brightness:1 alpha:1];
    [self setCellBackgroundColor];
    [self manageBackgroundColorLable];
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:@"Settings Tab Shown"];
    
    [super viewDidAppear:animated];

}


- (void)viewDidDisappear:(BOOL)animated
{
    //reporting to partners only when exiting settings back to dictionary (as opposed to into small print, about, or other.
    //could be in viewWillDisappear, viewController stack seems the same.
    NSArray *viewControllers = self.navigationController.viewControllers;
//    NSLog(@"index of self on viewControllers %ld", (unsigned long)[viewControllers indexOfObject:self]); //strange this wasn't logging what I expected, always showed 0 as the settings view was first in list, but code seemed to work. http://stackoverflow.com/questions/1816614/viewwilldisappear-determine-whether-view-controller-is-being-popped-or-is-showi
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
        NSLog(@"New view controller was pushed");
    } else if ([viewControllers indexOfObject:self] == 0) {
        // View is disappearing because it was popped from the stack
        NSLog(@"View controller was popped");
        
        //track event with GA to confirm final background color for this dictionary table view
        NSString *actionForGA = [NSString stringWithFormat:@"BackgoundColor_%@", self.customBackgroundColorSaturation];
        NSString *currentColorInHEX = [DD2GlobalHelper getHexStringForColor:self.customBackgroundColor];
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:actionForGA label:currentColorInHEX value:nil];
        
        //track event with GA to confirm final font choice
        NSString *currentFont = self.useDyslexieFont.on ? @"Dyslexie_Font" : @"System_Font";
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:@"Font" label:currentFont value:nil];
        
        //track event with GA to confirm final play choice
        NSString *currentPlayWordOnSelection = self.playOnSelectionSwitch.on ? @"Auto_Play" : @"Manual_Play";
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:@"PlayOnSelection" label:currentPlayWordOnSelection value:nil];
        
        //track event with GA to confirm final spelling Variant choice
        NSString *currentVariant = [self.spellingVariant isEqualToString:@"US"] ? @"US" : @"UK";
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:@"Variant" label:currentVariant value:nil];
        
        //track final settings with Flurry
        NSDictionary *flurryParameters = @{self.customBackgroundColorSaturation : @"backgroundColorSaturation",
                                           [DD2GlobalHelper getHexStringForColor:self.customBackgroundColor] : @"backgroundColorInHEX",
                                           self.useDyslexieFont.on ? @"Dyslexie_Font" : @"System_Font" : @"Font",
                                           self.playOnSelectionSwitch.on ? @"Auto_Play" : @"Manual_Play" : @"PlayOnSelection",
                                           [self.spellingVariant isEqualToString:@"US"] ? @"US" : @"UK" : @"Variant"};
        [Flurry logEvent:@"uiTracking_Customisations" withParameters:flurryParameters];
    }
}

- (void) setCellBackgroundColor
{
    NSArray *tableCells = self.tableView.visibleCells;
    for (UITableViewCell *cell in tableCells)
    {
        cell.backgroundColor = self.customBackgroundColor;
    }

}

- (void) setCellTextLabelFont
{
    NSArray *tableCells = self.tableView.visibleCells;
    for (UITableViewCell *cell in tableCells)
    {
        cell.textLabel.font = self.useDyslexieFont ? [UIFont fontWithName:@"Dyslexiea-Regular" size:18] : [UIFont boldSystemFontOfSize:20];
    }
    
}

- (IBAction)playOnSelectionSwitchChanged:(UISwitch *)sender 
{
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:PLAY_WORDS_ON_SELECTION];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //Notify that play on selected has changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:sender.on ? @"YES" : @"NO" forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"playWordsOnSelectionChanged" object:self userInfo:userInfo];

}

- (IBAction)voiceHintsSwitchChanged:(UISwitch *)sender
{
    BOOL useVoiceHints = sender.on;  //inverting switch logic to get default behavior to be ON
    //NSLog(@"useVoiceHints = %i", useVoiceHints);
    //NSLog(@"NOT_USE_VOICE_HINTS = %i", !useVoiceHints);
    [[NSUserDefaults standardUserDefaults] setBool:!useVoiceHints forKey:NOT_USE_VOICE_HINTS];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
}


- (IBAction)useDyslexieFontSwitchChanged:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:USE_DYSLEXIE_FONT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //Notify that the font has changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:sender.on ? @"YES" : @"NO" forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"useDyslexiFontChanged" object:self userInfo:userInfo];
    
}

- (IBAction)backgroundHueSliderChanged:(UISlider *)sender
{
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:BACKGROUND_COLOR_HUE];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.customBackgroundColorHue = [NSNumber numberWithFloat:sender.value];
    [self backgroundColorChanged];

}

- (IBAction)backgroundSaturationSliderChanged:(UISlider *)sender
{
    //slider runs from 0-2 to allow me to use interger rounding - storage and UIColor calulations assume a 0-1 range, so need to /10 and *10 where appropriate to deliver 10% and 20% saturation.
    int sliderValue;
    sliderValue = lroundf(sender.value);
    [sender setValue:sliderValue animated:YES];
    
    float saturation = sender.value/SATURATION_MULTIPLIER;
    
    [[NSUserDefaults standardUserDefaults] setFloat:saturation forKey:BACKGROUND_COLOR_SATURATION];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.customBackgroundColorSaturation = [NSNumber numberWithFloat:saturation];
    [self manageBackgroundColorLable];
    [self backgroundColorChanged];
}


- (void) backgroundColorChanged
{
    self.customBackgroundColor = [UIColor colorWithHue:[self.customBackgroundColorHue floatValue]  saturation:[self.customBackgroundColorSaturation floatValue] brightness:1 alpha:1];
    
    //Notify that the background color has changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.customBackgroundColor forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"customBackgroundColorChanged" object:self userInfo:userInfo];
    
    [self setCellBackgroundColor];
    
}

- (void) manageBackgroundColorLable
{
    if (self.backgroundSaturationSlider.value == 0) {
        self.customBackgroundColorLabel.text = [NSString stringWithFormat:@"Background color: None"];
        self.backgroundHueSlider.enabled = FALSE;
    } else if (self.backgroundSaturationSlider.value == 1) {
        self.customBackgroundColorLabel.text = [NSString stringWithFormat:@"Background color: Some"];
        self.backgroundHueSlider.enabled = TRUE;
    } else if (self.backgroundSaturationSlider.value == 2) {
        self.customBackgroundColorLabel.text  = [NSString stringWithFormat:@"Background color: Lots"];
        self.backgroundHueSlider.enabled = TRUE;
    } else {
        self.customBackgroundColorLabel.text  = [NSString stringWithFormat:@"Problem"];
    }
}

- (IBAction)spellingVariantSliderChanged:(UISlider *)sender
{
    //slider runs from 0-1 to allow me to use interger rounding and be neutral re UK and US being On vs OFF.
    int sliderValue;
    sliderValue = lroundf(sender.value);
    [sender setValue:sliderValue animated:YES];
    
    self.spellingVariant = sliderValue ? [NSString stringWithFormat:@"UK"] : [NSString stringWithFormat:@"US"];
    [[NSUserDefaults standardUserDefaults] setObject:self.spellingVariant forKey:SPELLING_VARIANT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Notify that the spellingVariant has changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.spellingVariant forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spellingVariantChanged" object:self userInfo:userInfo];
    
    NSLog (@"spelling variant = %@, %d", self.spellingVariant, sliderValue);
    [self manageSpellingVariantLable];
}

- (void) manageSpellingVariantLable
{
    if ([self.spellingVariant isEqualToString:@"US"]) {
        self.customSpellingVariantLabel.text = [NSString stringWithFormat:@"Spelling Variant: US"];
    } else if ([self.spellingVariant isEqualToString:@"UK"]) {
        self.customSpellingVariantLabel.text = [NSString stringWithFormat:@"Spelling Variant: UK"];
    } else {
        self.customSpellingVariantLabel.text  = [NSString stringWithFormat:@"Problem"];
    }
}



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.versionLable.text = [NSString stringWithFormat:@"Version: %@", [DD2GlobalHelper version]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.voiceHintsAvailable = [defaults boolForKey:VOICE_HINT_AVAILABLE];
    
    if (TEST_APPINGTON_ON) self.voiceHintsAvailable = YES; //for testing APPINGTON, set in DD2GlobalHelper.h
    
    if (self.voiceHintsAvailable) {
        self.voiceHintsTableCell.hidden = NO;
    } else {
        self.voiceHintsTableCell.hidden = YES;
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [self setPlayOnSelectionSwitch:nil];
    [self setVersionLable:nil];
    [self setVoiceHintsTableCell:nil];
    [self setUseVoiceHints:nil];
    [self setSpellingVariant:nil];
    [self setCustomSpellingVariantLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    
//    // Configure the cell...
//    
//    return cell;
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL voiceHintsRow = FALSE;
    if ([[NSIndexPath class] respondsToSelector:@selector(indexPathForItem:inSection:)]) {
        // we are in an iOS 6.0 device and can use cell position to test for which row is being asked about.
        if ([indexPath isEqual:[NSIndexPath indexPathForItem:2 inSection:0]]) voiceHintsRow = TRUE;
    } else {
        // we are in an iOS 5.0, 5.1 or 5.1.1 device
        if (indexPath.section == 0 && indexPath.row == 2) voiceHintsRow = TRUE;
    }

    if (voiceHintsRow && !self.voiceHintsAvailable) {
        return 0;
    } else {
        return 45;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = self.customBackgroundColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Indexpath of Selected Cell = %@", indexPath);
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    self.selectedCellIndexPath = indexPath;
    NSLog(@"selectedCell Tag = %d", selectedCell.tag);
    if (selectedCell.tag  == 3) {
       // http://stackoverflow.com/questions/3124080/app-store-link-for-rate-review-this-app - extend to encourage app store reviews
        [self sendEmail:selectedCell];
    } else if (selectedCell.tag == 1) {
        [self performSegueWithIdentifier:@"display WebView" sender:selectedCell];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //used to set up webView depending upon which item was selected.
    if ([segue.identifier isEqualToString:@"display WebView"]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            [segue.destinationViewController setStringForTitle:cell.textLabel.text];
            NSLog(@"IndexPath of selectedcell = %@", self.selectedCellIndexPath);
            NSLog(@"Cell Lable = %@", cell.textLabel.text);
            
            
            NSInteger switchValue;
            
            if ([[NSIndexPath class] respondsToSelector:@selector(indexPathForItem:inSection:)]) {
                // we are in an iOS 6.0 device and can use cell position to test for what was selected.
                if ([self.selectedCellIndexPath isEqual:[NSIndexPath indexPathForItem:0 inSection:2]]) {
                    switchValue = 0; //About
                } else if ([self.selectedCellIndexPath isEqual:[NSIndexPath indexPathForItem:3 inSection:2]]) {
                    switchValue = 1; //Small Print
                } else if ([self.selectedCellIndexPath isEqual:[NSIndexPath indexPathForItem:1 inSection:2]]) {
                    switchValue = 2; //The Dysle+ie font
                } else {
                    switchValue = 3;
                }
            } else {
                // we are in an iOS 5.0, 5.1 or 5.1.1 device
                if ([cell.textLabel.text isEqualToString:@"About Dy-Di"]) {
                    switchValue = 0; //About
                } else if ([cell.textLabel.text isEqualToString:@"Small Print"]) {
                    switchValue = 1; //Small Print
                } else if ([cell.textLabel.text isEqualToString:@"The Dysle+ie font"]) {
                    switchValue = 2; //Small Print
                } else {
                    switchValue = 3;
                }
            }
            
            NSFileManager *localFileManager = [[NSFileManager alloc] init];
            [segue.destinationViewController setCustomBackgroundColor:self.customBackgroundColor];  //set up background color for all.
            switch (switchValue) {
                case 0: {
                    //set up about page
                    [segue.destinationViewController setStringForTitle:@"About"]; //overriding cell label for cleaner UI
                    NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_about" ofType:@"html"];
                    
                    if ([localFileManager fileExistsAtPath:path]) { //avoid crash if file changes and forgot to clean build :-)
                        [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
                    }
                    break;
                }
                case 1: {
                    //small print selected.
                    NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_smallPrintv2" ofType:@"html"];
                    
                    if ([localFileManager fileExistsAtPath:path]) { //avoid crash if file changes and forgot to clean build :-)
                        [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
                    }
                    break;
                }
                case 2: {
                    //The Dysle+ie font selected.
                    NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_dysle+ie" ofType:@"html"];
                    
                    if ([localFileManager fileExistsAtPath:path]) { //avoid crash if file changes and forgot to clean build :-)
                        [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
                    }
                    break;
                }

                default:
                    NSLog(@"not resolved which cell was pressed on settings page");
                    break;
            }
            
//        if ([self.selectedCellIndexPath isEqual:[NSIndexPath indexPathForItem:0 inSection:2]]) { //NSIndexPath indexPathForItem: inSection: is triggering selector not found error in iOS 5.0 and 5.1
            // check out http://stackoverflow.com/questions/3862933/check-ios-version-at-runtime for another way to avoid the crash but run the better code where possible
//            if ([cell.textLabel.text isEqualToString:@"About Dy-Di"]) {
//            //about needed
//            [segue.destinationViewController setStringForTitle:@"About"]; //overriding cell label for cleaner UI
//            NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_about" ofType:@"html"];
//            [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
//            
//            
////        } else if ([self.selectedCellIndexPath isEqual:[NSIndexPath indexPathForItem:2 inSection:2]]) {
//            } else if ([cell.textLabel.text isEqualToString:@"Small Print"]) {
//            //small print selected.
//            NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_smallPrint" ofType:@"html"];
//            [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
//            }
        }
    }
}


#pragma mark - Sending an Email

- (IBAction) sendEmail: (id) sender
{
	BOOL	bCanSendMail = [MFMailComposeViewController canSendMail];
//    BOOL	bCanSendMail = NO; //for testing the no email alert
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:[NSString stringWithFormat:@"SendEmail triggered"]];

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
		[picker setSubject: @"Dy-Di Feedback"];
		[picker setMessageBody: [NSString stringWithFormat:@"What do you like about Dy-Di? \r\n\r\n What would you like to see improved? \r\n\r\n What new features would be key for you? \r\n\r\n Any other thoughts? \r\n\r\n\r\n\r\n Thank you so much for taking the time to give us your feedback.\r\n\r\n Best regards Alison.\r\n (from Version: %@ on an %@)",[DD2GlobalHelper version], [DD2GlobalHelper deviceType]] isHTML: NO];
        
		[self presentModalViewController: picker animated: YES];
	}
    [self.tableView deselectRowAtIndexPath:self.selectedCellIndexPath animated:YES];
}

- (void) mailComposeController: (MFMailComposeViewController *) controller
           didFinishWithResult: (MFMailComposeResult) result
                         error: (NSError *) error
{
	[self dismissModalViewControllerAnimated: YES];
}


@end
