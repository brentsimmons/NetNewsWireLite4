//
//  NNWWebPageViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "BCCenteredActivityTitleView.h"
#import "BCPostToTwitterViewController.h"
#import "NNWAppDelegate.h"
#import "NNWMainViewController.h"
#import "NNWSendToInstapaper.h"
#import "NNWWebPageViewController.h"


@interface BCNavTitleView : UIView {
	@private
	UIViewController *_nnwDelegate;
}

@property (nonatomic, assign) UIViewController *nnwDelegate;
@end

@implementation BCNavTitleView

@synthesize nnwDelegate = _nnwDelegate;

- (BOOL)autoresizesSubviews {
	return NO;
}


- (void)layoutSubviews {
	UILabel *titleLabel = [[self subviews] objectAtIndex:0];
	if (!titleLabel)
		return;
	float x = self.frame.origin.x;
	CGRect rTitleLabel = titleLabel.frame;
	rTitleLabel.origin.x = 0;
	rTitleLabel.origin.y = 0;
	rTitleLabel.size.height = 44;
	rTitleLabel.size.width = [self.nnwDelegate appFrameWidth] - (x * 2);
	titleLabel.frame = rTitleLabel;
//	titleLabel.backgroundColor = [UIColor greenColor];
}


//- (void)drawRect:(CGRect)r {
//	[[UIColor redColor] set];
//	UIRectFill(r);
//}
@end


@interface NNWWebPageViewController ()
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSURLRequest *initialRequest;
@property (nonatomic, retain) UIBarButtonItem *goBackToolbarItem;
@property (nonatomic, retain) UIBarButtonItem *goForwardToolbarItem;
@property (nonatomic, retain) UIBarButtonItem *actionMenuToolbarItem;
@property (nonatomic, assign) BOOL loadingWebPage;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) BCNavTitleView *titleViewContainer;
- (void)showActionSheet;
- (NSString *)webPageTitle;
- (void)updateBackAndForwardButtons;
- (NSString *)webPageURLString;
@end


@implementation NNWWebPageViewController

@synthesize webView = _webView, initialRequest = _initialRequest, goBackToolbarItem = _goBackToolbarItem, goForwardToolbarItem = _goForwardToolbarItem, actionMenuToolbarItem = _actionMenuToolbarItem, loadingWebPage = _loadingWebPage, titleLabel = _titleLabel, activityIndicator = _activityIndicator, titleViewContainer = _titleViewContainer;


#pragma mark Init

- (id)initWithURLRequest:(NSURLRequest *)request {
	self = [super initWithNibName:nil bundle:nil];
	if (!self)
		return nil;
	_initialRequest = [request retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[_webView releaseSafelyToWorkAroundOddWebKitCrashes];
//	_webView.delegate = nil;
//	[_webView stopLoading];
//	[_webView performSelector:@selector(autorelease) withObject:nil afterDelay:4.0]; /*To avoid crashes!*/
	[_initialRequest release];
	[_goBackToolbarItem release];
	[_goForwardToolbarItem release];
	[_actionMenuToolbarItem release];
	[_titleLabel release];
	[_activityIndicator release];
	[_titleViewContainer release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)addWebView {
	if (self.webView)
		return;
	self.webView = [[[UIWebView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
	self.webView.scalesPageToFit = YES;
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.webView.delegate = self;
	self.webView.dataDetectorTypes = UIDataDetectorTypeAll;
	[self.view addSubview:self.webView];
	self.webView.frame = self.view.bounds;
}


- (void)addTitleView {
	BCNavTitleView *dummyTitleViewThatiPhoneWillResize = [[[BCNavTitleView alloc] initWithFrame:CGRectMake(0, 0, [self appFrameWidth], 44)] autorelease];
	dummyTitleViewThatiPhoneWillResize.userInteractionEnabled = NO;
	dummyTitleViewThatiPhoneWillResize.backgroundColor = [UIColor clearColor];
	UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	titleLabel.userInteractionEnabled = NO;
	dummyTitleViewThatiPhoneWillResize.nnwDelegate = self;
//	NSString *longTitle = [self.topLevelTab objectForKey:@"LongTitle"];
//	longTitle = RSStringReplaceAll(longTitle, @"\\n", @"\n");
//	titleLabel.text = longTitle;//[self.topLevelTab objectForKey:@"LongTitle"];//@"Mossberg Solution\nby Katherine Boehret";
	titleLabel.adjustsFontSizeToFitWidth = YES;
	titleLabel.shadowOffset = CGSizeMake(0, -1);
	titleLabel.shadowColor = [UIColor colorWithWhite:0.2 alpha:0.4];
	titleLabel.frame = CGRectMake(0, 0, [self appFrameWidth], 44);
	titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;//UIViewAutoresizingNone;//UIViewAutoresizingFlexibleRightMargin;
	titleLabel.numberOfLines = 0;
	titleLabel.opaque = NO;
	titleLabel.backgroundColor = [UIColor clearColor];	
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.contentMode = UIViewContentModeRedraw;
	self.titleLabel = titleLabel;
	[dummyTitleViewThatiPhoneWillResize addSubview:titleLabel];
	dummyTitleViewThatiPhoneWillResize.contentMode = UIViewContentModeRedraw;
	self.titleViewContainer = dummyTitleViewThatiPhoneWillResize;
	self.navigationItem.titleView = dummyTitleViewThatiPhoneWillResize;
}


- (void)loadView {
	self.view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
	self.view.autoresizesSubviews = YES;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addWebView];	
	self.navigationItem.backBarButtonItem = app_delegate.backArrowButtonItem;
	[self addTitleView];
	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	self.activityIndicator.hidesWhenStopped = YES;
	[self.activityIndicator sizeToFit];
	UIBarButtonItem *activityIndicatorButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator] autorelease];
	self.navigationItem.rightBarButtonItem = activityIndicatorButtonItem;
	[self updateBackAndForwardButtons];
//	self.activityContainerView = [[[BCCenteredActivityTitleView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 49)] autorelease];
//	UIView *activityTitleViewContainerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 49)] autorelease];
//	[activityTitleViewContainerView addSubview:self.activityContainerView];
//	self.navigationItem.titleView = activityTitleViewContainerView;
}


- (void)viewDidUnload {
	[[self.webView retain] releaseSafelyToWorkAroundOddWebKitCrashes];
	self.webView = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


NSString *NNWStateWebPageViewControllerName = @"webPage";

- (NSDictionary *)stateDictionary {
	NSMutableDictionary *state = [NSMutableDictionary dictionary];
	[state setObject:NNWStateWebPageViewControllerName forKey:NNWViewControllerNameKey];
	[state safeSetObject:self.webPageTitle forKey:NNWStateViewControllerTitleKey];
	[state safeSetObject:self.webPageURLString forKey:NNWDataNameKey];
	return state;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.navigationItem.titleView setNeedsLayout];
	[self.navigationItem.titleView setNeedsDisplay];
}


+ (NNWWebPageViewController *)viewControllerWithState:(NSDictionary *)state {
	NSString *urlString = [state objectForKey:NNWDataNameKey];
	if (RSStringIsEmpty(urlString))
		return nil;
	return [[[self alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]] autorelease];
}


- (void)setTitle:(NSString *)title {
	[super setTitle:title];
	self.titleLabel.text = title;
}

#pragma mark Toolbar

- (NSArray *)toolbarItems {
	if (!self.goBackToolbarItem)
		self.goBackToolbarItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)] autorelease];
	if (!self.goForwardToolbarItem)
		self.goForwardToolbarItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goForward:)] autorelease];
	if (!self.actionMenuToolbarItem)
		self.actionMenuToolbarItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"action.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showActionMenu:)] autorelease];
	UIBarButtonItem *spaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	return [NSArray arrayWithObjects:self.actionMenuToolbarItem, spaceItem, spaceItem, self.goBackToolbarItem, spaceItem, self.goForwardToolbarItem, nil];
}


#pragma mark Activity Indicator

- (void)showActivityIndicator {
	//self.navigationItem.titleView = _activityContainerView;
	[self.activityIndicator startAnimating];
}


- (void)hideActivityIndicator {
	[self.activityIndicator stopAnimating];
//	self.navigationItem.titleView = self.titleViewContainer;
}


//- (void)showTitleViewInsteadOfActivityView {
//	self.navigationItem.titleView = self.titleViewContainer;
//}


- (void)updateTitleView {
	if (self.loadingWebPage)
		[self showActivityIndicator];
	else
		[self hideActivityIndicator];
}


#pragma mark Actions

- (void)goBack:(id)sender {
	if (self.webView.canGoBack)
		[self.webView goBack];
}


- (void)goForward:(id)sender {
	if (self.webView.canGoForward)
		[self.webView goForward];
}


- (void)showActionMenu:(id)sender {
	[self showActionSheet];
}


#pragma mark WebView

- (void)updateBackAndForwardButtons {
	self.goBackToolbarItem.enabled = self.webView.canGoBack;
	self.goForwardToolbarItem.enabled = self.webView.canGoForward;
}


- (void)_loadRequest:(NSURLRequest *)urlRequest {
	self.loadingWebPage = YES;
//	[self _updateShouldShowAdWithURLString:[[urlRequest URL] absoluteString]];
	[self.webView loadRequest:urlRequest];
}


- (void)loadHTML {
	//self.initialRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iopus.com/imacros/demo/v5/user-agent.htm"]];
	self.view; /*loadHTML may get called before view is loaded: this forces a load*/
	self.title = @"";
	self.loadingWebPage = YES;
	[self updateBackAndForwardButtons];
	[self updateTitleView];
	[self _loadRequest:self.initialRequest];
//	[self updateUI];
}


#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
	if (webView == _webView) {
		//[self _updateNavBarColors:NO];
		//[self.newsItem markRead];
		self.title = @"";
		self.loadingWebPage = YES;
		[self showActivityIndicator];
		[self updateBackAndForwardButtons];
		[self performSelector:@selector(updateTitleView) withObject:nil afterDelay:0.1];
	}
	//[self _sendNewsItemDidOpenNotification];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if (webView == _webView) {
		_loadingWebPage = NO;
		[self performSelector:@selector(updateTitleView) withObject:nil afterDelay:0.1];
		[self updateBackAndForwardButtons];
		self.title = [self webPageTitle];
		[[NNWMainViewController sharedViewController] saveState];
	}
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[self.navigationController popViewControllerAnimated:YES];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self performSelector:@selector(updateTitleView) withObject:nil afterDelay:0.1];
	if (webView == _webView) {
		[self updateBackAndForwardButtons];
		self.title = @"";
		_loadingWebPage = NO;
//		//[self hideActivityIndicator];
		if ([error code] == NSURLErrorCancelled)
			return;
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
		[d setObject:@"Can’t show web page" forKey:@"title"];
		[d setObject:@"Can’t show the web page because of an error: %@." forKey:@"baseMessage"];
		[d setObject:self forKey:@"delegate"];
		[d setObject:error forKey:@"error"];
		[app_delegate showAlertWithDictionary:d];
		self.loadingWebPage = NO;
	//	[self hideActivityIndicator];
	}
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
//		//		BOOL shouldHandOffURLToSystem = ![app_delegate shouldNavigateToURL:[request URL]];
//		//		if ([app_delegate shouldOpenURLInMoviePlayer:[request URL]] && !shouldHandOffURLToSystem) {
//		//			[self playMovieAtURL:[request URL]];
//		//			return NO;
//		//		}
//		//		else if ([[[request URL] scheme] caseInsensitiveCompare:@"file"] == NSOrderedSame) {
//		//			BCSingleWebPageViewController *webPageViewController = [[[BCSingleWebPageViewController alloc] initWithTabInfo:self.tabInfo topLevelTab:self.topLevelTab] autorelease];
//		//			webPageViewController.hidesRightBarButtonItem = YES;
//		//			webPageViewController.initialRequest = request;
//		//			[webPageViewController loadHTML];
//		//			webPageViewController.hidesBottomBarWhenPushed = YES;
//		//			[[self navigationController] pushViewController:webPageViewController animated:YES];
//		//			return NO;
//		//		}
//		//		else if (!shouldHandOffURLToSystem) {
//		NNWWebPageViewController *webPageViewController = [[[NNWWebPageViewController alloc] initWithURLRequest:request] autorelease];
//		//			webPageViewController.newsViewController = self.newsViewController;
//		//			webPageViewController.newsItem = self.newsItem;
//		//webPageViewController.initialRequest = request;
//		[webPageViewController loadHTML];
//		//webPageViewController.hidesBottomBarWhenPushed = !self.hidesBottomBarWhenPushed;
//		[[self navigationController] pushViewController:webPageViewController animated:YES];
//		return NO;
//		//		}
//		//		else {
//		//			[[UIApplication sharedApplication] openURL:[request URL]];
//		//			return NO;
//		//		}
//	}
	return YES;
}


#pragma mark Actions

- (NSString *)webPageURLString {
	return [[self.webView.request URL] absoluteString];
}


- (NSString *)webPageTitle {
	return [NSString stringWithCollapsedWhitespace:[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
}


- (void)openInSafari:(id)sender {
	if (RSIsEmpty(self.webPageURLString))
		return;
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.webPageURLString]];
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	if (result == MFMailComposeResultFailed)
		[app_delegate showAlertWithError:error];
	[self.navigationController dismissModalViewControllerAnimated:YES];
}


- (void)emailLink:(id)sender {
	NSString *title = self.webPageTitle;
	if (RSIsEmpty(title))
		title = @"Cool Link";
	MFMailComposeViewController *mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
	[mailComposeViewController setSubject:title];
	[mailComposeViewController setMessageBody:self.webPageURLString isHTML:NO];
	mailComposeViewController.mailComposeDelegate = self;
	[self.navigationController presentModalViewController:mailComposeViewController animated:YES];
}


- (void)postDidComplete:(UIViewController *)sharingViewController {
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[sharingViewController performSelector:@selector(release) withObject:nil afterDelay:1.0];
}


- (void)postToTwitter:(id)sender {
	BCPostToTwitterViewController *twitterViewController = [[BCPostToTwitterViewController alloc] init];
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithCapacity:2];
	[infoDict safeSetObject:self.webPageURLString forKey:@"urlString"];
	[infoDict safeSetObject:self.webPageTitle forKey:@"articleTitle"];
	[twitterViewController setInfoDict:infoDict];
	twitterViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//	twitterViewController.postDelegate = self;
	[self.navigationController presentModalViewController:twitterViewController animated:YES];
}


- (void)sendToInstapaperDidComplete:(NNWSendToInstapaper *)instapaperController {
	[instapaperController performSelector:@selector(release) withObject:nil afterDelay:3.0];	
}


- (void)sendToInstapaper:(id)sender {
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithCapacity:2];
	[infoDict safeSetObject:self.webPageTitle forKey:@"title"];
	[infoDict safeSetObject:self.webPageURLString forKey:@"url"];
	NNWSendToInstapaper *instapaperController = [[NNWSendToInstapaper alloc] initWithInfoDict:infoDict callbackTarget:self];
	[instapaperController run];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	_actionSheetShowing = NO;
	if (buttonIndex == actionSheet.cancelButtonIndex)
		return;
	if (buttonIndex == _emailMenuItemIndex)
		[self emailLink:self];
	else if (buttonIndex == _openInSafariMenuItemIndex)
		[self openInSafari:self];
	else if (buttonIndex == _postToTwitterMenuItemIndex)
		[self postToTwitter:self];
	else if (buttonIndex == _sendToInstapaperMenuItemIndex)
		[self sendToInstapaper:self];
}


- (void)showActionSheet {
	if (RSIsEmpty(self.webPageURLString))
		return;
	UIActionSheet *actionSheet = [[[UIActionSheet alloc] init] autorelease];
	_emailMenuItemIndex = NSNotFound;
	_postToTwitterMenuItemIndex = NSNotFound;
	_openInSafariMenuItemIndex = NSNotFound;
	
	NSInteger ix = 0;
	[actionSheet addButtonWithTitle:@"Email Link to Page"];
	_emailMenuItemIndex = ix;	
	ix++;
	
	[actionSheet addButtonWithTitle:@"Post to Twitter"];
	_postToTwitterMenuItemIndex = ix;
	ix++;

	[actionSheet addButtonWithTitle:@"Send to Instapaper"];
	_sendToInstapaperMenuItemIndex = ix;
	ix++;
	
	[actionSheet addButtonWithTitle:@"Open in Browser"];
	_openInSafariMenuItemIndex = ix;	
	ix++;
	
	[actionSheet addButtonWithTitle:@"Cancel"];
	actionSheet.cancelButtonIndex = ix;
	
	actionSheet.delegate = self;
//	[actionSheet showInView:self.view];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

@end
