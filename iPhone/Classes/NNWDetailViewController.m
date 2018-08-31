//
//  NNWDetailViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWDetailViewController.h"
#import "BCCenteredActivityTitleView.h"
#import "BCPostToTwitterViewController.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWFeedProxy.h"
#import "NNWMainViewController.h"
#import "NNWNewsItem.h"
#import "NNWNewsTableViewController.h"
#import "NNWNewsViewController.h"
#import "NNWSendToInstapaper.h"
#import "NNWWebPageViewController.h"


@interface NNWDetailViewController ()
@property (nonatomic, retain) UIBarButtonItem *starToolbarItem;
@property (nonatomic, retain) UIBarButtonItem *actionMenuToolbarItem;
@property (nonatomic, retain) UIBarButtonItem *nextUnreadToolbarItem;
@property (nonatomic, retain) UISegmentedControl *upDownControl;
@property (nonatomic, retain) NSString *lastHTMLString;
@property (nonatomic, retain) BCCenteredActivityTitleView *activityContainerView;
@property (nonatomic, assign) BOOL loadingWebPage;
- (void)showActionSheet;
- (void)updateUpDownControl;
- (void)updateStarInHTML;
@end


@implementation NNWDetailViewController

@synthesize webView = _webView, newsItemProxy = _newsItemProxy, newsItem = _newsItem, starToolbarItem = _starToolbarItem, actionMenuToolbarItem = _actionMenuToolbarItem, nextUnreadToolbarItem = _nextUnreadToolbarItem, upDownControl = _upDownControl, lastHTMLString = _lastHTMLString, newsViewController = _newsViewController, activityContainerView = _activityContainerView, loadingWebPage = _loadingWebPage;


#pragma mark Init

- (id)initWithNewsItemProxy:(NNWNewsItemProxy *)newsItemProxy {
	self = [super initWithNibName:nil bundle:nil];
	if (!self)
		return nil;
	self.title = @"";
	_newsItemProxy = [newsItemProxy retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_webView releaseSafelyToWorkAroundOddWebKitCrashes];
//	_webView.delegate = nil;
//	[_webView stopLoading];
//	[_webView performSelector:@selector(autorelease) withObject:nil afterDelay:4.0]; /*To avoid crashes!*/
	[_newsItemProxy release];
	[_lastHTMLString release];
	[_newsItem release];
	[_starToolbarItem release];
	[_actionMenuToolbarItem release];
	[_nextUnreadToolbarItem release];
	[_upDownControl release];
	[_activityContainerView release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)addRightBarButtonItem {
	/*Up/down buttons*/
	UISegmentedControl *upDownControl = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:@"arrow_up.png"], [UIImage imageNamed:@"arrow_down.png"], nil]] autorelease];
	upDownControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[upDownControl addTarget:self action:@selector(upDownAction:) forControlEvents:UIControlEventValueChanged];
	upDownControl.momentary = YES;
	self.upDownControl = upDownControl;
	[upDownControl setWidth:61.0f forSegmentAtIndex:0];
	[upDownControl setWidth:61.0f forSegmentAtIndex:1];	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:upDownControl] autorelease];
}


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


- (void)loadView {
	self.view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
	self.view.autoresizesSubviews = YES;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addWebView];	
	self.navigationItem.backBarButtonItem = app_delegate.backArrowButtonItem;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsListDidFetch:) name:NNWNewsItemsListDidFetchNotification object:nil];
	[self addRightBarButtonItem];
	[self updateUpDownControl];
	self.activityContainerView = [[[BCCenteredActivityTitleView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 49)] autorelease];
	UIView *activityTitleViewContainerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 49)] autorelease];
	[activityTitleViewContainerView addSubview:self.activityContainerView];
	self.navigationItem.titleView = activityTitleViewContainerView;
	//	if (self.newsItemProxy.plainTextTitle)
//		self.title = self.newsItemProxy.plainTextTitle;
}


- (void)viewDidUnload {
	[[self.webView retain] releaseSafelyToWorkAroundOddWebKitCrashes];
//	self.webView.delegate = nil;
//	[[self.webView retain] performSelector:@selector(autorelease) withObject:nil afterDelay:10];
	self.webView = nil;
	needsLoadWhenAppearsNext = YES;
}


- (void)viewDidAppear:(BOOL)animated {
	if (needsLoadWhenAppearsNext)
		[self loadHTML];
	needsLoadWhenAppearsNext = NO;
}


NSString *NNWStateDetailViewControllerName = @"detail";

- (NSDictionary *)stateDictionary {
	NSMutableDictionary *state = [NSMutableDictionary dictionary];
	[state setObject:NNWStateDetailViewControllerName forKey:NNWViewControllerNameKey];
	[state safeSetObject:self.newsItemProxy.googleID forKey:NNWDataNameKey];
	return state;
}


+ (NNWDetailViewController *)viewControllerWithState:(NSDictionary *)state {
	NSString *googleID = [state objectForKey:NNWDataNameKey];
	if (RSStringIsEmpty(googleID))
		return nil;
	NNWNewsItemProxy *newsItemProxy = [[[NNWNewsItemProxy alloc] initWithGoogleID:googleID] autorelease];
	[newsItemProxy inflateIfNeeded];
	return [[[self alloc] initWithNewsItemProxy:newsItemProxy] autorelease];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark Actions

- (void)starItem:(id)sender {
	[self.newsItemProxy userToggleStarred];
	[self updateStarInHTML];
}


- (void)showActionMenu:(id)sender {
	[self showActionSheet];
}


- (void)nextUnread:(id)sender {
	NNWNewsItemProxy *newsItemProxy = [self.newsViewController nextUnread:self.newsItemProxy];
	if (newsItemProxy) {
		self.newsItemProxy = newsItemProxy;
		[self loadHTML];
	}
}


#pragma mark Activity Indicator

- (void)showActivityIndicator {
	[_activityContainerView startActivity];
}


- (void)hideActivityIndicator {
	[_activityContainerView stopActivity];
}




#pragma mark Up/Down Control

- (void)enableUpDownControlUpSegment:(BOOL)enableUpSegment enableDownSegment:(BOOL)enableDownSegment {
	[self.upDownControl setEnabled:enableUpSegment forSegmentAtIndex:0];
	[self.upDownControl setEnabled:enableDownSegment forSegmentAtIndex:1];	
}


- (void)updateUpDownControl {
	if (!self.newsItemProxy || !self.newsViewController) {
		[self enableUpDownControlUpSegment:NO enableDownSegment:NO];
		return;
	}
	NNWNewsItemProxy *upNewsItem = [self.newsViewController nextOrPreviousNewsItem:self.newsItemProxy directionIsUp:YES];
	NNWNewsItemProxy *downNewsItem = [self.newsViewController nextOrPreviousNewsItem:self.newsItemProxy directionIsUp:NO];
	[self enableUpDownControlUpSegment:upNewsItem != nil enableDownSegment:downNewsItem != nil];
}


- (void)upDownAction:(id)sender {
	if (!self.newsViewController)
		return; /*shouldn't happen*/
	NNWNewsItemProxy *newsItemProxy = [self.newsViewController nextOrPreviousNewsItem:self.newsItemProxy directionIsUp:((UISegmentedControl *)sender).selectedSegmentIndex == 0];
	if (newsItemProxy) {
		self.newsItemProxy = newsItemProxy;
		[self loadHTML];		
	}
	else
		[self updateUpDownControl];
}



#pragma mark Toolbar

- (NSArray *)toolbarItems {
	if (!self.starToolbarItem)
		self.starToolbarItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star_tab.png"] style:UIBarButtonItemStylePlain target:self action:@selector(starItem:)] autorelease];
	if (!self.actionMenuToolbarItem)
		self.actionMenuToolbarItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"action.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showActionMenu:)] autorelease];
	if (!self.nextUnreadToolbarItem)
		self.nextUnreadToolbarItem = [[[UIBarButtonItem alloc] initWithTitle:@"Next Unread" style:UIBarButtonItemStyleBordered target:self action:@selector(nextUnread:)] autorelease];
	UIBarButtonItem *spaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	return [NSArray arrayWithObjects:self.actionMenuToolbarItem, spaceItem, self.starToolbarItem, spaceItem, spaceItem, self.nextUnreadToolbarItem, nil];
}



#pragma mark Accessors

- (void)setWebView:(UIWebView *)webView {
	if (_webView) {
		_webView.delegate = nil;
		[_webView stopLoading];
		[_webView performSelector:@selector(autorelease) withObject:nil afterDelay:4.0]; /*To avoid crashes!*/
	}
	_webView = [webView retain];
}


#pragma mark Notifications

- (void)handleNewsListDidFetch:(NSNotification *)note {
	[self updateUpDownControl];
}


#pragma mark HTML

static NSString *gHTMLTemplate = nil;

- (void)_replacePlaceholder:(NSString *)placeholderName inString:(NSMutableString *)s {
	NSMutableString *placeholder = [[[NSMutableString alloc] initWithString:@"[["] autorelease];
	[placeholder appendString:placeholderName];
	[placeholder appendString:@"]]"];
	NSString *value = [self.newsItem valueForKey:placeholderName];
	if (!value)
		value = @"";
	[s replaceOccurrencesOfString:placeholder withString:value options:0 range:NSMakeRange(0, [s length])];	
}


- (void)_replaceTitleLinkInString:(NSMutableString *)s {
	NSString *urlString = [self.newsItem valueForKey:RSDataPermalink];
	NSMutableString *linkString = [[[NSMutableString alloc] initWithString:@""] autorelease];
	if (!RSStringIsEmpty(urlString)) {
		[linkString appendString:@"<a href=\""];
		[linkString appendString:urlString];
		[linkString appendString:@"\">"];
	}
	NSString *title = [self.newsItem valueForKey:RSDataTitle];
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
	[s replaceOccurrencesOfString:@"[[displayDate]]" withString:[NSString stringWithFormat:@"\n<br />%@", displayDate] options:0 range:NSMakeRange(0, [s length])];	
}


- (void)_replaceCategoriesInString:(NSMutableString *)s {
	NSString *categories = [self.newsItem displayCategories];
	if (!categories)
		categories = @"";
	[s replaceOccurrencesOfString:@"[[categories]]" withString:categories options:0 range:NSMakeRange(0, [s length])];		
}


- (void)_replaceBylineInString:(NSMutableString *)s {
	NSString *author = [self.newsItem valueForKey:RSDataAuthorName];
	if (!author)
		author = @"";
	else
		author = [NSString stringWithFormat:@"\n<br />by %@", author];
	[s replaceOccurrencesOfString:@"[[byline]]" withString:author options:0 range:NSMakeRange(0, [s length])];
}


//- (NSString *)starGraphicURLString {
//	NSString *imageName = @"star_maintable5.png";
////	NSString *imageName = @"star_tab.png";
//	NSString *f = [[NSBundle mainBundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension]];
//	NSString *urlString = [[NSURL fileURLWithPath:f isDirectory:NO] absoluteString];
//	urlString = RSStringReplaceAll(urlString, @"file://", @"file:///");
//	return urlString;
//}
//
//
//- (void)_replaceStarGraphicInString:(NSMutableString *)s {
//	NSMutableString *imgTag = [NSMutableString stringWithString:@"<img src=\""];
//	[imgTag appendString:[self starGraphicURLString]];
//	[imgTag appendString:@"\" height=\"16\" width=\"16\" alt=\"This item is starred\" />"];
////	[s replaceOccurrencesOfString:@"[[starGraphic]]" withString:imgTag options:0 range:NSMakeRange(0, [s length])];
//	[s replaceOccurrencesOfString:@"[[starGraphic]]" withString:[self starGraphicURLString] options:0 range:NSMakeRange(0, [s length])];
//	NSLog(@"html: %@", s);
//}


- (void)_replacePlaceholdersInString:(NSMutableString *)s {
	[self _replaceTitleLinkInString:s];
	[self _replacePlaceholder:RSDataGoogleFeedTitle inString:s];
	[self _replacePlaceholder:RSDataPlainTextTitle inString:s];
	[self _replaceDatePublishedInString:s];
	[self _replaceCategoriesInString:s];
	[self _replaceBylineInString:s];
//	[self _replaceStarGraphicInString:s];
	[self _replacePlaceholder:@"htmlText" inString:s];
}


- (NSString *)_htmlStringForCurrentNewsItem {
	if (!gHTMLTemplate) {
		NSString *f = [[NSBundle mainBundle] pathForResource:@"newsItemTemplate" ofType:@"html"];
		gHTMLTemplate = [[NSString alloc] initWithContentsOfFile:f];
	}
	NSMutableString *s = [[gHTMLTemplate mutableCopy] autorelease];
	[self _replacePlaceholdersInString:s];
	return s;
}


- (NSString *)_baseURLStringForCurrentNewsItem {
	NSString *urlString = [self.newsItem valueForKey:RSDataXMLBaseURL];
	if (!RSStringIsEmpty(urlString))
		urlString = @"http://www.google.com/";
	if (![[urlString lowercaseString] hasPrefix:@"http"])
		urlString = [NSString stringWithFormat:@"http://%@", urlString]; /*Dumb feeds with missing http://*/
	return urlString;
}


- (void)sendHTMLToWebView:(NSDictionary *)d {
	if ([d objectForKey:RSDataGoogleID] && ![[d objectForKey:RSDataGoogleID] isEqualToString:self.newsItemProxy.googleID])
		return;
	self.lastHTMLString = [d objectForKey:@"htmlText"];
	[self.webView loadHTMLString:[d objectForKey:@"htmlText"] baseURL:[NSURL URLWithString:[d objectForKey:@"baseURLString"]]];
}

	
- (void)loadHTMLOnMainThread:(NSString *)htmlText baseURLString:(NSString *)baseURLString googleID:(NSString *)googleID {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:2];
	[d safeSetObject:htmlText forKey:@"htmlText"];
	[d safeSetObject:baseURLString forKey:@"baseURLString"];
	[d safeSetObject:googleID forKey:RSDataGoogleID];
	[self performSelectorOnMainThread:@selector(sendHTMLToWebView:) withObject:d waitUntilDone:NO];
}


- (void)buildHTML:(NSString *)googleID {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	EXCEPTION_START
		NNWNewsItem *newsItem = [[NNWDataController sharedController] existingNewsItemWithGoogleID:googleID];
		if (!newsItem) {
			[self loadHTMLOnMainThread:@"" baseURLString:@"about:blank" googleID:googleID];
			[pool drain];
			return;
		}
		self.newsItem = newsItem;
		NSString *htmlString = [self _htmlStringForCurrentNewsItem];
		NSString *baseURLString = [self _baseURLStringForCurrentNewsItem];
		[self loadHTMLOnMainThread:htmlString baseURLString:baseURLString googleID:googleID];
		self.newsItem = nil;
	EXCEPTION_END
	CATCH_EXCEPTION
	[pool drain];
}


- (void)loadHTML {
	self.view; /*loadHTML will get called before view is loaded: this forces a load*/
	_loadingWebPage = YES;
	[self.newsItemProxy userMarkAsRead];
	[self performSelector:@selector(buildHTML:) onThread:app_delegate.coreDataThread withObject:self.newsItemProxy.googleID waitUntilDone:NO];
	[self updateUpDownControl];
	//	[self.webView loadHTMLString:[self _htmlStringForAllNewsItems] baseURL:[NSURL URLWithString:[self _baseURLStringForCurrentNewsItem]]];
//	NSString *htmlString = [self _htmlStringForCurrentNewsItem];
	//self.lastHTMLString = htmlString;
	//_hasEmbeddedYoutube = [htmlString caseInsensitiveContains:@"youtube.com"] && [htmlString caseInsensitiveContains:@"<object"];
//	[self.webView loadHTMLString:htmlString baseURL:[NSURL URLWithString:[self _baseURLStringForCurrentNewsItem]]];
	//[self _updateUpDownControl];
}


- (void)updateStarInHTML {
	if (self.newsItemProxy.starred)
		(void)[self.webView stringByEvaluatingJavaScriptFromString:@"showStar()"];
	else
		(void)[self.webView stringByEvaluatingJavaScriptFromString:@"hideStar()"];
}


#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
	if (webView == _webView) {
		//[self _updateNavBarColors:NO];
		//[self.newsItem markRead];
		_loadingWebPage = YES;
		[self performSelector:@selector(showActivityIndicatorIfNeeded) withObject:nil afterDelay:0.1];
	}
	//[self _sendNewsItemDidOpenNotification];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if (webView == _webView) {
		//[self _updateNavBarColors:NO];
		_loadingWebPage = NO;
		[self hideActivityIndicator];
		[self updateStarInHTML];
		[self updateUpDownControl];
		[[NNWMainViewController sharedViewController] saveState];
	}
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if (webView == _webView) {
		_loadingWebPage = NO;
		[self hideActivityIndicator];
		[self updateUpDownControl];
	}
}


- (void)showActivityIndicatorIfNeeded {
	if (self.loadingWebPage)
		[self showActivityIndicator];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		BOOL shouldHandOffURLToSystem = ![app_delegate shouldNavigateToURL:[request URL]];
		if ([app_delegate shouldOpenURLInMoviePlayer:[request URL]] && !shouldHandOffURLToSystem) {
			[self playMediaAtURL:[request URL]];
			return NO;
		}
		if (!shouldHandOffURLToSystem) {
			NNWWebPageViewController *webPageViewController = [[[NNWWebPageViewController alloc] initWithURLRequest:request] autorelease];
			[webPageViewController loadHTML];
			[[self navigationController] pushViewController:webPageViewController animated:YES];
			return NO;
		}
		else {
			[[UIApplication sharedApplication] openURL:[request URL]];
			return NO;
		}
	}
	return YES;
}


#pragma mark Actions

- (NSString *)webPageURLString {
	return self.newsItemProxy.permalink;
}


- (NSString *)webPageTitle {
	return self.newsItemProxy.plainTextTitle;
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


- (void)emailHTMLContentOfNewsItem:(id)sender {
	NSString *title = self.webPageTitle;
	if (RSIsEmpty(title))
		title = @"Cool Link";
	MFMailComposeViewController *mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
	[mailComposeViewController setSubject:title];
	[mailComposeViewController setMessageBody:self.lastHTMLString isHTML:YES];
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
	NNWSendToInstapaper *instapaperController = [[NNWSendToInstapaper alloc] initWithInfoDict:infoDict callbackTarget:[NNWMainViewController sharedViewController]];
	[instapaperController run];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	_actionSheetShowing = NO;
	if (buttonIndex == actionSheet.cancelButtonIndex)
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
//	if (RSIsEmpty(self.webPageURLString))
//		return;
	UIActionSheet *actionSheet = [[[UIActionSheet alloc] init] autorelease];
	_emailMenuItemIndex = NSNotFound;
	_postToTwitterMenuItemIndex = NSNotFound;
	_openInSafariMenuItemIndex = NSNotFound;
	
	NSInteger ix = 0;
	if ([MFMailComposeViewController canSendMail]) {
		[actionSheet addButtonWithTitle:@"Email Article"];
		_emailMenuItemIndex = ix;	
		ix++;
	}
	
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
	//[actionSheet showInView:self.view];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}


@end
