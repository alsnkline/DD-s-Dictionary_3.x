//
//  DisplayWordViewController.h
//  DDPrototype
//
//  Created by Alison Kline on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DisplayWordViewController;

@protocol DisplayWordViewControllerDelegate <NSObject> //added <NSObject> so we can do a respondsToSelector: on the delegate
@optional

- (void) DisplayWordViewController:(DisplayWordViewController *) sender 
                                homophoneSelectedWith:(NSString *)spelling;
@end


@interface DisplayWordViewController : UIViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) NSDictionary * word; //word for display the model for this MVC
@property (nonatomic, strong) NSDictionary * homophonesForWord;  //NSDictionary key is pronunciation value is an Array containing all the homophones for that pronunciation
@property (nonatomic) BOOL playWordsOnSelection;
@property (nonatomic) BOOL useDyslexieFont;
@property (nonatomic, strong) UIColor *customBackgroundColor;
@property (nonatomic, weak) id <DisplayWordViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *spelling;
@property (weak, nonatomic) IBOutlet UIButton *listenButton;
@property (weak, nonatomic) IBOutlet UIButton *heteronymListenButton;
@property (weak, nonatomic) IBOutlet UIView *wordView;
@property (weak, nonatomic) IBOutletCollection(UIButton) NSArray *homophoneButtons;
@property (weak, nonatomic) IBOutlet UIButton *homophoneButton1;
@property (weak, nonatomic) IBOutlet UIButton *homophoneButton2;
@property (weak, nonatomic) IBOutlet UIButton *homophoneButton3;
@property (weak, nonatomic) IBOutlet UIButton *homophoneButton4;
@property (weak, nonatomic) IBOutlet UIButton *homophoneButton5;
@property (weak, nonatomic) IBOutlet UIButton *homophoneButton6;

- (IBAction)listenToWord:(id)sender;
- (void)playAllWords:(NSSet *)pronunciations;
+ (UIImage *)createImageOfColor:(UIColor *)color ofSize:(CGSize)size withCornerRadius:(float)cRadius;

@end
