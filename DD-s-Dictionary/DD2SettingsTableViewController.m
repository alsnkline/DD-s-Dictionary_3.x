//
//  DD2SettingsTableViewController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/21/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2SettingsTableViewController.h"
#import "NSUserDefaultKeys.h"
#import "htmlPageViewController.h"
#import "DD2AppDelegate.h"

@interface DD2SettingsTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSString *spellingVariant;
@property (nonatomic) BOOL voiceHintsAvailable;
@property (nonatomic, strong) NSIndexPath *selectedCellIndexPath;
@property (nonatomic, strong) NSNumber *customBackgroundColorHue;
@property (nonatomic, strong) NSNumber *customBackgroundColorSaturation;
@property (nonatomic, strong) UIColor *customBackgroundColor;

@property (nonatomic, strong) DD2SettingsTableViewCell *spellingVariantCell;
@property (nonatomic, strong) DD2SettingsTableViewCell *playOnSelectionCell;
@property (nonatomic, strong) DD2SettingsTableViewCell *voiceHintsCell;
@property (nonatomic, strong) DD2SettingsTableViewCell *useDyslexicFontCell;
@property (nonatomic, strong) DD2SettingsTableViewCell *backgroundColorSatCell;
@property (nonatomic, strong) DD2SettingsTableViewCell *backgroundColorHueCell;
@property (nonatomic, strong) DD2SettingsTableViewCell *versionLabelCell;


@end

@implementation DD2SettingsTableViewController
@synthesize tableView = _tableView;
@synthesize spellingVariant = _spellingVariant;
@synthesize selectedCellIndexPath = _selectedCellIndexPath;
@synthesize customBackgroundColorHue = _customBackgroundColorHue;
@synthesize customBackgroundColorSaturation = _customBackgroundColorSaturation;
@synthesize customBackgroundColor = _backgroundColor;
@synthesize collectionNames = _collectionNames;
@synthesize selectedCollections = _selectedCollections;

#define SATURATION_MULTIPLIER 10
//Saturation slider runs from 0-2 to allow me to use interger rounding - storage and UIColor calulations assume a 0-1 range, so need to / and * where appropriate by a factor to deliver two levels.

-(void)setSelectedCollections:(NSMutableArray *)selectedCollections {
    if (selectedCollections != _selectedCollections) {
        NSMutableArray *limitedSelectedCollections = [DD2SettingsTableViewController limitSelectedCollections:selectedCollections];
        _selectedCollections = limitedSelectedCollections;
    }
}

+ (NSMutableArray *) limitSelectedCollections:(NSMutableArray *)selectedCollections {
    while ([selectedCollections count]>2) {
        [selectedCollections removeObjectAtIndex:0];
        NSLog(@"removing collection to keep selection at %lu",(unsigned long)[selectedCollections count]);
    }
    return selectedCollections;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.spellingVariant = [defaults stringForKey:SPELLING_VARIANT];
    
    self.customBackgroundColorHue = [NSNumber numberWithFloat:[defaults floatForKey:BACKGROUND_COLOR_HUE]];
    self.customBackgroundColorSaturation = [NSNumber numberWithFloat:[defaults floatForKey:BACKGROUND_COLOR_SATURATION]];
    
    self.customBackgroundColor = [UIColor colorWithHue:[self.customBackgroundColorHue floatValue]  saturation:[self.customBackgroundColorSaturation floatValue] brightness:1 alpha:1];
    [self setCellBackgroundColor];
    
    self.selectedCollections = [[defaults stringArrayForKey:SELECTED_COLLECTIONS] mutableCopy];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:@"Settings Tab Shown"];
    
    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated {       //things in here so that outlets are set
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self.spellingVariant isEqualToString:@"US"]) {
        self.spellingVariantCell.smallSlider.value = 0.0;
    } else {
        self.spellingVariantCell.smallSlider.value = 1.0;
    }
    [self manageSpellingVariantLable];
    
    bool useVoiceHints = ![defaults boolForKey:NOT_USE_VOICE_HINTS]; //inverting switch logic to get default behavior to be ON
    self.voiceHintsCell.cellSwitch.on = useVoiceHints;
    
    self.playOnSelectionCell.cellSwitch.on = [defaults boolForKey:PLAY_WORDS_ON_SELECTION];
    self.useDyslexicFontCell.cellSwitch.on = [defaults boolForKey:USE_DYSLEXIE_FONT];
    
    self.backgroundColorHueCell.smallSlider.value = [self.customBackgroundColorHue floatValue];
    self.backgroundColorSatCell.smallSlider.value = [self.customBackgroundColorSaturation floatValue]*SATURATION_MULTIPLIER;
    
    [self manageBackgroundColorLable];
    
    //track starting settings with Flurry
    NSDictionary *flurryParameters = @{@"backgroundColorSaturation" : self.customBackgroundColorSaturation,
                                       @"backgroundColorInHEX" : [DD2GlobalHelper getHexStringForColor:self.customBackgroundColor],
                                       @"Font" : self.useDyslexicFontCell.cellSwitch.on ? @"Dyslexie_Font" : @"System_Font",
                                       @"PlayOnSelection" : self.playOnSelectionCell.cellSwitch.on ? @"Auto_Play" : @"Manual_Play",
                                       @"Variant" : [self.spellingVariant isEqualToString:@"US"] ? @"US" : @"UK",
                                       @"Collections" : [self stringForCurrentlySelectedCollections]};
    [Flurry logEvent:@"uiTracking_Customisations_Start" withParameters:flurryParameters];
    
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
        NSString *currentFont = self.useDyslexicFontCell.cellSwitch.on ? @"Dyslexie_Font" : @"System_Font";
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:@"Font" label:currentFont value:nil];
        
        //track event with GA to confirm final play choice
        NSString *currentPlayWordOnSelection = self.playOnSelectionCell.cellSwitch.on ? @"Auto_Play" : @"Manual_Play";
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:@"PlayOnSelection" label:currentPlayWordOnSelection value:nil];
        
        //track event with GA to confirm final spelling Variant choice
        NSString *currentVariant = [self.spellingVariant isEqualToString:@"US"] ? @"US" : @"UK";
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:@"Variant" label:currentVariant value:nil];
        
        //track event with GA to confirm final selcected collections
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiTracking_Customisations" action:@"Collections" label:[self stringForCurrentlySelectedCollections] value:nil];
        
        //track final settings with Flurry
        NSDictionary *flurryParameters = @{@"backgroundColorSaturation" : self.customBackgroundColorSaturation,
                                           @"backgroundColorInHEX" : [DD2GlobalHelper getHexStringForColor:self.customBackgroundColor],
                                           @"Font" : self.useDyslexicFontCell.cellSwitch.on ? @"Dyslexie_Font" : @"System_Font",
                                           @"PlayOnSelection" : self.playOnSelectionCell.cellSwitch.on ? @"Auto_Play" : @"Manual_Play",
                                           @"Variant" : [self.spellingVariant isEqualToString:@"US"] ? @"US" : @"UK",
                                           @"Collections" : [self stringForCurrentlySelectedCollections]};
        [Flurry logEvent:@"uiTracking_Customisations" withParameters:flurryParameters];
    }
}

- (NSString *)stringForCurrentlySelectedCollections {
    NSString *stringForReportingCollections;
    for (NSString *collection in self.selectedCollections) {
        if (!stringForReportingCollections) {
            stringForReportingCollections = [NSString stringWithString:collection];
        } else {
            stringForReportingCollections = [NSString stringWithFormat:@"%@, %@", stringForReportingCollections, collection];
        }
    }
    if (!stringForReportingCollections) stringForReportingCollections = @"None";
    return stringForReportingCollections;
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
        cell.textLabel.font = self.useDyslexicFontCell.cellSwitch ? [UIFont fontWithName:@"Dyslexiea-Regular" size:18] : [UIFont boldSystemFontOfSize:20];
    }
}

- (IBAction)playOnSelectionSwitchChanged:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:PLAY_WORDS_ON_SELECTION];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //Notify that play on selected has changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:sender.on ? @"YES" : @"NO" forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"playWordsOnSelectionChanged" object:self userInfo:userInfo];
    
    //track event with GA
    NSString *switchSetting = sender.on ? @"ON" : @"OFF";
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Setting" action:@"playOnSelectionChanged" label:switchSetting value:nil];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_playOnSelectionSwitch_%@", sender.on ? @"ON" : @"OFF"];
    [Flurry logEvent:logEventString withParameters:@{@"playOnSelectedSwitchSetting" : sender.on ? @"ON" : @"OFF"}];
}

- (IBAction)voiceHintsSwitchChanged:(UISwitch *)sender
{
    BOOL useVoiceHints = sender.on;  //inverting switch logic to get default behavior to be ON
    //NSLog(@"useVoiceHints = %i", useVoiceHints);
    //NSLog(@"NOT_USE_VOICE_HINTS = %i", !useVoiceHints);
    [[NSUserDefaults standardUserDefaults] setBool:!useVoiceHints forKey:NOT_USE_VOICE_HINTS];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //track event with GA
    NSString *switchSetting = sender.on ? @"ON" : @"OFF";
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Setting" action:@"voiceHintsSelectionChanged" label:switchSetting value:nil];
    
    //call Appington
    [self playButtonMsg:sender.on];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_voiceHintsSwitch_%@", sender.on ? @"ON" : @"OFF"];
    [Flurry logEvent:logEventString withParameters:@{@"voiceHintsSwitchSetting" : sender.on ? @"ON" : @"OFF"}];
}

- (void)playButtonMsg:(BOOL)buttonState
{
    static NSArray *buttonOnMsgs = nil;
    if (!buttonOnMsgs) buttonOnMsgs = [NSArray arrayWithObjects:@"18",@"19", nil];
    static NSArray *buttonOffMsgs = nil;
    if (!buttonOffMsgs) buttonOffMsgs = [NSArray arrayWithObjects:@"20",@"21", nil];
    
    NSArray *messages = buttonState ? buttonOffMsgs : buttonOnMsgs;
    int msgIndex = arc4random()%[messages count];
    
    // call Appington
    [Appington control:@"placement" andValues:@{@"id": [messages objectAtIndex:msgIndex]}];

}

- (IBAction)useDyslexieFontSwitchChanged:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:USE_DYSLEXIE_FONT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //Notify that the font has changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:sender.on ? @"YES" : @"NO" forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"useDyslexiFontChanged" object:self userInfo:userInfo];
    
    //track event with GA
    NSString *switchSetting = sender.on ? @"ON" : @"OFF";
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Setting" action:@"useDyslexieFontChanged" label:switchSetting value:nil];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_useDyslexieFontSwitch_%@", sender.on ? @"ON" : @"OFF"];
    [Flurry logEvent:logEventString withParameters:@{@"useDyslexieFontSwitchSetting" : sender.on ? @"ON" : @"OFF"}];
}

- (IBAction)backgroundHueSliderChanged:(UISlider *)sender
{
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:BACKGROUND_COLOR_HUE];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.customBackgroundColorHue = [NSNumber numberWithFloat:sender.value];
    [self backgroundColorChanged];
    
    //track event with GA
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Setting" action:@"backgroundColorChanged" label:@"Color Hue Changed" value:nil];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_BackgroundColorHueChanged"];
    [Flurry logEvent:logEventString withParameters:@{@"BackgroundColorHue" : [DD2GlobalHelper getHexStringForColor:self.customBackgroundColor]}];
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
    
    //track event with GA
    NSString *customBackgroundColorSaturationSetting = [NSString stringWithFormat:@"Color Saturation:%f", saturation];
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Setting" action:@"backgroundColorChanged" label:customBackgroundColorSaturationSetting value:nil];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_BackgroundColorSatChanged_%f", saturation];
    [Flurry logEvent:logEventString withParameters:@{@"BackgroundColorSat" : [NSString stringWithFormat:@"%f", saturation]}];
}

- (void) backgroundColorChanged
{
    self.customBackgroundColor = [UIColor colorWithHue:[self.customBackgroundColorHue floatValue]  saturation:[self.customBackgroundColorSaturation floatValue] brightness:1 alpha:1];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {    // in iOS7
        [DD2SettingsTableViewController manageWindowTintColor];
    }
    
    //Notify that the background color has changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.customBackgroundColor forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"customBackgroundColorChanged" object:self userInfo:userInfo];
    
    [self setCellBackgroundColor];
}

+ (void) manageWindowTintColor {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    DD2AppDelegate *appDelegate = (DD2AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL customColor = [defaults floatForKey:BACKGROUND_COLOR_SATURATION] != 0.0;
    if (!customColor) {
        appDelegate.window.tintColor = [UIColor colorWithHue:284/360.0 saturation:0.91 brightness:0.78 alpha:1];       // DD's purple
    } else {
        float hue = [defaults floatForKey:BACKGROUND_COLOR_HUE];
        appDelegate.window.tintColor = [UIColor colorWithHue:hue saturation:0.85  brightness:0.60 alpha:1];
    }
}

- (void) manageBackgroundColorLable
{
    if (self.backgroundColorSatCell.smallSlider.value == 0) {
        self.backgroundColorSatCell.label.text = [NSString stringWithFormat:@"Background color: None"];
        self.backgroundColorHueCell.bigSlider.enabled = FALSE;
    } else if (self.backgroundColorSatCell.smallSlider.value == 1) {
        self.backgroundColorSatCell.label.text = [NSString stringWithFormat:@"Background color: Some"];
        self.backgroundColorHueCell.bigSlider.enabled = TRUE;
    } else if (self.backgroundColorSatCell.smallSlider.value == 2) {
        self.backgroundColorSatCell.label.text  = [NSString stringWithFormat:@"Background color: Lots"];
        self.backgroundColorHueCell.bigSlider.enabled = TRUE;
    } else {
        self.backgroundColorSatCell.label.text  = [NSString stringWithFormat:@"Problem"];
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
    
    //NSLog (@"spelling variant = %@, %d", self.spellingVariant, sliderValue);
    [self manageSpellingVariantLable];
    
    //track event with GA
    NSString *variantSetting = [NSString stringWithFormat:@"Spelling Variant:%@", self.spellingVariant];
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Setting" action:@"spellingVariantChanged" label:variantSetting value:nil];
    
    //track switch change with Flurry
    NSString *logEventString = [NSString stringWithFormat:@"uiAction_SpellingVariantChanged_%@", self.spellingVariant];
    [Flurry logEvent:logEventString withParameters:@{@"SpellingVariant" : self.spellingVariant}];
}

- (void) manageSpellingVariantLable
{
    if ([self.spellingVariant isEqualToString:@"US"]) {
        self.spellingVariantCell.label.text = [NSString stringWithFormat:@"Spelling Variant: US"];
    } else if ([self.spellingVariant isEqualToString:@"UK"]) {
        self.spellingVariantCell.label.text = [NSString stringWithFormat:@"Spelling Variant: UK"];
    } else {
        self.spellingVariantCell.label.text  = [NSString stringWithFormat:@"Problem"];
    }
}

- (void) collectionSelectionChanged
{
    [self.tableView reloadData];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedCollections forKey:SELECTED_COLLECTIONS];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Notify that the selected Collections have changed
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.selectedCollections forKey:@"newValue"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"selectedCollectionsChanged" object:self userInfo:userInfo];
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.voiceHintsAvailable = [defaults boolForKey:VOICE_HINT_AVAILABLE];
    if (TEST_APPINGTON_ON) self.voiceHintsAvailable = YES; //for testing APPINGTON, set in DD2GlobalHelper.h
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 6;
    if (section == 1)
        return [self.collectionNames count];
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 2) {
        return @"Extras";
    } else if (section == 1) {
        return @"Word Collections";
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return 80;
    } else {
        return 0;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 2) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 60)];
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:11];
        label.text = @"Thank you - Alison\r\n\r\nCopyright © 2013 Alison Kline.\r\nAll rights reserved.";
        return label;
    } else {
        return nil;
    }
}

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DD2SettingsTableViewCell *cell;
    if (indexPath.section == 1) {
        NSString *CellIdentifier = @"Settings Collection";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        NSString *collectionForCell = [self.collectionNames objectAtIndex:indexPath.row];
        cell.label.text = [DD2Words displayNameForCollection:collectionForCell];
        if ([self.selectedCollections containsObject:collectionForCell]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        NSString *CellIdentifier = [NSString stringWithFormat:@"Settings %d %d", indexPath.section, indexPath.row ];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if ([cell isKindOfClass:[DD2SettingsTableViewCell class]]) {
            DD2SettingsTableViewCell *stvc = (DD2SettingsTableViewCell *)cell;
            if (indexPath.section == 0 && indexPath.row == 0) self.spellingVariantCell = stvc;
            if (indexPath.section == 0 && indexPath.row == 1) self.playOnSelectionCell = stvc;
            if (indexPath.section == 0 && indexPath.row == 2) {
                self.voiceHintsCell = stvc;
                stvc.hidden = !self.voiceHintsAvailable;        //hiding cell if appington voice Hints are not available.
            }
            if (indexPath.section == 0 && indexPath.row == 3) self.useDyslexicFontCell = stvc;
            if (indexPath.section == 0 && indexPath.row == 4) self.backgroundColorSatCell = stvc;
            if (indexPath.section == 0 && indexPath.row == 5) self.backgroundColorHueCell = stvc;
            if (indexPath.section == 2 && indexPath.row == 4) {
                self.versionLabelCell = stvc;
                self.versionLabelCell.label.text = [NSString stringWithFormat:@"Version: %@", [DD2GlobalHelper version]];
            }
        }
    }
    cell.backgroundColor = self.customBackgroundColor;
    return cell;
}


#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //manage the actions
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (selectedCell.tag == 10) {
        //toggle checkmark and update currently selected collection list.
        NSString *stringForTracking;
        if (selectedCell.accessoryType == UITableViewCellAccessoryCheckmark) {
            [self.selectedCollections removeObject:[self.collectionNames objectAtIndex:indexPath.row]];
            stringForTracking = [NSString stringWithFormat:@"%@_HIDE",[self.collectionNames objectAtIndex:indexPath.row]];
        } else {
            [self.selectedCollections addObject:[self.collectionNames objectAtIndex:indexPath.row]];
            self.selectedCollections = [DD2SettingsTableViewController limitSelectedCollections:self.selectedCollections];
            stringForTracking = [NSString stringWithFormat:@"%@_SHOW",[self.collectionNames objectAtIndex:indexPath.row]];
        }
        [self collectionSelectionChanged];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        
        //track event with GA
        NSString *collectionsChanged = [NSString stringWithFormat:@"collectionSelected:%@", stringForTracking];
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Setting" action:@"spellingVariantChanged" label:collectionsChanged value:nil];
        
        //track switch change with Flurry
        NSString *logEventString = [NSString stringWithFormat:@"uiAction_collectionSelected_%@", stringForTracking];
        [Flurry logEvent:logEventString withParameters:@{@"Collection Changed" : stringForTracking}];
        
    } else if (selectedCell.tag  == 21) {
        [self performSegueWithIdentifier:@"display Talk To Us" sender:selectedCell];
    } else if ([[NSArray arrayWithObjects:@"20",@"22",@"23", nil] containsObject:[@(selectedCell.tag) stringValue]]) {
        [self performSegueWithIdentifier:@"display WebView" sender:selectedCell];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //used to set up webView depending upon which item was selected.
    if ([segue.identifier isEqualToString:@"display WebView"]) {
        if ([sender isKindOfClass:[DD2SettingsTableViewCell class]]) {
            DD2SettingsTableViewCell *cell = (DD2SettingsTableViewCell *)sender;
            [segue.destinationViewController setStringForTitle:cell.textLabel.text];
            
            [segue.destinationViewController setCustomBackgroundColor:self.customBackgroundColor];
            NSFileManager *localFileManager = [[NSFileManager alloc] init];
            if (cell.tag == 23) {
                // small print selected
                NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_smallPrintv2" ofType:@"html"];
                
                if ([localFileManager fileExistsAtPath:path]) { //avoid crash if file changes and forgot to clean build :-)
                    [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
                }
            } else if (cell.tag == 22) {
                //The Dysle+ie font selected.
                NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_dysle+ie" ofType:@"html"];
                
                if ([localFileManager fileExistsAtPath:path]) { //avoid crash if file changes and forgot to clean build :-)
                    [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
                }
            } else {
                // About selected
                [segue.destinationViewController setStringForTitle:@"About"]; //overriding cell label for cleaner UI
                NSString *path = [[NSBundle mainBundle] pathForResource:@"resources.bundle/html/settings_about" ofType:@"html"];
                
                if ([localFileManager fileExistsAtPath:path]) { //avoid crash if file changes and forgot to clean build :-)
                    [segue.destinationViewController setUrlToDisplay:[NSURL fileURLWithPath:path]];
                }
            }
        }
    } else if ([segue.identifier isEqualToString:@"display Talk To Us"]){
        [segue.destinationViewController setCustomBackgroundColor:self.customBackgroundColor];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload {
    [super viewDidUnload];
}
@end

#pragma mark - DD2SettingsTableViewCell Class

@implementation DD2SettingsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end


