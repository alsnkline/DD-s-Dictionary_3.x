//
//  htmlPageViewController.h
//  DDPrototype
//
//  Created by Alison KLINE on 1/19/13.
//
//

#import <UIKit/UIKit.h>

@interface htmlPageViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *urlToDisplay;
@property (nonatomic, strong) NSString *stringForTitle;

@end
