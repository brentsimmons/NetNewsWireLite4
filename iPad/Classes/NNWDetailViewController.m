//
//  DetailViewController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/3/10.
//  Copyright NewsGator Technologies, Inc. 2010. All rights reserved.
//

#import "NNWDetailViewController.h"
#import "NNWAppDelegate.h"
#import "NNWArticleViewController.h"
#import "NNWDatabaseController.h"
#import "NNWDetailContentContainerView.h"
#import "NNWFeedProxy.h"
#import "NNWMainViewController.h"
#import "NNWNewsItemProxy.h"
#import "NNWNewsListTableController.h"
#import "NNWURLProtocol.h"
#import "NNWWebPageViewController.h"

NSString *NNWFeedsPopoverWillDisplayNotification = @"NNWFeedsPopoverWillDisplayNotification";

@interface NSObject (NNWDetailViewController)
- (void)updateToolbar;
- (void)updateToolbarAllowingPopoverItem:(BOOL)allowPopover;
@end


@interface NNWDetailViewController ()
@property (nonatomic, retain, readwrite) UIPopoverController *feedsPopoverController;
//- (void)loadBlankPage;
- (void)swapInArticleViewController;
@end


@implementation NNWDetailViewController

@synthesize navigationBar, popoverController, detailItem;
@synthesize webView;
@synthesize contentViewController;
@synthesize popoverItem;
@synthesize toolbar;
@synthesize oldContentViewController;
@synthesize feedsPopoverController;
@synthesize contentViewContainer;


#pragma mark Init

- (id)init {
	self = [super initWithNibName:@"DetailView" bundle:nil];
	if (!self)
		return nil;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[navigationBar release];
	[popoverController release];
	[detailItem release];
	webView.delegate = nil;
	[webView release];
	[contentViewController release];
	[contentViewContainer release];
	[popoverItem release];
	[toolbar release];
	[oldContentViewController release];
	[feedsPopoverController release];
	[super dealloc];
}


#pragma mark -
#pragma mark Managing the popover controller

/*
 When setting the detail item, update the view and dismiss the popover controller if it's showing.
 */
- (void)setDetailItem:(id)newDetailItem {
    if (detailItem != newDetailItem) {
        [detailItem release];
        detailItem = [newDetailItem retain];
    }

    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }
	if ([detailItem isKindOfClass:[NNWNewsItemProxy class]]) {
		[self swapInArticleViewController];
		app_delegate.articleViewController.newsItem = (NNWNewsItemProxy *)detailItem;
	}
}

#pragma mark -
#pragma mark Toolbar

- (void)updateToolbar {
	NSMutableArray *toolbarItems = [NSMutableArray array];
	if (self.contentViewController == nil)
		[toolbarItems safeAddObject:self.popoverItem];
	[self.toolbar setItems:toolbarItems animated:NO];		
}


#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
 	self.popoverItem = barButtonItem;
 	self.popoverItem.width = 175;
	self.popoverItem.title = aViewController.title;
	if ([aViewController isKindOfClass:[UINavigationController class]])
		self.popoverItem.title = [(UINavigationController *)aViewController topViewController].title;
	if (RSStringIsEmpty(self.popoverItem.title))
		self.popoverItem.title = @"Feeds";
    self.popoverController = pc;
	self.popoverController.delegate = self;
	[self updateToolbar];
	[self.contentViewController updateToolbar];
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
 
	self.popoverItem = nil;
 	self.popoverController.delegate = nil;
	self.popoverController = nil;
	[self updateToolbar];
	[self.contentViewController updateToolbar];
}


- (void)splitViewController: (UISplitViewController*)svc popoverController: (UIPopoverController*)pc willPresentViewController:(UIViewController *)aViewController {
	self.feedsPopoverController = pc;
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWPopoverWillDisplayNotification object:self userInfo:[NSDictionary dictionaryWithObject:pc forKey:NNWPopoverControllerKey]];
}

#pragma mark PopoverController Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	self.feedsPopoverController = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWLeftPanePopoverDidDismissNotification object:self userInfo:nil];
}


- (void)closeFeedsPopoverController {
	if (self.feedsPopoverController == nil)
		return;
	[self.feedsPopoverController dismissPopoverAnimated:YES];
	self.feedsPopoverController = nil;	
}


- (void)handlePopoverWillDisplay:(NSNotification *)note {
	if ([[note userInfo] objectForKey:NNWPopoverControllerKey] != self.feedsPopoverController)
		[self closeFeedsPopoverController];
}


#pragma mark First run - display popover

- (void)displayPopoverIfNeeded {
	if (self.popoverItem == nil)
		return;
	[self.popoverItem.target performSelector:self.popoverItem.action];
}


#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	app_delegate.interfaceOrientation = toInterfaceOrientation;
	
	NSMutableDictionary *userInfoDict = [NSMutableDictionary dictionary];
	[userInfoDict setObject:[NSNumber numberWithInt:toInterfaceOrientation] forKey:@"orientation"];
	[userInfoDict setObject:[NSNumber numberWithDouble:duration] forKey:@"duration"];
	
	NSNotification *rotationNotification = [NSNotification notificationWithName:NNWWillAnimateRotationToInterfaceOrientation 
																		 object:nil 
																	   userInfo:userInfoDict];
	[[NSNotificationCenter defaultCenter] postNotification:rotationNotification];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.view setNeedsLayout];
	[self.contentViewContainer setNeedsLayout];
	[self.view layoutIfNeeded];
	[self.contentViewContainer layoutIfNeeded];
	[self updateToolbar];
	[self.contentViewController updateToolbar];
	
	NSMutableDictionary *userInfoDict = [NSMutableDictionary dictionary];
	[userInfoDict setObject:[NSNumber numberWithInt:fromInterfaceOrientation] forKey:@"orientation"];
	
	NSNotification *rotationNotification = [NSNotification notificationWithName:NNWDidAnimateRotationToInterfaceOrientation 
																		 object:nil 
																	   userInfo:userInfoDict];
	[[NSNotificationCenter defaultCenter] postNotification:rotationNotification];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	static BOOL didRegisterForNotifications = NO;
	if (!didRegisterForNotifications) {
		didRegisterForNotifications = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePopoverWillDisplay:) name:NNWPopoverWillDisplayNotification object:nil];
	}
	app_delegate.interfaceOrientation = self.interfaceOrientation;
	self.view.contentMode = UIViewContentModeRedraw;
	static BOOL didStartupTasks = NO;
	if (!didStartupTasks) {
		didStartupTasks = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsTitleDidChange:) name:NNWFeedsTitleDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsItemsTitleDidChange:) name:NNWNewsListTitleDidChangeNotification object:nil];
		[app_delegate addObserver:self forKeyPath:NNWLeftPaneViewControllerKey options:0 context:nil];
	}
}


- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.popoverController = nil;
}


- (void)didReceiveMemoryWarning {
	;
}


#pragma mark Notifications

static NSString *NNWPopoverButtonTitleWithUnreadCountFormat = @"%@%@ (%d)";
static NSString *NNWPopoverButtonTitleWithoutUnreadCountFormat = @"%@%@";
static NSString *NNWPopoverEllipsis = @"…";

- (NSString *)truncatedTitle {
	NSString *title = app_delegate.currentLeftPaneViewController.title;
	if (title == nil)
		return @"Feeds";
	if ([title length] < 22)
		return title;
	NSString *titleWithoutUnreadCount = ((NNWMainViewController *)(app_delegate.currentLeftPaneViewController)).titleWithoutUnreadCount;
	if (titleWithoutUnreadCount == nil)
		return RSEmptyString;
	NSInteger lengthOfTitle = [titleWithoutUnreadCount length];
	NSInteger endingIndex = 17;
	if (lengthOfTitle < endingIndex + 1)
		endingIndex = lengthOfTitle - 1;
	titleWithoutUnreadCount = [titleWithoutUnreadCount substringToIndex:endingIndex];
	BOOL addEllipsis = (endingIndex != lengthOfTitle - 1); 
	NSInteger unreadCount = 0;
	if ([app_delegate.currentLeftPaneViewController respondsToSelector:@selector(totalUnreadCount)])
		unreadCount = ((NNWMainViewController *)(app_delegate.currentLeftPaneViewController)).totalUnreadCount;
	else
		unreadCount = ((NNWNewsListTableController *)(app_delegate.currentLeftPaneViewController)).unreadCount;
	NSString *ellipsis = addEllipsis ? NNWPopoverEllipsis : RSEmptyString;
	if (unreadCount > 0)
		return [NSString stringWithFormat:NNWPopoverButtonTitleWithUnreadCountFormat, titleWithoutUnreadCount, ellipsis, unreadCount];
	return [NSString stringWithFormat:NNWPopoverButtonTitleWithoutUnreadCountFormat, titleWithoutUnreadCount, ellipsis];
}
							   
							   
- (void)currentLeftPaneViewControllerDidChange {
	self.popoverItem.title = [self truncatedTitle];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:NNWLeftPaneViewControllerKey])
		[self currentLeftPaneViewControllerDidChange];
}

- (void)feedsTitleDidChange:(NSNotification *)note {
	if (app_delegate.currentLeftPaneViewController == app_delegate.masterViewController)
		self.popoverItem.title = [self truncatedTitle];
}


- (void)newsItemsTitleDidChange:(NSNotification *)note {
	if (app_delegate.currentLeftPaneViewController == app_delegate.newsListViewController)
		self.popoverItem.title = [self truncatedTitle];
}


#pragma mark Fetch News Items

- (NSArray *)googleIDs {
	if ([self.detailItem isKindOfClass:[NNWFeedProxy class]])
		return [NSArray arrayWithObject:((NNWFeedProxy *)(self.detailItem)).googleID];
	return nil;
}

#pragma mark -
#pragma mark Actions

- (IBAction)showNewsItemsPopover:(id)sender {
}


static const NSTimeInterval kSwapAnimationDuration = 0.15;
static const UIViewAnimationCurve kSwapAnimationCurve = UIViewAnimationCurveEaseInOut;


- (void)setContentViewController:(UIViewController *)vc {
	if (vc == self.contentViewController)
		return;
	self.oldContentViewController = self.contentViewController;
	self.contentViewContainer.contentView = vc.view;
	
//	if([vc isKindOfClass:[NNWArticleViewController class]])
//	{
//		//vc.view.frame = CGRectMake(-(vcSize.width / 3), 0, vcSize.width, vcSize.height);
//		//vc.view.frame = CGRectMake(0, 0, vcSize.width, vcSize.height);
//		vc.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//		//[self.contentViewContainer addSubview:vc.view];
//		//vc.view.alpha = 0.0;
//		
//		// if I have a view now, its probably a webview
//		// it needs to animate to the left and just go away
//		if(self.contentViewController != nil)
//		{
//			self.oldContentViewController = self.contentViewController;
//			if ([self.oldContentViewController respondsToSelector:@selector(makeWebViewTransparent)])
//				[self.oldContentViewController performSelector:@selector(makeWebViewTransparent)];
//			[self.contentViewContainer insertSubview:vc.view belowSubview:self.oldContentViewController.view];
//			//CGSize oldViewSize = self.oldContentViewController.view.frame.size;
//			
//			[UIView beginAnimations:@"swapOutContentViewController" context:nil];
//			[UIView setAnimationDuration:kSwapAnimationDuration];
//			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
//			[UIView setAnimationDelegate:self];
//			[UIView setAnimationCurve:kSwapAnimationCurve];
////			self.oldContentViewController.view.frame = CGRectMake((+oldViewSize.width) / 3, 0, oldViewSize.width, oldViewSize.height);
//			self.oldContentViewController.view.alpha = 0.0;
//			//vc.view.frame = CGRectMake(0, 0, vcSize.width, vcSize.height);
//			vc.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//			vc.view.alpha = 1.0;
//			
//			[UIView commitAnimations];
//		}
//		else
//		{
//			[self.contentViewContainer addSubview:vc.view];
//			[UIView beginAnimations:@"swapOutContentViewController" context:nil];
//			[UIView setAnimationDuration:0.0f];
//			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
//			[UIView setAnimationDelegate:self];
//			[UIView setAnimationCurve:kSwapAnimationCurve];
//
//			//vc.view.frame = CGRectMake(0, 0, vcSize.width, vcSize.height);
//			vc.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//			vc.view.alpha = 1.0;
//			
//			[UIView commitAnimations];
//		}
//	}
//	else if ([vc isKindOfClass:[NNWWebPageViewController class]])
//	{
//		//vc.view.frame = CGRectMake(+(vcSize.width / 3), 0, vcSize.width, vcSize.height);
//		//vc.view.frame = CGRectMake(0, 0, vcSize.width, vcSize.height);
//		vc.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
////		[self.contentViewContainer insertSubview:vc.view atIndex:<#(NSInteger)index#>:vc.view];
//		//vc.view.alpha = 0.0;
//		
//		// if I have a view now, its probably an article view
//		// it needs to animate to the left and just go away
//		if(self.contentViewController != nil)
//		{
//			self.oldContentViewController = self.contentViewController;
//			if ([self.oldContentViewController respondsToSelector:@selector(makeWebViewTransparent)])
//				[self.oldContentViewController performSelector:@selector(makeWebViewTransparent)];
//			[self.contentViewContainer insertSubview:vc.view belowSubview:self.oldContentViewController.view];
//			CGSize oldViewSize = self.oldContentViewController.view.frame.size;
//			
//			[UIView beginAnimations:@"swapOutContentViewController" context:nil];
//			[UIView setAnimationDuration:kSwapAnimationDuration];
//			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
//			[UIView setAnimationDelegate:self];
//			[UIView setAnimationCurve:kSwapAnimationCurve];
//
//			self.oldContentViewController.view.frame = CGRectMake(0, 0, oldViewSize.width, oldViewSize.height);
//			self.oldContentViewController.view.alpha = 0.0;
//			//vc.view.frame = CGRectMake(0, 0, vcSize.width, vcSize.height);
//			vc.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//		vc.view.alpha = 1.0;
//			
//			[UIView commitAnimations];
//		}
//		else
//		{
//			[self.contentViewContainer addSubview:vc.view];
//			[UIView beginAnimations:@"swapOutContentViewController" context:nil];
//			[UIView setAnimationDuration:kSwapAnimationDuration];
//			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
//			[UIView setAnimationDelegate:self];
//			[UIView setAnimationCurve:kSwapAnimationCurve];
//
//			//vc.view.frame = CGRectMake(0, 0, vcSize.width, vcSize.height);
//			vc.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//			vc.view.alpha = 1.0;
//			
//			[UIView commitAnimations];
//		}
//	}
//	
	contentViewController = [vc retain];
//	[self updateToolbar];
////	[contentViewController viewWillAppear:YES];
//	[contentViewController updateToolbarAllowingPopoverItem:NO];
//	vc.view.contentMode = UIViewContentModeRedraw;
//	[self.contentViewContainer setNeedsLayout];
//	[self.contentViewContainer layoutIfNeeded];
//	[contentViewController viewDidAppear:YES];
//	[self.view setNeedsLayout];
}


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	if([animationID isEqualToString:@"swapOutContentViewController"])
	{
		[self.oldContentViewController.view removeFromSuperview];
		[self.oldContentViewController autorelease];
		[self.contentViewController updateToolbarAllowingPopoverItem:YES];
	}
	[self updateToolbar];
	[self.contentViewContainer setNeedsLayout];
	[self.contentViewContainer layoutIfNeeded];
	[self.view setNeedsLayout];
}

- (void)swapInArticleViewController {
	self.contentViewController = app_delegate.articleViewController;
}


@end
