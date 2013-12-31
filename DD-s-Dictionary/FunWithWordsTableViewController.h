//
//  FunWithWordsTableViewController.h
//  DDPrototype
//
//  Created by Alison KLINE on 5/13/13.
//
//

#import <UIKit/UIKit.h>

@interface FunWithWordsTableViewController : UITableViewController
@property (nonatomic, strong) NSArray *allWordsForSpellingVariant;        //model for this MVC
@property (nonatomic, strong) NSArray *allWords;                           //used to set up list displays completely and allow us/uk quick switches.
@property (nonatomic, strong) NSArray *tagNames;
@property (nonatomic, strong) NSArray *smallCollections;

@end
