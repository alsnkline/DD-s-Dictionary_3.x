//
//  DD2AllWordSearchViewController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2AllWordSearchViewController.h"
#import "DisplayWordViewController.h"

@interface DD2AllWordSearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, DisplayWordViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *filteredWords;
@property (nonatomic, strong) NSArray *sections;    //only used in main tableview
@property (nonatomic, strong) NSDictionary *selectedWord;

@end

@implementation DD2AllWordSearchViewController
@synthesize allWordsForSpellingVariant = _allWordsForSpellingVariant;
@synthesize allWordsWithSections = _allWordsWithSections;
@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;
@synthesize filteredWords = _filteredWords;
@synthesize sections = _sections;
@synthesize selectedWord = _selectedWord;


-(void)setAllWordsForSpellingVariant:(NSArray *)allWordsForSpellingVariant {
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedWords = [allWordsForSpellingVariant sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
    if (sortedWords != _allWordsForSpellingVariant) {
        _allWordsForSpellingVariant = sortedWords;
        [self.tableView reloadData];
    }
}

-(void)setFilteredWords:(NSMutableArray *)filteredWords {
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedWords = [filteredWords sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
    if (sortedWords != _filteredWords) {
        _filteredWords = [NSMutableArray arrayWithArray:sortedWords];
    }
}

-(void)setAllWordsWithSections:(NSDictionary *)allWordsWithSections
{
    if (allWordsWithSections != _allWordsWithSections) {
        _allWordsWithSections = allWordsWithSections;
        self.sections = [[allWordsWithSections allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
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
        return [self.filteredWords count];
    } else {
        return [[self.allWordsWithSections objectForKey:[self.sections objectAtIndex:section]] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Search Word";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell ==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    cell.textLabel.font = self.useDyslexieFont ? [UIFont fontWithName:@"Dyslexiea-Regular" size:20] : [UIFont boldSystemFontOfSize:20];
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        //NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        //NSArray *sortedWords = [self.filteredWords sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        NSDictionary *word = [self.filteredWords objectAtIndex:indexPath.row];
        cell.textLabel.text = [word objectForKey:@"spelling"];
    } else {
        NSArray *wordsForSection = [self.allWordsWithSections objectForKey:[self.sections objectAtIndex:indexPath.section]];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWords = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        NSDictionary *word = [sortedWords objectAtIndex:indexPath.row];
        cell.textLabel.text = [word objectForKey:@"spelling"];
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


#pragma mark - Table view delegate

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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.spelling contains[c] %@",searchText];
    
    self.filteredWords = [NSMutableArray arrayWithArray:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:predicate]];
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


//DisplayWordViewControllerDelegate method
- (void)DisplayWordViewController:(DisplayWordViewController *)sender homophoneSelected:(NSDictionary *)word
{
    NSLog(@"homonymSelected with word = %@",word);
    //find the selected word
    //find the indexPathOfHomophone (the new one so you can scroll to it)
    // if in iphone
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
