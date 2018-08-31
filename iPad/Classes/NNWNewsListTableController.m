//
//  NNWNewsListTableController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWNewsListTableController.h"
#import "NNWAppDelegate.h"
#import "NNWCurrentNewsItemsController.h"
#import "NNWDataController.h"
#import "RSDetailViewController.h"
#import "NNWDownloadThumbnailOperation.h"
#import "NNWFeedProxy.h"
#import "NNWFeedsShadowedTableView.h"
#import "NNWFeedsTableBackgroundView.h"
#import "NNWFolderProxy.h"
#import "NNWMainViewController.h"
#import "NNWNewsItemProxy.h"
#import "NNWNewsListCell.h"
#import "NNWNewsListCellContentView.h"
#import "NNWProxy.h"
#import "RSDownloadThumbnailOperation.h"
#import "RSOperationController.h"
#import "NNWWebPageViewController.h"


@interface NNWNewsListTableBackgroundView : UIView
@end

@implementation NNWNewsListTableBackgroundView

//- (void)drawRect:(CGRect)r {
//	[[UIImage imageNamed:@"LoginScreenBackground.png"] drawInRect:r];
//}

@end


@interface NNWNewsListTableController ()
@property (retain) NSMutableArray *newsItemProxies;
@property (nonatomic, retain) UIBarButtonItem *markAllReadItem;
@property (nonatomic, retain) UIButton *markAllReadButton;
@property (nonatomic, assign) NSInteger indexOfSelectedRow;
@property (nonatomic, assign) BOOL showingActionSheet;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) UILabel *navbarTitleLabel;
@property (nonatomic, assign, readwrite) NSInteger unreadCount;
@property (nonatomic, retain, readwrite) NSString *titleWithoutUnreadCount;
@property (nonatomic, assign) BOOL didRegisterForNotifications;
@property (nonatomic, assign) BOOL didRestoreState;
@property (nonatomic, assign) BOOL didRestoreWebPageState;
@property (nonatomic, assign) BOOL needsToRestoreWebPageState;
@property (nonatomic, assign) BOOL oneShotReload;
@property (nonatomic, retain, readwrite) id userSelectedObject;

- (NNWNewsItemProxy *)newsItemProxyAtIndex:(NSUInteger)ix;
- (void)updateTitle;
- (void)updateUI;
- (void)redisplayVisibleCells;
- (void)gotoFirstUnread;
- (void)gotoNewsItemAtIndex:(NSInteger)indexOfNewsItem;
@end


@implementation NNWNewsListTableController

@synthesize nnwProxy, newsItemProxies;
@synthesize thumbnailCache, cancelableOperations;
@synthesize markAllReadItem, markAllReadButton;
@synthesize indexOfSelectedRow;
@synthesize showingActionSheet, actionSheet;
@synthesize navbarTitleLabel;
@synthesize unreadCount;
@synthesize titleWithoutUnreadCount;
@synthesize didRegisterForNotifications;
@synthesize oneShotGotoFirstUnreadItem;
@synthesize didRestoreState;
@synthesize didRestoreWebPageState;
@synthesize needsToRestoreWebPageState;
@synthesize oneShotReload;
@synthesize userSelectedObject;


#pragma mark Init

- (id)init {
	self = [super initWithStyle:UITableViewStylePlain];
	if (!self)
		return nil;
	thumbnailCache = [[NSMutableDictionary dictionary] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThumbnailDownloaded:) name:RSDownloadThumbnailOperationDidCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOperationDidCompleteNotification:) name:RSOperationDidCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentNewsItemsDidChange:) name:NNWCurrentNewsItemsDidUpdateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genericDirtyDisplay:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsStarredNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genericDirtyDisplay:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsUnstarredNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(genericDirtyDisplay:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleItemsMarkedRead:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolbarItemsDidUpdate:) name:NNWMainViewControllerToolbarItemsDidUpdateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsItemsDidSave:) name:NNWNewsItemsDidSaveNotification object:nil];
	return self;
}


#pragma Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[newsItemProxies release];
	[nnwProxy release];
	[thumbnailCache release];
	[cancelableOperations release];
	[actionSheet release];
	[navbarTitleLabel release];
	[userSelectedObject release];
	[super dealloc];
}


- (void)loadView {
	self.tableView = [[[NNWNewsListShadowedTableView alloc] initWithFrame:CGRectMake(0, 0, 320, 704) style:UITableViewStylePlain] autorelease];
	self.tableView.rowHeight = 90;
	self.tableView.contentMode = UIViewContentModeRedraw;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.backgroundView = [[[NNWFeedsTableBackgroundView alloc] initWithFrame:self.tableView.frame] autorelease];
}


- (void)viewDidLoad {
	if (markAllReadItem == nil) {
		self.markAllReadButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[self.markAllReadButton addTarget:self action:@selector(markAllRead:) forControlEvents:UIControlEventTouchUpInside];
		[self.markAllReadButton setImage:[UIImage imageNamed:@"MarkAllRead.png"] forState:UIControlStateNormal];
		[self.markAllReadButton setImage:[UIImage imageNamed:@"MarkAllReadDisabled.png"] forState:UIControlStateDisabled];
		[self.markAllReadButton setImage:[UIImage imageWithGlow:[UIImage imageNamed:@"MarkAllRead.png"]] forState:UIControlStateHighlighted];
		self.markAllReadButton.imageEdgeInsets = UIEdgeInsetsMake(2, 11, 2, 4);
		[self.markAllReadButton sizeToFit];
		self.markAllReadButton.contentMode = UIViewContentModeCenter;
		self.markAllReadButton.imageView.contentMode = UIViewContentModeCenter;
		self.markAllReadButton.adjustsImageWhenDisabled = NO;
		self.markAllReadButton.adjustsImageWhenHighlighted = NO;
		self.markAllReadButton.imageView.clipsToBounds = NO;
		self.markAllReadButton.clipsToBounds = NO;
		//self.markAllReadButton.showsTouchWhenHighlighted = YES;
		//		CGRect rMarkAllReadButton = self.markAllReadButton.frame;
//		rMarkAllReadButton.size.width = rMarkAllReadButton.size.width -3;
//		self.markAllReadButton.frame = rMarkAllReadButton;
		self.markAllReadItem = [[[UIBarButtonItem alloc] initWithCustomView:self.markAllReadButton] autorelease];
	}
	if (self.navbarTitleLabel == nil) {
		self.navbarTitleLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.navbarTitleLabel.userInteractionEnabled = NO;
		self.navbarTitleLabel.adjustsFontSizeToFitWidth = YES;
		self.navbarTitleLabel.shadowOffset = CGSizeMake(0, -1);
		self.navbarTitleLabel.shadowColor = [UIColor colorWithWhite:0.2 alpha:0.4];
		self.navigationItem.titleView = self.navbarTitleLabel;
		self.navbarTitleLabel.frame = CGRectMake(0, 0, 320, 44);
		self.navbarTitleLabel.autoresizingMask = UIViewAutoresizingNone;//UIViewAutoresizingFlexibleRightMargin;
		self.navbarTitleLabel.numberOfLines = 2;
		self.navbarTitleLabel.opaque = NO;
		self.navbarTitleLabel.backgroundColor = [UIColor clearColor];
		self.navbarTitleLabel.textColor = [UIColor whiteColor];
		self.navbarTitleLabel.font = [UIFont boldSystemFontOfSize:14.0];
		self.navbarTitleLabel.textAlignment = UITextAlignmentCenter;
		self.navbarTitleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		self.title = nil;
		[self updateTitle];
	}
	if (!self.didRegisterForNotifications) {
		self.didRegisterForNotifications = YES;
		[app_delegate addObserver:self forKeyPath:NNWRightPaneViewTypeKey options:0 context:nil];
	}
	self.navigationItem.rightBarButtonItem = self.markAllReadItem;
}


- (void)viewDidAppear:(BOOL)animated {
	app_delegate.currentLeftPaneViewController = self;
}


- (void)viewDidDisappear:(BOOL)animated {
	[self.thumbnailCache removeAllObjects];
}


- (void)viewWillAppear:(BOOL)animated {
	self.navigationItem.rightBarButtonItem = self.markAllReadItem;
//	[self.navigationController setToolbarHidden:YES animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated {
	if (self.showingActionSheet && self.actionSheet != nil) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:animated];
		self.showingActionSheet = NO;
		self.actionSheet = nil;
	}
}


- (void)didReceiveMemoryWarning {
	[self.thumbnailCache removeAllObjects];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark Title

- (void)setTitle:(NSString *)aTitle {
	[super setTitle:aTitle];
	self.navbarTitleLabel.text = aTitle;
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	if (aTitle == nil)
		[userInfo setObject:@"" forKey:@"title"];
	else
		[userInfo setObject:aTitle forKey:@"title"];
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:NNWTitleDidChangeNotification object:self userInfo:userInfo];
}


static NSString *NNWNewsListTitleWithUnreadCountFormat = @"%@ (%d)";

- (void)updateTitle {
	NSString *currentTitle = self.title;
	NSString *newTitle = nnwProxy.title == nil ? RSEmptyString : nnwProxy.title;
	self.titleWithoutUnreadCount = nnwProxy.title == nil ? RSEmptyString : nnwProxy.title;
	if (self.unreadCount > 0)
		newTitle = [NSString stringWithFormat:NNWNewsListTitleWithUnreadCountFormat, newTitle, self.unreadCount];
	if (![newTitle isEqualToString:currentTitle])
		self.title = newTitle;
}


#pragma mark Accessors

- (void)clearTable {
	self.newsItemProxies = nil;
	self.unreadCount = 0;
	self.indexOfSelectedRow = 0;
	[self.tableView reloadData];	
}


- (void)setNnwProxy:(NNWProxy *)aProxy {
	if (aProxy == self.nnwProxy && !self.oneShotReload)
		return;
	self.oneShotReload = NO;
	[self clearTable];
	[nnwProxy autorelease];
	nnwProxy = [aProxy retain];
	unreadCount = 0; /*Don't want to trigger updateTitle twice*/
	[self updateUI];
//	self.title = nnwProxy.title == nil ? RSEmptyString : nnwProxy.title;
	[app_delegate fetchNewsItemsForNNWProxy:aProxy]; // Fetch will run notification which gets back to us
	if (!RSStringIsEmpty(aProxy.googleID))
		[[NSUserDefaults standardUserDefaults] setObject:aProxy.googleID forKey:NNWStateNewsKey];
	else if ([aProxy isKindOfClass:[NNWStarredItemsProxy class]])
		[[NSUserDefaults standardUserDefaults] setObject:@"star" forKey:NNWStateNewsKey];
	else if ([aProxy isKindOfClass:[NNWLatestNewsItemsProxy class]])
		[[NSUserDefaults standardUserDefaults] setObject:@"latest" forKey:NNWStateNewsKey];
	[[NSUserDefaults standardUserDefaults] setBool:aProxy.isFolder forKey:NNWStateNewsProxyIsFolderKey];
}


- (BOOL)displayingSingleFeed {
	if (self.nnwProxy == nil)
		return NO;
	if ([self.nnwProxy isKindOfClass:[NNWLatestNewsItemsProxy class]] || [self.nnwProxy isKindOfClass:[NNWStarredItemsProxy class]] || [self.nnwProxy isKindOfClass:[NNWFolderProxy class]])
		return NO;
	return [self.nnwProxy isKindOfClass:[NNWFeedProxy class]];
}


#pragma mark Unread Count

- (void)setUnreadCount:(NSInteger)anUnreadCount {
	if (anUnreadCount == self.unreadCount)
		return;
	unreadCount = anUnreadCount;
	[self updateUI];
}


- (void)updateUnreadCount {
	NSArray *items = [self.newsItemProxies copy];
	NSInteger updatedUnreadCount = 0;
	for (NNWNewsItemProxy *oneNewsItem in items) {
		if (!oneNewsItem.read)
			updatedUnreadCount++;
	}
	[items release];
	self.unreadCount = updatedUnreadCount;
}


- (BOOL)hasAnyUnread {
	NSArray *items = [self.newsItemProxies copy];
	BOOL hasAtLeastOneUnreadItem = NO;
	for (NNWNewsItemProxy *oneNewsItem in items) {
		if (!oneNewsItem.read) {
			hasAtLeastOneUnreadItem = YES;
			break;
		}
	}
	[items release];
	return hasAtLeastOneUnreadItem;	
}


#pragma mark State

- (void)restoreWebPageState { //TODO FOO restoreWebPageState
//	@try {
//		if (app_delegate.didRestoreWebpageState) {
//			self.didRestoreWebPageState = YES;
//			self.needsToRestoreWebPageState = NO;
//			return;
//		}
//		app_delegate.didRestoreWebpageState = YES;
//		self.didRestoreWebPageState = YES;
//		self.needsToRestoreWebPageState = NO;
//		NNWRightPaneViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:NNWStateRightPaneViewControllerKey];
//		if (viewType == NNWRightPaneViewWebPage) {
//			NNWWebPageViewController *webPageViewController = [[[NNWWebPageViewController alloc] init] autorelease];
//			app_delegate.detailViewController.contentViewController = webPageViewController;
//			[webPageViewController restoreState];
//		}	
//	}
//	@catch (id obj) {
//		NSLog(@"news list restoreWebPageState error: %@", obj);
//		app_delegate.didRestoreWebpageState = YES;
//		self.didRestoreWebPageState = YES;
//		self.needsToRestoreWebPageState = NO;
//	}
}


- (void)restoreState {
	if (self.didRestoreState)
		return;
	self.didRestoreState = YES;
	@try {
		BOOL didOpenArticle = NO;
		NSString *googleIDOfItemToRestore = [[NSUserDefaults standardUserDefaults] objectForKey:NNWStateArticleIDKey];
		if (!RSStringIsEmpty(googleIDOfItemToRestore)) {
			NSInteger indexOfItem = NSNotFound;
			NSInteger ix = 0;
			for (NNWNewsItemProxy *oneNewsItem in self.newsItemProxies) {
				if ([oneNewsItem.googleID isEqualToString: googleIDOfItemToRestore]) {
					indexOfItem = ix;
				}
				ix++;
			}
			if (indexOfItem != NSNotFound) {
				didOpenArticle = YES;
				[self gotoNewsItemAtIndex:indexOfItem];
			}
		}
		/*Check to see if web page state needs restoring*/
		self.didRestoreWebPageState = YES;
		self.needsToRestoreWebPageState = NO;
		NNWRightPaneViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:NNWStateRightPaneViewControllerKey];
		if (viewType == NNWRightPaneViewWebPage) {
			NSString *urlString = [[NSUserDefaults standardUserDefaults] objectForKey:NNWStateWebPageURLKey];
			if (!RSStringIsEmpty(urlString)) {
				self.needsToRestoreWebPageState = YES;
				self.didRestoreWebPageState = NO;
			}
		}
		if (!self.didRestoreWebPageState && self.needsToRestoreWebPageState && !didOpenArticle) 
			[self restoreWebPageState];
	}
	@catch (id obj) {
		NSLog(@"news list restoreState error: %@", obj);
		app_delegate.didRestoreWebpageState = YES;
		self.didRestoreWebPageState = YES;
		self.needsToRestoreWebPageState = NO;
	}
}


#pragma mark Notifications

- (void)currentNewsItemsDidChange:(NSNotification *)note {
	self.newsItemProxies = [[note userInfo] objectForKey:NNWCurrentNewsItemsKey];
	self.unreadCount = 0;
	self.indexOfSelectedRow = 0;
	[self performSelectorOnMainThread:@selector(updateUnreadCount) withObject:nil waitUntilDone:NO];
	[self.tableView reloadData];
	if (!self.didRestoreState)
		[self restoreState];
	if (self.oneShotGotoFirstUnreadItem) {
		self.oneShotGotoFirstUnreadItem = NO;
		[self gotoFirstUnread];
	}
}


- (void)handleNewsItemsDidSave:(NSNotification *)note {
	self.oneShotReload = YES;
}


- (void)genericDirtyDisplay:(NSNotification *)note {
	[self.tableView.visibleCells makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}


- (void)handleItemsMarkedRead:(NSNotification *)note {
	[self updateUnreadCount];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:NNWRightPaneViewTypeKey])
		[self redisplayVisibleCells];
}


#pragma mark Operations

- (void)runCancelableOperation:(RSOperation *)operation {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(runCancelableOperation:) withObject:operation waitUntilDone:NO];
		return;
	}
	if ([[RSOperationController sharedController] addOperationIfNotInQueue:operation])
		[self.cancelableOperations addObject:operation];
}


- (void)cancelAllCancelableOperations:(BOOL)evenIfExecuting {
	NSInteger i = 0;
	NSInteger numberOfOperations = [self.cancelableOperations count];
	for (i = numberOfOperations - 1; i >= 0; i--) {
		RSOperation *oneOperation = [self.cancelableOperations safeObjectAtIndex:i];
		if (evenIfExecuting || ![oneOperation isExecuting]) {
			[[RSOperationController sharedController] cancelOperation:oneOperation];
			[self.cancelableOperations removeObjectAtIndex:i];
		}
	}
}


- (void)handleOperationDidCompleteNotification:(NSNotification *)note {
	[self.cancelableOperations removeObjectIdenticalTo:[note object]];
}


#pragma mark Mark All as Read

- (void)popViewControllerAnimated {
	[self.navigationController popViewControllerAnimated:YES];	
}


- (void)popViewControllerAnimatedAfterDelay {
	[self performSelector:@selector(popViewControllerAnimated) withObject:nil afterDelay:0.25];
}


- (void)userMarkAllNewsItemsAsRead {
	[NNWNewsItemProxy userMarkNewsItemsAsRead:self.newsItemProxies];
	[self.tableView reloadData];
	[self performSelectorOnMainThread:@selector(popViewControllerAnimatedAfterDelay) withObject:nil waitUntilDone:NO];
//	[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark Next Unread / Up / Down

- (void)selectRowAtIndex:(NSInteger)indexOfNewsItem {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfNewsItem inSection:0];
	[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];	
}


- (void)selectNextRow {
	if (![self canGoDown])
		return;
	[self selectRowAtIndex:self.indexOfSelectedRow + 1];
}


- (void)gotoNewsItemAtIndex:(NSInteger)indexOfNewsItem {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfNewsItem inSection:0];
	BOOL reloadAndTryAgain = NO;
	@try {
		[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
	}
	@catch (id obj) {
		reloadAndTryAgain = YES;
	}
	if (reloadAndTryAgain) {
		[self.tableView reloadData];
		[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
	}
	[self tableView:self.tableView didSelectRowAtIndexPath:indexPath];	
}



- (NSInteger)indexOfNextUnreadInSameSubscription {
	NSInteger start = self.indexOfSelectedRow + 1;
	NSInteger ix = 0;
	NSInteger numberOfNewsItems = [self.newsItemProxies count];
	for (ix = start; ix < numberOfNewsItems; ix++) {
		NNWNewsItemProxy *oneNewsItem = [self newsItemProxyAtIndex:ix];
		if (!oneNewsItem.read)
			return ix;
	}
	return NSNotFound;	
}


- (BOOL)canGoToNextUnreadAnywhere {
	if ([self hasAnyUnread])
		return YES; // Might be before current item, but that means even if all other feeds are read, we can still go that item
	return [app_delegate.masterViewController anySubscriptionHasUnread]; 
}


- (BOOL)canGoToNextUnreadInSameSubscription {
	return [self indexOfNextUnreadInSameSubscription] != NSNotFound;
}


- (BOOL)nextUnreadIsInOtherSubscription {
	if ([self canGoToNextUnreadInSameSubscription])
		return NO;
	return [app_delegate.masterViewController anyNodeOtherThanCurrentHasUnread];
}


- (BOOL)canGoToNextUnread {
	if ([self canGoToNextUnreadInSameSubscription])
		return YES;
	if ([self canGoToNextUnreadAnywhere])
		return YES;
	return NO;
}


- (NSInteger)indexOfFirstUnread {
	NSInteger start = 0;
	NSInteger ix = 0;
	NSInteger numberOfNewsItems = [self.newsItemProxies count];
	for (ix = start; ix < numberOfNewsItems; ix++) {
		NNWNewsItemProxy *oneNewsItem = [self newsItemProxyAtIndex:ix];
		if (!oneNewsItem.read)
			return ix;
	}
	return NSNotFound;	
}

- (void)gotoFirstUnread {
	NSInteger indexOfFirstUnread = [self indexOfFirstUnread];
	if (indexOfFirstUnread == NSNotFound)
		return;
	[self gotoNewsItemAtIndex:indexOfFirstUnread];
}


- (void)gotoNextUnread {
	NSInteger indexOfNextUnreadInSameSubscription = [self indexOfNextUnreadInSameSubscription];
	if (indexOfNextUnreadInSameSubscription != NSNotFound) {
		[self gotoNewsItemAtIndex:indexOfNextUnreadInSameSubscription];
		return;
	}
	if ([self canGoToNextUnreadAnywhere])
		[app_delegate.masterViewController findNextUnreadItemAndSetupState];
}


- (BOOL)canGoUp {
	return self.indexOfSelectedRow > 0;
}


- (void)goUp {
	if ([self canGoUp])
		[self gotoNewsItemAtIndex:self.indexOfSelectedRow - 1];
}


- (BOOL)canGoDown {
	return self.indexOfSelectedRow + 1 < [self.newsItemProxies count];
	
}


- (void)goDown {
	if ([self canGoDown])
		[self gotoNewsItemAtIndex:self.indexOfSelectedRow + 1];
}


#pragma mark -
#pragma mark UI

- (void)updateNavbar {
	markAllReadItem.enabled = (self.unreadCount > 0);
}


- (void)updateToolbar {
	[self setToolbarItems:((NNWMainViewController *)[NNWMainViewController sharedViewController]).lastToolbarItems animated:NO];
}


- (void)updateUI {
	[self updateNavbar];
	[self updateTitle];
	[self updateToolbar];
}


- (void)toolbarItemsDidUpdate:(NSNotification *)note {
	[self updateToolbar];
}


- (void)redisplayVisibleCells {
	[self.tableView.visibleCells makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}


#pragma mark -
#pragma mark Actions

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.showingActionSheet = NO;
	self.actionSheet = nil;
	if (buttonIndex != 0)
		return;
	[self userMarkAllNewsItemsAsRead];
}


- (void)markAllRead:(id)sender {
	/*Show action sheet*/
	if (self.showingActionSheet)
		return;
	self.showingActionSheet = YES;
	self.actionSheet = [[[UIActionSheet alloc] init] autorelease];
	[self.actionSheet addButtonWithTitle:@"Mark All as Read"];
	self.actionSheet.destructiveButtonIndex = 0;
	[self.actionSheet addButtonWithTitle:@"Cancel"];
	self.actionSheet.cancelButtonIndex = 1;
	self.actionSheet.delegate = self;
//	if ([self.tableView rs_inPopover])
//		[self.actionSheet showFromToolbar:self.navigationController.toolbar];
//	else
		[self.actionSheet showFromBarButtonItem:self.markAllReadItem animated:YES];
}


#pragma mark -
#pragma mark Thumbnails

- (UIImage *)cachedThumbnail:(NSString *)urlString {
	if (RSStringIsEmpty(urlString))
		return nil;
	return [self.thumbnailCache objectForKey:urlString];
}


static const CGSize NNWThumbnailSize = {70.0f, 70.0f};

- (BOOL)wantsThumbnail:(UIImage *)thumbnail url:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners {
	return roundedCorners == NO && CGSizeEqualToSize(targetSize, NNWThumbnailSize);
}


- (BOOL)hasCachedThumbnail:(NSString *)urlString {
	return urlString != nil && [self.thumbnailCache objectForKey:urlString] != nil;
}


- (void)thumbnailCached:(NSString *)urlString {
	NSArray *visibleCells = [self.tableView visibleCells];
	for (NNWNewsListCell *oneCell in visibleCells) {
		if ([oneCell wantsThumbnailWithURLString:urlString])
			[oneCell setNeedsDisplay];
	}
}


- (void)cacheThumbnail:(UIImage *)thumbnail urlString:(NSString *)urlString {
	if (thumbnail != nil && !RSStringIsEmpty(urlString) && [self.thumbnailCache objectForKey:urlString] == nil) {
		[self.thumbnailCache setObject:thumbnail forKey:urlString];
		[self thumbnailCached:urlString];
	}
}


- (void)cacheThumbnailIfWanted:(UIImage *)thumbnail url:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners {
	if ([self wantsThumbnail:thumbnail url:url targetSize:targetSize roundedCorners:roundedCorners])
		[self cacheThumbnail:thumbnail urlString:[url absoluteString]];
}


- (void)handleThumbnailDownloaded:(NSNotification *)note {
	RSDownloadThumbnailOperation *operation = [note object];
	if (operation.thumbnailImage != nil)
		[self cacheThumbnailIfWanted:operation.thumbnailImage url:operation.url targetSize:operation.targetImageSize roundedCorners:operation.roundedCorners];
}


- (void)downloadThumbnail:(NSString *)urlString {
	if (RSStringIsEmpty(urlString))
		return;
	RSDownloadThumbnailOperation *downloadThumbnailOperation = [[[NNWDownloadThumbnailOperation alloc] initWithURL:[NSURL URLWithString:urlString] delegate:nil callbackSelector:nil targetImageSize:NNWThumbnailSize roundedCorners:NO] autorelease];
	[downloadThumbnailOperation setQueuePriority:NSOperationQueuePriorityHigh];
	[self runCancelableOperation:downloadThumbnailOperation];
}


- (UIImage *)thumbnailForURLString:(NSString *)urlString {
	if (RSIsIgnorableImgURLString(urlString))
		return nil;
	UIImage *image = [self cachedThumbnail:urlString];
	if (image == nil)
		[self downloadThumbnail:urlString];
	return image;
}


#pragma mark -
#pragma mark Table view data source

- (NNWNewsItemProxy *)newsItemProxyAtIndex:(NSUInteger)ix {
	NSMutableArray *newsItems = self.newsItemProxies;
	return newsItems == nil ? nil : [newsItems safeObjectAtIndex:ix];	
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
	if (section > 0)
		return 0;
	NSMutableArray *newsItems = self.newsItemProxies;
	return newsItems == nil ? 0 : [newsItems count];
}


NSString *NNWNewsListCellIdentifier = @"NewsListCell";

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	NNWNewsListCell *cell = (NNWNewsListCell *)[tv dequeueReusableCellWithIdentifier:NNWNewsListCellIdentifier];
    if (!cell)
        cell = [[[NNWNewsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NNWNewsListCellIdentifier] autorelease];
	cell.tableController = self;
	NNWNewsItemProxy *newsItem = [self newsItemProxyAtIndex:indexPath.row];
	[cell setIsAlternate:(indexPath.row % 2) == 1];
	[cell setNewsItemProxy:newsItem];
	[cell setNeedsDisplay];
    return cell;
}


- (void)handleDidSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.indexOfSelectedRow = indexPath.row;
	//app_delegate.detailViewController.detailItem = [self newsItemProxyAtIndex:indexPath.row];
//	app_delegate.detailViewController.representedObject = [self newsItemProxyAtIndex:indexPath.row];
	self.userSelectedObject = [self newsItemProxyAtIndex:indexPath.row];
	[app_delegate.detailViewController userDidSelectObject:self];
	NNWNewsListCell *selectedCell = (NNWNewsListCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	if (selectedCell != nil) {
		[selectedCell setHighlighted:NO];
		[selectedCell setSelected:YES];
	}
	for (NNWNewsListCell *oneCell in self.tableView.visibleCells) {
		if (selectedCell == oneCell)
			continue;
		[oneCell setHighlighted:NO];
		[oneCell setSelected:NO];		
	}
	if (!self.didRestoreWebPageState && self.needsToRestoreWebPageState)
		[self restoreWebPageState];
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NNWNewsItemProxy *newsItem = [self newsItemProxyAtIndex:indexPath.row];
	[newsItem userMarkAsRead];
	NNWNewsListCell *selectedCell = (NNWNewsListCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	selectedCell.highlighted = YES;
	[self performSelectorOnMainThread:@selector(handleDidSelectRowAtIndexPath:) withObject:indexPath waitUntilDone:NO];
}


- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NNWNewsItemProxy *newsItem = [self newsItemProxyAtIndex:indexPath.row];
	return [NNWNewsListCellContentView rowHeightForNewsItem:newsItem];
}


@end
