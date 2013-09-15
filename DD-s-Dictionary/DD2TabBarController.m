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

// Tab controller managed which tabs are visible and what data is displayed ie manages the impact of spelling Variant

@interface DD2TabBarController ()
@property (nonatomic, strong) NSString *spellingVariant;

@end

@implementation DD2TabBarController
@synthesize spellingVariant = _spellingVariant;

- (NSString *)spellingVariant
{
    if (!_spellingVariant) {
        _spellingVariant = [[NSUserDefaults standardUserDefaults] stringForKey:SPELLING_VARIANT];
        if (!_spellingVariant) {
            //set up the default for the first time
            NSLog(@"defaulting SPELLING_VARIANT to US");
            [[NSUserDefaults standardUserDefaults] setObject:@"US" forKey:SPELLING_VARIANT];
            [[NSUserDefaults standardUserDefaults] synchronize];
            _spellingVariant = @"US";
        }
    }
    return _spellingVariant;
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
    [self manageTabs];
	// Do any additional setup after loading the view.
    
    //registering for spellingVariant notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"spellingVariantChanged" object:nil];
    
}

-(void)onNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"spellingVariantChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.spellingVariant = [userinfo objectForKey:@"newValue"];
        [self manageTabs];
    }
}

- (NSArray *)collectionsInWordlist
{
    NSMutableArray *collections = [NSMutableArray arrayWithArray:[DD2Words sharedWords].collectionNames];
    [collections removeObject:@"allWords"];
    NSLog(@"collections for tabs %@", collections);
    return collections;
}

- (void)manageTabs
{
    NSArray *collections = [self collectionsInWordlist];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil]; //TODO figure out how iphone and ipad works with this
    NSMutableArray *listOfTabVC = [NSMutableArray arrayWithArray:self.viewControllers];
    NSLog(@"listOfTabVC %@", listOfTabVC);
    
    for (UIViewController *vc in listOfTabVC) {
        if ([vc isKindOfClass:[UINavigationController class]]) {        //removing any old DD2WordlistTableControllers
            UINavigationController *nvc = (UINavigationController *)vc;
            for (UIViewController *vc in nvc.viewControllers) {
                if ([vc isKindOfClass:[DD2WordListTableViewController class]]) {
                    [nvc removeFromParentViewController];
                }
            }
            if ([nvc.visibleViewController isKindOfClass:[DD2AllWordSearchViewController class]]) {     //setting data for search tab for spelling variant
                DD2AllWordSearchViewController *searchTable = (DD2AllWordSearchViewController *)nvc.visibleViewController;
                searchTable.allWordsWithSectionsData = [DD2Words singleCollectionNamed:@"allWords" spellingVariant:self.spellingVariant];
                searchTable.allWordsData = [DD2Words allWordsWithSpellingVariant:self.spellingVariant];
            }
        }
        
            
    }
    listOfTabVC = [NSMutableArray arrayWithArray:self.viewControllers];     //resetting after old VCs have been removed.
    
    for (NSString *collection in collections) {     //adding VCs needed now.
        id vc = [storyboard instantiateViewControllerWithIdentifier:@"List Controller"];
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nvc = (UINavigationController *)vc;
            if ([nvc.visibleViewController isKindOfClass:[DD2WordListTableViewController class]]) {
                DD2WordListTableViewController *collectionTable = (DD2WordListTableViewController *) nvc.visibleViewController;
                collectionTable.wordListWithSectionsData = [DD2Words singleCollectionNamed:collection spellingVariant:self.spellingVariant];
                UIImage *img = [UIImage imageNamed:@"resources.bundle/Images/DinoTabIconv2.png"];
                nvc.tabBarItem = [[UITabBarItem alloc] initWithTitle:collection image:img tag:1];
            }
            [listOfTabVC insertObject:vc atIndex:0];
        }
    }
    [self setViewControllers:listOfTabVC animated:NO];
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
