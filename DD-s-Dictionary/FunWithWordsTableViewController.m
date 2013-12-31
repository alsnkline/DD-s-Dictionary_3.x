//
//  FunWithWordsTableViewController.m
//  DDPrototype
//
//  Created by Alison KLINE on 5/13/13.
//
//

#import "FunWithWordsTableViewController.h"
#import "NSUserDefaultKeys.h"
#import "DD2WordListTableViewController.h"

@interface FunWithWordsTableViewController ()

@property (nonatomic, strong) UIColor *customBackgroundColor;
@property (nonatomic) BOOL useDyslexieFont;
@property (nonatomic, strong) NSPredicate *predicateForSelectedCell;

@end

@implementation FunWithWordsTableViewController

@synthesize customBackgroundColor = _customBackgroundColor;
@synthesize useDyslexieFont = _useDyslexieFont;
@synthesize tagNames = _tagNames;
@synthesize smallCollections = _smallCollections;
@synthesize allWordsForSpellingVariant = _allWordsForSpellingVariant;
@synthesize allWords = _allWords;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)setAllWordsForSpellingVariant:(NSArray *)allWordsForSpellingVariant {
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"spelling" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedWords = [allWordsForSpellingVariant sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
    if (sortedWords != _allWordsForSpellingVariant) {
        _allWordsForSpellingVariant = sortedWords;
        [self.tableView reloadData];
    }
}

-(void)setTagNames:(NSArray *)tagNames{
    
    NSArray *sortedTags = [tagNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    if (sortedTags != _tagNames) {
        _tagNames = sortedTags;
    }
    //[self.tableView reloadData];
}

-(void)setSmallCollections:(NSArray *)smallCollections{
    NSArray *sortedCollections = [smallCollections sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    if (sortedCollections != _smallCollections) {
        _smallCollections = sortedCollections;
    }
}

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
        [self setupColor];
    }
}
-(void)setupColor
{
    if ([self.tableView indexPathForSelectedRow]) {
        // we have to deselect change color and reselect or we get the old color showing up when the selection is changed.
        NSIndexPath *selectedCell = [self.tableView indexPathForSelectedRow];
        [self.tableView deselectRowAtIndexPath:selectedCell animated:NO];
        [self setCellBackgroundColor];
        [self.tableView selectRowAtIndexPath:selectedCell animated:NO scrollPosition:UITableViewScrollPositionNone]; //not animated so it takes effect immediately
        [self.tableView deselectRowAtIndexPath:selectedCell animated:YES]; //animated so the user sees it deselect gracefully.
    } else {
        [self setCellBackgroundColor];
    }
}

- (void) setCellBackgroundColor
{
    NSArray *tableCells = self.tableView.visibleCells;
    for (UITableViewCell *cell in tableCells)
    {
        cell.backgroundColor = self.customBackgroundColor;
    }
    
}

- (void) setVisibleCellsCellTextLabelFont
{
    NSArray *tableCells = self.tableView.visibleCells;
    for (UITableViewCell *cell in tableCells)
    {
        [self setTextLabelFontForCell:cell];
    }
    
}

- (void) setTextLabelFontForCell:(UITableViewCell *)cell
{
    cell.textLabel.font = self.useDyslexieFont ? [UIFont fontWithName:@"Dyslexiea-Regular" size:18] : [UIFont boldSystemFontOfSize:20];
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
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    NSLog(@"view controller stack : %@", viewControllers);
    
    [self setupColor];
    [self setVisibleCellsCellTextLabelFont];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:@"Fun With Words Tab Shown"];
    //track Tab Appeared with Flurry
    [Flurry logEvent:@"Tab Appeared: Fun"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO; //taking control manually so that the background color change can be done after this.

 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //registering for color notifications remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"customBackgroundColorChanged" object:nil];

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSInteger sectionNumber = 3;
    return sectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 2;
    if (section == 1) {
        rowCount = [self.smallCollections count];
    }
    if (section == 2) {
        rowCount = [self.tagNames count];
    }
    return rowCount;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *titleForSection = nil;
    if (section == 0) {
        titleForSection = [NSString stringWithFormat:@"Word types:"];
    } else if (section == 1) {
        titleForSection = [NSString stringWithFormat:@"Related Meanings:"];
    } else if (section == 2) {
        titleForSection = [NSString stringWithFormat:@"Pronunciation groups:"];
    }
    return titleForSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

//    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath]; //used for updating a static cell programatically
    
    static NSString *cellIdentifier = @"Fun With Words Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell ==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    if (section == 0) {
        if (row == 0) cell.textLabel.text = [NSString stringWithFormat:@"homophones"];
        if (row == 1) cell.textLabel.text = [NSString stringWithFormat:@"heteronyms"];
    }
    if (section == 1) {
        cell.textLabel.text = [DD2Words exchangeUnderscoresForSpacesin:[self.smallCollections objectAtIndex:indexPath.row]];
    }
    if (section == 2) {
        cell.textLabel.text = [DD2Words exchangeUnderscoresForSpacesin:[self.tagNames objectAtIndex:indexPath.row]];
    }
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = self.customBackgroundColor;
    [self setTextLabelFontForCell:cell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Indexpath of Selected Cell = %@", indexPath);
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"Cell Label = %@", selectedCell.textLabel.text);
    
    if ([indexPath isEqual:[NSIndexPath indexPathForItem:0 inSection:0]]) {
        // homophones
        self.predicateForSelectedCell = [NSPredicate predicateWithFormat:@"locHomophones.@count > 0"];
        // Appington
        [Appington control:@"conversion" andValues:@{@"id": @"22"}];
        if (LOG_APPINGTON_NOTIFICATIONS) NSLog(@"Appington conversion id 22 (homophones) sent");
    } else if ([indexPath isEqual:[NSIndexPath indexPathForItem:1 inSection:0]]) {
        // heteronyms
        self.predicateForSelectedCell = [NSPredicate predicateWithFormat:@"pronunciations.@count > 1"];
        // from http://www.raywenderlich.com/14742/core-data-on-ios-5-tutorial-how-to-work-with-relations-and-predicates
        // Appington
        [Appington control:@"conversion" andValues:@{@"id": @"23"}];
        if (LOG_APPINGTON_NOTIFICATIONS) NSLog(@"Appington conversion id 23 (heteronyms) sent");
    } else if (indexPath.section == 1) {
        // small_collections
        self.predicateForSelectedCell = [NSPredicate predicateWithFormat:@"SELF.small_collection contains[c] %@",[DD2Words exchangeSpacesForUnderscoresin:selectedCell.textLabel.text]];
    } else if (indexPath.section == 2) {
        // tags
        self.predicateForSelectedCell = [NSPredicate predicateWithFormat:@"SELF.tags contains[c] %@",[DD2Words exchangeSpacesForUnderscoresin:selectedCell.textLabel.text]];
    }
    
    [self performSegueWithIdentifier:@"Fun Tag Selected" sender:selectedCell];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Fun Tag Selected"]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            
            //selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling contains[cd] %@", stringForPredicate];
            //selectionPredicate = [NSPredicate predicateWithFormat:@"inGroups.@count > 0"]; //worked
            //selectionPredicate = [NSPredicate predicateWithFormat:@"%@ IN SELF.inGroups.displayName", cell.textLabel.text];

            if (LOG_PREDICATE_RESULTS) NSLog(@"predicate = %@", self.predicateForSelectedCell);
            if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:self.predicateForSelectedCell onWords:self.allWordsForSpellingVariant];
            
            [segue.destinationViewController setAllWordsForSpellingVariant:self.allWordsForSpellingVariant];
            [segue.destinationViewController setAllWords:self.allWords];
            [segue.destinationViewController setTitle:cell.textLabel.text];
            [segue.destinationViewController setWordList:[NSMutableArray arrayWithArray:[self.allWordsForSpellingVariant filteredArrayUsingPredicate:self.predicateForSelectedCell]]];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
