//
//  MasterViewController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/3/10.
//  Copyright NewsGator Technologies, Inc. 2010. All rights reserved.
//

#import "NNWMainViewController.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWDatabaseController.h"
#import "RSDetailViewController.h"
#import "NNWFavicon.h"
#import "NNWFeed.h"
#import "NNWFeedProxy.h"
#import "NNWFeedsTableBackgroundView.h"
#import "NNWFolderProxy.h"
#import "NNWLastUpdateContainerView.h"
#import "NNWMainTableViewCell.h"
#import "NNWNewsListTableController.h"
#import "NNWOutlineController.h"
#import "NNWRefreshController.h"
#import "RSOperationController.h"
#import "NNWWebPageViewController.h"


NSString *NNWCollapsedFolderGoogleIDsKey = @"collapsedFolderGoogleIDs";
NSString *NNWUserDidExpandOrCollapseFolderNotification = @"NNWUserDidExpandOrCollapseFolderNotification";
NSString *NNWViewControllerTitleKey = @"title";
NSString *NNWMainViewControllerToolbarItemsDidUpdateNotification = @"NNWMainViewControllerToolbarItemsDidUpdateNotification";

static NSArray *pathForOutlineNode(NNWOutlineNode *outlineNode, NSArray *flatOutline);

@interface NSObject (NNWState)
- (NSDictionary *)stateDictionary;
@end


@interface NNWMainViewController ()
@property (nonatomic, retain) NNWOutlineController *outlineController;
@property (nonatomic, retain) NSTimer *updateTimer;
@property (nonatomic, retain) NSArray *syntheticFeeds;
@property (nonatomic, retain) NSMutableArray *flatOutline;
@property (nonatomic, retain) NSMutableArray *flatOutlineOfVisibleItems;
@property (nonatomic, retain) UIActivityIndicatorView *refreshActivityIndicator;
@property (nonatomic, assign) BOOL feedDownloadsInProgress;
@property (nonatomic, retain) UIBarButtonItem *refreshActivityIndicatorButton;
@property (retain) NSDate *lastTableViewUpdate;
@property (assign) BOOL activeView;
@property (nonatomic, retain) NSMutableArray *collapsedFolderGoogleIDs;
@property (nonatomic, assign) BOOL tableDisplayDirty;
@property (nonatomic, retain) UILabel *statusTextLabel;
@property (nonatomic, retain) UIBarButtonItem *statusToolbarItem;
@property (nonatomic, retain) NSMutableArray *statusMessages;
@property (nonatomic, assign) BOOL googleSyncCallsInProgress;
@property (nonatomic, retain) NSArray *locationInOutline;
@property (nonatomic, retain) NSTimer *updateStatusMessageTimer;
@property (nonatomic, retain) UIView *statusTextContainer;
@property (nonatomic, retain) NSDate *lastUpdateCellsDate;
@property (nonatomic, retain) NSArray *currentFeedIDs;
@property (nonatomic, assign, readwrite) NSInteger totalUnreadCount;
@property (nonatomic, assign) NSInteger numberOfCurrentTableViewAnimations;
@property (nonatomic, retain) UIView *activityIndicatorContainerView;
@property (nonatomic, retain, readwrite) NSArray *lastToolbarItems;
@property (nonatomic, retain, readwrite) NSString *titleWithoutUnreadCount;
@property (nonatomic, retain) NNWLastUpdateContainerView *lastUpdateContainerView;
@property (nonatomic, retain) UIBarButtonItem *lastUpdateToolbarItem;
@property (nonatomic, retain) NSDate *lastTitleUpdate;
@property (nonatomic, retain) NSTimer *updateTitleTimer;
@property (nonatomic, retain) NNWFeedSelection *savedSelection;
@property (nonatomic, retain, readwrite) id userSelectedObject;

- (NSArray *)fetchFeeds;
- (NSArray *)fetchAllFeedIDs;
- (NSMutableArray *)buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:(NSMutableArray *)flatOutline;
- (NSMutableArray *)readOutlineFromDisk;
- (void)updateTitle;
- (void)saveSelection;
- (void)restoreState;
- (void)handleDidSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation NNWMainViewController

@synthesize detailViewController;
@synthesize outlineController = _outlineController, updateTimer = _updateTimer;
@synthesize syntheticFeeds = _syntheticFeeds, flatOutline = _flatOutline;
@synthesize flatOutlineOfVisibleItems = _flatOutlineOfVisibleItems;
@synthesize refreshButton;
@synthesize feedDownloadsInProgress = _feedDownloadsInProgress;
@synthesize refreshActivityIndicator = _refreshActivityIndicator;
@synthesize refreshActivityIndicatorButton = _refreshActivityIndicatorButton;
@synthesize lastTableViewUpdate = _lastTableViewUpdate, activeView = _activeView;
@synthesize collapsedFolderGoogleIDs = _collapsedFolderGoogleIDs;
@synthesize tableDisplayDirty = _tableDisplayDirty, statusTextLabel = _statusTextLabel;
@synthesize statusToolbarItem = _statusToolbarItem, statusMessages = _statusMessages;
@synthesize googleSyncCallsInProgress = _googleSyncCallsInProgress;
@synthesize locationInOutline = _locationInOutline;
@synthesize updateStatusMessageTimer = _updateStatusMessageTimer;
@synthesize statusTextContainer = _statusTextContainer;
@synthesize lastUpdateCellsDate = _lastUpdateCellsDate;
@synthesize currentFeedIDs;
@synthesize editButton, totalUnreadCount;
@synthesize numberOfCurrentTableViewAnimations;
@synthesize activityIndicatorContainerView;
@synthesize lastToolbarItems;
@synthesize titleWithoutUnreadCount;
@synthesize lastUpdateContainerView;
@synthesize lastUpdateToolbarItem;
@synthesize lastTitleUpdate;
@synthesize updateTitleTimer;
@synthesize savedSelection;
@synthesize refreshItem;
@synthesize allFeedIDs;
@synthesize userSelectedObject;


static NNWMainViewController *gMainViewController = nil;
static NSString *NNWFeedsTableTitle = @"Feeds";
static NSString *NNWFeedsTableTitleWithUnreadCountFormat = @"Feeds (%d)";

+ (NNWMainViewController *)sharedViewController {
	return gMainViewController;
	
}


#pragma mark Init

- (id)init {
	self = [super initWithNibName:nil bundle:nil];
	if (!self)
		return nil;
	titleWithoutUnreadCount = [NNWFeedsTableTitle retain];
	return self;
}

#pragma mark Dealloc

- (void)dealloc {
	[_outlineController release];
	[currentFeedIDs release];
	[detailViewController release];
	[lastToolbarItems release];
	[titleWithoutUnreadCount release];
	[lastUpdateContainerView release];
	[lastUpdateToolbarItem release];
	[lastTitleUpdate release];
	[updateTitleTimer invalidateIfValid];
	[updateTitleTimer release];
	[super dealloc];
}


#pragma mark -
#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark UIViewController

- (void)viewDidLoad {
	gMainViewController = self;
	titleWithoutUnreadCount = [NNWFeedsTableTitle retain];
	if (!self.collapsedFolderGoogleIDs)
		self.collapsedFolderGoogleIDs = [[NSUserDefaults standardUserDefaults] objectForKey:NNWCollapsedFolderGoogleIDsKey];
	if (!self.collapsedFolderGoogleIDs)
		self.collapsedFolderGoogleIDs = [NSMutableArray array];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	self.tableView.rowHeight = 44;
	self.tableView.contentMode = UIViewContentModeRedraw;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor colorWithWhite:0.985f alpha:1.0];
	self.tableView.backgroundView = [[[NNWFeedsTableBackgroundView alloc] initWithFrame:self.tableView.frame] autorelease];
	self.tableView.allowsSelection = YES;
	self.tableView.allowsSelectionDuringEditing = YES;
	[self updateTitle];
	if (!self.flatOutline) {
		self.flatOutline = [self readOutlineFromDisk];
		self.flatOutlineOfVisibleItems = [self buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:self.flatOutline];		
	}
	[self.navigationController setToolbarHidden:NO animated:NO];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	
	if (!self.statusMessages)
		self.statusMessages = [NSMutableArray array];
	static BOOL didRegisterForNotifications = NO;
	if (!didRegisterForNotifications) {
		didRegisterForNotifications = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTotalUnreadCountDidUpdate:) name:NNWTotalUnreadCountDidUpdateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncSessionDidBegin:) name:NNWRefreshSessionDidBeginNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncSessionDidEnd:) name:NNWRefreshSessionDidEndNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDidExpandOrCollapseFolderNotification:) name:NNWUserDidExpandOrCollapseFolderNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickRedisplayVisibleCells) name:NNWDidUpdateUnreadCountNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsItemsDidChange:) name:NNWDidUpdateUnreadCountNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsItemsDidChange:) name:NNWNewsItemsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickRedisplayVisibleCells) name:NNWFeedDidUpdateMostRecentItemNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFeedHideShowStatusDidChange:) name:NNWFeedHideShowStatusDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusMessageDidBegin:) name:NNWStatusMessageDidBeginNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusMessageDidEnd:) name:NNWStatusMessageDidEndNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickRedisplayVisibleCells) name:NNWFaviconDidDownloadNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsItemsDidChange:) name:NNWSubscriptionsDidUpdateNotification object:nil];
		[app_delegate addObserver:self forKeyPath:NNWRightPaneViewTypeKey options:0 context:nil];
	}
	self.activeView = YES;
	static BOOL didStartupTasks = NO;
	if (!didStartupTasks) {
		didStartupTasks = YES;
		if (!self.syntheticFeeds)
			self.syntheticFeeds = [NSArray arrayWithObjects:[NNWStarredItemsProxy proxy], [NNWLatestNewsItemsProxy proxy], nil];
		[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(handleNewsItemsDidChange:) withObject:nil waitUntilDone:NO];
		[self performSelector:@selector(_updateTimerDidFire:) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(updateToolbarItems) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(ensureFavicons) withObject:nil waitUntilDone:NO];
	}
	[self performSelector:@selector(updateAllFeedIDs) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:NO];
	[NNWFeedProxy updateUnreadCounts];
}


- (void)_updateTableView {
	self.lastTableViewUpdate = [NSDate date];
	[self.tableView reloadData];
}


- (void)invalidateUpdateTitleTimer {
	if (self.updateTitleTimer == nil)
		return;
	[self.updateTitleTimer invalidateIfValid];
	self.updateTitleTimer = nil;
}


- (void)updateTitle {
	self.lastTitleUpdate = [NSDate date];
	[self invalidateUpdateTitleTimer];
	if (self.titleWithoutUnreadCount == nil)
		self.titleWithoutUnreadCount = NNWFeedsTableTitle;
	NSString *currentTitle = self.title;
	NSString *newTitle = self.totalUnreadCount < 1 ? NNWFeedsTableTitle : [NSString stringWithFormat:NNWFeedsTableTitleWithUnreadCountFormat, self.totalUnreadCount];
	if (![newTitle isEqualToString:currentTitle]) {
		self.title = newTitle;
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
		if (newTitle == nil)
			[userInfo setObject:@"" forKey:@"title"];
		else
			[userInfo setObject:newTitle forKey:@"title"];
		[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:NNWTitleDidChangeNotification object:self userInfo:userInfo];
	}
}


- (void)rescheduleUpdateTitle {
	NSDate *previousTitleUpdate = self.lastTitleUpdate;
	if (previousTitleUpdate == nil)
		previousTitleUpdate = [NSDate distantPast];
	if ([previousTitleUpdate earlierDate:[NSDate dateWithTimeIntervalSinceNow:-1]] == previousTitleUpdate) {
		[self updateTitle];
		return;
	}
	[self invalidateUpdateTitleTimer];
	self.updateTitleTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTitle) userInfo:nil repeats:NO];
}


- (void)updateUnreadCounts {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateUnreadCounts) withObject:nil waitUntilDone:NO];
		return;
	}
	[NNWFeedProxy updateUnreadCounts];
}


- (void)_updateTimerDidFire:(NSTimer *)timer {
	if (self.updateTimer) {
		[self.updateTimer invalidateIfValid];
		self.updateTimer = nil;
	}
	self.lastTableViewUpdate = [NSDate date];
	[self performSelectorOnMainThread:@selector(updateUnreadCounts) withObject:nil waitUntilDone:NO];
	
	NSArray *feedIDs = self.isEditing? self.allFeedIDs : [self fetchFeeds];
	if (![feedIDs isEqual:self.currentFeedIDs]) {
		NNWOutlineController *outlineController = [[NNWOutlineController alloc] init]; /*released on callback*/
		outlineController.delegate = self;
		self.currentFeedIDs = feedIDs;
		[outlineController rebuildOutline:feedIDs includeExcludedFeeds:self.isEditing];
	}
}


- (void)_rescheduleUpdateTimer {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	static BOOL didInitialUpdate = NO;
	if (!didInitialUpdate) {
		didInitialUpdate = YES;
		[self _updateTimerDidFire:nil];
		goto _rescheduleUpdateTimer_exit;		
	}
	else if (self.lastTableViewUpdate && [self.lastTableViewUpdate earlierDate:[NSDate dateWithTimeIntervalSinceNow:-4]] == self.lastTableViewUpdate) {
		[self _updateTimerDidFire:nil];
		goto _rescheduleUpdateTimer_exit;		
	}
	if (self.updateTimer) {
		[self.updateTimer invalidateIfValid];
		self.updateTimer = nil;
	}
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_updateTimerDidFire:) userInfo:nil repeats:NO];
_rescheduleUpdateTimer_exit:
	[pool drain];
}


- (void)setNeedsDisplayForVisibleCells {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(setNeedsDisplayForVisibleCells) withObject:nil waitUntilDone:NO];
		return;
	}
	if (!_mainViewScrolling)
		[[self.tableView visibleCells] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}


- (void)quickRedisplayVisibleCells {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(quickRedisplayVisibleCells) withObject:nil waitUntilDone:NO];
		return;
	}
	[self setNeedsDisplayForVisibleCells];
}


- (void)handleNewsItemsDidChange:(NSNotification *)note {
	if ([NSThread currentThread] != app_delegate.coreDataThread) {
		[self performSelector:@selector(handleNewsItemsDidChange:) onThread:app_delegate.coreDataThread withObject:note waitUntilDone:NO];
		return;
	}
	if (!self.activeView)
		return;
	[self _rescheduleUpdateTimer];
}


- (void)handleFeedHideShowStatusDidChange:(NSNotification *)note {
	[self handleNewsItemsDidChange:note];
}


- (void)ensureFavicons {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *flatOutlineOfNonCollapsedItems = [self buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:[[self.flatOutline copy] autorelease]];
	for (NNWOutlineNode *oneNode in flatOutlineOfNonCollapsedItems) {
		if (oneNode.isFolder)
			continue;
		NNWProxy *oneProxy = oneNode.nnwProxy;
		if (!oneProxy || RSStringIsEmpty(oneProxy.googleID))
			continue;
		(void)[NNWFavicon imageForFeedWithGoogleID:oneProxy.googleID];
	}
	[pool drain];
}


- (void)outlineDidRebuild:(NNWOutlineController *)outlineController {
	self.flatOutline = outlineController.flattenedOutline;
	[self performSelectorOnMainThread:@selector(ensureFavicons) withObject:nil waitUntilDone:NO];
	[outlineController performSelectorOnMainThread:@selector(autorelease) withObject:nil waitUntilDone:NO];	
	self.flatOutlineOfVisibleItems = [self buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:self.flatOutline];
	[self _updateTableView];
	[self updateUnreadCounts];
}


- (void)viewWillAppear:(BOOL)animated {
	[NNWFeedProxy updateUnreadCounts];
	self.locationInOutline = nil;
	self.activeView = YES;
    [super viewWillAppear:animated];
	[self.tableView setNeedsDisplay];
}


- (void)viewDidAppear:(BOOL)animated {
	[NNWFeedProxy invalidateAllUnreadCounts];
	app_delegate.currentLeftPaneViewController = self;
	self.navigationController.toolbarHidden = NO;
}


- (void)didReceiveMemoryWarning {
	;
}


#pragma mark Actions

- (IBAction)refreshButtonPressed:(id)sender {
	[[NNWRefreshController sharedController] runRefreshSession];
}


#pragma mark Toolbar

- (void)updateStatusTextContainerFrame {
	self.statusTextContainer.frame = CGRectMake(0, 0, self.view.frame.size.width - 60, 20);
}


- (void)updateToolbarItems {
	NSArray *toolbarItems = nil;
	if (self.refreshItem == nil) {
			self.refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *refreshImage = [UIImage imageNamed:@"Reload.png"];
		CGSize refreshImageSize = refreshImage.size;
			[self.refreshButton setImage:[UIImage imageWithoutGlow:refreshImage] forState:UIControlStateNormal];
		[self.refreshButton setImage:[UIImage imageWithGlow:refreshImage] forState:UIControlStateHighlighted];
		[self.refreshButton addTarget:self action:@selector(refreshButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
			self.refreshButton.adjustsImageWhenDisabled = NO;
			self.refreshButton.adjustsImageWhenHighlighted = NO;
			self.refreshButton.showsTouchWhenHighlighted = YES;
			self.refreshButton.userInteractionEnabled = YES;
			self.refreshButton.frame = CGRectMake(0, 0, refreshImageSize.width, refreshImage.size.height);
		self.refreshButton.contentMode = UIViewContentModeCenter;
		self.refreshButton.imageView.contentMode = UIViewContentModeCenter;
		self.refreshButton.imageView.clipsToBounds = NO;
		self.refreshButton.clipsToBounds = NO;
			self.refreshItem = [[[UIBarButtonItem alloc] initWithCustomView:self.refreshButton] autorelease];
			
	}
	if (self.activityIndicatorContainerView == nil) {
		self.activityIndicatorContainerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 34, 36)] autorelease];
		self.activityIndicatorContainerView.backgroundColor = [UIColor clearColor];
	}
	if (!self.refreshActivityIndicator) {
		self.refreshActivityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
		[self.activityIndicatorContainerView addSubview:self.refreshActivityIndicator];
		self.refreshActivityIndicator.center = self.activityIndicatorContainerView.center;
	}
	if (!self.refreshActivityIndicatorButton)
		self.refreshActivityIndicatorButton = [[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorContainerView] autorelease];
	if (!self.statusTextLabel) {
		self.statusTextLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		self.statusTextLabel.frame = CGRectMake(0, -1, self.view.frame.size.width - 0, 20);
		self.statusTextLabel.textColor = [UIColor whiteColor];
		self.statusTextLabel.backgroundColor = [UIColor clearColor];
		self.statusTextLabel.font = [UIFont boldSystemFontOfSize:12];
		self.statusTextLabel.shadowColor = [UIColor darkGrayColor];
		self.statusTextLabel.text = @"";
		self.statusTextLabel.userInteractionEnabled = YES;
		self.statusTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	}
	if (!self.statusTextContainer) {
		self.statusTextContainer = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 0, 20)] autorelease];
		[self.statusTextContainer addSubview:self.statusTextLabel];
		self.statusTextContainer.backgroundColor = [UIColor clearColor];
	}
	if (!self.statusToolbarItem)
		self.statusToolbarItem = [[[UIBarButtonItem alloc] initWithCustomView:self.statusTextContainer] autorelease];
	
	if (!self.lastUpdateContainerView)
		self.lastUpdateContainerView = [[[NNWLastUpdateContainerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 60, 22)] autorelease];
	if (!self.lastUpdateToolbarItem)
		self.lastUpdateToolbarItem = [[[UIBarButtonItem alloc] initWithCustomView:self.lastUpdateContainerView] autorelease];
	
	if (self.googleSyncCallsInProgress || self.feedDownloadsInProgress) {
		[self.refreshActivityIndicator startAnimating];
		toolbarItems = [NSArray arrayWithObjects:self.refreshActivityIndicatorButton, self.statusToolbarItem, nil];		
	}
	else {
		[self.refreshActivityIndicator stopAnimating];
		toolbarItems = [NSArray arrayWithObjects:self.refreshItem, self.lastUpdateToolbarItem, nil];		
	}
	if (![toolbarItems isEqualToArray:self.lastToolbarItems]) {
		[self setToolbarItems:toolbarItems animated:YES];
		self.lastToolbarItems = toolbarItems;
		[[NSNotificationCenter defaultCenter] postNotificationName:NNWMainViewControllerToolbarItemsDidUpdateNotification object:nil];
	}
}


#pragma mark Status Text

- (void)invalidateStatusMessageTimer {
	if (self.updateStatusMessageTimer) {
		[self.updateStatusMessageTimer invalidateIfValid];
		self.updateStatusMessageTimer = nil;
	}	
}


- (void)updateStatusMessageTimerDidFire:(NSTimer *)timer {
	[self invalidateStatusMessageTimer];
	if (RSIsEmpty(self.statusMessages))
		self.statusTextLabel.text = @"";
	else
		self.statusTextLabel.text = [self.statusMessages lastObject];
}


- (void)rescheduleUpdateStatusMessage {
	[self invalidateStatusMessageTimer];
	self.updateStatusMessageTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateStatusMessageTimerDidFire:) userInfo:nil repeats:NO];
}


- (void)updateStatusText {
	if (RSIsEmpty(self.statusMessages)) {
		[self rescheduleUpdateStatusMessage];
		//		self.statusTextLabel.text = @"";
	}
	else {
		NSString *aStatusMessage = [self.statusMessages lastObject];
		if (aStatusMessage == nil)
			aStatusMessage = @"";
		else if (![aStatusMessage hasSuffix:@"…"])
			aStatusMessage = [NSString stringWithFormat:@"%@…", aStatusMessage];
		self.statusTextLabel.text = aStatusMessage;
		[self invalidateStatusMessageTimer];
	}
}


#pragma mark Accessors

- (void)setTotalUnreadCount:(NSInteger)unreadCount {
	if (totalUnreadCount == unreadCount)
		return;
	totalUnreadCount = unreadCount;
	[self rescheduleUpdateTitle];
}

#pragma mark Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:NNWRightPaneViewTypeKey])
		[self quickRedisplayVisibleCells];
}


- (void)handleFeedDownloadingDidEndNotification:(NSNotification *)note {
	self.feedDownloadsInProgress = NO;
	[self updateToolbarItems];
}


- (void)handleFeedDownloadsInProgressNotification:(NSNotification *)note {
	if (!self.feedDownloadsInProgress) {
		self.feedDownloadsInProgress = YES;
		[self updateToolbarItems];
	}
}


- (void)handleStatusMessageDidBegin:(NSNotification *)note {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(handleStatusMessageDidBegin:) withObject:note waitUntilDone:NO];
		return;
	}
	[self.statusMessages safeAddObject:[[note userInfo] objectForKey:NNWStatusMessageKey]];
	[self updateStatusText];
}


- (void)handleStatusMessageDidEnd:(NSNotification *)note {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(handleStatusMessageDidEnd:) withObject:note waitUntilDone:NO];
		return;
	}
	[self.statusMessages removeObject:[[note userInfo] objectForKey:NNWStatusMessageKey]];
	[self updateStatusText];
}


- (void)handleSyncSessionDidBegin:(NSNotification *)note {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(handleSyncSessionDidBegin:) withObject:note waitUntilDone:NO];
		return;
	}
	[self.statusMessages removeAllObjects];
	self.googleSyncCallsInProgress = YES;
	[self updateToolbarItems];
}


- (void)handleSyncSessionDidEnd:(NSNotification *)note {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(handleSyncSessionDidEnd:) withObject:note waitUntilDone:NO];
		return;
	}
	[self.statusMessages removeAllObjects];
	self.googleSyncCallsInProgress = NO;
	[self updateStatusText];
	[self updateToolbarItems];
	[self performSelector:@selector(updateAllFeedIDs) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:NO];
}


- (void)handleTotalUnreadCountDidUpdate:(NSNotification *)note {
	NSNumber *unreadCountNum = [[note userInfo] objectForKey:NNWTotalUnreadCountKey];
	NSInteger unreadCount = 0;
	if (unreadCountNum != nil)
		unreadCount = [unreadCountNum integerValue];
	self.totalUnreadCount = unreadCount;
}


#pragma mark Fetching Feeds

- (NSArray *)fetchFeedIDs {
	return [[NNWDatabaseController sharedController] feedIDsForCurrentItems];
}


- (NSArray *)fetchFeeds {
	return [self fetchFeedIDs];
}


- (NSArray *)fetchAllFeedIDs {
	/*For when editing -- gets *all* feed ids, even excluded feeds*/
	return [NNWFeed allFeedIDs];
}


- (void)updateAllFeedIDs {
	self.allFeedIDs = [self fetchAllFeedIDs];
}


- (NSArray *)allFeedIDs {
	if (allFeedIDs)
		return allFeedIDs;
	[self performSelector:@selector(updateAllFeedIDs) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:YES];
	return allFeedIDs;
}


#pragma mark Next Unread

static NSInteger indexOfOutlineNodeInFlatOutline(NNWOutlineNode *outlineNode, NSArray *flatOutline) {
	NSInteger ix = 0;
	for (NNWOutlineNode *oneOutlineNode in flatOutline) {
		if (oneOutlineNode == outlineNode)
			return ix;
		ix++;
	}
	return NSNotFound;
}


static NNWOutlineNode *parentOfOutlineNodeInFlatOutline(NNWOutlineNode *outlineNode, NSArray *flatOutline) {
	if (outlineNode.level < 1)
		return nil;
	NSInteger indexOfOutlineNode = indexOfOutlineNodeInFlatOutline(outlineNode, flatOutline);
	if (indexOfOutlineNode == NSNotFound)
		return nil;
	NSInteger levelForOutlineNode = outlineNode.level;
	NSInteger i;
	for (i = indexOfOutlineNode - 1; i >= 0; i--) {
		NNWOutlineNode *oneOutlineNode = [flatOutline objectAtIndex:i];
		if (oneOutlineNode.isFolder && oneOutlineNode.level == levelForOutlineNode - 1)
			return oneOutlineNode;
	}
	return nil;
}


static NSArray *pathForOutlineNode(NNWOutlineNode *outlineNode, NSArray *flatOutline) {
	NSMutableArray *path = [NSMutableArray array];
	NNWOutlineNode *nomad = outlineNode;
	while (true) {
		[path insertObject:nomad.googleID atIndex:0];
		nomad = parentOfOutlineNodeInFlatOutline(nomad, flatOutline);
		if (!nomad)
			break;
	}
	return path;
}


static NNWOutlineNode *outlineNodeWithPath(NSArray *locationArray, NSArray *flatOutline) {
	for (NNWOutlineNode *oneOutlineNode in flatOutline) {
		NSArray *onePath = pathForOutlineNode(oneOutlineNode, flatOutline);
		if ([onePath isEqualToArray:locationArray])
			return oneOutlineNode;
	}
	return nil;
}


static NNWOutlineNode *firstOutlineNodeWithGoogleIDInOutline(NSString *googleID, NSArray *flatOutline) {
	for (NNWOutlineNode *oneOutlineNode in flatOutline) {
		if ([googleID isEqualToString:oneOutlineNode.googleID])
			return oneOutlineNode;
	}
	return nil;
}


static NNWOutlineNode *outlineNodeWithParentAndGoogleIDInOutline(NNWOutlineNode *parent, NSString *googleID, NSArray *flatOutline) {
	NSInteger ixParent =  parent ? indexOfOutlineNodeInFlatOutline(parent, flatOutline) : -1;
	NSInteger i;
	NSInteger numberOfOutlineNodes = [flatOutline count];
	NSInteger parentLevel = parent ? parent.level : -1;
	for (i = ixParent + 1; i < numberOfOutlineNodes; i++) {
		NNWOutlineNode *oneOutlineNode = [flatOutline objectAtIndex:i];
		if (oneOutlineNode.level == parentLevel + 1 && [googleID isEqualToString:oneOutlineNode.googleID])
			return oneOutlineNode;
		if (oneOutlineNode.level <= parentLevel)
			return nil;
	}
	return nil;
}


static NNWOutlineNode *outlineNodeForPathInOutline(NSArray *path, NSArray *flatOutline) {
	/*A path is an array of googleIDs that detail the location of an item in the outline. If the outline has changed since the path was created, just find the first NNWOutlineNode matching the final googleID in the path. (Remember that a single feed can live in multiple places, but folders exist in just one place.)*/
	if (RSIsEmpty(path))
		return nil;
	NNWOutlineNode *nomad = nil;
	NSInteger i;
	NSInteger numberOfItemsInPath = [path count];
	for (i = 0; i < numberOfItemsInPath; i++) {
		nomad = outlineNodeWithParentAndGoogleIDInOutline(nomad, [path objectAtIndex:i], flatOutline);
		if (!nomad)
			break;
		if (i == numberOfItemsInPath - 1)
			return nomad;
	}
	return firstOutlineNodeWithGoogleIDInOutline([path lastObject], flatOutline);
}




static BOOL outlineNodeHasUnreadItems(NNWOutlineNode *outlineNode) {
	NNWProxy *nnwProxy = outlineNode.nnwProxy;
	if (!nnwProxy)
		return NO;
	if (nnwProxy.unreadCountIsValid)
		return nnwProxy.unreadCount > 0;
	[NNWFeedProxy updateUnreadCounts];
	[(NNWFeedProxy *)nnwProxy updateUnreadCount];
	return nnwProxy.unreadCount > 0;	
}


static NNWOutlineNode *firstOutlineNodeWithUnreadItems(NSArray *flatOutline) {
	for (NNWOutlineNode *oneOutlineNode in flatOutline) {
		if (outlineNodeHasUnreadItems(oneOutlineNode))
			return oneOutlineNode;
	}
	return nil;
}


- (NNWOutlineNode *)nextOutlineNodeWithUnreadItemsAfterCurrentLocation { /*For Next Unread button. Also loops around.*/
	NNWOutlineNode *outlineNode = outlineNodeForPathInOutline(self.locationInOutline, self.flatOutline);
	if (!outlineNode) /*Rare, but outline could have changed: for instance, a feed being shown via state-restoring at startup may have since been deleted via syncing (say the user had deleted the feed on another device or at Google Reader*/
		return firstOutlineNodeWithUnreadItems(self.flatOutline);
	NSInteger indexOfCurrentNode = indexOfOutlineNodeInFlatOutline(outlineNode, self.flatOutline);
	if (indexOfCurrentNode == NSNotFound) /*Shouldn't happen if we get here, but remedy is the same as above*/
		return firstOutlineNodeWithUnreadItems(self.flatOutline);
	NSInteger i;
	NSInteger numberOfOutlineNodes = [self.flatOutline count];
	NSInteger levelForCurrentOutlineNode = outlineNode.level;
	for (i = indexOfCurrentNode + 1; i < numberOfOutlineNodes; i++) {
		NNWOutlineNode *oneOutlineNode = [self.flatOutline safeObjectAtIndex:i];
		if (!oneOutlineNode || oneOutlineNode.level > levelForCurrentOutlineNode) /*Skip children. Sibs or parents only*/
			continue;
		if (outlineNodeHasUnreadItems(oneOutlineNode))
			return oneOutlineNode;
	}
	for (i = 0; i <= indexOfCurrentNode; i++) {
		NNWOutlineNode *oneOutlineNode = [self.flatOutline safeObjectAtIndex:i];
		if (!oneOutlineNode || oneOutlineNode.level > levelForCurrentOutlineNode) /*Skip children. Sibs or parents only*/
			continue;
		if (outlineNodeHasUnreadItems(oneOutlineNode))
			return oneOutlineNode;
	}
	/*Shouldn't happen unless there are no unreads anywhere. But, just in case.*/
	return firstOutlineNodeWithUnreadItems(self.flatOutline);
}


- (NSIndexPath *)indexPathOfOutlineNode:(NNWOutlineNode *)outlineNode {
	NSInteger ixNode = [self.flatOutlineOfVisibleItems indexOfObjectIdenticalTo:outlineNode];
	if (ixNode == NSNotFound)
		return nil;
	return [NSIndexPath indexPathForRow:ixNode inSection:1];
}


- (void)findNextUnreadItemAndSetupState { //TODO FOO
	/*Called once at the end of a news items list, and we have to find the next feed/folder with an unread item. This method returns that item -- but it also updates app state: sets the list for the news view controller and makes it run a fetch, the gets the first unread item after doing the fetch and returns it.*/
	NNWOutlineNode *newOutlineNode = [self nextOutlineNodeWithUnreadItemsAfterCurrentLocation];
	if (!newOutlineNode)
		return;
	self.locationInOutline = pathForOutlineNode(newOutlineNode, self.flatOutline);
	NNWProxy *nnwProxy = newOutlineNode.nnwProxy;
	if (nnwProxy.isFolder)
		((NNWFolderProxy *)nnwProxy).googleIDsOfDescendants = [self googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)nnwProxy];
	app_delegate.newsListViewController.oneShotGotoFirstUnreadItem = YES;
	self.userSelectedObject = nnwProxy;
	[app_delegate.detailViewController userDidSelectObject:self];
//	app_delegate.detailViewController.detailItem = nnwProxy;
	app_delegate.newsListViewController.nnwProxy = nnwProxy;
	NSIndexPath *newPathToSelect = [self indexPathOfOutlineNode:newOutlineNode];
	if (newPathToSelect != nil)
		[self.tableView selectRowAtIndexPath:newPathToSelect animated:YES scrollPosition:UITableViewScrollPositionMiddle];
//	self.newsViewController.nnwProxy = nnwProxy;
//	self.newsViewController.title = nnwProxy.title;
//	[self.newsViewController fetchNewsItemsInBackgroundAndWait];
	return;
//	return self.newsViewController.firstUnreadItem;	
//	return nil;
}


- (BOOL)anySubscriptionHasUnread {
	for (NNWOutlineNode *oneNode in self.flatOutline) {
		if ([oneNode hasAtLeastOneUnreadItem])
			return YES;
	}
	return NO;
}


- (BOOL)anyNodeOtherThanCurrentHasUnread {
	NNWOutlineNode *currentOutlineNode = outlineNodeForPathInOutline(self.locationInOutline, self.flatOutline);
	NNWOutlineNode *newOutlineNode = [self nextOutlineNodeWithUnreadItemsAfterCurrentLocation];
	return newOutlineNode != nil && newOutlineNode != currentOutlineNode;
}


#pragma mark Expand/Collapse

- (NSInteger)rowOfVisibleFolderWithGoogleID:(NSString *)folderGoogleID {
	if (RSStringIsEmpty(folderGoogleID))
		return NSNotFound;
	NSInteger row = -1;
	for (NNWOutlineNode *oneNode in self.flatOutlineOfVisibleItems) {
		row++;
		if (!oneNode.isFolder)
			continue;
		NNWProxy *oneFolderProxy = oneNode.nnwProxy;
		if (!oneFolderProxy || RSStringIsEmpty(oneFolderProxy.googleID))
			continue;
		if ([folderGoogleID isEqualToString:oneFolderProxy.googleID])
			return row;
	}
	return NSNotFound;
}


- (BOOL)folderWithGoogleIDIsCollapsed:(NSString *)folderGoogleID {
	return [self.collapsedFolderGoogleIDs containsObject:folderGoogleID];
}


- (BOOL)folderOutlineNodeIsCollapsed:(NNWOutlineNode *)folderOutlineNode {
	NNWProxy *folderProxy = folderOutlineNode.nnwProxy;
	if (!folderProxy || RSStringIsEmpty(folderProxy.googleID))
		return NO;
	return [self folderWithGoogleIDIsCollapsed:folderProxy.googleID];
}


- (NSArray *)indexPathsOfVisibleChildrenOfFolderWithGoogleID:(NSString *)folderGoogleID {
	NSInteger folderRow = [self rowOfVisibleFolderWithGoogleID:folderGoogleID];
	if (folderRow == NSNotFound)
		return nil;
	NSInteger folderLevel = ((NNWOutlineNode *)[self.flatOutlineOfVisibleItems objectAtIndex:folderRow]).level;
	NSMutableArray *indexSetArray = [NSMutableArray array];
	NSInteger i;
	NSInteger numberOfVisibleNodes = [self.flatOutlineOfVisibleItems count];
	for (i = folderRow + 1; i < numberOfVisibleNodes; i++) {
		NNWOutlineNode *oneNode = [self.flatOutlineOfVisibleItems safeObjectAtIndex:i];
		if (!oneNode)
			break;
		if (oneNode.level > folderLevel)
			[indexSetArray addObject:[[NSIndexPath indexPathWithIndex:1] indexPathByAddingIndex:i]];
		else if (oneNode.level <= folderLevel)
			break;
		
	}
	return indexSetArray;
}


- (void)saveCollapsedFolderGoogleIDs {
	[[NSUserDefaults standardUserDefaults] setObject:self.collapsedFolderGoogleIDs forKey:NNWCollapsedFolderGoogleIDsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)collapseFolder:(NSString *)folderGoogleID contentView:(UIView *)contentView {
	[self saveSelection];
	if (RSStringIsEmpty(folderGoogleID))
		return;
	NSArray *indexPathsOfVisibleChildren = [self indexPathsOfVisibleChildrenOfFolderWithGoogleID:folderGoogleID];
	if (![self.collapsedFolderGoogleIDs containsObject:folderGoogleID]) {
		[self.collapsedFolderGoogleIDs addObject:folderGoogleID];
		[self performSelectorOnMainThread:@selector(saveCollapsedFolderGoogleIDs) withObject:nil waitUntilDone:NO];
	}
	if (RSIsEmpty(indexPathsOfVisibleChildren))
		return;
	self.flatOutlineOfVisibleItems = [self buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:self.flatOutline];
	[UIView beginAnimations:nil context:contentView];
	[UIView setAnimationDelegate:self]; 
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:indexPathsOfVisibleChildren withRowAnimation:UITableViewRowAnimationMiddle];
	[self.tableView endUpdates];
	[UIView commitAnimations];
}


- (void)collapseFolder:(NSString *)folderGoogleID {
	[self collapseFolder:folderGoogleID contentView:nil];
}


- (void)turnOffDisclosureHighlightingForAllRows {
	[[self.tableView visibleCells] makeObjectsPerformSelector:@selector(turnOffDisclosureHighlight)];
}


- (void)incrementNumberOfCurrentTableViewAnimations {
	self.numberOfCurrentTableViewAnimations = self.numberOfCurrentTableViewAnimations + 1;
}


- (void)decrementNumberOfCurrentTableViewAnimations {
	self.numberOfCurrentTableViewAnimations = self.numberOfCurrentTableViewAnimations - 1;
	if (self.numberOfCurrentTableViewAnimations < 1)
		[self turnOffDisclosureHighlightingForAllRows];	
}


- (void)saveSelection {
	self.savedSelection = [[[NNWFeedSelection alloc] init] autorelease];
	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (selectedIndexPath == nil) {
		self.savedSelection = nil;
		return;
	}
	if (selectedIndexPath.section == 0) {
		self.savedSelection.nnwProxy = [self.syntheticFeeds safeObjectAtIndex:selectedIndexPath.row];
		self.savedSelection.section = 0;
		return;
	}
	NNWOutlineNode *node = [self.flatOutlineOfVisibleItems objectAtIndex:selectedIndexPath.row];
	self.savedSelection.node = node;
	self.savedSelection.section = 1;
	self.savedSelection.row = selectedIndexPath.row;
}


- (void)restoreSelection {
	if (self.savedSelection == nil)
		return;
	if (self.savedSelection.section == 0) {
		self.savedSelection = nil; //Nothing to do for synthetic feeds at top, since they don't move
		return;
	}
	/*The saved row and node might already match, in which case we need do nothing.*/
	NNWOutlineNode *nodeAtSavedRow = [self.flatOutlineOfVisibleItems safeObjectAtIndex:self.savedSelection.row];
	if (nodeAtSavedRow != self.savedSelection.node) {
		/*Have to find it.*/
		[self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:self.savedSelection.row inSection:1] animated:NO]; //remove bogus selection
		NSUInteger foundRow = [self.flatOutlineOfVisibleItems indexOfObjectIdenticalTo:self.savedSelection.node];
		if (foundRow != NSNotFound)
			[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:foundRow inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	self.savedSelection = nil;
}


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if ([(NNWMainTableCellContentView *)context respondsToSelector:@selector(decrementDisclosureHighlights)])
		[(NNWMainTableCellContentView *)context performSelector:@selector(decrementDisclosureHighlights)];
	[self decrementNumberOfCurrentTableViewAnimations];
//	if (self.numberOfCurrentTableViewAnimations < 1)
	[self performSelectorOnMainThread:@selector(turnOffDisclosureHighlightingForAllRows) withObject:nil waitUntilDone:NO];
	[self restoreSelection];
}


- (void)expandFolder:(NSString *)folderGoogleID contentView:(UIView *)contentView {
	[self saveSelection];
	if (RSStringIsEmpty(folderGoogleID))
		return;
	if ([self.collapsedFolderGoogleIDs containsObject:folderGoogleID]) {
		[self.collapsedFolderGoogleIDs removeObject:folderGoogleID];
		[self performSelectorOnMainThread:@selector(saveCollapsedFolderGoogleIDs) withObject:nil waitUntilDone:NO];
	}
	self.flatOutlineOfVisibleItems = [self buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:self.flatOutline];
	NSArray *indexPathsOfVisibleChildren = [self indexPathsOfVisibleChildrenOfFolderWithGoogleID:folderGoogleID];
	if (RSIsEmpty(indexPathsOfVisibleChildren))
		return;
	[self incrementNumberOfCurrentTableViewAnimations];
	[UIView beginAnimations:nil context:contentView];
	[UIView setAnimationDelegate:self]; 
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:indexPathsOfVisibleChildren withRowAnimation:UITableViewRowAnimationTop];
	[self.tableView endUpdates];
	[UIView commitAnimations];
}


- (void)expandFolder:(NSString *)folderGoogleID {
	[self expandFolder:folderGoogleID contentView:nil];
}


- (void)expandOrCollapseFolderWithGoogleID:(NSString *)folderGoogleID contentView:(UIView *)contentView {
	if ([self folderWithGoogleIDIsCollapsed:folderGoogleID])
		[self expandFolder:folderGoogleID contentView:contentView];
	else
		[self collapseFolder:folderGoogleID contentView:contentView];
}


- (void)handleUserDidExpandOrCollapseFolderNotification:(NSNotification *)note {
	NSDictionary *representedObject = [note userInfo];
	if (RSIsEmpty(representedObject))
		return;
	NNWProxy *folderProxy = [representedObject objectForKey:@"nnwProxy"];
	if (!folderProxy || !folderProxy.isFolder)
		return;
	NSString *googleID = folderProxy.googleID;
	if (RSStringIsEmpty(googleID))
		return;
	[self expandOrCollapseFolderWithGoogleID:googleID contentView:[note object]];
	[[note object] setCollapsed:[self folderWithGoogleIDIsCollapsed:googleID]];
	self.tableDisplayDirty = YES;
}


#pragma mark Outline of visible items

- (NSMutableArray *)buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:(NSMutableArray *)flatOutline {
	NSMutableArray *visibleItems = [NSMutableArray array];
	NSInteger currentCollapsedLevel = 0;
	for (NNWOutlineNode *oneNode in flatOutline) {
		if (oneNode.level < currentCollapsedLevel)
			currentCollapsedLevel = 0;
		if (currentCollapsedLevel == 0)
			[visibleItems addObject:oneNode];
		if (currentCollapsedLevel == 0 && oneNode.isFolder && [self folderOutlineNodeIsCollapsed:oneNode])
			currentCollapsedLevel = oneNode.level + 1;
	}
	return visibleItems;
}



#pragma mark Folders - descendants

- (NSInteger)indexOfProxy:(NNWProxy *)proxy {
	NSInteger ix = 0;
	for (NNWOutlineNode *oneNode in self.flatOutline) {
		if (oneNode.nnwProxy == proxy)
			return ix;
		ix++;
	}
	return NSNotFound;
}


- (NSArray *)googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)folder {
	NSInteger ix = [self indexOfProxy:(NNWProxy *)folder];
	if (ix == NSNotFound)
		return nil;
	NNWOutlineNode *folderNode = [self.flatOutline objectAtIndex:ix];
	NSInteger folderLevel = folderNode.level;
	NSMutableArray *googleIDs = [NSMutableArray array];
	while (true) {
		ix++;
		NNWOutlineNode *oneNode = [self.flatOutline safeObjectAtIndex:ix];
		if (!oneNode || oneNode.level <= folderLevel)
			break;
		if (oneNode.level > folderLevel && !oneNode.isFolder)
			[googleIDs safeAddObject:oneNode.nnwProxy.googleID];
	}
	return googleIDs;
}


#pragma mark State

- (void)restoreLocationInOutline:(NSArray *)locationArray {
	@try {
		if (RSIsEmpty(locationArray))
			return;
		NNWOutlineNode *outlineNode = outlineNodeWithPath(locationArray, self.flatOutline);
		if (outlineNode == nil)
			return;
		NNWProxy *nnwProxy = outlineNode.nnwProxy;
		if (nnwProxy.isFolder)
			((NNWFolderProxy *)nnwProxy).googleIDsOfDescendants = [self googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)nnwProxy];
		NSIndexPath *newPathToSelect = [self indexPathOfOutlineNode:outlineNode];
		if (newPathToSelect != nil)
			[self.tableView scrollToRowAtIndexPath:newPathToSelect atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
	}
	@catch (id obj) {
		NSLog(@"error restoring state in restoreLocationInOutline: %@", obj);
	}
}


static NSString *NNWOutlineFileName = @"nnw2_flatoutline.archive";

- (void)saveOutlineToDisk {
	if (!RSIsEmpty(self.flatOutline))
		[NSKeyedArchiver archiveRootObject:self.flatOutline toFile:RSDocumentsFilePath(NNWOutlineFileName)];
}


- (NSMutableArray *)readOutlineFromDisk {
	NSArray *flatOutline = [NSKeyedUnarchiver unarchiveObjectWithFile:RSDocumentsFilePath(NNWOutlineFileName)];
	return [[flatOutline mutableCopy] autorelease];
}


- (void)saveState {
	if (RSIsEmpty(_locationInOutline))
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:NNWStateFeedsLocationInOutlineKey];
	else
		[[NSUserDefaults standardUserDefaults] setObject:_locationInOutline forKey:NNWStateFeedsLocationInOutlineKey];
}


- (void)restoreLocationInOutlineFromPrefs {
	[self restoreLocationInOutline:[[NSUserDefaults standardUserDefaults] objectForKey:NNWStateFeedsLocationInOutlineKey]];	
}


- (void)restoreState { //TODO FOO
	
//	@try {
//		NNWLeftPaneViewType leftType = [[NSUserDefaults standardUserDefaults] integerForKey:NNWStateLeftPaneViewControllerKey];
//		if (leftType == NNWLeftPaneViewFeeds) {
//			[self restoreLocationInOutlineFromPrefs];
//			app_delegate.didRestoreWebpageState = YES;
//			NNWRightPaneViewType viewType = [[NSUserDefaults standardUserDefaults] integerForKey:NNWStateRightPaneViewControllerKey];
//			if (viewType == NNWRightPaneViewWebPage) {
//				NNWWebPageViewController *webPageViewController = [[[NNWWebPageViewController alloc] init] autorelease];
//				app_delegate.detailViewController.contentViewController = webPageViewController;
//				[webPageViewController restoreState];
//			}
//			return;
//		}
//		if (leftType == NNWLeftPaneViewNews) {
//			NSString *nnwProxyID = [[NSUserDefaults standardUserDefaults] stringForKey:NNWStateNewsKey];
//			if (RSStringIsEmpty(nnwProxyID))
//				return;
//			NNWProxy *nnwProxy = nil;
//			if ([nnwProxyID isEqualToString:@"star"])
//				nnwProxy = [NNWStarredItemsProxy proxy];
//			else if ([nnwProxyID isEqualToString:@"latest"])
//				nnwProxy = [NNWLatestNewsItemsProxy proxy];
//			else {
//				BOOL isFolder = [[NSUserDefaults standardUserDefaults] boolForKey:NNWStateNewsProxyIsFolderKey];
//				if (isFolder) {
//					nnwProxy = [NNWFolderProxy folderProxyWithGoogleID:nnwProxyID];
//					((NNWFolderProxy *)nnwProxy).googleIDsOfDescendants = [self googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)nnwProxy];
//				}
//				else
//					nnwProxy = [NNWFeedProxy feedProxyWithGoogleID:nnwProxyID];
//			}
//			if (nnwProxy == nil)
//				return;
//			app_delegate.detailViewController.detailItem = nnwProxy;
//			app_delegate.newsListViewController.nnwProxy = nnwProxy;
//			NNWOutlineNode *outlineNode = nil;
//			for (NNWOutlineNode *oneOutlineNode in self.flatOutlineOfVisibleItems) {
//				if (oneOutlineNode.nnwProxy == nnwProxy) {
//					outlineNode = oneOutlineNode;
//					break;
//				}
//			}
//			if (outlineNode != nil) {
//				NSInteger outlineNodeIndex = indexOfOutlineNodeInFlatOutline(outlineNode, self.flatOutlineOfVisibleItems);
//				if (outlineNodeIndex != NSNotFound) {
//					NSIndexPath *path = [NSIndexPath indexPathForRow:outlineNodeIndex inSection:1];
//					[self handleDidSelectRowAtIndexPath:path];
//					return;
//				}
//			}
//			if ([nnwProxy isKindOfClass:[NNWStarredItemsProxy class]]) {
//				[self handleDidSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//				return;
//			}
//			else if ([nnwProxy isKindOfClass:[NNWLatestNewsItemsProxy class]]) {
//				[self handleDidSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
//				return;
//			}
//		}	
//	}
//	
//	@catch (id obj) {
//		NSLog(@"main view controller restore state error: %@", obj);
//	}
//
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return [self.syntheticFeeds count];
	if (section == 1)
		return [self.flatOutlineOfVisibleItems count];
	return 0;
}


NSString *_NNWMainCellIdentifier = @"MainViewCell";

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
 	NSInteger section = indexPath.section;
	NNWMainTableViewCell *cell = nil;
	cell = (NNWMainTableViewCell *)[tv dequeueReusableCellWithIdentifier:_NNWMainCellIdentifier];
	if (!cell)
		cell = [[[NNWMainTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_NNWMainCellIdentifier] autorelease];

	NSInteger row = indexPath.row;
	cell.contentView.backgroundColor = [UIColor whiteColor];
	
	NSString *title = nil;
	NSInteger rowType = 0;
	
	if (section == 2) {
		if (row == 0) {
			title = @"Show/Hide Feeds";
			rowType = NNWShowHideFeedsItem;
		}
	}
	
	cell.clipsToBounds = YES;
	[cell setHasFolderShadow:NO];
	cell.expandable = NO;
	cell.level = 0;
	
	NSMutableDictionary *representedObject = [NSMutableDictionary dictionary];
	
	if (section == 0) {
		NNWProxy *nnwProxy = [self.syntheticFeeds objectAtIndex:row];
		[representedObject safeSetObject:nnwProxy forKey:@"nnwProxy"];
		rowType = NNWFeedItem;
		[representedObject safeSetObject:nnwProxy.title forKey:RSDataTitle];
		[representedObject setBool:YES forKey:@"synthetic"];
		if ([nnwProxy respondsToSelector:@selector(proxyFeedImage)])
			[representedObject safeSetObject:[(NNWStarredItemsProxy *)nnwProxy proxyFeedImage] forKey:@"image"];
		[cell setMainViewController:self];
		cell.expandable = NO;
		
		
//		UIImageView *img = (UIImageView*)[cell.contentView viewWithTag:kCheckmarkImageTag];
//		if(img)
//		{
//			[img removeFromSuperview];
//			[img release];
//		}
	}
	else if (section == 1) {
		//NNWProxy *nnwProxy = ((NNWOutlineNode *)[self.flatOutlineOfVisibleItems objectAtIndex:indexPath.row]).nnwProxy;
		NNWOutlineNode *node = [self.flatOutlineOfVisibleItems objectAtIndex:indexPath.row];
		cell.level = MIN(node.level, 3);
		NNWProxy *nnwProxy = node.nnwProxy;
		[representedObject safeSetObject:nnwProxy forKey:@"nnwProxy"];
		BOOL isFeed = !nnwProxy.isFolder;
		rowType = isFeed ? NNWFeedItem : NNWFolderItem;
		[representedObject safeSetObject:nnwProxy.title forKey:RSDataTitle];
		if (RSIsEmpty([representedObject objectForKey:RSDataTitle]))
			[representedObject setObject:@"Unknown" forKey:RSDataTitle];
		[cell setMainViewController:self];
		if (!isFeed)
			[cell setCollapsed:[self folderWithGoogleIDIsCollapsed:nnwProxy.googleID]];
		cell.expandable = !isFeed;
		/*If is feed, find out if previous item is folder. If so, we need the shadow.*/
		if (isFeed && indexPath.row > 0) {
			NNWProxy *previousItem = ((NNWOutlineNode *)[self.flatOutlineOfVisibleItems safeObjectAtIndex:indexPath.row - 1]).nnwProxy;
			if (previousItem != nil && previousItem.isFolder && ![self folderWithGoogleIDIsCollapsed:previousItem.googleID])
				[cell setHasFolderShadow:YES];
		}
		
//		if(isFeed)
//		{
//	//		UIImageView *img = (UIImageView*)[cell.contentView viewWithTag:kCheckmarkImageTag];
////			
////			if(!img)
////			{
////				NNWFeedProxy *nnwFeedProxy = (NNWFeedProxy*)nnwProxy;
////				NSString *imgName = (nnwFeedProxy.userExcludes) ? @"EditScreen_Hidden.png" : @"EditScreen_Shown.png";
////				img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];
////				img.frame = CGRectMake(2, 10, 29, 30);
////				//img.alpha = 0.0;
////				[cell.contentView addSubview:img];
////				img.tag = kCheckmarkImageTag;
////			}
//			
////			[UIView beginAnimations:@"fadeEditBadge" context:nil];
////			[UIView setAnimationDuration:0.33];
////			img.alpha = (self.tableView.editing) ? 1.0 : 0.0;
////			[UIView commitAnimations];
//		}
//		else 
//		{
//			UIImageView *img = (UIImageView*)[cell.contentView viewWithTag:kCheckmarkImageTag];
//			if(img)
//			{
//				[img removeFromSuperview];
//				[img release];
//			}
//		}

	}
	else
		[representedObject setObject:title forKey:RSDataTitle];
	
	[representedObject setObject:[NSNumber numberWithInteger:rowType] forKey:@"rowType"];
	[cell setRepresentedObject:representedObject];
	
//	cell.backgroundView = [[[NNWTableCellBackgroundGradientView alloc] init] autorelease];

    return cell;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		NNWOutlineNode *node = [self.flatOutlineOfVisibleItems safeObjectAtIndex:indexPath.row];
		NSInteger level = 0;
		if (node)
			level = node.level;
		if (level > 3)
			level = 3;
		
		if((tableView.editing)&&(!node.isFolder))
			level++;
		
		return level;
	}
	return 0;
}


- (void)handleDidSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NNWMainTableViewCell *cell = (NNWMainTableViewCell *)[self tableView:self.tableView cellForRowAtIndexPath:indexPath];
	cell.highlighted = NO;
	cell.selected = YES;
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	self.locationInOutline = nil;
	if (section == 0) {
		NNWProxy *nnwProxy = [self.syntheticFeeds objectAtIndex:row];
		app_delegate.newsListViewController.nnwProxy = nnwProxy;
		[self.navigationController pushViewController:app_delegate.newsListViewController animated:YES];
	}
	else if (section == 1) {
		NNWOutlineNode *outlineNode = [self.flatOutlineOfVisibleItems safeObjectAtIndex:indexPath.row];
		if (!outlineNode)
			return;
		self.locationInOutline = pathForOutlineNode(outlineNode, self.flatOutline);
		NNWProxy *nnwProxy = outlineNode.nnwProxy;
		app_delegate.newsListViewController.nnwProxy = nnwProxy;
		if (nnwProxy.isFolder)
			((NNWFolderProxy *)nnwProxy).googleIDsOfDescendants = [self googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)nnwProxy];
		[self.navigationController pushViewController:app_delegate.newsListViewController animated:YES];
	}
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NNWMainTableViewCell *cell = (NNWMainTableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
	if (self.isEditing) {
		if (indexPath.section < 1) {
			cell.highlighted = NO;
			cell.selected = NO;
			return;
		}
		NNWOutlineNode *outlineNode = [self.flatOutlineOfVisibleItems safeObjectAtIndex:indexPath.row];
		NNWProxy *nnwProxy = outlineNode.nnwProxy;
		if (nnwProxy.isFolder) {
			cell.highlighted = NO;
			cell.selected = NO;
			return;
		}		
	}
	cell.highlighted = YES;
	[self performSelectorOnMainThread:@selector(handleDidSelectRowAtIndexPath:) withObject:indexPath waitUntilDone:NO];
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	_mainViewScrolling = YES;
	[[RSOperationController sharedController] setSuspended:YES];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	_mainViewScrolling = YES;
	if (!decelerate) {
		[[RSOperationController sharedController] setSuspended:NO];
		_mainViewScrolling = NO;
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	_mainViewScrolling = NO;
	[[RSOperationController sharedController] setSuspended:NO];
}


@end


@implementation NNWFeedSelection

@synthesize section, row, nnwProxy, node;

- (void)dealloc {
	[nnwProxy release];
	[node release];
	[super dealloc];
}

@end
