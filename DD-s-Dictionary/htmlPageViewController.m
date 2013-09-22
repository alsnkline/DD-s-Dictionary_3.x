//
//  htmlPageViewController.m
//  DDPrototype
//
//  Created by Alison KLINE on 1/19/13.
//
//

#import "htmlPageViewController.h"

@interface htmlPageViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation htmlPageViewController
@synthesize urlToDisplay = _urlToDisplay;
@synthesize stringForTitle =_stringForTitle;
@synthesize webView = _webView;
@synthesize customBackgroundColor = _customBackgroundColor;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setWebView:(UIWebView *)webView
{
    _webView = webView;
    NSLog(@"urlToDisplay = %@", self.urlToDisplay);
    self.webView.scalesPageToFit = NO;  //set to yes to enable zooming etc of the webpages
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = self.stringForTitle;
    NSLog(@"stingForTitle = %@", self.stringForTitle);
    self.webView.delegate = self;
    NSLog(@"urlToDisplay = %@", self.urlToDisplay);
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.urlToDisplay]];
    
    [self.webView setOpaque:NO];
    self.webView.backgroundColor = self.customBackgroundColor;
    
//    self.webView.scrollView.minimumZoomScale = 0.2;
//    self.webView.scrollView.maximumZoomScale = 5;
//    [self.webView.scrollView setZoomScale:2 animated:YES];
//    NSLog(@"zoomScale = %f", self.webView.scrollView.zoomScale);
//    NSLog(@"max zoomScale, min zoomscale = %f, %f", self.webView.scrollView.maximumZoomScale, self.webView.scrollView.minimumZoomScale);
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //track screen with GA
    [DD2GlobalHelper sendViewToGAWithViewName:[NSString stringWithFormat:@"Web view Shown : %@", self.stringForTitle]];
}

-(void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

// used in early versions before separating into its own html file.
//    NSFileManager *localFileManager = [[NSFileManager alloc] init];
//    NSString* filepath = [[NSBundle mainBundle] pathForResource:@"resources.bundle/Images/dinoOnlyIcon" ofType:@"png"];
//    if ([localFileManager fileExistsAtPath:filepath]) {
//        NSLog(@"found icon file at path %@", filepath);
//        NSURL* urlForIcon = [NSURL URLWithString:filepath];
//        NSLog(@"url = %@", urlForIcon);
//    }
//
//
//    NSString *html = @"<html><body><div align=""center""><img src=""icon-72e.png"" width=""72"" height=""72"" />    </div><h1  align=""center""> Dy-Di the <br /> Dyslexic's Dictionary </h1>   <p>I have managed my reading and writing challenges all my life and am now supporting my daughter as she starts  the same journey. I decided to create The Dyslexic’s Dictionary or Dy-Di (pronounced 'Dee Dee') to give those having difficulty spelling, a tool for independent discovery of an unknown spelling or a quick check of an uncertain one.</p>        <h2>Future enhancements </h2>        <p>I would love to hear your thougths and ideas for future enhancements. Some of the ideas I have had are:</p>            <ul>            <li>Contraction roots, <br /> ie showing ""he will"" by ""he'll""</li>            <li>Additional dictionaries with grade appropriate word lists</li>            <li>The ability to favorite words</li>            <li>Showing groups of words with similar components</li>            </ul></body></html>";
//    NSURL *baseURL = [NSURL URLWithString:@"http://www.google.com"];
//    [self.webView loadHTMLString:html baseURL:baseURL];

@end
