//
//  DD2SetTrackTableViewController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2SetTrackTableViewController.h"

@interface DD2SetTrackTableViewController ()


@end

@implementation DD2SetTrackTableViewController
@synthesize playWordsOnSelection = _playWordsOnSelection;
@synthesize useDyslexieFont = _useDyslexieFont;
@synthesize customBackgroundColor = _customBackgroundColor;
@synthesize tableView = _tableView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - methods for the various Settings

-(BOOL)useDyslexieFont{
    if (!_useDyslexieFont) _useDyslexieFont = [[NSUserDefaults standardUserDefaults] boolForKey:USE_DYSLEXIE_FONT];
    return _useDyslexieFont;
}

-(void)setUseDyslexieFont:(BOOL)useDyslexieFont {
    if (useDyslexieFont != _useDyslexieFont) {
        _useDyslexieFont = useDyslexieFont;
        [self.tableView reloadData];
    }
}

-(BOOL)playWordsOnSelection {
    if(!_playWordsOnSelection) _playWordsOnSelection = [[NSUserDefaults standardUserDefaults] boolForKey:PLAY_WORDS_ON_SELECTION];
    return _playWordsOnSelection;
}

-(UIColor *)customBackgroundColor{
    if (!_customBackgroundColor) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _customBackgroundColor = [UIColor colorWithHue:[defaults floatForKey:BACKGROUND_COLOR_HUE] saturation:[defaults floatForKey:BACKGROUND_COLOR_SATURATION] brightness:1 alpha:1];
    }
    return _customBackgroundColor;
}

-(void)setCustomBackgroundColor:(UIColor *)customBackgroundColor
{
    if (customBackgroundColor != _customBackgroundColor) {
        _customBackgroundColor = customBackgroundColor;
        [self setTableViewsColor];
    }
}

-(void)checkBackgroundColorSetting
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIColor *currentNSUserDefaultBackgroundColor = [UIColor colorWithHue:[defaults floatForKey:BACKGROUND_COLOR_HUE] saturation:[defaults floatForKey:BACKGROUND_COLOR_SATURATION] brightness:1 alpha:1];
    if (![self.customBackgroundColor isEqual:currentNSUserDefaultBackgroundColor]) {
        NSLog(@"resetting background color");
        self.customBackgroundColor = currentNSUserDefaultBackgroundColor;
    }
}

-(void)setTableViewsColor
{
    if ([self.tableView indexPathForSelectedRow]) {
        // we have to deselect change color and reselect or we get the old color showing up when the selection is changed.
        NSIndexPath *selectedCell = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:selectedCell animated:NO];
        [self setTheColor];
        [self.tableView selectRowAtIndexPath:selectedCell animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        [self setTheColor];
    }
}

-(void)setTheColor {
    self.tableView.backgroundColor = self.customBackgroundColor;
    if (self.searchDisplayController.searchResultsTableView) {      //if we have a searchtable change that background too.
        self.searchDisplayController.searchResultsTableView.backgroundColor = self.customBackgroundColor;
    }
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];   // needed for iOS7
    }
}

-(void)onNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"customBackgroundColorChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.customBackgroundColor = [userinfo objectForKey:@"newValue"];
    }
    
    if ([[notification name] isEqualToString:@"playWordsOnSelectionChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.playWordsOnSelection = [[userinfo objectForKey:@"newValue"] boolValue];
    }
    
    if ([[notification name] isEqualToString:@"useDyslexiFontChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.useDyslexieFont = [[userinfo objectForKey:@"newValue"] boolValue];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self checkBackgroundColorSetting];
    [self setTableViewsColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //registering for color notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"customBackgroundColorChanged" object:nil];

    //registering for playWordsOnSelection notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"playWordsOnSelectionChanged" object:nil];
    
    //registering for Font change notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"useDyslexiFontChanged" object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
