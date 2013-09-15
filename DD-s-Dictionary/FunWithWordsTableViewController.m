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

@property (nonatomic, strong) NSString *spellingVariant;
@property (nonatomic, strong) UIColor *customBackgroundColor;
@property (nonatomic) BOOL useDyslexieFont;
@property (nonatomic, strong) NSArray *tagNames;
@property (nonatomic, strong) NSArray *allWords;

@end

@implementation FunWithWordsTableViewController

@synthesize spellingVariant = _spellingVariant;
@synthesize customBackgroundColor = _customBackgroundColor;
@synthesize useDyslexieFont = _useDyslexieFont;
@synthesize tagNames = _tagNames;
@synthesize allWords = _allWords;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(NSArray *)tagNames{
    if(!_tagNames) _tagNames = [DD2Words tagNames];
    return _tagNames;
}

- (NSArray *)allWords
{
    if(!_allWords) _allWords = [DD2Words allWordsWithSpellingVariant:self.spellingVariant];
    return _allWords;
}

- (NSString *)spellingVariant
{
    if (!_spellingVariant) {
        _spellingVariant = [[NSUserDefaults standardUserDefaults] stringForKey:SPELLING_VARIANT];
    }
    return _spellingVariant;
}
- (void)setSpellingVariant:(NSString *)spellingVariant
{
    if (spellingVariant != _spellingVariant) {
        _spellingVariant = spellingVariant;
        _allWords = nil;
        [self.tableView reloadData];        //not sure this is needed as the table doesn't show any word with a uk/us variants.
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
        self.customBackgroundColor = [userinfo objectForKey:@"newColor"];
    }
    if ([[notification name] isEqualToString:@"spellingVariantChanged"]) {
        NSDictionary *userinfo = [notification userInfo];
        self.spellingVariant = [userinfo objectForKey:@"newSpellingVariant"];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setupColor];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //set useDyslexieFont if necessary
    if (self.useDyslexieFont != [defaults boolForKey:USE_DYSLEXIE_FONT]) {
        self.useDyslexieFont = [defaults boolForKey:USE_DYSLEXIE_FONT];
        [self setVisibleCellsCellTextLabelFont];
    }
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
    //registering for spellingVariant notifications  remember to dealloc
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotification:)
                                                 name:@"spellingVariantChanged" object:nil];
    
    //To DO clean up useDylexie font and use notification - possibly subclass DD2SetTrackTableViewController
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
    NSInteger sectionNumber = 1;
    if ([self.tagNames count] > 0) sectionNumber = 2;
    return sectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 2;
    if (section == 1) rowCount = [self.tagNames count];
    return rowCount;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *titleForSection = nil;
    if (section == 0) {
        titleForSection = [NSString stringWithFormat:@"Word types:"];
    } else if (section == 1) {
        titleForSection = [NSString stringWithFormat:@"Word groups:"];
    }
    return titleForSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

//    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath]; //used for updating a static cell programatically
    
    static NSString *cellIdentifier = @"Fun With Words Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
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
        cell.textLabel.text = [self.tagNames objectAtIndex:indexPath.row];
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
    //need to implement push segue called "Fun Tag Selected"
    
    NSLog(@"Indexpath of Selected Cell = %@", indexPath);
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    [self performSegueWithIdentifier:@"Fun Tag Selected" sender:selectedCell];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Fun Tag Selected"]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSLog(@"Cell Label = %@", cell.textLabel.text);
            
            NSInteger switchValue;  //not really used yet, set up incase options got out of control
            NSPredicate *selectionPredicate;
            
            if ([cell.textLabel.text isEqualToString:@"homophones"]) {
                switchValue = 0;
                selectionPredicate = [NSPredicate predicateWithFormat:@"homophones.@count > 0"];
            } else if ([cell.textLabel.text isEqualToString:@"heteronyms"]) {
                switchValue = 1;
                selectionPredicate = [NSPredicate predicateWithFormat:@"pronunciations.@count > 1"];
                // from http://www.raywenderlich.com/14742/core-data-on-ios-5-tutorial-how-to-work-with-relations-and-predicates
            } else {
                switchValue = 5;
                selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.tags contains[c] %@",cell.textLabel.text];
            }
            
            //selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling contains[cd] %@", stringForPredicate];
            //selectionPredicate = [NSPredicate predicateWithFormat:@"inGroups.@count > 0"]; //worked
            //selectionPredicate = [NSPredicate predicateWithFormat:@"%@ IN SELF.inGroups.displayName", cell.textLabel.text];

            NSLog(@"predicate = %@", selectionPredicate);
            if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:self.allWords];
            
            [segue.destinationViewController setTitle:cell.textLabel.text];
            [segue.destinationViewController setWordListData:[NSMutableArray arrayWithArray:[self.allWords filteredArrayUsingPredicate:selectionPredicate]]];

        }
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
