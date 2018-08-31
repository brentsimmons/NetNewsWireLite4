//
//  NNWArticleViewController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NNWArticleViewController.h"
#import "NGAnimatedBarButtonItem.h"
#import "NGModalViewPresenter.h"
#import "NGWebView.h"
#import "NNWAppDelegate.h"
#import "NNWDatabaseController.h"
#import "RSDetailViewController.h"
#import "NNWExtras.h"
#import "NNWFeedProxy.h"
#import "NNWNewsItemProxy.h"
#import "NNWNewsListTableController.h"
#import "NNWPostToTwitterViewController.h"
#import "NNWRefreshController.h"
#import "NNWSendToInstapaper.h"


@implementation NNWArticleContainerView

- (void)makeWebviewTransparent {
	for (UIView *oneSubview in self.subviews) {
		if ([oneSubview isKindOfClass:[UIWebView class]])
			oneSubview.backgroundColor = [UIColor clearColor];
	}
}


@end

@interface NNWArticleViewController ()

@property (nonatomic, retain) NSString *html;
@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, assign) BOOL showingActionSheet;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain, readwrite) id userSelectedObject;

- (void)showActionSheet;
- (void)closeActionSheetIfNeeded;
- (void)validateToolbarItems;

@end


@implementation NNWArticleViewController

@synthesize webView;
@synthesize newsItem;
@synthesize html, baseURL;
@synthesize popoverItem;
@synthesize upDownButtonsItem, upButton, downButton;
@synthesize flexibleSpaceItem, actionMenuItem, starItem, nextUnreadItem;
@synthesize showingActionSheet, actionSheet;
@synthesize nextUnreadButton;
@synthesize fixedSpaceItem;
@synthesize actionMenuButton;
@synthesize representedObject;
@synthesize userSelectedObject;


#pragma mark Class Methods (RSContentViewController)

+ (BOOL)wantsToDisplayRepresentedObject:(id)aRepresentedObject {
	return aRepresentedObject != nil && [aRepresentedObject isKindOfClass:[NNWNewsItemProxy class]];
}


+ (UIViewController<RSContentViewController> *)contentViewControllerWithRepresentedObject:(id)aRepresentedObject {
	static NNWArticleViewController *gSharedInstance = nil;
	if (gSharedInstance == nil)
		gSharedInstance = [[self alloc] init];
	gSharedInstance.newsItem = aRepresentedObject;
	gSharedInstance.representedObject = aRepresentedObject;
	return gSharedInstance;
}


#pragma mark Init

- (id)init {
	self = [super initWithNibName:@"Article" bundle:nil];
	if (self == nil)
		return nil;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePopoverWillDisplay:) name:NNWPopoverWillDisplayNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[representedObject release];
	[newsItem release];
	[html release];
	webView.delegate = nil;
	[webView release];
	[baseURL release];
	[popoverItem release];
	[upButton release];
	[downButton release];
	[upDownButtonsItem release];
	[flexibleSpaceItem release];
	[actionMenuItem release];
	[starItem release];
	[nextUnreadItem release];
	[actionSheet release];
	[modalViewPresenter	release];
	[nextUnreadButton release];
	[fixedSpaceItem release];
	[actionMenuButton release];
	[userSelectedObject release];
    [super dealloc];
}


#pragma mark RSContentViewController Protocol

- (BOOL)canReuseViewWithRepresentedObject:(id)aRepresentedObject {
	return YES;
}

#pragma mark Display

- (UIWebView *)createWebView {
	UIWebView *wv = [[[NGWebView alloc] initWithFrame:CGRectZero] autorelease];
	wv.frame = self.view.bounds;
	wv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	wv.dataDetectorTypes = UIDataDetectorTypeAll;
	return wv;
}


- (void)webviewSwapAnimationDidComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	UIWebView *oldWebview = (UIWebView *)context;
	[oldWebview removeFromSuperview];
	[oldWebview autorelease];
	[self.view setNeedsLayout];
	[self.view layoutIfNeeded];
	[self validateToolbarItems];
}


- (void)swapInNewWebView {
	UIWebView *wv = [self createWebView];
	UIWebView *oldWebView = [self.webView retain];
	if (oldWebView == nil) {
		self.webView = wv;
		self.webView.delegate = self;
		self.webView.alpha = 1.0;
		[self.view addSubview:self.webView];
		[self.view setNeedsLayout];
		[self.view layoutIfNeeded];
		return;
	}
	oldWebView.delegate = nil;
	oldWebView.backgroundColor = [UIColor clearColor];
	CGRect rWebView = oldWebView.frame;

	self.webView = wv;
	self.webView.frame = rWebView;
	self.webView.delegate = self;

	[self.view insertSubview:self.webView belowSubview:oldWebView];

	[UIView beginAnimations:nil context:oldWebView];
	[UIView setAnimationDuration:0.05f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self]; 
	[UIView setAnimationDidStopSelector:@selector(webviewSwapAnimationDidComplete:finished:context:)];

	oldWebView.alpha = 0.0f;

	[UIView commitAnimations];
}


static NSString *gHTMLTemplate = nil;

- (void)_replacePlaceholder:(NSString *)placeholderName inString:(NSMutableString *)s {
	NSMutableString *placeholder = [[[NSMutableString alloc] initWithString:@"[["] autorelease];
	[placeholder appendString:placeholderName];
	[placeholder appendString:@"]]"];
	NSString *key = placeholderName;
	if ([key isEqualToString:@"htmlText"])
		key = @"htmlContent";
	NSString *value = [self.newsItem valueForKey:key];
	if (!value)
		value = @"";
	[s replaceOccurrencesOfString:placeholder withString:value options:0 range:NSMakeRange(0, [s length])];	
}


- (void)_replaceTitleLinkInString:(NSMutableString *)s {
	NSString *urlString = self.newsItem.permalink;
	NSMutableString *linkString = [[[NSMutableString alloc] initWithString:@""] autorelease];
	if (!RSStringIsEmpty(urlString)) {
		[linkString appendString:@"<a href=\""];
		[linkString appendString:urlString];
		[linkString appendString:@"\">"];
	}
	NSString *title = self.newsItem.plainTextTitle;
	if (RSStringIsEmpty(title))
		title = @"Untitled";
	[linkString appendString:title];
	if (!RSStringIsEmpty(urlString))
		[linkString appendString:@"</a>"];
	[s replaceOccurrencesOfString:@"[[titleLink]]" withString:linkString options:0 range:NSMakeRange(0, [s length])];
}


- (void)_replaceDatePublishedInString:(NSMutableString *)s {
	NSString *displayDate = [self.newsItem displayDate];
	if (!displayDate)
		displayDate = @"";
	[s replaceOccurrencesOfString:@"[[displayDate]]" withString:[NSString stringWithFormat:@"%@", displayDate] options:0 range:NSMakeRange(0, [s length])];	
}


- (void)_replaceCategoriesInString:(NSMutableString *)s {
	[s replaceOccurrencesOfString:@"[[categories]]" withString:RSEmptyString options:0 range:NSMakeRange(0, [s length])];		
}


- (void)_replaceBylineInString:(NSMutableString *)s { //TODO
	NSString *author = self.newsItem.author;
	if (author == nil)
		author = RSEmptyString;
	if (!RSStringIsEmpty(author))
		author = [NSString stringWithFormat:@"by %@", author];
	[s replaceOccurrencesOfString:@"[[byline]]" withString:author options:0 range:NSMakeRange(0, [s length])];
}


static NSString *NNWPlaceholderGoogleFeedTitle = @"[[googleFeedTitle]]";

- (void)replaceFeedTitleInString:(NSMutableString *)s {
	/*The user-specified title is actually stored with the feed*/
	NSString *googleFeedTitle = [NNWFeedProxy titleOfFeedWithGoogleID:self.newsItem.googleFeedID];
	if (RSStringIsEmpty(googleFeedTitle))
		googleFeedTitle = self.newsItem.googleFeedTitle;
	if (googleFeedTitle == nil)
		googleFeedTitle = RSEmptyString;
	[s replaceOccurrencesOfString:NNWPlaceholderGoogleFeedTitle withString:googleFeedTitle options:0 range:NSMakeRange(0, [s length])];		
}


- (void)_replacePlaceholdersInString:(NSMutableString *)s {
	[self _replaceTitleLinkInString:s];
	[self replaceFeedTitleInString:s];
	[self _replacePlaceholder:RSDataPlainTextTitle inString:s];
	[self _replaceDatePublishedInString:s];
	[self _replaceCategoriesInString:s];
	[self _replaceBylineInString:s];
	[self _replacePlaceholder:@"htmlText" inString:s];
}


- (NSString *)_htmlStringForCurrentNewsItem {
	if (gHTMLTemplate == nil) {
		NSString *f = [[NSBundle mainBundle] pathForResource:@"newsItemTemplate" ofType:@"html"];
		gHTMLTemplate = [[NSString alloc] initWithContentsOfFile:f];
	}
	NSMutableString *s = [[gHTMLTemplate mutableCopy] autorelease];
	[self _replacePlaceholdersInString:s];
	return s;
}


- (void)buildHTML {
	self.html = [self _htmlStringForCurrentNewsItem];
}


- (void)displayHTML {
	[self.webView loadHTMLString:self.html baseURL:self.baseURL];
}


#pragma mark UIViewController

- (void)viewDidLoad {
	[upButton setImage:[UIImage imageWithGlow:upButton.imageView.image] forState:UIControlStateHighlighted];
	[downButton setImage:[UIImage imageWithGlow:downButton.imageView.image] forState:UIControlStateHighlighted];	
	[self validateToolbarItems];
}


- (void)viewWillAppear:(BOOL)animated {
	[self.view setNeedsLayout];
	[self validateToolbarItems];
}


- (void)viewDidAppear:(BOOL)animated {
	[self.view setNeedsLayout];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWArticleDidAppearNotification object:nil];
	[self validateToolbarItems];
}


- (void)didReceiveMemoryWarning {
	;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark State

- (void)saveState {
	NSString *googleID = self.newsItem.googleID;
	if (googleID == nil)
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:NNWStateArticleIDKey];
	else
		[[NSUserDefaults standardUserDefaults] setObject:googleID forKey:NNWStateArticleIDKey];
	[[NSUserDefaults standardUserDefaults] setInteger:NNWRightPaneViewArticle forKey:NNWStateRightPaneViewControllerKey];
}


#pragma mark Toolbar

- (NSArray *)toolbarItems:(BOOL)orientationIsLandscape {
	
	NSMutableArray *toolbarItems = [NSMutableArray array];

	if (!orientationIsLandscape) {
//		UIBarButtonItem *leftSpaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
//		//leftSpaceItem.width = 200.0f;
//		[toolbarItems addObject:leftSpaceItem];
		[toolbarItems safeAddObject:self.upDownButtonsItem];
		[self.upButton configureForToolbar];
		[self.downButton configureForToolbar];
	}
	if (self.flexibleSpaceItem == nil)
		self.flexibleSpaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil  action:nil] autorelease];
	[toolbarItems safeAddObject:flexibleSpaceItem];
	if (self.actionMenuItem == nil) {
		self.actionMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[self.actionMenuButton setImage:[UIImage imageNamed:@"Action.png"] forState:UIControlStateNormal];
		[self.actionMenuButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"Action.png"]] forState:UIControlStateHighlighted];
		[self.actionMenuButton addTarget:self action:@selector(showActionMenu:) forControlEvents:UIControlEventTouchUpInside];
		self.actionMenuButton.adjustsImageWhenDisabled = NO;
		self.actionMenuButton.adjustsImageWhenHighlighted = YES;
		self.actionMenuButton.showsTouchWhenHighlighted = NO;
		self.actionMenuButton.userInteractionEnabled = YES;
		self.actionMenuButton.frame = CGRectMake(0, 0, 40, 44);
		[self.actionMenuButton configureForToolbar];
		self.actionMenuItem = [[[UIBarButtonItem alloc] initWithCustomView:self.actionMenuButton] autorelease];		
	}
	[toolbarItems safeAddObject:actionMenuItem];
	if (self.starItem == nil) {
		NSArray *animationImages = [NSArray arrayWithObjects:
									//[UIImage imageNamed:@"Star Animation010.png"],
									[UIImage imageNamed:@"Star Animation011.png"],
									[UIImage imageNamed:@"Star Animation012.png"],
									[UIImage imageNamed:@"Star Animation013.png"],
									[UIImage imageNamed:@"Star Animation014.png"],
									[UIImage imageNamed:@"Star Animation015.png"],
									[UIImage imageNamed:@"Star Animation016.png"],
									[UIImage imageNamed:@"Star Animation017.png"],
									[UIImage imageNamed:@"Star Animation018.png"],
									[UIImage imageNamed:@"Star Animation019.png"],
									[UIImage imageNamed:@"Star Animation020.png"],
									[UIImage imageNamed:@"Star Animation021.png"],
									[UIImage imageNamed:@"Star Animation022.png"],
									[UIImage imageNamed:@"Star Animation023.png"],
									[UIImage imageNamed:@"Star Animation024.png"],
									[UIImage imageNamed:@"Star Animation025.png"],
									[UIImage imageNamed:@"Star Animation026.png"],
									[UIImage imageNamed:@"Star Animation027.png"],
									nil];
		self.starItem = [[[NGAnimatedBarButtonItem alloc] initWithImages:animationImages duration:0.75 target:self selector:@selector(toggleStar:)] autorelease];
	}
	[toolbarItems safeAddObject:self.fixedSpaceItem];
	[(NGAnimatedBarButtonItem *)self.starItem setOn:self.newsItem.starred];
	[toolbarItems safeAddObject:self.starItem];
	if (self.nextUnreadItem == nil) {
		self.nextUnreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[self.nextUnreadButton setImage:[UIImage imageNamed:@"NextUnread.png"] forState:UIControlStateNormal];
		[self.nextUnreadButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"NextUnread.png"]] forState:UIControlStateHighlighted];
		[self.nextUnreadButton setImage:[UIImage imageNamed:@"NextUnreadDisabled.png"] forState:UIControlStateDisabled];
		[self.nextUnreadButton addTarget:self action:@selector(gotoNextUnread:) forControlEvents:UIControlEventTouchUpInside];
		self.nextUnreadButton.adjustsImageWhenDisabled = NO;
		self.nextUnreadButton.adjustsImageWhenHighlighted = NO;
		self.nextUnreadButton.showsTouchWhenHighlighted = YES;
		self.nextUnreadButton.userInteractionEnabled = YES;
		self.nextUnreadButton.frame = CGRectMake(0, 0, 60, 44);
		[self.nextUnreadButton configureForToolbar];
		self.nextUnreadItem = [[[UIBarButtonItem alloc] initWithCustomView:self.nextUnreadButton] autorelease];
	}
	
	[toolbarItems safeAddObject:nextUnreadItem];

	[self validateToolbarItems];
	
	return toolbarItems;
}


- (void)validateToolbarItems {
	self.upButton.enabled = [app_delegate.newsListViewController canGoUp];
	self.downButton.enabled = [app_delegate.newsListViewController canGoDown];
	self.nextUnreadButton.enabled = YES;
	if ([app_delegate.newsListViewController canGoToNextUnreadInSameSubscription])
	{
		[self.nextUnreadButton setImage:[UIImage imageNamed:@"NextUnread.png"] forState:UIControlStateNormal];
		[self.nextUnreadButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"NextUnread.png"]] forState:UIControlStateHighlighted];
	}
	else if ([app_delegate.newsListViewController nextUnreadIsInOtherSubscription])
	{
		[self.nextUnreadButton setImage:[UIImage imageNamed:@"NextUnreadNewBlog.png"] forState:UIControlStateNormal];
		[self.nextUnreadButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"NextUnreadNewBlog.png"]] forState:UIControlStateHighlighted];
	}
	else if ([app_delegate.newsListViewController hasAnyUnread])
	{
		[self.nextUnreadButton setImage:[UIImage imageNamed:@"NextUnread.png"] forState:UIControlStateNormal];
		[self.nextUnreadButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"NextUnread.png"]] forState:UIControlStateHighlighted];
	}
	else
		self.nextUnreadButton.enabled = NO;	
}

#pragma mark Actions

- (IBAction)goUp:(id)sender {	
	[self closeActionSheetIfNeeded];
	[app_delegate.newsListViewController goUp];
}


- (IBAction)goDown:(id)sender {	
	[self closeActionSheetIfNeeded];
	[app_delegate.newsListViewController goDown]; 
}


- (IBAction)showActionMenu:(id)sender {
	[self showActionSheet];
}


- (IBAction)toggleStar:(id)sender {
	[self closeActionSheetIfNeeded];
	[self.newsItem userToggleStarred];
}


- (IBAction)gotoNextUnread:(id)sender {
	[self closeActionSheetIfNeeded];
	[app_delegate.newsListViewController gotoNextUnread]; 
}


#pragma mark Action Menu

- (NSString *)webPageURLString {
	return self.newsItem.permalink;
}


- (NSString *)webPageTitle {
	return self.newsItem.plainTextTitle;
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


- (void)emailHTMLContentOfNewsItem:(id)sender {
	NSString *title = self.webPageTitle;
	if (RSIsEmpty(title))
		title = @"Cool Link";
	MFMailComposeViewController *mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
	[mailComposeViewController setSubject:title];
	[mailComposeViewController setMessageBody:self.html isHTML:YES];
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
	[infoDict setObject:self.newsItem.plainTextTitle forKey:@"articleTitle"];
	[infoDict setObject:self.newsItem.permalink forKey:@"urlString"];
	[postToTwitterViewController setInfoDict:infoDict];
}


- (void)sendToInstapaperDidComplete:(NNWSendToInstapaper *)instapaperController {
	[instapaperController performSelector:@selector(release) withObject:nil afterDelay:3.0];	
}


- (void)sendToInstapaper:(id)sender {
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithCapacity:2];
	[infoDict setObject:self.newsItem.plainTextTitle forKey:@"title"];
	[infoDict setObject:self.newsItem.permalink forKey:@"url"];
	
	NNWSendToInstapaper *sendToInstapaper = [[NNWSendToInstapaper alloc]initWithInfoDict:infoDict callbackTarget:self];
	[sendToInstapaper run];
}


- (void)actionSheet:(UIActionSheet *)anActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.showingActionSheet = NO;
	self.actionSheet = nil;
	if (buttonIndex == anActionSheet.cancelButtonIndex)
		return;
	if (buttonIndex == _emailMenuItemIndex)
		[self emailHTMLContentOfNewsItem:self];
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
	self.showingActionSheet = YES;
	self.actionSheet = [[[UIActionSheet alloc] init] autorelease];
	_emailMenuItemIndex = NSNotFound;
	_postToTwitterMenuItemIndex = NSNotFound;
	_openInSafariMenuItemIndex = NSNotFound;
	_sendToInstapaperMenuItemIndex = NSNotFound;
	
	NSInteger ix = 0;
	if ([MFMailComposeViewController canSendMail]) {
		[self.actionSheet addButtonWithTitle:@"Email Article"];
		_emailMenuItemIndex = ix;	
		ix++;
	}
	
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
	[self.actionSheet showFromBarButtonItem:actionMenuItem animated:YES];
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


#pragma mark News Item

- (void)displayNewsItem {
	[self swapInNewWebView];
	if (self.newsItem == nil)
		return; // blank page
	[self buildHTML];
	[self displayHTML];
}


- (void)setNewsItem:(NNWNewsItemProxy *)aNewsItem {
	if (aNewsItem == self.newsItem)
		return;
	[newsItem autorelease];
	[[NNWDatabaseController sharedController] inflateNewsItem:aNewsItem];
	newsItem = [aNewsItem retain];
	[self displayNewsItem];
	[self validateToolbarItems];
}


#pragma mark Web View Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		BOOL shouldHandOffURLToSystem = ![app_delegate shouldNavigateToURL:[request URL]];
		if ([app_delegate shouldOpenURLInMoviePlayer:[request URL]] && !shouldHandOffURLToSystem) {
			[self playMediaAtURL:[request URL]];
			return NO;
		}
		if (!shouldHandOffURLToSystem) {
			self.userSelectedObject = [request URL];
			[[UIApplication sharedApplication] sendAction:@selector(userDidSelectTemporaryObject:) to:nil from:self forEvent:nil];
			return NO;
		}
		else {
			[[UIApplication sharedApplication] openURL:[request URL]];
			return NO;
		}
	}
	return YES;
}


@end
