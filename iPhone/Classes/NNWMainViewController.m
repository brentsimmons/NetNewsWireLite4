//
//  RootViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright NewsGator Technologies, Inc. 2009. All rights reserved.
//

#import "NNWMainViewController.h"
#import "BCDownloadManager.h"
#import "BCFeedbackHUDViewController.h"
#import "NNWAdView.h"
#import "NNWAddDefaultsViewController.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWDetailViewController.h"
#import "NNWFavicon.h"
#import "NNWFeed.h"
#import "NNWFeedProxy.h"
#import "NNWFolderProxy.h"
#import "NNWLoginViewController.h"
#import "NNWMainTableViewCell.h"
#import "NNWNewsViewController.h"
#import "NNWOutlineController.h"
#import "NNWRefreshController.h"
#import "NNWRefreshSession.h"
#import "NNWSendToInstapaper.h"
#import "NNWShowHideFeedsTableViewController.h"
#import "NNWSyncActionsController.h"
#import "NNWWebPageViewController.h"


NSString *NNWMainViewControllerWillAppearNotification = @"NNWMainViewControllerWillAppearNotification";
NSString *NNWCollapsedFolderGoogleIDsKey = @"collapsedFolderGoogleIDs";
NSString *NNWUserDidExpandOrCollapseFolderNotification = @"NNWUserDidExpandOrCollapseFolderNotification";

static NSArray *pathForOutlineNode(NNWOutlineNode *outlineNode, NSArray *flatOutline);

@interface NSObject (NNWState)
- (NSDictionary *)stateDictionary;
@end


/*If you triple-tap the status text, it displays a HUD window telling you what version of NetNewsWire you're running.*/

@interface NNWStatusLabel : UILabel
@end

@implementation NNWStatusLabel

- (NSInteger)highestTapCountForTouches:(NSSet *)touches {
	NSInteger maxTapCount = 0;
	for (UITouch *oneTouch in touches) {
		if (oneTouch.tapCount > maxTapCount)
			maxTapCount = oneTouch.tapCount;
	}
	return maxTapCount;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([self highestTapCountForTouches:[event touchesForView:self]] == 3)
		[app_delegate displayAboutOverlay:self];
	[super touchesEnded:touches withEvent:event];
}


@end

@interface NNWMainViewController ()
@property (nonatomic, retain) NNWOutlineController *outlineController;
@property (nonatomic, retain) NSTimer *updateTimer;
@property (nonatomic, retain) NSArray *syntheticFeeds;
@property (nonatomic, retain) NSMutableArray *flatOutline;
@property (nonatomic, retain) NSMutableArray *flatOutlineOfVisibleItems;
@property (nonatomic, retain) UIBarButtonItem *refreshButton;
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
@property (nonatomic, retain) NNWNewsViewController *newsViewController;
@property (nonatomic, retain) NNWAdView *adView;
@property (nonatomic, retain) NSTimer *updateStatusMessageTimer;
@property (nonatomic, retain) UIView *statusTextContainer;
@property (nonatomic, retain) NSDate *lastUpdateCellsDate;
@property (retain) NSTimer *folderUnreadCountTimer;
- (void)updateMetadataForVisibleFeeds;
- (NSArray *)fetchFeeds;
- (NSMutableArray *)buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:(NSMutableArray *)flatOutline;
- (void)createAdView;
- (void)restoreState;
- (NSMutableArray *)readOutlineFromDisk;
- (NSString *)googleIDSavedByState;
- (void)_invalidateDisplayCountsForFoldersAndSyntheticFeeds;
- (void)updateStatusTextContainerFrame;
@end


@implementation NNWMainViewController

@synthesize outlineController = _outlineController, updateTimer = _updateTimer, syntheticFeeds = _syntheticFeeds, flatOutline = _flatOutline, flatOutlineOfVisibleItems = _flatOutlineOfVisibleItems, refreshButton = _refreshButton, feedDownloadsInProgress = _feedDownloadsInProgress, refreshActivityIndicator = _refreshActivityIndicator, refreshActivityIndicatorButton = _refreshActivityIndicatorButton, lastTableViewUpdate = _lastTableViewUpdate, activeView = _activeView, collapsedFolderGoogleIDs = _collapsedFolderGoogleIDs, tableDisplayDirty = _tableDisplayDirty, statusTextLabel = _statusTextLabel, statusToolbarItem = _statusToolbarItem, statusMessages = _statusMessages, googleSyncCallsInProgress = _googleSyncCallsInProgress, locationInOutline = _locationInOutline, newsViewController = _newsViewController, adView = _adView, updateStatusMessageTimer = _updateStatusMessageTimer, statusTextContainer = _statusTextContainer, lastUpdateCellsDate = _lastUpdateCellsDate, folderUnreadCountTimer = _folderUnreadCountTimer;


static NNWMainViewController *gMainViewController = nil;

+ (NNWMainViewController *)sharedViewController {
	return gMainViewController;
	
}


//#pragma mark Init
//
//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
//	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//	if (!self)
//		return nil;
//	return self;
//}
//

#pragma mark Dealloc

- (void)dealloc {
	[_outlineController release];
    [super dealloc];
}


#pragma mark UIViewController

- (void)viewDidLoad {
	gMainViewController = self;
	if (!self.collapsedFolderGoogleIDs)
		self.collapsedFolderGoogleIDs = [[NSUserDefaults standardUserDefaults] objectForKey:NNWCollapsedFolderGoogleIDsKey];
	if (!self.collapsedFolderGoogleIDs)
		self.collapsedFolderGoogleIDs = [NSMutableArray array];
	self.tableView.rowHeight = self.tableView.rowHeight + 8;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.title = @"Feeds";
	self.navigationItem.backBarButtonItem = app_delegate.backArrowButtonItem;
	if (!self.flatOutline) {
		self.flatOutline = [self readOutlineFromDisk];
		self.flatOutlineOfVisibleItems = [self buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:self.flatOutline];		
	}
	[self.navigationController setToolbarHidden:NO animated:NO];
	if (!self.statusMessages)
		self.statusMessages = [NSMutableArray array];
	static BOOL didRegisterForNotifications = NO;
	if (!didRegisterForNotifications) {
		didRegisterForNotifications = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncSessionDidBegin:) name:NNWGoogleSyncSessionDidBeginNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyncSessionDidEnd:) name:NNWGoogleSyncSessionDidEndNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_invalidateDisplayCountsForFoldersAndSyntheticFeeds) name:NNWGoogleSyncSessionDidEndNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDidExpandOrCollapseFolderNotification:) name:NNWUserDidExpandOrCollapseFolderNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTableDisplayDirty) name:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_invalidateDisplayCountsForFoldersAndSyntheticFeeds) name:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickRedisplayVisibleCells) name:NNWUserDidMarkOneOrMoreItemsInFeedAsStarredNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickRedisplayVisibleCells) name:NNWUserDidMarkOneOrMoreItemsInFeedAsUnstarredNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTableDisplayDirty) name:NNWFeedDidUpdateUnreadCountNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickRedisplayVisibleCells) name:NNWFeedDidUpdateMostRecentItemNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsItemsDidChange:) name:NNWFeedHideShowStatusDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_invalidateDisplayCountsForFoldersAndSyntheticFeeds) name:NNWFeedHideShowStatusDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusMessageDidBegin:) name:NNWStatusMessageDidBeginNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusMessageDidEnd:) name:NNWStatusMessageDidEndNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAdTouched:) name:NNWAdTouchedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quickRedisplayVisibleCells) name:NNWFaviconDidDownloadNotification object:nil];
	}
	static BOOL didStartupTasks = NO;
	if (!didStartupTasks) {
		didStartupTasks = YES;
		if (!self.syntheticFeeds)
			self.syntheticFeeds = [NSArray arrayWithObjects:[NNWStarredItemsProxy proxy], [NNWLatestNewsItemsProxy proxy], nil];
		[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		[self performSelector:@selector(_updateTimerDidFire:) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:NO];
		BOOL needsStartupLogin = ![app_delegate hasGoogleUsernameAndPassword];
		if (!needsStartupLogin)
			[self performSelectorOnMainThread:@selector(_startupAfterEnsuringGoogleAccountExists) withObject:nil waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(updateToolbarItems) withObject:nil waitUntilDone:NO];
		if (needsStartupLogin)
			[self performSelectorOnMainThread:@selector(showStartupLogin) withObject:nil waitUntilDone:NO];
		[self restoreState];
	}
	[self updateStatusTextContainerFrame];
}


//- (void)viewDidUnload {
//}


- (void)createAdView {
#if ADS
	NSInteger adViewHeight = [NNWAdView adViewHeight];
	CGRect rTableView = self.tableView.frame;
	CGRect rAdView = CGRectMake(0, 0, rTableView.size.width, adViewHeight);
	self.adView = [NNWAdView adViewWithFrameIfConnected:rAdView];
	self.tableView.tableHeaderView = self.adView;
#endif	
}


- (void)_startupAfterEnsuringGoogleAccountExists {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFeedDownloadingDidEndNotification:) name:BCFeedDownloadsDidEndNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_invalidateDisplayCountsForFoldersAndSyntheticFeeds) name:BCFeedDownloadsDidEndNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFeedDownloadsInProgressNotification:) name:BCFeedDownloadsInProgressNotification object:nil];
	[self performSelectorOnMainThread:@selector(_doDataStartup) withObject:nil waitUntilDone:NO];	
}


- (void)loginSuccess {
	/*Called back from first-run login controller*/
	[self performSelectorOnMainThread:@selector(_startupAfterEnsuringGoogleAccountExists) withObject:nil waitUntilDone:NO];
}


- (void)showStartupLogin {
	NNWLoginViewController *loginViewController = [[[NNWLoginViewController alloc] initWithNibName:@"Login" bundle:nil] autorelease];
	loginViewController.callbackDelegate = self;
	[self.navigationController presentModalViewController:loginViewController animated:YES];	
}


- (void)_deleteOldNewsItemsExceptFor:(NSString *)googleIDSavedByState {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	EXCEPTION_START
		[app_delegate sendStatusMessageDidBegin:@"Cleaning up old items"];
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:RSDataEntityNewsItem inManagedObjectContext:app_delegate.managedObjectContext];
		[fetchRequest setEntity:entity];
		[fetchRequest setIncludesPropertyValues:NO];
		NSDate *cutOffDate = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24)];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(read == YES) AND (starred != YES) AND (datePublished < %@)", cutOffDate];
		if (!RSStringIsEmpty(googleIDSavedByState))
			predicate = [NSPredicate predicateWithFormat:@"(read == YES) AND (starred != YES) AND (googleID != %@) AND (datePublished < %@)", googleIDSavedByState, cutOffDate];
		[fetchRequest setPredicate:predicate];
		NSError *error = nil;
		NSArray *oldNewsItems = [app_delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (!RSIsEmpty(oldNewsItems)) {
			for (NSManagedObject *oneManagedObject in oldNewsItems)
				[app_delegate.managedObjectContext deleteObject:oneManagedObject];			
			[app_delegate saveManagedObjectContext];
		}
		[fetchRequest release];
		/*Also delete all items older than 31 days, since GR has marked them read*/
		NSFetchRequest *fetchMonthOldItems = [[NSFetchRequest alloc] init];
		[fetchMonthOldItems setEntity:entity];
		[fetchMonthOldItems setIncludesPropertyValues:NO];
		cutOffDate = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * 31)];
		[fetchMonthOldItems setPredicate:[NSPredicate predicateWithFormat:@"datePublished < %@", cutOffDate]];
		if (!RSStringIsEmpty(googleIDSavedByState))
			[fetchMonthOldItems setPredicate:[NSPredicate predicateWithFormat:@"(googleID != %@) AND (datePublished < %@)", googleIDSavedByState, cutOffDate]];
		error = nil;
		oldNewsItems = [app_delegate.managedObjectContext executeFetchRequest:fetchMonthOldItems error:&error];
		if (!RSIsEmpty(oldNewsItems)) {
			for (NSManagedObject *oneManagedObject in oldNewsItems)
				[app_delegate.managedObjectContext deleteObject:oneManagedObject];
			[app_delegate saveManagedObjectContext];
		}
		[fetchMonthOldItems release];
		[app_delegate sendStatusMessageDidEnd:@"Cleaning up old items"];
	EXCEPTION_END
	CATCH_EXCEPTION
	[pool drain];
}


- (void)_invalidateDisplayCountsForSyntheticFeeds {
	[self.syntheticFeeds makeObjectsPerformSelector:@selector(invalidateUnreadCount)];
}


- (void)_invalidateDisplayCountsForFolders {
	for (NNWOutlineNode *oneOutlineNode in self.flatOutline) {
		if (!oneOutlineNode.isFolder)
			continue;
		NNWFolderProxy *oneFolderProxy = (NNWFolderProxy *)(oneOutlineNode.nnwProxy);
		[oneFolderProxy invalidateUnreadCount];
	}
}


- (void)_invalidateDisplayCountsForFoldersAndSyntheticFeeds {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(_invalidateDisplayCountsForFoldersAndSyntheticFeeds) withObject:nil waitUntilDone:NO];
		return;
	}
	[self _invalidateDisplayCountsForFolders];
	[self _invalidateDisplayCountsForSyntheticFeeds];
}


static NSString *NNWDateLastOldNewsItemsCleanup = @"dateLastNewsItemsCleanup";

- (void)_doDataStartup {
	NSDate *dateLastCleanup = [[NSUserDefaults standardUserDefaults] objectForKey:NNWDateLastOldNewsItemsCleanup];
	if (!dateLastCleanup)
		dateLastCleanup = [NSDate distantPast];
	NSDate *oneHourAgo = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60)];
	if ([oneHourAgo earlierDate:dateLastCleanup] == dateLastCleanup) {
		[self performSelector:@selector(_deleteOldNewsItemsExceptFor:) onThread:app_delegate.coreDataThread withObject:[self googleIDSavedByState] waitUntilDone:NO];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NNWDateLastOldNewsItemsCleanup];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsItemsDidChange:) name:NNWNewsItemsDidChangeNotification object:nil];
	[self performSelectorOnMainThread:@selector(handleNewsItemsDidChange:) withObject:nil waitUntilDone:NO];
	[NNWSyncActionsController sharedController]; /*starts it up*/
	[app_delegate startRefreshingIfNeeded];
}


- (void)_updateTableView {
	self.lastTableViewUpdate = [NSDate date];
	[self.tableView reloadData];
}


- (void)_updateTimerDidFire:(NSTimer *)timer {
	EXCEPTION_START
		if (self.updateTimer) {
			[self.updateTimer invalidateIfValid];
			self.updateTimer = nil;
		}
		self.lastTableViewUpdate = [NSDate date];
		if (!self.activeView)
			return;
		NNWOutlineController *outlineController = [[NNWOutlineController alloc] init]; /*released on callback*/
		outlineController.delegate = self;
		[outlineController rebuildOutline:[self fetchFeeds]];
	EXCEPTION_END
	CATCH_EXCEPTION
}


- (void)_rescheduleUpdateTimer {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	static BOOL didInitialUpdate = NO;
	if (!self.activeView)
		goto _rescheduleUpdateTimer_exit;		
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


- (void)handleTableDisplayDirty {
	/*Any of various notifications that should trigger a reloadData but not re-building the outline -- such as an unread count change*/
	self.tableDisplayDirty = YES;
	[self performSelectorOnMainThread:@selector(reloadDataInTableViewIfNeeded) withObject:nil waitUntilDone:NO];
}


- (void)setNeedsDisplayForVisibleCells {
	if (!self.lastUpdateCellsDate)
		self.lastUpdateCellsDate = [NSDate distantPast];
	if (!_mainViewScrolling && [self.lastUpdateCellsDate earlierDate:[NSDate dateWithTimeIntervalSinceNow:1.0]] == self.lastUpdateCellsDate) {
		[[self.tableView visibleCells] makeObjectsPerformSelector:@selector(setNeedsDisplay)];
		self.lastUpdateCellsDate = [NSDate date];
	}
	else
		(void)[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(setNeedsDisplayForVisibleCells) userInfo:nil repeats:NO];
}


- (void)quickRedisplayVisibleCells {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(quickRedisplayVisibleCells) withObject:nil waitUntilDone:NO];
		return;
	}
	[self setNeedsDisplayForVisibleCells];
}


- (void)reloadDataInTableViewIfNeeded {
	if (self.tableDisplayDirty && self.activeView) {
		[self setNeedsDisplayForVisibleCells];
		self.tableDisplayDirty = NO;
		[self updateMetadataForVisibleFeeds];
	}
}


- (void)handleNewsItemsDidChange:(NSNotification *)note {
	EXCEPTION_START
		if ([NSThread currentThread] != app_delegate.coreDataThread) {
			[self performSelector:@selector(handleNewsItemsDidChange:) onThread:app_delegate.coreDataThread withObject:note waitUntilDone:NO];
			return;
		}
		if (!self.activeView)
			return;
		[self _rescheduleUpdateTimer];
	EXCEPTION_END
	CATCH_EXCEPTION
}


- (void)outlineDidRebuild:(NNWOutlineController *)outlineController {
	self.flatOutline = outlineController.flattenedOutline;
	[outlineController performSelectorOnMainThread:@selector(autorelease) withObject:nil waitUntilDone:NO];	
	self.flatOutlineOfVisibleItems = [self buildFlatOutlineOfVisibleItemsFromFlatOutlineOfAllItems:self.flatOutline];
	[self _updateTableView];
	[self performSelectorOnMainThread:@selector(updateMetadataForVisibleFeeds) withObject:nil waitUntilDone:NO];	
}


- (void)_invalidateFolderUnreadCountTimer {
	[self.folderUnreadCountTimer invalidateIfValid];
	self.folderUnreadCountTimer = nil;
}


- (void)handleFolderUnreadCountTimerDidFire:(NSTimer *)timer {
	if (_mainViewScrolling || !self.activeView)
		return;
	self.tableDisplayDirty;
	[self _invalidateDisplayCountsForFoldersAndSyntheticFeeds];
}


- (void)startFolderUnreadCountTimer {
	if (self.folderUnreadCountTimer)
		return;
	self.folderUnreadCountTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(handleFolderUnreadCountTimerDidFire:) userInfo:nil repeats:YES];
}


- (void)viewWillAppear:(BOOL)animated {
#if ADS
	static NSInteger counter = 0;
	/*The counter is a hack to not show an ad on first-run right after the initial login screen. Just a first impressions thing.*/
	if (!self.adView && counter > 1)
		[self createAdView];
	counter++;
#endif
	self.locationInOutline = nil;
	self.activeView = YES;
	[app_delegate sendBigUIStartNotification];
    [super viewWillAppear:animated];
	[self reloadDataInTableViewIfNeeded];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWMainViewControllerWillAppearNotification object:self];
}


- (void)viewDidAppear:(BOOL)animated {
	self.newsViewController = nil;
	self.navigationController.toolbarHidden = NO;
	[self _invalidateDisplayCountsForFoldersAndSyntheticFeeds];
	
	[self updateMetadataForVisibleFeeds];
	[super viewDidAppear:animated];
	[self startFolderUnreadCountTimer];
	[app_delegate sendBigUIEndNotification];
	[self updateStatusTextContainerFrame];
}


- (void)viewWillDisappear:(BOOL)animated {
	[self _invalidateFolderUnreadCountTimer];
	self.activeView = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self performSelectorOnMainThread:@selector(updateStatusTextContainerFrame) withObject:nil waitUntilDone:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Actions

- (void)_refreshButtonPressed:(id)sender {
	[[NNWRefreshController sharedController] runRefreshSession];
}


#pragma mark Toolbar

- (void)updateStatusTextContainerFrame {
	self.statusTextContainer.frame = CGRectMake(0, 0, self.view.frame.size.width - 60, 20);
}


- (void)updateToolbarItems {
	NSArray *toolbarItems = nil;
	if (!self.refreshButton)
		self.refreshButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(_refreshButtonPressed:)] autorelease];
	if (!self.refreshActivityIndicator)
		self.refreshActivityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	if (!self.refreshActivityIndicatorButton)
		self.refreshActivityIndicatorButton = [[[UIBarButtonItem alloc] initWithCustomView:self.refreshActivityIndicator] autorelease];
	if (!self.statusTextLabel) {
		self.statusTextLabel = [[[NNWStatusLabel alloc] initWithFrame:CGRectZero] autorelease];
		self.statusTextLabel.frame = CGRectMake(0, -1, self.view.frame.size.width - 60, 20);
		self.statusTextLabel.textColor = [UIColor whiteColor];
		self.statusTextLabel.backgroundColor = [UIColor clearColor];
		self.statusTextLabel.font = [UIFont boldSystemFontOfSize:12];
		self.statusTextLabel.shadowColor = [UIColor darkGrayColor];
		self.statusTextLabel.text = @"";
		self.statusTextLabel.userInteractionEnabled = YES;
		self.statusTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	}
	if (!self.statusTextContainer) {
		self.statusTextContainer = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 60, 20)] autorelease];
		[self.statusTextContainer addSubview:self.statusTextLabel];
		self.statusTextContainer.backgroundColor = [UIColor clearColor];
	}
	if (!self.statusToolbarItem)
		self.statusToolbarItem = [[[UIBarButtonItem alloc] initWithCustomView:self.statusTextContainer] autorelease];
	if (self.googleSyncCallsInProgress || self.feedDownloadsInProgress) {
		[self.refreshActivityIndicator startAnimating];
		toolbarItems = [NSArray arrayWithObjects:self.statusToolbarItem, self.refreshActivityIndicatorButton, nil];		
	}
	else {
		[self.refreshActivityIndicator stopAnimating];
		toolbarItems = [NSArray arrayWithObjects:self.statusToolbarItem, self.refreshButton, nil];		
	}
	[self setToolbarItems:toolbarItems animated:NO];
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
	self.updateStatusMessageTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateStatusMessageTimerDidFire:) userInfo:nil repeats:NO];
}


- (void)updateStatusText {
	if (RSIsEmpty(self.statusMessages)) {
		[self rescheduleUpdateStatusMessage];
//		self.statusTextLabel.text = @"";
	}
	else {
		self.statusTextLabel.text = [self.statusMessages lastObject];
		[self invalidateStatusMessageTimer];
	}
}


#pragma mark Notifications

- (void)handleFeedDownloadingDidEndNotification:(NSNotification *)note {
	self.feedDownloadsInProgress = NO;
	[self _invalidateDisplayCountsForSyntheticFeeds];
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
	self.googleSyncCallsInProgress = YES;
	[self updateToolbarItems];
}


- (void)handleSyncSessionDidEnd:(NSNotification *)note {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(handleSyncSessionDidEnd:) withObject:note waitUntilDone:NO];
		return;
	}
	self.googleSyncCallsInProgress = NO;
	[self _invalidateDisplayCountsForSyntheticFeeds];
	[self updateToolbarItems];
}


- (void)handleAdTouched:(NSNotification *)note {
	if ([note object] != self.adView)
		return;
	NSString *urlString = [[note userInfo] objectForKey:@"urlString"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	NNWWebPageViewController *webPageViewController = [[[NNWWebPageViewController alloc] initWithURLRequest:request] autorelease];
	[webPageViewController loadHTML];
	[[self navigationController] pushViewController:webPageViewController animated:YES];
}


#pragma mark Feed Metadata

- (void)updateMetadataForFeedProxies:(NSArray *)feedProxies {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	EXCEPTION_START
		BOOL dirty = NO;
		for (NNWFeedProxy *oneFeedProxy in feedProxies) {
			if (!oneFeedProxy.unreadCountIsValid) {
				[oneFeedProxy updateUnreadCountOnCoreDataThread];
				dirty = YES;
			}
			if (!oneFeedProxy.isFolder && !oneFeedProxy.mostRecentItemIsValid) {
				[oneFeedProxy updateMostRecentItem];
				dirty = YES;
			}
		}
		if (dirty)
			self.tableDisplayDirty = YES;
	EXCEPTION_END
	CATCH_EXCEPTION
	[pool drain];
}


- (NSArray *)indexPathsForVisibleRows {
	NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];
	if (RSIsEmpty(indexPathsForVisibleRows)) {
		NSMutableArray *indexPathsBasedOnVisibleCells = [NSMutableArray array];
		if (!RSIsEmpty([self.tableView visibleCells])) {
			/*Jiggle it*/
			for (UITableViewCell *oneCell in [self.tableView visibleCells]) {
				NSIndexPath *oneIndex = [self.tableView indexPathForCell:oneCell];
				if (oneIndex)
					[indexPathsBasedOnVisibleCells addObject:oneIndex];
			}
		}
		indexPathsForVisibleRows = [[indexPathsBasedOnVisibleCells copy] autorelease];
	}
	return indexPathsForVisibleRows;
}


- (void)updateMetadataForVisibleFeeds {
	/*Update unread count and most recent item only for visible feeds, and only for those that need it.*/
	if (_mainViewScrolling)
		return;
	NSArray *indexPathsForVisibleRows = [self indexPathsForVisibleRows];
	if (RSIsEmpty(indexPathsForVisibleRows))
		return;
	NSMutableArray *feedProxies = [NSMutableArray array];
	for (NSIndexPath *oneIndexPath in indexPathsForVisibleRows) {
		if (oneIndexPath.section != 1)
			continue;
		NNWProxy *nnwProxy = ((NNWOutlineNode *)[self.flatOutlineOfVisibleItems objectAtIndex:oneIndexPath.row]).nnwProxy;
		if (nnwProxy.isFolder) {
			if (!((NNWFeedProxy *)nnwProxy).unreadCountIsValid)
				[feedProxies addObject:nnwProxy];
			continue;
		}
		if (!((NNWFeedProxy *)nnwProxy).unreadCountIsValid)
			[feedProxies addObject:nnwProxy];
		else if (!((NNWFeedProxy *)nnwProxy).mostRecentItem)
			[feedProxies addObject:nnwProxy];
	}
	/*Synthetic feeds*/
	for (NSIndexPath *oneIndexPath in indexPathsForVisibleRows) {
		if (oneIndexPath.section != 0)
			continue;
		NNWFeedProxy *nnwFeedProxy = [self.syntheticFeeds safeObjectAtIndex:oneIndexPath.row];
		if (!nnwFeedProxy.unreadCountIsValid)
			[feedProxies addObject:nnwFeedProxy];
	}
	if (RSIsEmpty(feedProxies))
		return;
	[self performSelector:@selector(updateMetadataForFeedProxies:) onThread:app_delegate.coreDataThread withObject:feedProxies waitUntilDone:NO];
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


- (void)collapseFolder:(NSString *)folderGoogleID {
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
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:indexPathsOfVisibleChildren withRowAnimation:UITableViewRowAnimationBottom];
	[self.tableView endUpdates];
	[self performSelectorOnMainThread:@selector(updateMetadataForVisibleFeeds) withObject:nil waitUntilDone:NO];
}


- (void)expandFolder:(NSString *)folderGoogleID {
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
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:indexPathsOfVisibleChildren withRowAnimation:UITableViewRowAnimationTop];
	[self.tableView endUpdates];
	[self performSelectorOnMainThread:@selector(updateMetadataForVisibleFeeds) withObject:nil waitUntilDone:NO];
}


- (void)expandOrCollapseFolderWithGoogleID:(NSString *)folderGoogleID {
	if ([self folderWithGoogleIDIsCollapsed:folderGoogleID])
		[self expandFolder:folderGoogleID];
	else
		[self collapseFolder:folderGoogleID];
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
	[self expandOrCollapseFolderWithGoogleID:googleID];
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
	NSInteger ix = [self indexOfProxy:folder];
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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return [self.syntheticFeeds count];
	if (section == 1)
		return [self.flatOutlineOfVisibleItems count];
	if (section == 2)
		return 1;
	return 0;
}


NSString *_NNWMainCellIdentifier = @"MainViewCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
 	NSInteger section = indexPath.section;
	NNWMainTableViewCell *cell = nil;
		cell = (NNWMainTableViewCell *)[tableView dequeueReusableCellWithIdentifier:_NNWMainCellIdentifier];
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
	}
	else if (section == 1) {
		NNWProxy *nnwProxy = ((NNWOutlineNode *)[self.flatOutlineOfVisibleItems objectAtIndex:indexPath.row]).nnwProxy;
		[representedObject safeSetObject:nnwProxy forKey:@"nnwProxy"];
		BOOL isFeed = !nnwProxy.isFolder;
		rowType = isFeed ? NNWFeedItem : NNWFolderItem;
		[representedObject safeSetObject:nnwProxy.title forKey:RSDataTitle];
		if (RSIsEmpty([representedObject objectForKey:RSDataTitle]))
			[representedObject setObject:@"Unknown" forKey:RSDataTitle];
		[cell setMainViewController:self];
		if (!isFeed)
			[cell setCollapsed:[self folderWithGoogleIDIsCollapsed:nnwProxy.googleID]];
	}
	else
		[representedObject setObject:title forKey:RSDataTitle];

	[representedObject setObject:[NSNumber numberWithInteger:rowType] forKey:@"rowType"];
	[cell setRepresentedObject:representedObject];
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		NNWOutlineNode *node = [self.flatOutlineOfVisibleItems safeObjectAtIndex:indexPath.row];
		NSInteger level = 0;
		if (node)
			level = node.level;
		if (level > 3)
			level = 3;
		return level;
	}
	return 0;
}


- (void)handleDidSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController *viewControllerToPush = nil;
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	self.locationInOutline = nil;
	self.newsViewController = nil;
	if (section == 0) {
		viewControllerToPush = [[[NNWNewsViewController alloc] initWithNibName:nil bundle:nil] autorelease];
		((NNWNewsViewController *)viewControllerToPush).nnwProxy = [self.syntheticFeeds objectAtIndex:row];
	}
	else if (section == 1) {
		viewControllerToPush = [[[NNWNewsViewController alloc] initWithNibName:nil bundle:nil] autorelease];
		NNWOutlineNode *outlineNode = [self.flatOutlineOfVisibleItems safeObjectAtIndex:indexPath.row];
		if (!outlineNode)
			return;
		((NNWNewsViewController *)viewControllerToPush).mainViewController = self;
		self.newsViewController = (NNWNewsViewController *)viewControllerToPush;
		self.locationInOutline = pathForOutlineNode(outlineNode, self.flatOutline);
		NNWProxy *nnwProxy = outlineNode.nnwProxy;
		((NNWNewsViewController *)viewControllerToPush).nnwProxy = nnwProxy;
		if (nnwProxy.isFolder)
			((NNWFolderProxy *)nnwProxy).googleIDsOfDescendants = [self googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)nnwProxy];
	}
	else if (section == 2) {
		if (row == 0)
			viewControllerToPush = [NNWShowHideFeedsTableViewController showHideFeedsTableViewController];
	}
	if (viewControllerToPush)
		[self.navigationController pushViewController:viewControllerToPush animated:YES];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self performSelectorOnMainThread:@selector(handleDidSelectRowAtIndexPath:) withObject:indexPath waitUntilDone:NO];
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
     return NO;
}


#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	_mainViewScrolling = YES;
	[app_delegate sendBigUIStartNotification];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	_mainViewScrolling = YES;
	if (!decelerate) {
		_mainViewScrolling = NO;
		[app_delegate sendBigUIEndNotification];
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	_mainViewScrolling = NO;
	[self updateMetadataForVisibleFeeds];
	[app_delegate sendBigUIEndNotification];
}


#pragma mark Fetching Feeds

- (NSArray *)fetchFeeds {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:RSDataEntityNewsItem inManagedObjectContext:app_delegate.managedObjectContext]];
	static NSArray *propertiesToFetch = nil;
	if (!propertiesToFetch)
		propertiesToFetch = [[NSArray alloc] initWithObjects:RSDataGoogleFeedID, nil];
	[request setPropertiesToFetch:propertiesToFetch];
	[request setResultType:NSDictionaryResultType];
	static BOOL firstLoad = YES;
	if (firstLoad) {
		firstLoad = NO;
		[request setPredicate:[NSPredicate predicateWithFormat:@"read != YES"]];
	}
	else
		[request setPredicate:[NSPredicate predicateWithFormat:@"(read != YES) OR (datePublished > %@)", [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24)]]];
	[request setReturnsDistinctResults:YES];
	NSError *error = nil;
	NSArray *result = [app_delegate.managedObjectContext executeFetchRequest:request error:&error];
	NSArray *googleFeedIDs = [result valueForKeyPath:RSDataGoogleFeedID];
	return googleFeedIDs;
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
	[(NNWFeedProxy *)nnwProxy performSelector:@selector(updateUnreadCountOnCoreDataThread) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:YES];
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


- (NNWNewsItemProxy *)findNextUnreadItemAndSetupState {
	/*Called once at the end of a news items list, and we have to find the next feed/folder with an unread item. This method returns that item -- but it also updates app state: sets the list for the news view controller and makes it run a fetch, the gets the first unread item after doing the fetch and returns it.*/
	NNWOutlineNode *newOutlineNode = [self nextOutlineNodeWithUnreadItemsAfterCurrentLocation];
	if (!newOutlineNode)
		return nil;
	/*TODO: refactor. Same code appears in didSelect...*/
	self.locationInOutline = pathForOutlineNode(newOutlineNode, self.flatOutline);
	NNWProxy *nnwProxy = newOutlineNode.nnwProxy;
	if (nnwProxy.isFolder)
		((NNWFolderProxy *)nnwProxy).googleIDsOfDescendants = [self googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)nnwProxy];
	self.newsViewController.mainViewController = self;
	self.newsViewController.nnwProxy = nnwProxy;
	self.newsViewController.title = nnwProxy.title;
	[self.newsViewController fetchNewsItemsInBackgroundAndWait];
	return self.newsViewController.firstUnreadItem;	
}



#pragma mark State

static NSString *NNWStateKey = @"savedState";
static NSString *NNWMainViewControllerName = @"feeds";
NSString *NNWViewControllerNameKey = @"name";
NSString *NNWDataNameKey = @"dataName";
NSString *NNWStateViewControllerTitleKey = @"title";

- (NSDictionary *)stateDictionary {
	return [NSDictionary dictionaryWithObject:NNWMainViewControllerName forKey:NNWViewControllerNameKey];
}


static NSString *NNWOutlineFileName = @"flatoutline.archive";

- (void)saveOutlineToDisk {
	if (!RSIsEmpty(self.flatOutline))
		[NSKeyedArchiver archiveRootObject:self.flatOutline toFile:RSDocumentsFilePath(NNWOutlineFileName)];
}


- (NSMutableArray *)readOutlineFromDisk {
	NSArray *flatOutline = [NSKeyedUnarchiver unarchiveObjectWithFile:RSDocumentsFilePath(NNWOutlineFileName)];
	return [[flatOutline mutableCopy] autorelease];
}


- (void)saveState {
	NSMutableArray *stateArray = [NSMutableArray array];
	for (UIViewController *oneController in self.navigationController.viewControllers) {
		if ([oneController respondsToSelector:@selector(stateDictionary)])
			[stateArray safeAddObject:[oneController stateDictionary]];		
	}
	[[NSUserDefaults standardUserDefaults] setObject:stateArray forKey:NNWStateKey];
}


- (NSString *)googleIDSavedByState {
	NSArray *stateArray = [[NSUserDefaults standardUserDefaults] objectForKey:NNWStateKey];
	NSDictionary *newsItemDict = [stateArray safeObjectAtIndex:2];
	if (RSIsEmpty(newsItemDict))
		return nil;
	return [newsItemDict objectForKey:NNWDataNameKey];
}


- (void)restoreState {
	NSArray *stateArray = [[NSUserDefaults standardUserDefaults] objectForKey:NNWStateKey];
	if (RSIsEmpty(stateArray) || [stateArray count] == 1) /*first object in array is always this view controller*/
		return;
	NNWNewsViewController *newsViewController = [NNWNewsViewController viewControllerWithState:[stateArray objectAtIndex:1]];
	if (!newsViewController)
		return;
	newsViewController.mainViewController = self;
	NSDictionary *detailDict = [stateArray safeObjectAtIndex:2];
	NSString *stateRestoringNewsItemGoogleID = nil;
	if (detailDict)
		stateRestoringNewsItemGoogleID = [detailDict objectForKey:NNWDataNameKey];
	NNWNewsItemProxy *stateRestoringNewsItemProxy = nil;
	if (stateRestoringNewsItemGoogleID) {
		stateRestoringNewsItemProxy = [[[NNWNewsItemProxy alloc] initWithGoogleID:stateRestoringNewsItemGoogleID] autorelease];
		[stateRestoringNewsItemProxy inflateIfNeeded];
		newsViewController.stateRestoredNewsItemProxy = stateRestoringNewsItemProxy;
	}
	[self.navigationController pushViewController:newsViewController animated:NO];
	newsViewController.view;
	if (RSIsEmpty(detailDict))
		return;
	if (RSStringIsEmpty(stateRestoringNewsItemGoogleID))
		return;
	/*Need to run fetch on newsViewController to pick up news item proxy, so that up/down arrows etc. work properly.*/
	[newsViewController fetchNewsItems];//InBackgroundAndWait];
	NNWDetailViewController *detailViewController = [[[NNWDetailViewController alloc] initWithNewsItemProxy:stateRestoringNewsItemProxy] autorelease];
	if (!detailViewController)
		return;
	detailViewController.newsViewController = newsViewController;
	[detailViewController loadHTML];		
	[self.navigationController pushViewController:detailViewController animated:NO];
	NSDictionary *webPageDict = [stateArray safeObjectAtIndex:3];
	if (RSIsEmpty(webPageDict))
		return;
	NNWWebPageViewController *webPageViewController = [NNWWebPageViewController viewControllerWithState:webPageDict];
	[webPageViewController loadHTML];
	[self.navigationController pushViewController:webPageViewController animated:NO];
}


#pragma mark Defaults Prompt

- (void)defaultFeedsPromptDidEnd:(NNWAddDefaultsViewController *)viewController {
	[viewController performSelector:@selector(autorelease) withObject:viewController afterDelay:5.0]; /*because of weird downloading crashes sometimes*/
	[[NNWRefreshController sharedController] runRefreshSession];
}


static BOOL didRunDefaultsPrompt = NO;

- (void)runDefaultsAfterBriefDelay {
	if (self.navigationController.modalViewController) {
		[self performSelector:@selector(runDefaultsAfterBriefDelay) withObject:nil afterDelay:0.1];
		return;
	}
	NNWAddDefaultsViewController *viewController = [[NNWAddDefaultsViewController alloc] initWithCallbackDelegate:self];
	[self.navigationController presentModalViewController:viewController animated:YES];	
}


- (void)runDefaultsPrompt {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(runDefaultsPrompt) withObject:nil waitUntilDone:NO];
		return;
	}
	if (didRunDefaultsPrompt)
		return;
	didRunDefaultsPrompt = YES;
	[self runDefaultsAfterBriefDelay];
}


#pragma mark Instapaper

- (void)sendToInstapaperDidComplete:(NNWSendToInstapaper *)instapaperController {
	[instapaperController performSelector:@selector(release) withObject:nil afterDelay:3.0];	
}

@end

