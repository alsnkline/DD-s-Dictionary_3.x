//
//  DD2WordListTableViewController.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2SetTrackTableViewController.h"

@interface DD2WordListTableViewController : DD2SetTrackTableViewController

@property (nonatomic, strong) NSDictionary *wordListWithSectionsData; //the model for view if the table is to have sections
@property (nonatomic, strong) NSArray *wordListData; //the model for view if table is not to have sections

@end
