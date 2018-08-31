//
//  DetailViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/3/10.
//  Copyright NewsGator Technologies, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *NNWFeedsPopoverWillDisplayNotification;

@class NNWDetailContentContainerView;

@interface NNWDetailViewController : UIViewController <UIPopoverControllerDelegate, UISplitViewControllerDelegate> {
    
    UIPopoverController *popoverController;
    UINavigationBar *navigationBar;
    
	UIWebView *webView;
    id detailItem;
	
	UIViewController *contentViewController;
	UIViewController *oldContentViewController;
	NNWDetailContentContainerView *contentViewContainer;
	
	UIBarButtonItem *popoverItem;
	UIToolbar *toolbar;
	UIPopoverController *feedsPopoverController;
}


/*To change the main content view, set the contentViewController. The toolbar remains static:
 the app will get the new toolbar items from the new contentViewController.*/

@property (nonatomic, retain) UIViewController *contentViewController;


@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet NNWDetailContentContainerView *contentViewContainer;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) UIBarButtonItem *popoverItem;
@property (nonatomic, retain) id detailItem;
@property (nonatomic, retain, readonly) UIPopoverController *feedsPopoverController;

@property (nonatomic, retain) UIViewController *oldContentViewController;

- (IBAction)showNewsItemsPopover:(id)sender;
- (void)swapInArticleViewController;

@end
