//
//  DD2SetTrackTableViewController.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/14/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DD2SetTrackTableViewController : UIViewController

@property (nonatomic) BOOL playWordsOnSelection;
@property (nonatomic) BOOL useDyslexieFont;
@property (nonatomic, strong) UIColor *customBackgroundColor;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
