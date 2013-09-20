//
//  DD2AllWordSearchViewController.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2SetTrackTableViewController.h"

@interface DD2AllWordSearchViewController : DD2SetTrackTableViewController

@property (nonatomic, strong) NSArray *allWordsForSpellingVariant; //the model for search view does not have sections and allows homophone look up 

@end
