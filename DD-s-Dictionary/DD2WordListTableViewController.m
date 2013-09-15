//
//  DD2WordListTableViewController.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2WordListTableViewController.h"
#import "DisplayWordViewController.h"

@interface DD2WordListTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray *sections;    //only used if data is a dictionary with sections
@property (nonatomic, strong) NSDictionary *selectedWord;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DD2WordListTableViewController
@synthesize wordListData = _wordListData;
@synthesize wordListWithSectionsData = _wordListWithSectionsData;
@synthesize sections = _sections;
@synthesize selectedWord = _selectedWord;

//-(NSArray *)wordListData {
//    if (!_wordListData) _wordListData = [[NSArray alloc] init];
//    return _wordListData;
//}

-(void)setWordListData:(NSArray *)wordListData {
    if (wordListData != _wordListData) {
        _wordListData = wordListData;
        self.wordListWithSectionsData = nil;
        self.sections = nil;
    }
}

//-wordListWithSectionsData {
//    if (!_wordListWithSectionsData) _wordListWithSectionsData = [[NSDictionary alloc] init];
//    return _wordListWithSectionsData;
//}

-(void)setWordListWithSectionsData:(NSDictionary *)wordListWithSectionsData {
    if (wordListWithSectionsData != _wordListWithSectionsData) {
        _wordListWithSectionsData = wordListWithSectionsData;
        self.sections = [[wordListWithSectionsData allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        self.wordListData = nil;
    }
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
        return [self.wordListData count];
    } else {
        return [[self.wordListWithSectionsData objectForKey:[self.sections objectAtIndex:section]] count];
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
    
    cell.textLabel.font = self.useDyslexieFont ? [UIFont fontWithName:@"Dyslexiea-Regular" size:20] : [UIFont boldSystemFontOfSize:20];
    
    if (!self.sections) {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWords = [self.wordListData sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        NSDictionary *word = [sortedWords objectAtIndex:indexPath.row];
        cell.textLabel.text = [word objectForKey:@"spelling"];
    } else {
        NSArray *wordsForSection = [self.wordListWithSectionsData objectForKey:[self.sections objectAtIndex:indexPath.section]];
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
        return [self.wordListData objectAtIndex:indexPath.row];
    } else {
        NSArray *wordsForSection = [self.wordListWithSectionsData objectForKey:[self.sections objectAtIndex:indexPath.section]];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortedWordsForSection = [wordsForSection sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
        return [sortedWordsForSection objectAtIndex:indexPath.row];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self wordSelectedAtIndexPath:(NSIndexPath *)indexPath fromTableView:tableView];
}

- (void) wordSelectedAtIndexPath:(NSIndexPath *)indexPath fromTableView:(UITableView *)tableView
{
    
    self.selectedWord = [self wordForIndexPath:indexPath];
    
    if ([self getSplitViewWithDisplayWordViewController]) { //iPad
        DisplayWordViewController *dwvc = [self getSplitViewWithDisplayWordViewController];
        dwvc.word = self.selectedWord;
        if (self.playWordsOnSelection) {
            [dwvc playAllWords:[DD2GlobalHelper pronunciationsForWord:self.selectedWord]];
        }
    } else { //iPhone (passing playWordsOnSelection handled in prepare for Segue)
        [self performSegueWithIdentifier:@"Word Selected" sender:self.selectedWord];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //used for iphone only
    if ([segue.identifier isEqualToString:@"Word Selected"]) {
        [segue.destinationViewController setWord:self.selectedWord];
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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
