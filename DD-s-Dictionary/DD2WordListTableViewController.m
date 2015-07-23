//
//  DD2WordListTableViewController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2WordListTableViewController.h"
#import "DisplayWordViewController.h"

@interface DD2WordListTableViewController () <UITableViewDataSource, UITableViewDelegate, DisplayWordViewControllerDelegate>
@property (nonatomic, strong) NSDictionary *selectedWord;

@end

@implementation DD2WordListTableViewController
@synthesize wordList = _wordList;
@synthesize allWords = _allWords;
@synthesize wordListWithSections = _wordListWithSections;
@synthesize sections = _sections;
@synthesize selectedWord = _selectedWord;


-(void)setWordList:(NSArray *)wordList {
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedWords = [wordList sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
    if (sortedWords != _wordList) {
        _wordList = sortedWords;
    }
    [self.tableView reloadData];
}

-(void)setWordListWithSections:(NSDictionary *)wordListWithSections {
    if (wordListWithSections != _wordListWithSections) {
        _wordListWithSections = wordListWithSections;
        self.sections = [[wordListWithSections allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (!self.sections) {
        return 1;
    } else {
        return [self.sections count];
    }
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (!self.sections) {
        return nil;
    } else {
        return self.sections;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (!self.sections) {
        NSLog(@"this was called :-)");      //not called
        return 1;
    } else {
        return index;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!self.sections) {
        return nil;
    } else {
        return [self.sections objectAtIndex:section];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (!self.sections) {
        return [self.wordList count];
    } else {
        return [[self.wordListWithSections objectForKey:[self.sections objectAtIndex:section]] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"List Word";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell ==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
    
    // Configure the cell...
    if ([self getSplitViewWithDisplayWordViewController]) cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor clearColor]; //needed for iOS7
    cell.textLabel.font = self.useDyslexieFont ? [UIFont fontWithName:@"Dyslexiea-Regular" size:20] : [UIFont boldSystemFontOfSize:20];
    
    if (!self.sections) {
        NSDictionary *word = [self.wordList objectAtIndex:indexPath.row];
        cell.textLabel.text = [word objectForKey:@"spelling"];
    } else {
        NSArray *wordsForSection = [self.wordListWithSections objectForKey:[self.sections objectAtIndex:indexPath.section]];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWords = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        NSDictionary *word = [sortedWords objectAtIndex:indexPath.row];
        cell.textLabel.text = [word objectForKey:@"spelling"];
    }
    
    return cell;
}

- (NSDictionary *)wordForIndexPath:(NSIndexPath *)indexPath
{
    if (!self.sections) {
        return [self.wordList objectAtIndex:indexPath.row];
    } else {
        NSArray *wordsForSection = [self.wordListWithSections objectForKey:[self.sections objectAtIndex:indexPath.section]];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWordsForSection = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        return [sortedWordsForSection objectAtIndex:indexPath.row];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedWord = [self wordForIndexPath:indexPath];
    [self displaySelectedWord];
}

- (void)displaySelectedWord
{
    if (LOG_MORE) NSLog(@"displaying word %@", self.selectedWord);
    if ([self getSplitViewWithDisplayWordViewController]) { //iPad
        DisplayWordViewController *dwvc = [self getSplitViewWithDisplayWordViewController];
        [self setupDwvc:dwvc foriPhone:NO];
    } else { //iPhone (passing playWordsOnSelection handled in prepare for Segue)
        [self performSegueWithIdentifier:@"Word Selected" sender:self];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    //used for iphone only
    if ([segue.identifier isEqualToString:@"Word Selected"]) {
        
        if ([segue.destinationViewController isKindOfClass:[DisplayWordViewController class]]) {
            DisplayWordViewController *dwvc = (DisplayWordViewController *)segue.destinationViewController;
            [self setupDwvc:dwvc foriPhone:YES];
        }
    }
}

-(void) setupDwvc:(DisplayWordViewController *)dwvc foriPhone:(BOOL)iPhone
{

    dwvc.homophonesForWord = [DD2Words homophonesForWord:self.selectedWord andWordList:self.allWords];      // always do to clear any homophonesForWord from prior words

    if ([self.selectedWord objectForKey:@"usukVariant"]) {
        dwvc.hasOtherVariantWord = YES;
    } else {
        dwvc.hasOtherVariantWord = NO;
    }
    dwvc.word = self.selectedWord;
    dwvc.delegate = self;
    
    if (self.playWordsOnSelection) {
        if (iPhone) {
            [dwvc setPlayWordsOnSelection:self.playWordsOnSelection];
        } else {
            [dwvc playAllWords:[DD2Words pronunciationsForWord:self.selectedWord]];
        }
    }
    if (iPhone) {
        if (self.customBackgroundColor) {
            [dwvc setCustomBackgroundColor:self.customBackgroundColor];
        }
        if (self.useDyslexieFont) {
            [dwvc setUseDyslexieFont:self.useDyslexieFont];
        }
    }
}

//DisplayWordViewControllerDelegate methods
- (void)DisplayWordViewController:(DisplayWordViewController *)sender homophoneSelected:(NSDictionary *)word
{
    NSLog(@"homonymSelected with word = %@",[word objectForKey:@"spelling"]);
    //find the selected word
    //find the indexPathOfHomophone (the new one so you can scroll to it)
    // if in iphone
    if (![self getSplitViewWithDisplayWordViewController]) { //iPhone
        //pop old word off navigation controller
        [self.navigationController popViewControllerAnimated:NO]; //Not animated as this is just preparing the Navigation Controller stack for the new word to be pushed on.
    }
    
    NSIndexPath *indexPathOfHomophone;
    if (self.sections) {
        NSString *sectionOfHomophone = [word objectForKey:@"section"];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWords = [[self.wordListWithSections objectForKey:sectionOfHomophone] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        if ([sortedWords indexOfObject:word] != NSNotFound) {
            indexPathOfHomophone = [NSIndexPath indexPathForRow:[sortedWords indexOfObject:word] inSection:[self.sections indexOfObject:sectionOfHomophone]];
        }
    } else {
        if ([self.wordList indexOfObject:word] != NSNotFound) {
           indexPathOfHomophone = [NSIndexPath indexPathForRow:[self.wordList indexOfObject:word] inSection:0];
        }
    }
    
    if (!indexPathOfHomophone) {
        NSLog(@"Selected Homophone not in currently displayed list");
        //deselect table and display homophone
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
        self.selectedWord = word;
        [self displaySelectedWord];
        
    } else {
        [self.tableView selectRowAtIndexPath:indexPathOfHomophone animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPathOfHomophone];
    }
}

- (void)DisplayWordViewController:(DisplayWordViewController *)sender otherVariantSegmentedControlSelected:(NSString *)selection whileDisplayingWord:(NSDictionary *)word
{
    // find otherVariant word,
    // display word
    
    if (![self getSplitViewWithDisplayWordViewController]) { //iPhone
        //pop old word off navigation controller
        [self.navigationController popViewControllerAnimated:NO]; //Not animated as this is just preparing the Navigation Controller stack for the new word to be pushed on.
    }
    NSDictionary *wordToBeDisplayed = [DD2Words wordWithOtherSpellingVariantFrom:word andListOfAllWords:self.allWords];
    if (LOG_MORE) NSLog(@"usukVariant to be displayed = %@", wordToBeDisplayed);
    self.selectedWord = wordToBeDisplayed;
    [self displaySelectedWord];
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self getSplitViewWithDisplayWordViewController] && self.selectedWord) {
        [self displaySelectedWord];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:[NSString stringWithFormat:@"%@ WordList Tab Shown", self.title]];
    //track Tab Appeared with Flurry
    [Flurry logEvent:[NSString stringWithFormat:@"Tab Appeared: %@", self.title]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (DisplayWordViewController *)getSplitViewWithDisplayWordViewController
{
    id dwvc = [self.splitViewController.viewControllers lastObject];
    if (![dwvc isKindOfClass:[DisplayWordViewController class]]) {
        dwvc = nil;
    }
    return dwvc;
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
