//
//  DD2AllWordSearchViewController.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2SetTrackTableViewController.h"

@interface DD2AllWordSearchViewController : DD2SetTrackTableViewController

@property (nonatomic, strong) NSDictionary *allWordsWithSections; //the model for main table view has sections
@property (nonatomic, strong) NSArray *allWords; //the model for search view does not have sections

@end
