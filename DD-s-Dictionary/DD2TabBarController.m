//
//  DD2TabBarController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/13/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2TabBarController.h"
#import "DD2WordListTableViewController.h"
#import "DD2AllWordSearchViewController.h"
#import "FunWithWordsTableViewController.h"
#import "DisplayWordViewController.h"
#import "DD2SettingsTableViewController.h"

// Tab controller managed which tabs are visible and what data is displayed ie manages the impact of spelling Variant

@interface DD2TabBarController () <UITabBarControllerDelegate>
@property (nonatomic, strong) DD2Words *wordBrain; //the model for this MVC
@property (nonatomic, strong) NSString *spellingVariant;
@property (nonatomic, strong) NSArray *selectedCollections;
@property (nonatomic) BOOL animateTabChanges;

@end

@implementation DD2TabBarController
@synthesize wordBrain = _wordBrain;
@synthesize spellingVariant = _spellingVariant;
@synthesize selectedCollections = _selectedCollections;
@synthesize animateTabChanges = _animateTabChanges;

-(DD2Words *)wordBrain
{
    if (!_wordBrain) {
        _wordBrain = [DD2Words sharedWords];
        _wordBrain.spellingVariant = self.spellingVariant;
    }
    return _wordBrain;
}

- (NSString *)spellingVariant
{
    if (!_spellingVariant) {
        _spellingVariant = [[NSUserDefaults standardUserDefaults] stringForKey:SPELLING_VARIANT];
        if (!_spellingVariant) {
            //set up the default for the first time
            NSLog(@"defaulting SPELLING_VARIANT to UK");
            [[NSUserDefaults standardUserDefaults] setObject:@"UK" forKey:SPELLING_VARIANT];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.spellingVariant = @"UK";
        }
    }
    return _spellingVariant;
}

- (void)setSpellingVariant:(NSString *)spellingVariant {
    if (spellingVariant != _spellingVariant) {
        _spellingVariant = spellingVariant;
        self.wordBrain.spellingVariant = spellingVariant;
        self.animateTabChanges = NO;        //avoid tab flicker
    }
}

- (NSArray *)selectedCollections {
    if (!_selectedCollections) {
        _selectedCollections = [DD2SettingsTableViewController limitSelectedCollections:[[[NSUserDefaults standardUserDefaults] stringArrayForKey:SELECTED_COLLECTIONS] mutableCopy]];
        if (!_selectedCollections) {
            //set up the default for the first time
            NSLog(@"defaulting SELECTED_COLLECTIONS to first_words, recents");
            NSArray *selCollections = [NSArray arrayWithObjects: @"Recents", @"first_words", nil];
            [[NSUserDefaults standardUserDefaults] setObject:selCollections forKey:SELECTED_COLLECTIONS];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.selectedCollections = selCollections;
        }
    }
    return _selectedCollections;
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
    self.delegate = self;
    [self manageTabs];
	// Do any additional setup after loading the view.
    
    //registering for spellingVariant notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"spellingVariantChanged" object:nil];
    
    //registering for selectedCollections notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"selectedCollectionsChanged" object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    //track all page views with Flurry
    [Flurry logAllPageViews:self];
}

-(void)onNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"spellingVariantChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.spellingVariant = [userinfo objectForKey:@"newValue"];
        [self manageTabs];
    }
    if ([[notification name] isEqualToString:@"selectedCollectionsChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.selectedCollections = [[userinfo objectForKey:@"newValue"] copy];
        self.animateTabChanges = YES;        //manage tabs 'pretty'
        [self manageTabs];
    }
}


- (void)manageTabs
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil]; //seems to pick right one for iPhone and iPad!
    NSMutableArray *listOfTabVC = [NSMutableArray arrayWithArray:self.viewControllers];
    //NSLog(@"listOfTabVC %@", listOfTabVC);
    
    for (UIViewController *vc in listOfTabVC) {
        if ([vc isKindOfClass:[UINavigationController class]]) {        //removing old DD2WordlistTableControllers
            UINavigationController *nvc = (UINavigationController *)vc;
            UIViewController *vc1OnStack;
            if ([nvc.viewControllers count] > 0) vc1OnStack = [nvc.viewControllers objectAtIndex:0];
            //NSLog(@"vcs = %@", nvc.viewControllers);
        
            if ([vc1OnStack isKindOfClass:[DD2WordListTableViewController class]]) {
                [nvc removeFromParentViewController];
            
            } else if ([vc1OnStack isKindOfClass:[DD2AllWordSearchViewController class]]){  //setting data for search tab for spelling variant
                DD2AllWordSearchViewController *searchTable = (DD2AllWordSearchViewController *)vc1OnStack;
                searchTable.allWordsForSpellingVariant = [self.wordBrain allWordsForCurrentSpellingVariant];
                searchTable.selectedWord = nil;
                searchTable.allWords = self.wordBrain.allWords;
                if (searchTable.searchDisplayController.searchResultsTableView) {
                    [searchTable.searchDisplayController setActive:NO];
                }
                if ([searchTable.tableView indexPathForSelectedRow]) {
                    [searchTable.tableView deselectRowAtIndexPath:[searchTable.tableView indexPathForSelectedRow] animated:NO];
                }
            
            } else if ([vc1OnStack isKindOfClass:[FunWithWordsTableViewController class]]) {    //setting up the fun vc (spelling variant and tagNames)
                FunWithWordsTableViewController *funTable = (FunWithWordsTableViewController *)vc1OnStack;
                funTable.tagNames = self.wordBrain.tagNames;
                funTable.smallCollections = self.wordBrain.smallCollectionNames;
                funTable.allWordsForSpellingVariant = [self.wordBrain allWordsForCurrentSpellingVariant];
                funTable.allWords = self.wordBrain.allWords;
                while ([nvc.viewControllers count]>1) {
                    [nvc popViewControllerAnimated:NO];
                }
            } else if ([vc1OnStack isKindOfClass:[DD2SettingsTableViewController class]]) {    //setting up the settings vc (collection Names)
                DD2SettingsTableViewController *settingsTable = (DD2SettingsTableViewController *)vc1OnStack;
                NSMutableArray *collectionNamesForSettings = [self.wordBrain.collectionNames mutableCopy];
                [collectionNamesForSettings addObject:@"Recents"];
                settingsTable.collectionNames = collectionNamesForSettings;
            }
            if ([[nvc.viewControllers lastObject]isKindOfClass:[DisplayWordViewController class]]) { //iphone only
                //DisplayWordViewController *dwvc = (DisplayWordViewController *)[nvc.viewControllers lastObject];
                //dwvc.word = nil;  //extra
                [nvc popViewControllerAnimated:NO];
                if ([[nvc.viewControllers lastObject] isKindOfClass:[DD2WordListTableViewController class]]) {
                    DD2WordListTableViewController *newLastObject = (DD2WordListTableViewController *)[nvc.viewControllers lastObject];
                    [newLastObject.tableView deselectRowAtIndexPath:[newLastObject.tableView indexPathForSelectedRow] animated:NO];
                } else if ([[nvc.viewControllers lastObject] isKindOfClass:[DD2AllWordSearchViewController class]]) {
                    DD2AllWordSearchViewController *newLastObject = (DD2AllWordSearchViewController *)[nvc.viewControllers lastObject];
                    [newLastObject.tableView deselectRowAtIndexPath:[newLastObject.tableView indexPathForSelectedRow] animated:NO];
                    newLastObject.allWordsForSpellingVariant = [self.wordBrain allWordsForCurrentSpellingVariant];
                }
            }
            if ([self getSplitViewWithDisplayWordViewController]) {
                [self getSplitViewWithDisplayWordViewController].word = nil;
                // have to deselect for visible table
            }
        }
    }
    listOfTabVC = [NSMutableArray arrayWithArray:self.viewControllers];     //resetting after old VCs have been removed.
    
    for (NSString *collection in self.selectedCollections) {     //adding VCs needed now.
        id vc = [storyboard instantiateViewControllerWithIdentifier:@"List Controller"];
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nvc = (UINavigationController *)vc;
            if ([[nvc.viewControllers objectAtIndex:0] isKindOfClass:[DD2WordListTableViewController class]]) {
                DD2WordListTableViewController *collectionTable = (DD2WordListTableViewController *) [nvc.viewControllers objectAtIndex:0];
                
                NSString *collectionTitle = [DD2Words displayNameForCollection:collection];
                collectionTable.title = collectionTitle;
                collectionTable.allWords = self.wordBrain.allWords;
                
                if ([collection isEqualToString:@"Recents"]) {
                    NSLog(@"setup collection %@", collectionTitle);
                    // Recent then set word list from RecentWords
                    [self setRecentWordListForCollectionTable:collectionTable];
                    nvc.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemRecents tag:1];
                } else {
                    // setting word list from DD2Words
                    NSLog(@"setup collection %@", collectionTitle);
                    collectionTable.wordListWithSections = [DD2Words wordsBySectionFromWordList:[self.wordBrain wordsForCurrentSpellingVariantInCollectionNamed:collection]];
                    UIImage *img = [UIImage imageNamed:@"resources.bundle/Images/DinoTabIconv2.png"];
                    nvc.tabBarItem = [[UITabBarItem alloc] initWithTitle:collectionTitle image:img tag:1];
                }
            }
            [listOfTabVC insertObject:vc atIndex:0];
        }
    }
    [self setViewControllers:listOfTabVC animated:self.animateTabChanges];
    self.animateTabChanges = NO;     //defaulting to NO, so only way to get an animation is with a change to selectedCollections
}

#pragma mark - Tab Bar Controller Delegate Methods

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    //NSLog(@"Tab selected %@", viewController);
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nvc = (UINavigationController *)viewController;
        if ([[nvc.viewControllers objectAtIndex:0] isKindOfClass:[FunWithWordsTableViewController class]]) {
            [self playAppingtonMsgForFun];
        } else if ([[nvc.viewControllers objectAtIndex:0] isKindOfClass:[DD2AllWordSearchViewController class]]) {
            DD2AllWordSearchViewController *searchTable = (DD2AllWordSearchViewController *)[nvc.viewControllers objectAtIndex:0];
            [searchTable.tableView deselectRowAtIndexPath:[searchTable.tableView indexPathForSelectedRow] animated:NO];
            [searchTable.searchDisplayController setActive:YES animated:YES];
            [searchTable.searchDisplayController.searchBar becomeFirstResponder];
        } else if ([[nvc.viewControllers objectAtIndex:0] isKindOfClass:[DD2WordListTableViewController class]]) {
            DD2WordListTableViewController *collectionTable = (DD2WordListTableViewController *) [nvc.viewControllers objectAtIndex:0];
            if ([collectionTable.title isEqualToString:@"Recents"]) {        //update recent word list before recent tab is displayed
                [self setRecentWordListForCollectionTable:collectionTable];
            }
            
        }
    }
}

- (void) setRecentWordListForCollectionTable:(DD2WordListTableViewController *)collectionTable {
    NSArray *recentWordList = [DD2Words currentRecentlyViewedWordList];
    if ([recentWordList count] <10) {
        collectionTable.wordList = recentWordList;
    } else {
        collectionTable.wordListWithSections = [DD2Words wordsBySectionFromWordList:recentWordList];
    }
}

- (void) playAppingtonMsgForFun
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:NOT_USE_VOICE_HINTS]) {
        static NSArray *msgs = nil;
        if (!msgs) msgs = [NSArray arrayWithObjects:@"22",@"23", nil];
        int msgIndex = arc4random()%[msgs count];
        // call Appington
        [Appington control:@"placement" andValues:@{@"id": [msgs objectAtIndex:msgIndex]}];
        if (LOG_APPINGTON_NOTIFICATIONS) NSLog(@"Appington placement id %@ (fun tab) sent", [msgs objectAtIndex:msgIndex]);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation //iOS 5 not 6
{
    if ([self getSplitViewWithDisplayWordViewController]) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (DisplayWordViewController *)getSplitViewWithDisplayWordViewController
{
    id dwvc = [self.splitViewController.viewControllers lastObject];
    if (![dwvc isKindOfClass:[DisplayWordViewController class]]) {
        dwvc = nil;
    }
    return dwvc;
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
