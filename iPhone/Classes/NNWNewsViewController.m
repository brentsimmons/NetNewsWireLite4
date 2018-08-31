//
//  NNWNewsViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWNewsViewController.h"
#import "BCDownloadManager.h"
#import "BCDownloadRequest.h"
#import "NNWAppDelegate.h"
#import "NNWDetailViewController.h"
#import "NNWFeedProxy.h"
#import "NNWFolderProxy.h"
#import "NNWMainViewController.h"
#import "NNWNewsTableViewController.h"
#if ADS
#import "NNWAdView.h"
#endif

@interface NNWNewsViewController ()
@property (nonatomic, retain) NNWNewsTableViewController *tableViewController;
@property (nonatomic, retain) UIBarButtonItem *markAllAsReadToolbarItem;
@property (nonatomic, retain) NNWAdView *adView;
@end


@implementation NNWNewsViewController

@synthesize tableViewController = _tableViewController, nnwProxy = _nnwProxy, markAllAsReadToolbarItem = _markAllAsReadToolbarItem, /*syntheticFeed = _syntheticFeed,*/ googleIDsOfDescendants = _googleIDsOfDescendants, mainViewController = _mainViewController, adView = _adView, stateRestoredNewsItemProxy = _stateRestoredNewsItemProxy;


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_tableViewController release];
	[_nnwProxy release];
//	[_managedObject release];
	[_markAllAsReadToolbarItem release];
//	[_syntheticFeed release];
	[_googleIDsOfDescendants release];
	[_adView release];
	[_stateRestoredNewsItemProxy release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)loadView {
	self.view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
	self.view.backgroundColor = [UIColor whiteColor];
	self.view.autoresizesSubviews = YES;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	if (!self.tableViewController)
		self.tableViewController = [[[NNWNewsTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	if (self.stateRestoredNewsItemProxy)
		self.tableViewController.stateRestoredNewsItemProxy = self.stateRestoredNewsItemProxy;
	self.tableViewController.nnwProxy = self.nnwProxy;
	//self.tableViewController.syntheticFeed = self.syntheticFeed;
	self.tableViewController.googleIDsOfDescendants = self.googleIDsOfDescendants;
	self.tableViewController.tableView.frame = self.view.bounds;
	self.tableViewController.delegate = self;
	[self.view addSubview:self.tableViewController.tableView];

	self.navigationItem.backBarButtonItem = app_delegate.backArrowButtonItem;
	self.title = self.nnwProxy.title;
	self.navigationController.toolbarHidden = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsItemsDidFetch:) name:NNWNewsItemsListDidFetchNotification object:nil];
	
//#if ADS
//	NSInteger adViewHeight = [NNWAdView adViewHeight];
//	CGRect rTableView = self.tableViewController.tableView.frame;
//	rTableView.size.height = rTableView.size.height - adViewHeight;
//	//self.tableViewController.tableView.frame = rTableView;
//	CGRect rAdView = CGRectMake(0, CGRectGetMaxY(rTableView), rTableView.size.width, adViewHeight);
//	self.adView = [[[NNWAdView alloc] initWithFrame:rAdView] autorelease];
//	self.adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
//	//[self.view addSubview:self.adView];
//#endif
}


- (void)viewWillAppear:(BOOL)animated {
	[app_delegate sendBigUIStartNotification];
	[super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
	[self.navigationController setToolbarHidden:NO animated:NO];
	[self.tableViewController.tableView deselectCurrentRow];
	[self.tableViewController.tableView reloadData];
	[self.tableViewController runFetchIfNeeded];
	self.markAllAsReadToolbarItem.enabled = self.tableViewController.hasUnreadItems;
	[app_delegate sendBigUIEndNotification];
}


- (void)viewWillDisappear:(BOOL)animated {
	[[BCDownloadManager sharedManager] removeAllPendingDownloadsOfType:BCDownloadTypeThumbnail];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


NSString *NNWNewsViewControllerName = @"news";
NSString *NNWStarredItemsName = @"starredItems";
NSString *NNWLatestItemsName = @"latestItems";
NSString *NNWStateGoogleIDsOfDescendantsKey = @"googleIDsOfDescendants";
NSString *NNWStateIsFolderKey = @"isFolder";

- (NSString *)stateDataIdentifier {
	if ([self.nnwProxy isKindOfClass:[NNWStarredItemsProxy class]])
		return NNWStarredItemsName;
	if ([self.nnwProxy isKindOfClass:[NNWLatestNewsItemsProxy class]])
		return NNWLatestItemsName;
	return self.nnwProxy.googleID;
}


+ (NNWProxy *)proxyWithState:(NSDictionary *)state {
	NSString *proxyIdentifier = [state objectForKey:NNWDataNameKey];
	if ([proxyIdentifier isEqualToString:NNWStarredItemsName])
		return [NNWStarredItemsProxy proxy];
	if ([proxyIdentifier isEqualToString:NNWLatestItemsName])
		return [NNWLatestNewsItemsProxy proxy];
	if ([state boolForKey:NNWStateIsFolderKey]) {
		NNWFolderProxy *folderProxy = [NNWFolderProxy folderProxyWithGoogleID:proxyIdentifier];
		folderProxy.googleIDsOfDescendants = [state objectForKey:NNWStateGoogleIDsOfDescendantsKey];
		return folderProxy;
	}
	return [NNWFeedProxy feedProxyWithGoogleID:proxyIdentifier];
}


- (NSDictionary *)stateDictionary {
	NSMutableDictionary *state = [NSMutableDictionary dictionary];
	[state setObject:NNWNewsViewControllerName forKey:NNWViewControllerNameKey];
	[state safeSetObject:[self stateDataIdentifier] forKey:NNWDataNameKey];
	[state setBool:self.nnwProxy.isFolder forKey:NNWStateIsFolderKey];
	if (self.nnwProxy.isFolder)
		[state safeSetObject:((NNWFolderProxy *)(self.nnwProxy)).googleIDsOfDescendants forKey:NNWStateGoogleIDsOfDescendantsKey];
	[state safeSetObject:self.title forKey:NNWStateViewControllerTitleKey];
	return state;
}


+ (NNWNewsViewController *)viewControllerWithState:(NSDictionary *)state {
	NNWNewsViewController *newsViewController = [[[self alloc] initWithNibName:nil bundle:nil] autorelease];
	newsViewController.nnwProxy = [self proxyWithState:state];
	newsViewController.title = [state objectForKey:NNWStateViewControllerTitleKey];
	return newsViewController;
}


- (NNWNewsItemProxy *)newsItemProxyWithGoogleID:(NSString *)googleID {
	/*Used by state restoring*/
	NSArray *newsItemProxies = self.tableViewController.newsItemProxies;
	for (NNWNewsItemProxy *oneNewsItemProxy in newsItemProxies) {
		if ([googleID isEqualToString:oneNewsItemProxy.googleID])
			return oneNewsItemProxy;
	}
	return nil;
}

#pragma mark Accessors

- (void)setNnwProxy:(NNWProxy *)nnwProxy {
	self.tableViewController.nnwProxy = nnwProxy;
	[_nnwProxy autorelease];
	_nnwProxy = [nnwProxy retain];
}


- (void)setStateRestoredNewsItemProxy:(NNWNewsItemProxy *)newsItemProxy {
	self.tableViewController.stateRestoredNewsItemProxy = newsItemProxy;
	[_stateRestoredNewsItemProxy autorelease];
	_stateRestoredNewsItemProxy = [newsItemProxy retain];
}


#pragma mark NNWNewsTableViewController Delegate

- (void)tableViewController:(UITableViewController *)tableViewController didSelectNewsItem:(NNWNewsItemProxy *)newsItemProxy {	
//	NSString *mediaURLString = newsItemProxy.movieURLString;//[newsItem valueForKey:RSDataMovieURL];
//	if (RSStringIsEmpty(mediaURLString))
//		mediaURLString = newsItemProxy.audioURLString;//[newsItem valueForKey:RSDataAudioURL];
//	if (!RSStringIsEmpty(mediaURLString)) {
//		NSString *preview = newsItemProxy.preview;//[newsItem valueForKey:RSDataHTMLText];
//		if (!preview || [preview length] < 100) {
//			[self playMediaAtURL:[NSURL URLWithString:mediaURLString]];
//			return;			
//		}
//	}
	NNWDetailViewController *detailViewController = [[[NNWDetailViewController alloc] initWithNewsItemProxy:newsItemProxy] autorelease];
	detailViewController.newsViewController = self;
	[detailViewController loadHTML];		
	[self.navigationController pushViewController:detailViewController animated:YES];
}



- (void)newsItemsDidFetch:(NSNotification *)note {
	self.markAllAsReadToolbarItem.enabled = self.tableViewController.hasUnreadItems;	
	[[NNWMainViewController sharedViewController] saveState];
}


#pragma mark Toolbar

- (NSArray *)toolbarItems {
	if (!self.markAllAsReadToolbarItem)
		self.markAllAsReadToolbarItem = [[[UIBarButtonItem alloc] initWithTitle:@"Mark All as Read" style:UIBarButtonItemStyleBordered target:self action:@selector(_markAllAsRead:)] autorelease];
	self.markAllAsReadToolbarItem.enabled = self.tableViewController.hasUnreadItems;
	UIBarButtonItem *spaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	return [NSArray arrayWithObjects:self.markAllAsReadToolbarItem, spaceItem, nil];
}


#pragma mark Actions

- (void)_markAllAsRead:(id)sender {
	self.markAllAsReadToolbarItem.enabled = NO;
	[self.tableViewController.newsItemProxies makeObjectsPerformSelector:@selector(userMarkAsRead)];
	[self.tableViewController.tableView reloadData];
	[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark Up/Down Arrows

- (NNWNewsItemProxy *)nextOrPreviousNewsItem:(NNWNewsItemProxy *)relativeToNewsItem directionIsUp:(BOOL)directionIsUp {
	int ixCurrentNewsItem = [self.tableViewController.newsItemProxies indexOfObjectIdenticalTo:relativeToNewsItem];
	if (ixCurrentNewsItem == NSNotFound)
		return nil;
	if (ixCurrentNewsItem < 1 && directionIsUp)
		return nil;
	if (ixCurrentNewsItem >= [self.tableViewController.newsItemProxies count] - 1 && !directionIsUp)
		return nil;
	return [self.tableViewController.newsItemProxies objectAtIndex:directionIsUp ? ixCurrentNewsItem - 1 : ixCurrentNewsItem + 1];
}


#pragma mark Next Unread

- (NNWNewsItemProxy *)firstUnreadItemInArray:(NSArray *)newsItemProxies {
	if (RSIsEmpty(newsItemProxies))
		return nil;
	for (NNWNewsItemProxy *oneNewsItemProxy in newsItemProxies) {
		if (!oneNewsItemProxy.read)
			return oneNewsItemProxy;
	}
	return nil;
}


- (NNWNewsItemProxy *)firstUnreadItemInArray:(NSArray *)newsItemProxies afterIndex:(NSInteger)indexOfNewsItemProxy {
	if (RSIsEmpty(newsItemProxies))
		return nil;
	NSInteger ix = 0;
	for (NNWNewsItemProxy *oneNewsItemProxy in newsItemProxies) {
		if (ix > indexOfNewsItemProxy && !oneNewsItemProxy.read)
			return oneNewsItemProxy;
		ix++;
	}
	return nil;
	
}


- (NNWNewsItemProxy *)nextUnread:(NNWNewsItemProxy *)relativeToNewsItem {
	NNWNewsItemProxy *newsItemProxy = nil;
	int ixCurrentNewsItem = [self.tableViewController.newsItemProxies indexOfObjectIdenticalTo:relativeToNewsItem];
	if (ixCurrentNewsItem == NSNotFound || ixCurrentNewsItem >= [self.tableViewController.newsItemProxies count]) {
		newsItemProxy = [self firstUnreadItemInArray:self.tableViewController.newsItemProxies];
		if (newsItemProxy)
			return newsItemProxy;
		return [self.mainViewController findNextUnreadItemAndSetupState];
	}
	newsItemProxy = [self firstUnreadItemInArray:self.tableViewController.newsItemProxies afterIndex:ixCurrentNewsItem];
	if (newsItemProxy)
		return newsItemProxy;
	return [self.mainViewController findNextUnreadItemAndSetupState];	
}



- (void)fetchNewsItems {
	[self.tableViewController runFetch];	
}


- (void)fetchNewsItemsInBackgroundAndWait {
	[self.tableViewController fetchNewsItemsInBackgroundAndWait];
}


- (NNWNewsItemProxy *)firstUnreadItem {
	return [self firstUnreadItemInArray:self.tableViewController.newsItemProxies];
}



@end
