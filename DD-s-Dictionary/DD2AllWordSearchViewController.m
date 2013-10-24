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

@end

@implementation DD2AllWordSearchViewController
@synthesize allWordsForSpellingVariant = _allWordsForSpellingVariant;
@synthesize allWordsWithSections = _allWordsWithSections;
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize filteredWords = _filteredWords;
@synthesize sections = _sections;
@synthesize selectedWord = _selectedWord;


-(void)setAllWordsForSpellingVariant:(NSArray *)allWordsForSpellingVariant
{
    NSArray *sortedWords = [self sortArrayAlphabetically:allWordsForSpellingVariant];
    if (sortedWords != _allWordsForSpellingVariant) {
        _allWordsForSpellingVariant = sortedWords;
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
    
    //track search start with Flurry
    [Flurry logEvent:@"Dict Search Started"];
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
            return [self.filteredWords count];
        } else {
            return 1;   //for add word button
        }
    } else {
        return [[self.allWordsWithSections objectForKey:[self.sections objectAtIndex:section]] count];
    }
}

#define ADD_WORD_BUTTON_TAG 1111

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
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if ([self.filteredWords count]>0) {
            // clean out add button if there is one
            if ([cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG]) [[cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG] removeFromSuperview];
            NSDictionary *word = [self.filteredWords objectAtIndex:indexPath.row];
            cell.textLabel.text = [word objectForKey:@"spelling"];
            
        } else {    //Search has no results
            if (![cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG]) { //button isn't already present
                cell.textLabel.text = @"";
                UIButton *button = [self getAddWordButton];
                button.tag = ADD_WORD_BUTTON_TAG;
                [cell.contentView addSubview:button];
            }
        }
    } else {
        // clean out add button if there is one
        if ([cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG]) [[cell.contentView viewWithTag:ADD_WORD_BUTTON_TAG] removeFromSuperview];
        // reset accessoryType
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        // set text for cell
        NSArray *wordsForSection = [self.allWordsWithSections objectForKey:[self.sections objectAtIndex:indexPath.section]];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWords = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        NSDictionary *word = [sortedWords objectAtIndex:indexPath.row];
        cell.textLabel.text = [word objectForKey:@"spelling"];
        
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
    self.selectedWord = [self wordForIndexPath:indexPath fromTableView:tableView];
    [self displaySelectedWord];
}

- (void) displaySelectedWord
{
    if ([self getSplitViewWithDisplayWordViewController]) { //iPad
        DisplayWordViewController *dwvc = [self getSplitViewWithDisplayWordViewController];
        dwvc.homophonesForWord = [DD2Words homophonesForWord:self.selectedWord andWordList:self.allWordsForSpellingVariant];
        dwvc.word = self.selectedWord;
        dwvc.delegate = self;
        if (self.playWordsOnSelection) {
            [dwvc playAllWords:[DD2Words pronunciationsForWord:self.selectedWord]];
        }
    } else { //iPhone (passing playWordsOnSelection handled in prepare for Segue)
        [self performSegueWithIdentifier:@"Search Word Selected" sender:self.selectedWord];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //used for iphone only
    if ([segue.identifier isEqualToString:@"Search Word Selected"]) {
        [segue.destinationViewController setWord:self.selectedWord];
        [segue.destinationViewController setHomophonesForWord:[DD2Words homophonesForWord:self.selectedWord andWordList:self.allWordsForSpellingVariant]];
        if (self.playWordsOnSelection) {
            [segue.destinationViewController setPlayWordsOnSelection:self.playWordsOnSelection];
        }
        if (self.customBackgroundColor) {
            [segue.destinationViewController setCustomBackgroundColor:self.customBackgroundColor];
        }
        if (self.useDyslexieFont) {
            [segue.destinationViewController setUseDyslexieFont:self.useDyslexieFont];
        }
        [segue.destinationViewController setDelegate:self];
    }
}

#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredWords removeAllObjects];
    
    // Filter the array using NSPredicate
    NSPredicate *containsPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling contains[c] %@",searchText];
    self.filteredWords = [NSMutableArray arrayWithArray:[self sortArrayAlphabetically:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:containsPredicate]]];
    
    //check for exact match
    NSPredicate *exactMatchPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling like[c] %@",searchText];
    NSMutableArray *matches = [NSMutableArray arrayWithArray:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:exactMatchPredicate]];
    if ([matches count]==1) {
        [self.filteredWords removeObject:[matches objectAtIndex:0]];
        [self.filteredWords insertObject:[matches objectAtIndex:0] atIndex:0];
    }
    //if ([matches count] == 0) NSLog(@"no exact match");
    if ([matches count] > 1) NSLog(@"we have too many exact matches");
    
    //track search event with GA
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_Search" action:@"All_words" label:searchText value:nil];
    
    //track search event with Flurry
    NSDictionary *flurryParameters = @{@"searchTerm" : searchText};
    [Flurry logEvent:@"uiAction_Search" withParameters:flurryParameters];
}

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
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
                                                        message:[NSString stringWithFormat:@"Thank you for asking for '%@' to be added to the list.\nDD with work to included it in an update soon.",requestedText]
                                                       delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertUser sizeToFit];
    [alertUser show];
    
    
    //track Add Word request event with GA
    [DD2GlobalHelper sendEventToGAWithCategory:@"uiAction_WordAddRequest" action:@"word_add_request" label:requestedText value:nil];
    //track Add Word request event with Flurry
    NSDictionary *flurryParameters = @{@"word_add_request" : requestedText};
    [Flurry logEvent:@"uiAction_WordAddRequest" withParameters:flurryParameters];
    
}

#pragma mark - DisplayWordViewControllerDelegate method
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
