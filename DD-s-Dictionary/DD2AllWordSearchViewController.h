//
//  DD2AllWordSearchViewController.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2SetTrackTableViewController.h"

@interface DD2AllWordSearchViewController : DD2SetTrackTableViewController

@property (nonatomic, strong) NSArray *allWordsForSpellingVariant; //the model (word list) for search view does not have sections
@property (nonatomic, strong) NSArray *allWords; //full list of words used for showing UK/US word differences on word level display and more general homophone look up
@property (nonatomic, strong) NSDictionary *selectedWord;       //public so that TabBarViewController can clear it is spellingVariant changes

@end
