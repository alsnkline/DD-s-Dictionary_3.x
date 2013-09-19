//
//  DD2WordListTableViewController.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2SetTrackTableViewController.h"

@interface DD2WordListTableViewController : DD2SetTrackTableViewController

@property (nonatomic, strong) NSArray *wordList; //the model for the table and full list of words displayed in the table
@property (nonatomic, strong) NSDictionary *wordListWithSections; //the word for display organised by section if the table is to have sections
@property (nonatomic, strong) NSArray *sections;    //populated from wordListWithSections, if nil table will use wordList and won't have sections
@property (nonatomic, strong) NSArray *allWordsForSpellingVariant;      //needed for Homophone lookup

@end
