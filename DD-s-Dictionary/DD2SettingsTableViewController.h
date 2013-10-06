//
//  DD2SettingsTableViewController.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/21/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DD2SettingsTableViewController : UIViewController

@property (nonatomic, strong) NSArray *collectionNames;
@property (nonatomic, strong) NSMutableArray *selectedCollections;

+ (void) manageWindowTintColor;
+ (NSMutableArray *) limitSelectedCollections:(NSMutableArray *)selectedCollections;

@end


@interface DD2SettingsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISlider *smallSlider;
@property (weak, nonatomic) IBOutlet UISwitch *cellSwitch;
@property (weak, nonatomic) IBOutlet UISlider *bigSlider;

@end