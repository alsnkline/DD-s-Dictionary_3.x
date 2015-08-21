//
//  DisplayWordViewController.m
//  DDPrototype
//
//  Created by Alison Kline on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DisplayWordViewController.h"
#import <AudioToolbox/AudioToolbox.h>  //for system sounds
#import <AVFoundation/AVFoundation.h> //for audioPlayer
#import "NSUserDefaultKeys.h"
#import <QuartzCore/QuartzCore.h>

@interface DisplayWordViewController () <AVAudioPlayerDelegate>

@property (nonatomic, strong) UIBarButtonItem *splitViewBarButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;        //not actually used as split view controller forced to show master all the time.
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSArray *soundsToPlay;

@end

@implementation DisplayWordViewController
@synthesize word = _word;
@synthesize hasOtherVariantWord = _hasOtherVariantWord;
@synthesize homophonesForWord = _homophonesForWord;
@synthesize playWordsOnSelection = _playWordsOnSelection;
@synthesize useDyslexieFont = _useDyslexieFont;
@synthesize customBackgroundColor = _customBackgroundColor;
@synthesize delegate = _delegate;
@synthesize spelling = _spelling;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize toolbar = _toolbar;
@synthesize listenButton = _listenButton;
@synthesize heteronymListenButton = _heteronymListenButton;
@synthesize wordView = _wordView;
@synthesize homophoneButtons = _homophoneButtons;
@synthesize homophoneButton1 = _homophoneButton1;
@synthesize homophoneButton2 = _homophoneButton2;
@synthesize homophoneButton3 = _homophoneButton3;
@synthesize homophoneButton4 = _homophoneButton4;
@synthesize homophoneButton5 = _homophoneButton5;
@synthesize homophoneButton6 = _homophoneButton6;
@synthesize usukVariantSegmentedControl = _usukVariantSegmentedControl;
@synthesize usukVariantButton = _usukVariantButton;
@synthesize spellingToClipboardButton = _spellingToClipboardButton;
@synthesize audioPlayer = _audioPlayer;
@synthesize soundsToPlay = _soundsToPlay;

#define StringFromBOOL(b) ((b) ? @"YES" : @"NO")

ApptimizeBoolean(useUsukFlagIcons, NO);
ApptimizeBoolean(hideCopySpellingToClipboardButton, NO);

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
    
}

// setup of audioSession and audioSessionCategory moved to AppDelegate to enable Appington interation.


-(void)setWord:(NSDictionary *)word
{
    if (_word != word) {
        _word = word;
        [DD2Words viewingWordNow:_word];
        if ([self getSplitViewWithDisplayWordViewController]) {
            [self setUpViewForWord:word];       //used for iPad in iPhone outlets not set yet
        }
    }
}

-(NSArray *)homophoneButtons {      //needed as iOS 5 doesn't support IBOutletCollection populating property if is wasn't done automatically.
    if (!_homophoneButtons) {
        _homophoneButtons = [NSArray arrayWithObjects:self.homophoneButton1, self.homophoneButton2, self.homophoneButton3, self.homophoneButton4, self.homophoneButton5, self.homophoneButton6, nil];
    }
    return _homophoneButtons;
}

-(void)setCustomBackgroundColor:(UIColor *)customBackgroundColor
{
    if (_customBackgroundColor != customBackgroundColor) {
        _customBackgroundColor = customBackgroundColor;
        
        self.view.backgroundColor = self.customBackgroundColor;
        NSArray *myListenButtons = [NSArray arrayWithObjects:self.listenButton, self.heteronymListenButton, nil];
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {    //not in iOS7
            [self setColorOfButtons:myListenButtons toColor:self.customBackgroundColor areHomophoneButtons:NO];  // part of the iOS 7 problem!
            [self setColorOfButtons:self.homophoneButtons toColor:self.customBackgroundColor areHomophoneButtons:YES];
        }
    }
}

-(void)setUseDyslexieFont:(BOOL)useDyslexieFont
{
    if(_useDyslexieFont != useDyslexieFont) {
        _useDyslexieFont = useDyslexieFont;
        
        int spellingFontsize = 55; //setting for iphone
        if ([self getSplitViewWithDisplayWordViewController]) spellingFontsize = 140;   //setting for ipad
        
        if (self.useDyslexieFont) {
            [self.spelling setFont:[UIFont fontWithName:@"Dyslexiea-Regular" size:spellingFontsize]];
            UIFont *font = [UIFont fontWithName:@"Dyslexiea-Regular" size:25];
            for (UIButton * button in self.homophoneButtons) {
                button.titleLabel.font = font;
            }
        } else {
            [self.spelling setFont:[UIFont systemFontOfSize:spellingFontsize]];
            UIFont *font = [UIFont boldSystemFontOfSize:30];
            for (UIButton * button in self.homophoneButtons) {
                button.titleLabel.font = font;
            }
        }
    }
}

-(void)setHomophonesForWord:(NSDictionary *)homophonesForWord {
    if (_homophonesForWord != homophonesForWord) {
        _homophonesForWord = homophonesForWord;
        if(LOG_MORE) NSLog(@"homophonesForWord set to %@", homophonesForWord);
    }
}

-(void)setUpViewForWord:(NSDictionary *)word
{
    NSString *forDisplay;
    if (word) {
        [self manageListenButtons];
        
        NSLog(@"Enrolled Tests: %@",[Apptimize testInfo]);
        NSLog(@"hideCopySpellingToClipboardButton = %@", StringFromBOOL([hideCopySpellingToClipboardButton boolValue]));
        NSLog(@"useUsukFlagIcons = %@", StringFromBOOL([useUsukFlagIcons boolValue]));
        
        self.spellingToClipboardButton.hidden = [hideCopySpellingToClipboardButton boolValue];
        
        if (self.hasOtherVariantWord) {
            if ([useUsukFlagIcons boolValue]) {
                    self.usukVariantButton.hidden = NO;
                    self.usukVariantSegmentedControl.hidden = YES;
                } else {
                    self.usukVariantButton.hidden = YES;
                    self.usukVariantSegmentedControl.hidden = NO;
                }
            NSString *variant = [word objectForKey:@"wordVariant"];
            if ([variant isEqualToString:@"uk"]) {
                //select the UK variant
                [self.usukVariantButton setImage:[UIImage imageNamed:@"resources.bundle/Images/UK_front_35x32.png"] forState:UIControlStateNormal];
                self.usukVariantSegmentedControl.selectedSegmentIndex = 0;
            } else {
                //select the US variant
                [self.usukVariantButton setImage:[UIImage imageNamed:@"resources.bundle/Images/US_front_35x32.png"] forState:UIControlStateNormal];
                self.usukVariantSegmentedControl.selectedSegmentIndex = 1;
            }
        } else {
            self.usukVariantButton.hidden = YES;
            self.usukVariantSegmentedControl.hidden = YES;
        }
        forDisplay = [word objectForKey:@"spelling"];
    } else {
        [self resetView];
        forDisplay = @"pick a word";
    }
    [UIView transitionWithView:self.wordView duration:.2 options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ {
                        self.spelling.text = forDisplay;
                    }
                    completion:nil];
    if (self.isViewLoaded && self.view.window) {
        //viewController is visible track with GA allowing iPad stats to show which word got loaded.
        [DD2GlobalHelper sendViewToGAWithViewName:[NSString stringWithFormat:@"Viewed Word :%@", self.spelling.text]];
        
        //track word view with Flurry
        NSDictionary *flurryParameters = @{@"Viewed Word": self.spelling.text};
        [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
        
        //track word view with Apptimize
        [Apptimize track:@"Viewed Word" value:1] ;
    }
}

- (void) resetView {
    for (UIButton * button in self.homophoneButtons) {
        button.hidden = YES;
    }
    self.listenButton.hidden = YES;
    self.heteronymListenButton.hidden = YES;
    self.usukVariantSegmentedControl.hidden = YES;
    self.usukVariantButton.hidden = YES;
    self.spellingToClipboardButton.hidden = YES;
}

- (void) manageListenButtons
{
    NSSet *pronunciations = [DD2Words pronunciationsForWord:self.word];
    
    if ([pronunciations count] == 1) {
        NSArray *buttonsToHide = [NSArray arrayWithObjects:self.heteronymListenButton, self.homophoneButton4, self.homophoneButton5, self.homophoneButton6, nil];
        for (UIButton *button in buttonsToHide) {
            button.hidden = YES;
        };
        self.listenButton.hidden = NO;
        //iOS7 only
        //[self.listenButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]; doesn't work!
        
        self.listenButton.frame = CGRectMake((self.listenButton.superview.frame.size.width/2 - self.listenButton.frame.size.width/2), self.listenButton.frame.origin.y, self.listenButton.frame.size.width, self.listenButton.frame.size.height);
        
        NSString *pronunciation = [[pronunciations allObjects] lastObject];
        NSURL *fileURL = [DD2GlobalHelper fileURLForPronunciation:pronunciation];
        fileURL? (self.listenButton.enabled = YES) : (self.listenButton.enabled = NO);
                
        [self manageHomophonesOfPronunciation:pronunciation withButtons:[NSArray arrayWithObjects:self.homophoneButton1, self.homophoneButton2, self.homophoneButton3, nil]  underListenButton:self.listenButton];
        
    } else if ([pronunciations count] == 2) {
        self.heteronymListenButton.hidden = NO;
        self.listenButton.hidden = NO;
        
        self.listenButton.frame = CGRectMake(56, self.listenButton.frame.origin.y, self.listenButton.frame.size.width, self.listenButton.frame.size.height);
        
        for (NSString *pronunciation in pronunciations) {
            NSURL *fileURL = [DD2GlobalHelper fileURLForPronunciation:pronunciation];
            if ([pronunciation hasSuffix:[NSString stringWithFormat:@"1"]]) {
                fileURL? (self.listenButton.enabled = YES) : (self.listenButton.enabled = NO);
                [self manageHomophonesOfPronunciation:pronunciation withButtons:[NSArray arrayWithObjects:self.homophoneButton1, self.homophoneButton2, self.homophoneButton3, nil] underListenButton:self.listenButton];
            }
            if ([pronunciation hasSuffix:[NSString stringWithFormat:@"2"]]) {
                fileURL? (self.heteronymListenButton.enabled = YES) : (self.heteronymListenButton.enabled = NO);
                [self manageHomophonesOfPronunciation:pronunciation withButtons:[NSArray arrayWithObjects:self.homophoneButton4, self.homophoneButton5, self.homophoneButton6, nil] underListenButton:self.heteronymListenButton];
            }
        }
    } else {
        self.listenButton.enabled = NO;
    }
}

    
- (void) manageHomophonesOfPronunciation:(NSString *)pronunciation withButtons:(NSArray *)buttons underListenButton:(UIButton *)listenbutton
{
    for (int i = 0; i < [[self.homophonesForWord objectForKey:pronunciation] count]; i++) {
        UIButton *buttonForLoop = [buttons objectAtIndex:i];
        buttonForLoop.hidden = NO;
        
        NSArray *homophoneWords = [self.homophonesForWord objectForKey:pronunciation];
        [buttonForLoop setTitle:[[homophoneWords objectAtIndex:i] objectForKey:@"spelling" ] forState:UIControlStateNormal];

        [self sizeHomophoneButton:buttonForLoop];
        CGRect frame = CGRectMake(listenbutton.frame.origin.x - (buttonForLoop.frame.size.width/2 - listenbutton.frame.size.width/2), buttonForLoop.frame.origin.y, buttonForLoop.frame.size.width, buttonForLoop.frame.size.height);
        buttonForLoop.frame = frame;
    }
    for (NSUInteger i = [[self.homophonesForWord objectForKey:pronunciation] count]; i < [buttons count]; i++) {
        UIButton *buttonForLoop = [buttons objectAtIndex:i];
        buttonForLoop.hidden = YES;
    }
}

-(void) sizeHomophoneButton:(UIButton *)button
{
    // set background image of all buttons
    CGFloat spacingBetweenImageAndText = 2;
    CGFloat spacingToTop = 0;
    CGFloat spacingToBottom = 0;
    if (self.useDyslexieFont) {
        spacingToBottom = -3;
        spacingToTop = 3;
    }
    
    [button sizeToFit];
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {    //not in iOS7
        CGRect buttonFrame = button.frame;
    //    NSLog(@"button size from bounds = h%f w%f", button.bounds.size.height, button.bounds.size.width);
        buttonFrame.size = CGSizeMake(button.frame.size.width, 43); //forcing button height as backgroud image seems to make it large
        button.frame = buttonFrame;
        
    //    NSLog(@"titleLabel = %f, %f", button.titleLabel.bounds.size.width, button.titleLabel.bounds.size.height);
    //    NSLog(@"button bounds = %f, %f", button.bounds.size.width, button.bounds.size.height);
    //    NSLog(@"image bounds = %f, %f", button.imageView.bounds.size.width, button.imageView.bounds.size.height);
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacingBetweenImageAndText);
        button.titleEdgeInsets = UIEdgeInsetsMake(spacingToTop, spacingBetweenImageAndText, spacingToBottom, 0);
    }
}

- (void) setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    if (_splitViewBarButtonItem != splitViewBarButtonItem) {
        NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
        if (_splitViewBarButtonItem) [toolbarItems removeObject:_splitViewBarButtonItem];
        if (splitViewBarButtonItem) [toolbarItems insertObject:splitViewBarButtonItem atIndex:0];
        self.toolbar.items = toolbarItems;
        _splitViewBarButtonItem = splitViewBarButtonItem;
    }
}

- (BOOL)splitViewController:(UISplitViewController *)svc 
   shouldHideViewController:(UIViewController *)vc 
              inOrientation:(UIInterfaceOrientation)orientation
{
//    return UIInterfaceOrientationIsPortrait(orientation);
    return NO;
}

- (void)splitViewController:(UISplitViewController *)svc 
     willHideViewController:(UIViewController *)aViewController 
          withBarButtonItem:(UIBarButtonItem *)barButtonItem 
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = @"Dictionary";    //need to localise
    self.splitViewBarButtonItem = barButtonItem;
}

-(void)splitViewController:(UISplitViewController *)svc 
    willShowViewController:(UIViewController *)aViewController 
 invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.splitViewBarButtonItem = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)playAllWords:(NSSet *)pronunciations
{
    if ([pronunciations count] == 1) {
        for (NSString *pronunciation in pronunciations) {
            [self playWord:pronunciation];
            
            //track word event with GA auto sent with Value 2
            [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"listenToWord" label:pronunciation value:[NSNumber numberWithInt:2]];
            
            //track word view with Flurry
            NSDictionary *flurryParameters = @{@"listenToWord" : pronunciation,
                                               @"wordPlayMode" : @"Auto_Play"};
            [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
        };
    } else {
        NSMutableArray *pronunciationsArray = [[pronunciations allObjects] mutableCopy];
        self.soundsToPlay = pronunciationsArray;
        NSLog(@"started to play first word");
        NSString *pronunciationToPlay = [self.soundsToPlay lastObject];
        [self playWord:pronunciationToPlay];
        
        //track word event with GA auto sent with Value 2
        [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"listenToWord" label:[pronunciationsArray lastObject] value:[NSNumber numberWithInt:2]];
        
        //track word view with Flurry
        NSDictionary *flurryParameters = @{@"listenToWord" : [pronunciationsArray lastObject],
                                           @"wordPlayMode" : @"Auto_Play"};
        [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
    }
    
}


- (void)playWord:(NSString *)pronunciation
{
    // can't use system sounds as needs a .caf or .wav - too big.
    
    NSURL *fileURL = [DD2GlobalHelper fileURLForPronunciation:pronunciation];
    
    NSError *error = nil;
    AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    self.audioPlayer = newPlayer;
    
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer setDelegate:self];
    NSLog(@"started to play a word");
    [self.audioPlayer play];
    
    
}

- (IBAction)listenToWord:(UIButton *)sender 
{   

    NSSet *pronunciations = [DD2Words pronunciationsForWord:self.word];
    
    for (NSString *pronunciation in pronunciations) {
        
        if (([pronunciations count] > 1 && [pronunciation hasSuffix:[NSString stringWithFormat:@"%li",(long)sender.tag]]) || ([pronunciations count] == 1)) {
            [self playWord:pronunciation];
            
            //track word event with GA manual sent with Value 1
            [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"listenToWord" label:pronunciation value:[NSNumber numberWithInt:1]];
            
            //track word view with Flurry
            NSDictionary *flurryParameters = @{@"listenToWord" : pronunciation,
                                               @"wordPlayMode" : @"Manual_Play"};
            [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
        }
    }
}


- (IBAction)homophoneButtonPressed:(UIButton *)sender 
{
    NSString *spelling = sender.titleLabel.text;
    
    //track word event with GA manual sent with Value 1
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"homophoneButtonPressed" label:spelling value:[NSNumber numberWithInt:1]];
    
    //track word view with Flurry
    NSDictionary *flurryParameters = @{@"homophoneButtonPressed" : spelling};
    [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
    
    NSSet *pronunciations = [DD2Words pronunciationsForWord:self.word];
    NSMutableArray *allHomophones = [[NSMutableArray alloc] init];
    for (NSString *pronunciation in pronunciations) {
        [allHomophones addObjectsFromArray:[self.homophonesForWord objectForKey:pronunciation]];
    }
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling LIKE[c] %@",spelling];
    if (LOG_PREDICATE_RESULTS) {
        NSLog(@"Searching in homophoneButtonPressed");
        NSLog(@"predicate = %@", selectionPredicate);
        [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:allHomophones];
    }
    NSArray *matches = [NSArray arrayWithArray:[allHomophones filteredArrayUsingPredicate:selectionPredicate]];
    if ([matches count] != 1) NSLog(@"DisplayWordVC more or less than one matches ** PROBLEM **");
    
    //send to delegate
    [self.delegate DisplayWordViewController:self homophoneSelected:[matches lastObject]];
}

- (IBAction)usukVariantSegmentedControlPressed:(UISegmentedControl *)sender {
    //track word event with GA manual sent with Value 1
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"usukVariantPressed" label:self.spelling.text value:nil];
    
    //track word view with Flurry
    NSDictionary *flurryParameters = @{@"usukVariantPressed" : self.spelling.text};
    [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
    
    NSString *selection = sender.selectedSegmentIndex ? @"us" : @"uk";
    [self usukChangeMadeWithSelection:selection];
}

- (IBAction)usukVariantButtonPressed:(UIButton *)sender {
    //track word event with GA manual sent with Value 1
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"usukVariantPressed" label:self.spelling.text value:nil];
    
    //track word view with Flurry
    NSDictionary *flurryParameters = @{@"usukVariantPressed" : self.spelling.text};
    [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
    
    NSString *selection;
    if ([[self.word objectForKey:@"wordVariant"] isEqualToString:@"us"]) {
        selection = @"uk";
    } else {
        selection = @"us";
    }
    [self usukChangeMadeWithSelection:selection];
}

- (void) usukChangeMadeWithSelection:(NSString *)selection {
    //report to Apptimize
    if (LOG_MORE) NSLog(@"Other Word selected show '%@' variant", selection);
    [Apptimize track:@"usukChangeMade" value:1];
    [self.delegate DisplayWordViewController:self otherVariantSelectedWhileDisplayingWord:self.word];
}

- (IBAction)spellingToClipboardButtonPressed:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.spelling.text;
    
    //track word event with GA manual sent with Value 1
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"copyToClipboard" label:self.spelling.text value:nil];
    
    //track word view with Flurry
    NSDictionary *flurryParameters = @{@"copyToClipboard" : self.spelling.text};
    [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
    
}



-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)playedSuccessfully
{
    self.audioPlayer = nil;
    NSLog(@"finished playing a word %@", playedSuccessfully? @"successfully" : @"with error");
    
    if ([self.soundsToPlay count] > 0) {
        NSMutableArray *pronunciationsArray = [NSMutableArray arrayWithArray:self.soundsToPlay];
        [pronunciationsArray removeLastObject];
        self.soundsToPlay = pronunciationsArray;
        
        if ([self.soundsToPlay count] > 0) {
            [self playWord:[self.soundsToPlay lastObject]];
            
            //track word event with GA auto sent with Value 2
            [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Word" action:@"listenToWord" label:[pronunciationsArray lastObject] value:[NSNumber numberWithInt:2]];
            
            //track word view with Flurry
            NSDictionary *flurryParameters = @{@"listenToWord" : [pronunciationsArray lastObject],
                                               @"wordPlayMode" : @"Auto_Play"};
            [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
        }
    }
}

-(void)onNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"customBackgroundColorChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.customBackgroundColor = [userinfo objectForKey:@"newValue"];
    }
    
    if ([[notification name] isEqualToString:@"useDyslexiFontChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.useDyslexieFont = [[userinfo objectForKey:@"newValue"] boolValue];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //check if correct background color is set - needed if user changed color in settings while a word is showing in iPhone.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *currentDesiredColor = [UIColor colorWithHue:[defaults floatForKey:BACKGROUND_COLOR_HUE] saturation:[defaults floatForKey:BACKGROUND_COLOR_SATURATION] brightness:1 alpha:1];
    if (![self.customBackgroundColor isEqual:currentDesiredColor]) {
        self.customBackgroundColor = currentDesiredColor;
    }
    
    self.useDyslexieFont = [defaults boolForKey:USE_DYSLEXIE_FONT];
    
    if (self.word) {
        [self setUpViewForWord:self.word];
        if (self.playWordsOnSelection) { //only used in iPhone - playwords on iPad done from DD2Table/SearchViewController no need to follow notifications as in iPhone view will be instanciated with the right setting just before the setting is used.
            [self playAllWords:[DD2Words pronunciationsForWord:self.word]];
        }
    }
    NSLog(@"Displaying %@", [self.word objectForKey:@"spelling"]);
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:[NSString stringWithFormat:@"Viewed Word :%@", self.spelling.text]];
    
    //track word view with Flurry
    NSDictionary *flurryParameters = @{@"Viewed Word": self.spelling.text};
    [Flurry logEvent:@"uiAction_Word" withParameters:flurryParameters];
    
    //track word view with Apptimize
    [Apptimize track:@"Viewed Word" value:1];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view. 
    
    //registering for color notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"customBackgroundColorChanged" object:nil];
    
    
    //registering for spellingVariant notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"useDyslexiFontChanged" object:nil];
    
    self.word ? (self.listenButton.enabled = YES) : (self.listenButton.enabled = NO);
}

- (void)viewDidUnload
{
    [self setWord:nil];
    [self setSpelling:nil];
    [self setToolbar:nil];
//    [self setUsukVariantButton:nil];
//    [self setUsukVariantSegmentedControl:nil];
//    [self setSpellingToClipboardButton:nil];
    [self setListenButton:nil];
    [self setHeteronymListenButton:nil];
    [self setWordView:nil];
    [self setHomophoneButton1:nil];
    [self setHomophoneButton2:nil];
    [self setHomophoneButton3:nil];
    [self setHomophoneButton4:nil];
    [self setHomophoneButton5:nil];
    [self setHomophoneButton6:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation //iOS 5 not 6
{
    if ([self getSplitViewWithDisplayWordViewController]) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } //iOS 6 makes supporting rotation on iPhone harder (changes in how its done - so just supporting portrait for now - upsidedown is also out without category on UINavController and UITabController to override the default no upsidedown on iPhone. http://stackoverflow.com/questions/12520030/how-to-force-a-uiviewcontroller-to-portait-orientation-in-ios-6
    
}


- (DisplayWordViewController *)getSplitViewWithDisplayWordViewController
{
    id dwvc = [self.splitViewController.viewControllers lastObject];
    if (![dwvc isKindOfClass:[DisplayWordViewController class]]) {
        dwvc = nil;
    }
    return dwvc;
}

- (void) setColorOfButtons:(NSArray*)buttons toColor:(UIColor *)color areHomophoneButtons:(BOOL)areHomophones
{
    //raw idea at http://stackoverflow.com/questions/7238507/change-round-rect-button-background-color-on-statehighlighted
    //modified to take UIColor on input not a color spec
    
    if (buttons.count == 0) {
        return;
    }
    
    // get the first button
    NSEnumerator* buttonEnum = [buttons objectEnumerator];
    UIButton* button = (UIButton*)[buttonEnum nextObject];
    
    UIColor *highlightColor = color;
    [button setTintColor:highlightColor];
    
    float cRadius = 8;
//    NSLog(@"button size from imageView.image = h%f w%f", button.imageView.image.size.height, button.imageView.image.size.width);
//    NSLog(@"button size from layer.frame = h%f w%f", button.layer.frame.size.height, button.layer.frame.size.width);
//    NSLog(@"button size from button.bounds = h%f w%f", button.bounds.size.height, button.bounds.size.width);
    UIImage *image = [DisplayWordViewController createImageOfColor:highlightColor ofSize:CGSizeMake(40, 25) withCornerRadius:cRadius];
//    NSLog(@"created image size = %f, %f", image.size.width, image.size.height);
    
    UIImage *stretchableImage;
    if ([[UIImage class] respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)]) {    //only supported in iOS 6
        stretchableImage = [image resizableImageWithCapInsets:UIEdgeInsetsMake(12, 12, 12, 12) resizingMode:UIImageResizingModeStretch];
    } else {
        stretchableImage = [image stretchableImageWithLeftCapWidth:12 topCapHeight:12];    //supported in iOS 5
    }
    
    // set background image of all buttons
    do {
        
        [button setBackgroundImage:stretchableImage forState:UIControlStateNormal];
        
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = cRadius;
        button.layer.needsDisplayOnBoundsChange = YES;
        
        if (areHomophones) {
            [self sizeHomophoneButton:button];
        }
        
    } while (button = (UIButton*)[buttonEnum nextObject]);
    
    //    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    //    CAGradientLayer *gradient = [CAGradientLayer layer];
    //    gradient.frame = rect;
    //    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor whiteColor] CGColor], nil];
    //    [view.layer insertSublayer:gradient atIndex:0];
}

+ (UIImage *)createImageOfColor:(UIColor *)color ofSize:(CGSize)size withCornerRadius:(float)cRadius
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    // image drawing code here

    
//    Used to draw a perfect rectangle for use as button background during development.
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, 0, 0);
//    CGContextAddLineToPoint(context, 0, image.size.height);
//    CGContextAddLineToPoint(context, image.size.width, image.size.height);
//    CGContextAddLineToPoint(context, image.size.width, 0);
//    CGContextAddLineToPoint(context, 0, 0);
//    CGContextClosePath(context);
//    CGContextFillPath(context);
    
    [color setFill];
    [[UIColor grayColor] setStroke];
    
    UIGraphicsPushContext(context);
    
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius: cRadius];
    [roundedRect fillWithBlendMode: kCGBlendModeNormal alpha:1.0f];
    
//    [[UIColor yellowColor] setFill];
    CGFloat hue;   CGFloat sat;   CGFloat bright;   CGFloat alpha;
    [color getHue:&hue saturation:&sat brightness:&bright alpha:&alpha];
    CGFloat darkest=0.8;
    int loopMax = 5;  //loops 1 times less than this
    int stepSize = 1;
    
    for (int i = 1 ; i < loopMax ; i++)
    {

        CGFloat increaseBrightnessEachLoop = (1-darkest)/(loopMax-1);
        CGFloat brightThisLoop = darkest + increaseBrightnessEachLoop*i;
 //       NSLog(@"brightThisLoop = %f", brightThisLoop);
        [[UIColor colorWithHue:hue saturation:sat brightness:brightThisLoop alpha:alpha] setFill];
     
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, size.height-stepSize*(i-1));
        CGContextAddLineToPoint(context, size.width, size.height-stepSize*(i-1));
        CGContextAddLineToPoint(context, size.width, size.height-stepSize*i);
        CGContextAddLineToPoint(context, 0, size.height-stepSize*i);
        CGContextAddLineToPoint(context, 0, size.height-stepSize*(i-1));
        CGContextClosePath(context);
        CGContextFillPath(context);
//        NSLog(@"rectangle this loop tl:%f,%f tr:%f,%f br:%f,%f bl:%f,%f",
//              0.0f,size.height-stepSize*(i-1),
//              size.width,size.height-stepSize*(i-1),
//              size.width,size.height-stepSize*i,
//              0.0f,size.height-stepSize*i);
        
    }
    
    CGFloat lineWidth = 2.0;
    CGRectInset(rect, lineWidth/2.0, lineWidth/2.0);
    [roundedRect strokeWithBlendMode:kCGBlendModeNormal alpha:1.0f];
    
    UIGraphicsPopContext();
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    NSLog(@"image I'm passing back %@", coloredImage);
    return coloredImage;    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
