    //
//  NNWWebPageViewController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWWebPageViewController.h"
#import "NGModalViewPresenter.h"
#import "NNWAppDelegate.h"
#import "NNWBrowserAddressTextField.h"
#import "NNWPostToTwitterViewController.h"
#import "NNWSendToInstapaper.h"
#import "RSDetailViewController.h"


#define kNNWWebPageToolbarWidthLandscape 474.0f
#define kNNWWebPageToolbarWidthPortrait 380.0f

@interface NNWWebPageViewController ()
@property (nonatomic, assign) BOOL showingActionSheet;
//@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
//@property (nonatomic, retain) UIBarButtonItem *activityIndicatorButtonItem;
@property (nonatomic, retain) UIActionSheet *actionSheet;

- (void)updateAddressFieldWithURLString:(NSString *)urlString;
- (void)updateAddressField;
- (void)updateToolbar;
- (void)showActionSheet;
- (void)closeActionSheetIfNeeded;
@end


@implementation NNWWebPageViewController

@synthesize toolbar, webView, addressField;
@synthesize popoverItem, backForwardButtonsItem;
@synthesize backButton, forwardButton;
@synthesize addressFieldItem, actionMenuItem;
@synthesize showingActionSheet;
@synthesize activityIndicator;//, activityIndicatorButtonItem;
@synthesize flexibleSpaceItem;
@synthesize actionMenuButton;
@synthesize actionSheet;
@synthesize representedObject;
@synthesize webPageToolbarView;
@synthesize barButtonContainer;

#pragma mark Class Methods (RSContentViewController)

+ (BOOL)wantsToDisplayRepresentedObject:(id)aRepresentedObject {
	return aRepresentedObject != nil && [aRepresentedObject isKindOfClass:[NSURL class]];
}


+ (UIViewController<RSContentViewController> *)contentViewControllerWithRepresentedObject:(id)aRepresentedObject {
	NNWWebPageViewController *webPageViewController = [[[self alloc] init] autorelease];
	return webPageViewController;
}

#pragma mark Init

- (id)init {
	self = [super initWithNibName:@"WebPage" bundle:nil];
	if (self == nil)
		return nil;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePopoverWillDisplay:) name:NNWPopoverWillDisplayNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[toolbar release];
	webView.delegate = nil;
	[webView release];
	[addressFieldItem release];
	addressField.delegate = nil;
	[addressField release];
	[popoverItem release];
	[backForwardButtonsItem release];
	[backButton release];
	[forwardButton release];
	[actionMenuItem release];
	[activityIndicator release];
//	[activityIndicatorButtonItem release];
	[flexibleSpaceItem release];
	[actionMenuButton release];
	[actionSheet release];
	[barButtonContainer release];
	[webPageToolbarView release];
	[super dealloc];
}


#pragma mark UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self updateToolbar];
}


- (void)viewDidLoad {
	[self.webPageToolbarView setNeedsLayout];
	if (self.representedObject != nil)
		[self loadURL:(NSURL *)(self.representedObject)];
}


- (void)viewWillAppear:(BOOL)animated {
	[self updateToolbar];
}


- (void)viewDidAppear:(BOOL)animated {
	[self updateToolbar];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWWebPageDidAppearNotification object:nil];
}


- (void)viewWillDisappear:(BOOL)animated {
}


#pragma mark RSContentViewController Protocol

- (BOOL)canReuseViewWithRepresentedObject:(id)aRepresentedObject {
	return NO;
}


#pragma mark State

- (void)saveState {
	NSString *urlString = [[[self.webView request] URL] absoluteString];
	if (urlString == nil)
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:NNWStateWebPageURLKey];
	else
		[[NSUserDefaults standardUserDefaults] setObject:urlString forKey:NNWStateWebPageURLKey];
	[[NSUserDefaults standardUserDefaults] setInteger:NNWRightPaneViewWebPage forKey:NNWStateRightPaneViewControllerKey];
}


- (void)restoreState {
	@try {
		NSString *urlString = [[NSUserDefaults standardUserDefaults] objectForKey:NNWStateWebPageURLKey];
		if (!RSStringIsEmpty(urlString))
			[self loadURL:[NSURL URLWithString:urlString]];
	}
	@catch (id obj) {
		NSLog(@"web page restore state error: %@", obj);
	}
}


#pragma mark Loading

- (void)loadURL:(NSURL *)url {
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	[self updateAddressFieldWithURLString:[url absoluteString]];
}


#pragma mark Address Field

- (void)updateAddressFieldWithURLString:(NSString *)urlString {
	if (urlString == nil)
		urlString = RSEmptyString;
	addressField.text = urlString;
}


- (void)updateAddressField {
	/*Get URL from webview request*/
	[self updateAddressFieldWithURLString:[[self.webView.request URL] absoluteString]];
}	


#pragma mark Toolbar

- (NSArray *)toolbarItems:(BOOL)orientationIsLandscape {

	CGRect r = self.webPageToolbarView.frame;
	if (orientationIsLandscape) {
		r.origin.x = 0.0f;
		r.size.width = 703.0f;
	}
	else {
		r.origin.x = 137.0f;
		r.size.width = 768.0f - r.origin.x;
	}
	self.webPageToolbarView.frame = r;
	
	[self.webPageToolbarView setNeedsLayout];
	return [NSArray arrayWithObject:self.barButtonContainer];
}


- (void)validateToolbar {
	self.forwardButton.enabled = self.webView.canGoForward;
	[self.webPageToolbarView setNeedsLayout];
}


- (void)updateToolbar {
	[self validateToolbar];
}


#pragma mark Activity Indicator

- (void)showActivityIndicator {
	[self.activityIndicator startAnimating];
}


- (void)hideActivityIndicator {
	[self.activityIndicator stopAnimating];
}


#pragma mark Actions

- (IBAction)goBack:(id)sender {
	[self closeActionSheetIfNeeded];
	if ([self.webView canGoBack])
		[self.webView goBack];
	else
		[[UIApplication sharedApplication] sendAction:@selector(userDidDeselectObject:) to:nil from:self forEvent:nil];
}


- (IBAction)goForward:(id)sender {
	[self closeActionSheetIfNeeded];
	if ([self.webView canGoForward])
		[self.webView goForward];
}


- (IBAction)showActionMenu:(id)sender {
	[self showActionSheet];
}


#pragma mark Action Menu

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
	[app_delegate.splitViewController dismissModalViewControllerAnimated:YES];
}


- (void)emailLink:(id)sender {
	NSString *title = self.webPageTitle;
	if (RSIsEmpty(title))
		title = @"Cool Link";
	MFMailComposeViewController *mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
	[mailComposeViewController setSubject:title];
	[mailComposeViewController setMessageBody:self.webPageURLString isHTML:NO];
	mailComposeViewController.mailComposeDelegate = self;
	[app_delegate.splitViewController presentModalViewController:mailComposeViewController animated:YES];
}


- (void)postDidComplete:(UIViewController *)sharingViewController {
//	[self.navigationController dismissModalViewControllerAnimated:YES];
//	[sharingViewController performSelector:@selector(release) withObject:nil afterDelay:1.0];
}


- (void)postToTwitter:(id)sender {
	NNWPostToTwitterViewController *postToTwitterViewController = [[NNWPostToTwitterViewController alloc]initWithNibName:@"PostToTwitter" bundle:nil];
	[modalViewPresenter	release];
	modalViewPresenter = [[[NGModalViewPresenter alloc]initWithViewController:postToTwitterViewController]retain];
	[modalViewPresenter presentModalView];
	
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithCapacity:2];
	[infoDict setObject:self.webPageTitle forKey:@"articleTitle"];
	[infoDict setObject:self.webPageURLString forKey:@"urlString"];
	[postToTwitterViewController setInfoDict:infoDict];
}


- (void)sendToInstapaperDidComplete:(NNWSendToInstapaper *)instapaperController {
	//	[instapaperController performSelector:@selector(release) withObject:nil afterDelay:3.0];	
}


- (void)sendToInstapaper:(id)sender {
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithCapacity:2];
	[infoDict setObject:self.webPageTitle forKey:@"title"];
	[infoDict setObject:self.webPageURLString forKey:@"url"];
	
	NNWSendToInstapaper *sendToInstapaper = [[NNWSendToInstapaper alloc]initWithInfoDict:infoDict callbackTarget:self];
	[sendToInstapaper run];
}


- (void)actionSheet:(UIActionSheet *)anActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.showingActionSheet = NO;
	if (buttonIndex == anActionSheet.cancelButtonIndex)
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
	if (self.showingActionSheet)
		return;
	if (RSIsEmpty(self.webPageURLString))
		return;
	self.showingActionSheet = YES;
	self.actionSheet = [[[UIActionSheet alloc] init] autorelease];
	_emailMenuItemIndex = NSNotFound;
	_postToTwitterMenuItemIndex = NSNotFound;
	_openInSafariMenuItemIndex = NSNotFound;
	_sendToInstapaperMenuItemIndex = NSNotFound;
	
	NSInteger ix = 0;
	[self.actionSheet addButtonWithTitle:@"Email Link to Page"];
	_emailMenuItemIndex = ix;	
	ix++;
	
	[self.actionSheet addButtonWithTitle:@"Post to Twitter"];
	_postToTwitterMenuItemIndex = ix;
	ix++;
	
	[self.actionSheet addButtonWithTitle:@"Send to Instapaper"];
	_sendToInstapaperMenuItemIndex = ix;
	ix++;
	
	[self.actionSheet addButtonWithTitle:@"Open in Browser"];
	_openInSafariMenuItemIndex = ix;	
	ix++;
	
	[self.actionSheet addButtonWithTitle:@"Cancel"];
	self.actionSheet.cancelButtonIndex = ix;
	
	self.actionSheet.delegate = self;
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWPopoverWillDisplayNotification object:self userInfo:[NSDictionary dictionaryWithObject:self.actionSheet forKey:NNWPopoverControllerKey]];
	
	CGRect rAction = self.actionMenuButton.frame;
	rAction.size.height = rAction.size.height - 9.0f; //bring the popover arrow up a little
	rAction = CGRectIntegral(rAction);
	[self.actionSheet showFromRect:rAction inView:self.webPageToolbarView animated:YES];
}


- (void)closeActionSheetIfNeeded {
	if (!self.showingActionSheet || self.actionSheet == nil)
		return;
	self.showingActionSheet = NO;
	[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
	self.actionSheet = nil;
}


- (void)handlePopoverWillDisplay:(NSNotification *)note {
	if ([[note userInfo] objectForKey:NNWPopoverControllerKey] != self.actionSheet)
		[self closeActionSheetIfNeeded];
}


#pragma mark Web View Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	[self updateAddressFieldWithURLString:[[request URL] absoluteString]];
//	[self validateToolbar];
	return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
	[self updateAddressField];
	[self validateToolbar];
	[self showActivityIndicator];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[self updateAddressField];	
	[self validateToolbar];
	[self hideActivityIndicator];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self updateAddressField];	
	[self validateToolbar];
	[self hideActivityIndicator];
	if ([error code] != NSURLErrorCancelled || ![[error domain] isEqualToString:NSURLErrorDomain])
		[app_delegate showAlertWithError:error];
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSString *urlString = [[textField.text copy] autorelease];
	urlString = RSStringReplaceAll(urlString, @" ", @"%20");
	if (![[urlString lowercaseString] hasPrefix:@"http://"])
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	[self loadURL:[NSURL URLWithString:urlString]];
	[textField performSelectorOnMainThread:@selector(resignFirstResponder) withObject:nil waitUntilDone:NO];
	return YES;
}

@end


@interface NNWWebPageToolbarView ()

@property (nonatomic, assign) BOOL didConfigureButtons;
@end


@implementation NNWWebPageToolbarView

@synthesize backForwardButtonsContainer;
@synthesize backButton;
@synthesize forwardButton;
@synthesize browserAddressTextField;
@synthesize activityIndicator;
@synthesize actionMenuButton;
@synthesize didConfigureButtons;

#pragma mark Dealloc

- (void)dealloc {
	[backForwardButtonsContainer release];
	[backButton release];
	[forwardButton release];
	[browserAddressTextField release];
	[activityIndicator release];
	[actionMenuButton release];
	[super dealloc];
}


#pragma mark Configuring

- (void)configureButtonsIfNeeded {
	if (self.didConfigureButtons)
		return;
	self.didConfigureButtons = YES;	
	[backButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"ArrowBack.png"]] forState:UIControlStateHighlighted];
	[forwardButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"ArrowForward.png"]] forState:UIControlStateHighlighted];	
	[actionMenuButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"Action.png"]] forState:UIControlStateHighlighted];
	[self.backButton configureForToolbar];
	[self.forwardButton configureForToolbar];
	[self.actionMenuButton configureForToolbar];
	[self.activityIndicator sizeToFit];
}


#pragma mark Layout


static const CGFloat toolbarItemsMarginLeftPortrait = 0.0f;
static const CGFloat toolbarItemsMarginLeftLandscape = 0.0f;
static const CGFloat backForwardButtonsContainerWidth = 116.0f;
static const CGFloat backForwardButtonsOriginX = 0.0f;
static const CGFloat backForwardButtonsMarginRight = 12.0f;
static const CGFloat actionButtonMarginRight = 12.0f;
static const CGFloat actionButtonWidth = 45.0f;
static const CGFloat actionButtonMarginLeft = 6.0f;
static const CGFloat activityMarginLeft = 12.0f;
static const CGFloat activityWidth = 20.0f;
static const CGFloat activityHeight = 20.0f;
static const CGFloat activityOriginY = 12.0f;

- (void)layoutSubviews {
	[self configureButtonsIfNeeded];
	
//	CGRect r = self.superview.bounds;
//	NSLog(@"toolbar bounds %f %f %f %f", r.origin.x, r.origin.y, r.size.width, r.size.height);
//	r = self.bounds;
//	NSLog(@"self bounds %f %f %f %f", r.origin.x, r.origin.y, r.size.width, r.size.height);
//	r = self.frame;
//	NSLog(@"self frame %f %f %f %f", r.origin.x, r.origin.y, r.size.width, r.size.height);
////	r = self.bounds;
////	if (CGRectGetWidth(r) > 760.f)
////		r.origin.x = toolbarItemsMarginLeftPortrait;
////	else
////		r.origin.x = toolbarItemsMarginLeftLandscape;
	CGRect r = self.bounds;
	r.size.width = CGRectGetWidth(self.superview.bounds) - self.frame.origin.x;
	//NSLog(@"w: %f", r.size.width);
	CGRect rBackForwardButtonsContainer = self.backForwardButtonsContainer.frame;
	rBackForwardButtonsContainer.size.width = backForwardButtonsContainerWidth;
	rBackForwardButtonsContainer.origin.x = r.origin.x + backForwardButtonsOriginX;
	rBackForwardButtonsContainer = CGRectIntegral(rBackForwardButtonsContainer);
	self.backForwardButtonsContainer.frame = rBackForwardButtonsContainer;
	
	CGRect rAction = self.actionMenuButton.frame;
	rAction.size.width = actionButtonWidth;
	rAction.origin.x = CGRectGetMaxX(r) - (rAction.size.width + actionButtonMarginRight);
	rAction = CGRectIntegral(rAction);
	self.actionMenuButton.frame = rAction;
	
	CGRect rActivity = self.activityIndicator.frame;
	rActivity.size.width = activityWidth;
	rActivity.size.height = activityHeight;
	rActivity.origin.x = CGRectGetMinX(rAction) - (rActivity.size.width + actionButtonMarginLeft);
	rActivity.origin.y = activityOriginY;
	rActivity = CGRectIntegral(rActivity);
	self.activityIndicator.frame = rActivity;
	
	CGRect rAddress = self.browserAddressTextField.frame;
	rAddress.origin.x = CGRectGetMaxX(rBackForwardButtonsContainer) + backForwardButtonsMarginRight;
	CGFloat endAddressX = CGRectGetMinX(rActivity) - activityMarginLeft;
	rAddress.size.width = endAddressX - rAddress.origin.x;
	rAddress = CGRectIntegral(rAddress);
	self.browserAddressTextField.frame = rAddress;
	
}

@end

