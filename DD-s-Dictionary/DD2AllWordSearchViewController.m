//
//  DD2AllWordSearchViewController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2AllWordSearchViewController.h"
#import "DisplayWordViewController.h"
#import <QuartzCore/QuartzCore.h>   //for layer work on Add Word button

@interface DD2AllWordSearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, DisplayWordViewControllerDelegate>

@property (nonatomic, strong) NSDictionary *allWordsWithSections;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *filteredWords;
@property (nonatomic, strong) NSArray *sections;    //only used in main tableview
@property (nonatomic) BOOL showAddWordButton;
@property (nonatomic, strong) NSString *currentSearchText;
@property (nonatomic, strong) dispatch_queue_t workQueue;
@end

@implementation DD2AllWordSearchViewController
@synthesize allWordsForSpellingVariant = _allWordsForSpellingVariant;
@synthesize allWords = _allWords;
@synthesize allWordsWithSections = _allWordsWithSections;
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize filteredWords = _filteredWords;
@synthesize sections = _sections;
@synthesize selectedWord = _selectedWord;
@synthesize currentSearchText = _currentSearchText;
@synthesize workQueue = _workQueue;



- (dispatch_queue_t)workQueue {
    if (!_workQueue) {
        _workQueue = dispatch_queue_create("com.AlisonKline.DD-s-Dictionary", DISPATCH_QUEUE_SERIAL);
    }
    return _workQueue;
}

-(void)setAllWordsForSpellingVariant:(NSArray *)allWordsForSpellingVariant
{
    NSArray *sortedWords = [self sortArrayAlphabetically:allWordsForSpellingVariant];
    if (sortedWords != _allWordsForSpellingVariant) {
        _allWordsForSpellingVariant = sortedWords;
        NSLog(@"Search Tab setup");
        self.allWordsWithSections = [DD2Words wordsBySectionFromWordList:sortedWords];
        [self.tableView reloadData];
    }
}

-(void)setFilteredWords:(NSMutableArray *)filteredWords
{
    if (filteredWords != _filteredWords) {
        _filteredWords = [NSMutableArray arrayWithArray:filteredWords];
    }
}

-(void)setAllWordsWithSections:(NSDictionary *)allWordsWithSections
{
    if (allWordsWithSections != _allWordsWithSections) {
        _allWordsWithSections = allWordsWithSections;
        self.sections = [[allWordsWithSections allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
}

- (NSArray *)sortArrayAlphabetically:(NSArray *)wordsForSort
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    return [wordsForSort sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Table appearance

-(void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.backgroundColor = self.customBackgroundColor;
    tableView.rowHeight = 55.0f; // setting row height on the search results table to match the main table.
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:@"Dict Search Started"];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:@"Dict Search Ended"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    } else {
        return [self.sections count];
    }
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return self.sections;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        NSLog(@"this was called :-)");      //not called
        return 1;
    } else {
        return index;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return [self.sections objectAtIndex:section];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if ([self.filteredWords count] > 0) {
            if (self.showAddWordButton) {
                return [self.filteredWords count] + 1;    // +1 for add word button
            }
            return [self.filteredWords count];
        } else {
            return 1;   //for add word button
        }
    } else {
        return [[self.allWordsWithSections objectForKey:[self.sections objectAtIndex:section]] count];
    }
}

#define ADD_WORD_BUTTON_TAG 1111
#define USUK_NOTIFIER_VIEW_TAG 2222

- (void) setupCell:(UITableViewCell *)cell WithWord:(NSDictionary *)word{
    cell.textLabel.text = [word objectForKey:@"spelling"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([[word objectForKey:@"usukVariant"] isEqualToString:@"spelling"]) {
        if (LOG_MORE) NSLog(@"Adding usuk spelling indicator to:%@", word[@"spelling"]);
        UIImageView *notifier = [self getUSUKVariantNotifierWithVariant:[word objectForKey:@"wordVariant"]];
        notifier.tag = USUK_NOTIFIER_VIEW_TAG;
        [cell.contentView addSubview:notifier];
    }
}

- (void) setupAddWordCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"";      //make sure clean for button reuse
    UIButton *button = [self getAddWordButton];
    button.tag = ADD_WORD_BUTTON_TAG;
    [cell.contentView addSubview:button];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Search Word";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell ==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    cell.backgroundColor = [UIColor clearColor]; //needed for iOS7
    cell.textLabel.font = self.useDyslexieFont ? [UIFont fontWithName:@"Dyslexiea-Regular" size:20] : [UIFont boldSystemFontOfSize:20];
    if ([cell.contentView viewWithTag:USUK_NOTIFIER_VIEW_TAG]) [[cell.contentView viewWithTag:USUK_NOTIFIER_VIEW_TAG] removeFromSuperview]; //clean cell before reuse
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if ([self.filteredWords count]>0) {
            // clean out add button if there is one
            if ([cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG]) [[cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG] removeFromSuperview];
            
            if ([self.filteredWords count] == indexPath.row) {      //looking for last cell when we need to show the addWord button
                [self setupAddWordCell:cell];
            } else {
                NSDictionary *word = [self.filteredWords objectAtIndex:indexPath.row];
                [self setupCell:cell WithWord:word];
            }
        } else {    //Search has no results
            if (![cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG]) { //button isn't already present
                [self setupAddWordCell:cell];
            }
        }
    } else {
        // clean out add button if there is one
        if ([cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG]) [[cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG] removeFromSuperview];
        // set text for cell
        NSArray *wordsForSection = [self.allWordsWithSections objectForKey:[self.sections objectAtIndex:indexPath.section]];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWords = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        NSDictionary *word = [sortedWords objectAtIndex:indexPath.row];
        [self setupCell:cell WithWord:word];
        
        //NSLog(@"After reconfigure Cell content view %@", cell.contentView.subviews);
        //NSLog(@"cell: %@", cell.textLabel.text);
    }
    
    return cell;
}

- (NSDictionary *)wordForIndexPath:(NSIndexPath *)indexPath fromTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredWords objectAtIndex:indexPath.row];
    } else {
        NSArray *wordsForSection = [self.allWordsWithSections objectForKey:[self.sections objectAtIndex:indexPath.section]];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWordsForSection = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        return [sortedWordsForSection objectAtIndex:indexPath.row];
    }
}


#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if ([selectedCell.contentView viewWithTag:ADD_WORD_BUTTON_TAG]) {
        NSLog(@"cell containing Ask DD button pressed");
        [self addwordButtonPressed];
    } else {
        self.selectedWord = [self wordForIndexPath:indexPath fromTableView:tableView];
        [self displaySelectedWord];
    }
}

- (void) displaySelectedWord
{
    if (LOG_MORE) NSLog(@"displaying word %@, %@", self.selectedWord[@"spelling"], self.selectedWord[@"wordVariant"]);
    if ([self getSplitViewWithDisplayWordViewController]) { //iPad
        DisplayWordViewController *dwvc = [self getSplitViewWithDisplayWordViewController];
        [self setupDwvc:dwvc foriPhone:NO];
    } else { //iPhone (passing playWordsOnSelection handled in prepare for Segue)
        [self performSegueWithIdentifier:@"Search Word Selected" sender:self.selectedWord];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //used for iphone only
    if ([segue.identifier isEqualToString:@"Search Word Selected"]) {
        
        if ([segue.destinationViewController isKindOfClass:[DisplayWordViewController class]]) {
            DisplayWordViewController *dwvc = (DisplayWordViewController *)segue.destinationViewController;
            [self setupDwvc:dwvc foriPhone:YES];
        }
    }
}

-(void) setupDwvc:(DisplayWordViewController *)dwvc foriPhone:(BOOL)iPhone
{
    
    dwvc.homophonesForWord = [DD2Words homophonesForWord:self.selectedWord andWordList:self.allWords]; // always do to clear any homophonesForWord from prior words

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

#pragma mark Content Filtering

-(NSMutableArray *)wordsForFilteredWordsWithSearchText:(NSString*)searchText scope:(NSString*)scope stop:(BOOL *)stop {
    
    // Filter the array using NSPredicate
    NSPredicate *containsPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling contains[c] %@",searchText];
    NSMutableArray *wordsForFilteredWords = [NSMutableArray arrayWithArray:[self sortArrayAlphabetically:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:containsPredicate]]];
    
    if (![self isCurrentSearchText: searchText]) {
        *stop = YES;     //checking to see if searchText has changed
        NSLog(@"stop 0");
        return [wordsForFilteredWords copy];
    }
    
    //check for exact match(es) and put at top of list
    NSPredicate *exactMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling like %@",searchText];
    NSMutableArray *exactMatch = [NSMutableArray arrayWithArray:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:exactMatchPredicate]];
    NSPredicate *caseInsensitiveMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling like[c] %@",searchText];
    NSMutableArray *caseInsensitiveMatch = [NSMutableArray arrayWithArray:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:caseInsensitiveMatchPredicate]];
    if ([caseInsensitiveMatch count] > 0) {
        for (NSDictionary *word in caseInsensitiveMatch) {
            [wordsForFilteredWords insertObject:word atIndex:0];
        }
    }
    if ([exactMatch count] == 1) [wordsForFilteredWords insertObject:[exactMatch lastObject] atIndex:0];
    
    if (![self isCurrentSearchText: searchText]) {
        *stop = YES;     //checking to see if searchText has changed
        NSLog(@"stop 1");
        return [wordsForFilteredWords copy];
    }
    
    //set need to show addWord button if no beginswith (includes exact) matches for searchText
    NSPredicate *bwMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling beginswith[c] %@",searchText];
    NSArray *bwMatches = [wordsForFilteredWords filteredArrayUsingPredicate:bwMatchPredicate];
    
    //Check USUKVariants "spelling" type for matches (hide addWord button)
    NSMutableArray *usukVariantMatches = [NSMutableArray arrayWithArray:[self.allWords filteredArrayUsingPredicate:bwMatchPredicate]];
    
    if ([bwMatches count] < 1 && [usukVariantMatches count] < 1) self.showAddWordButton = YES;
    
    if (LOG_MORE) NSLog(@"search result list is %lu words long", (unsigned long)[wordsForFilteredWords count]);
    
    if (![self isCurrentSearchText: searchText]) {
        *stop = YES;     //checking to see if searchText has changed
        NSLog(@"stop 2");
        return [wordsForFilteredWords copy];
    }
    
    if ([wordsForFilteredWords count] < 15) {
        if (LOG_MORE) NSLog(@"Adding Levenshtein Distance matches");
        //check and add words to end of list if their LevenshteinDistance is low
        [self appendLowestLevenshteinDistanceWordsForSearchText:searchText toWordList:wordsForFilteredWords];
        if (LOG_MORE) NSLog(@"search result list is %lu words long  (with dups)", (unsigned long)[wordsForFilteredWords count]);
    }
    
    if (![self isCurrentSearchText: searchText]) {
        *stop = YES;     //checking to see if searchText has changed
        NSLog(@"stop 3");
        return [wordsForFilteredWords copy];
    }
    
    if ([wordsForFilteredWords count] < 15) {
        if (LOG_MORE) NSLog(@"Adding doubleMetaphone matches");
        //check for and append doubleMetaphone matches
        NSArray *searchTextDMCodes = [DD2GlobalHelper doubleMetaphoneCodesFor:searchText];
        
        //primary to primary
        NSPredicate *DMMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.doubleMphonePrimary beginswith[c] %@",[searchTextDMCodes objectAtIndex:0]];
        [self appendDMMatchesUsingPredicate:DMMatchPredicate toWordList:wordsForFilteredWords];
        //secondary (searchText) to primary only if searchText has a secondary doubleMetaphone code
        if ([searchTextDMCodes count] > 1) {
            DMMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.doubleMphonePrimary beginswith[c] %@",[searchTextDMCodes objectAtIndex:1]];
            [self appendDMMatchesUsingPredicate:DMMatchPredicate toWordList:wordsForFilteredWords];
        }
        //primary (searchText) to secondary
        DMMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.doubleMphoneAlt beginswith[c] %@",[searchTextDMCodes objectAtIndex:0]];
        [self appendDMMatchesUsingPredicate:DMMatchPredicate toWordList:wordsForFilteredWords];
        //secondary (searchText) to secondary only if searchText has a secondary doubleMetaphone code
        if ([searchTextDMCodes count] > 1) {
            DMMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.doubleMphoneAlt beginswith[c] %@",[searchTextDMCodes objectAtIndex:1]];
            [self appendDMMatchesUsingPredicate:DMMatchPredicate toWordList:wordsForFilteredWords];
        }
        if (LOG_MORE) NSLog(@"search result list is %lu words long (with dups)", (unsigned long)[wordsForFilteredWords count]);
    }
    return [wordsForFilteredWords copy];
}

-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredWords removeAllObjects];
    self.showAddWordButton = NO;
    
    // complete the search (on different thread - soon http://stackoverflow.com/questions/16685922/speed-up-search-using-dispatch-async)
    
    dispatch_async(self.workQueue, ^{
        NSDate *start = [NSDate date];
        
        //// quit before we even begin?
        if ( ![self isCurrentSearchText: searchText] )
            return;
    
        // we're going to search, so show the indicator (may already be showing)        //taken out as wasn't visible on the searchDisplayController
//        [self.activityIndicatorView performSelectorOnMainThread: @selector( startAnimating )
//                                                 withObject: nil
//                                              waitUntilDone: NO];
        
        BOOL stop = NO;
        NSMutableArray *wordsForFilteredWords = [self wordsForFilteredWordsWithSearchText:searchText scope:scope stop:&stop];
        
        if (stop)
        {
            NSTimeInterval ti = [start timeIntervalSinceNow];
            NSLog( @"interrupted search after %.4lf seconds, searchText = %@", -ti, self.currentSearchText);
            return;
        }
        

        if ( [self isCurrentSearchText:searchText] )
        {
            NSTimeInterval ti = [start timeIntervalSinceNow];
            NSLog( @"completed search in %.4lf seconds, searchText = %@", -ti, self.currentSearchText);
            
            dispatch_sync( dispatch_get_main_queue(), ^{
                
                // clean out all duplicates keeping order of first occurance in list
                self.filteredWords = [NSMutableArray arrayWithArray:[[NSOrderedSet orderedSetWithArray:wordsForFilteredWords] array]];
                NSLog(@"Showing %lu results", (unsigned long)[self.filteredWords count]);
                [self.searchDisplayController.searchResultsTableView reloadData];
//                [self.activityIndicatorView stopAnimating];
                
                //track search event with GA
                [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Search" action:@"All_words" label:searchText value:nil];

            });
        }
    });
}

- (void)appendDMMatchesUsingPredicate:(NSPredicate *)predicate toWordList:(NSMutableArray *)wordList
{
    NSMutableArray *dmMatches = [NSMutableArray arrayWithArray:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:predicate]];
    if ([dmMatches count] > 0 && [wordList count] < 15) {
        [wordList addObjectsFromArray:dmMatches];
    }
}

- (void)appendLowestLevenshteinDistanceWordsForSearchText:(NSString*)searchText toWordList:(NSMutableArray *)wordList
{
    int LDcutOff = 3;
    NSMutableArray *workingWordList = [NSMutableArray arrayWithCapacity:[self.allWordsForSpellingVariant count]];
    for (NSDictionary *word in self.allWordsForSpellingVariant) {
        NSMutableDictionary *wordWithLD = [NSMutableDictionary dictionaryWithDictionary:word];
        int levenshteinDistance = [DD2GlobalHelper LevenshteinDistance:searchText and:word[@"spelling"]];
        if (levenshteinDistance < LDcutOff) {
            [wordWithLD setObject:[NSNumber numberWithInt:levenshteinDistance] forKey:@"LD"];
            [workingWordList addObject:wordWithLD];
        }
    }
    NSSortDescriptor *sortByLD = [NSSortDescriptor sortDescriptorWithKey:@"LD" ascending:YES];
    NSArray *sortedWordList = [workingWordList sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByLD]];
    //print out if wanted the added LD words before removing the LD key/value ready for next search
    if (LOG_MORE) NSLog(@"sorted Word List LD < %i search = %@", LDcutOff, searchText);
    for (NSDictionary *word in sortedWordList) {
       if (LOG_MORE) NSLog(@"%@ LD = %@", word[@"spelling"], word[@"LD"]);
    }
    [sortedWordList makeObjectsPerformSelector:@selector(removeObjectForKey:) withObject:@"LD"];
    
    [wordList addObjectsFromArray:sortedWordList];
}

- (BOOL) isCurrentSearchText: (NSString*) searchText
{
    @synchronized (self)
    {
        // are we current at this point?
        BOOL current = [self.currentSearchText isEqualToString: searchText];
        return current;
    }
}


#pragma mark - UISearchDisplayController Delegate Methods

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    @synchronized (self) {          //setting currentSearchText so we can stop search if it changes.
        self.currentSearchText = searchString;
    }
    
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded. (don't always want to reload as search may be slow and out dated by it returns)
    return NO;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void) addwordButtonPressed {
    [DD2AllWordSearchViewController showAddWordRequested:self.title and:self.searchDisplayController.searchBar.text];
    self.searchDisplayController.searchBar.text = @"";
    [self.searchDisplayController setActive:NO];
}

+ (void) showAddWordRequested:(NSString *)dictionaryTitle and:(NSString *)requestedText     //used if no results and user requests words to be added to dictionary
{
    UIAlertView *alertUser = [[UIAlertView alloc] initWithTitle:@"Word Requested"
                                                        message:[NSString stringWithFormat:@"Thank you for asking for '%@' to be added to the list.\nDD will work to included it in an update soon.",requestedText]
                                                       delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertUser sizeToFit];
    [alertUser show];
    
    
    //track Add Word request event with GA
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_WordAddRequest" action:@"word_add_request" label:requestedText value:nil];
    
}

#pragma mark - DisplayWordViewControllerDelegate methods
- (void)DisplayWordViewController:(DisplayWordViewController *)sender homophoneSelected:(NSDictionary *)word
{
    NSLog(@"homonymSelected with word = %@",word);
    
    if (![self getSplitViewWithDisplayWordViewController]) { //iPhone
        //pop old word off navigation controller
        [self.navigationController popViewControllerAnimated:NO]; //Not animated as this is just preparing the Navigation Controller stack for the new word to be pushed on.
        }

    if (self.searchDisplayController.isActive) {
        
        if ([self.filteredWords containsObject:word]) {
            //Find where it is and scroll to it
            NSIndexPath * indexPathOfHomophone = [NSIndexPath indexPathForRow:[self.filteredWords indexOfObject:word] inSection:0];
            [self.searchDisplayController.searchResultsTableView selectRowAtIndexPath:indexPathOfHomophone animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            [self tableView:self.searchDisplayController.searchResultsTableView didSelectRowAtIndexPath:indexPathOfHomophone];
        } else {
            NSIndexPath *selectedCell = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:selectedCell animated:NO];
            self.selectedWord = word;
            [self displaySelectedWord];
        }
        
    } else {
        NSString *sectionOfHomophone = [word objectForKey:@"section"];
        NSArray *wordsForSection = [self.allWordsWithSections objectForKey:sectionOfHomophone];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWords = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        NSIndexPath *indexPathOfHomophone = [NSIndexPath indexPathForRow:[sortedWords indexOfObject:word] inSection:[self.sections indexOfObject:sectionOfHomophone]];
        // search is across all words so homophones will always be present.
        [self.tableView selectRowAtIndexPath:indexPathOfHomophone animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPathOfHomophone];
    }
}

- (void)DisplayWordViewController:(DisplayWordViewController *)sender otherVariantSelectedWhileDisplayingWord:(NSDictionary *)word
{
    // find otherVariant word,
    // display word
    
    if (![self getSplitViewWithDisplayWordViewController]) { //iPhone
        //pop old word off navigation controller
        [self.navigationController popViewControllerAnimated:NO]; //Not animated as this is just preparing the Navigation Controller stack for the new word to be pushed on.
    }
    NSDictionary *wordToBeDisplayed = [DD2Words wordWithOtherSpellingVariantFrom:word andListOfAllWords:self.allWords];
    if (LOG_MORE) NSLog(@"usukVariant to be displayed = %@", wordToBeDisplayed[@"spelling"]);
    self.selectedWord = wordToBeDisplayed;
    [self displaySelectedWord];
    
}

- (UIButton *)getAddWordButton
{
    UIButton *myButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [myButton addTarget:self action:@selector(addwordButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat buttonWidth = 225;  //hard coded for now
    CGFloat leftSpacing = (self.tableView.frame.size.width/2)-(buttonWidth/2);  //centralizing the button in the tableView
    CGFloat cRadius = 8; //corner radius for button
    CGFloat spacing = 4; // the amount of spacing to appear between image and title
    //NSLog(@"spacing = %f, buttonWidth = %f", leftSpacing, buttonWidth);
    myButton.frame = CGRectMake(leftSpacing, 4, buttonWidth, 45);
    
    [myButton setImage:[UIImage imageNamed:@"resources.bundle/Images/dinoOnlyIcon32x32.png"] forState:UIControlStateNormal];
    [myButton setTitle:@"Ask DD to add this word" forState:UIControlStateNormal];
    myButton.tintColor = [UIColor grayColor];
    
    UIImage *backImage = [DisplayWordViewController createImageOfColor:self.customBackgroundColor ofSize:CGSizeMake(40, 25) withCornerRadius:cRadius];
    UIImage *stretchableImage = [backImage resizableImageWithCapInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
    [myButton setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    
    myButton.layer.masksToBounds = YES;
    myButton.layer.cornerRadius = cRadius;
    myButton.layer.needsDisplayOnBoundsChange = YES;
    
    myButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacing);
    myButton.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
    
    return myButton;
}

- (UIImageView *)getUSUKVariantNotifierWithVariant: (NSString *)variant
{
    UIImageView *myImage = [UIImageView new];
    
    CGFloat imageWidth = 35;  //hard coded for now
    CGFloat leftSpacing = (self.tableView.frame.size.width)-(imageWidth*2.5);  //image to right in the tableView
    CGFloat cRadius = 0; //corner radius for button
    myImage.frame = CGRectMake(leftSpacing, 11, imageWidth, 32);
    
    NSString *imageToUse = [NSString stringWithFormat:@"resources.bundle/Images/%@_front_35x32.png", [variant uppercaseString]];
    [myImage setImage:[UIImage imageNamed:imageToUse]];
    
    myImage.layer.masksToBounds = YES;
    myImage.layer.cornerRadius = cRadius;
    myImage.layer.needsDisplayOnBoundsChange = YES;
    
    return myImage;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //set AutocapitalizationTypeNone as iOS8 causes this not to be set correctly from storyboard
    self.searchDisplayController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    if ([self getSplitViewWithDisplayWordViewController] && self.selectedWord) {
        [self displaySelectedWord];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:@"Search Tab Shown"];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
