//
//  DD2SettingsTableViewCell.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/22/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DD2SettingsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISlider *smallSlider;
@property (weak, nonatomic) IBOutlet UISwitch *cellSwitch;
@property (weak, nonatomic) IBOutlet UISlider *bigSlider;

@end
