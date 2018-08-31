//
//  NNWAppDelegate.m
//  nnwipad
//
//  Created by Brent Simmons on 2/3/10.
//  Copyright NewsGator Technologies, Inc. 2010. All rights reserved.
//

#import "NNWAppDelegate.h"
#import "NNWAddDefaultsViewController.h"
#import "NNWArticleViewController.h"
#import "NNWCurrentNewsItemsController.h"
#import "NNWDataController.h"
#import "NNWDatabaseController.h"
#import "RSDetailViewController.h"
#import "NNWFavicon.h"
#import "NNWFeedProxy.h"
#import "NNWFolderProxy.h"
#import "NNWLockedReadDatabase.h"
#import "NNWLoginViewController.h"
#import "NNWMainViewController.h"
#import "NNWNewsListTableController.h"
#import "NNWRefreshController.h"
#import "NNWSyncActionsController.h"
#import "NNWURLProtocol.h"
#import "NNWWebPageViewController.h"
#import "SFHFKeychainUtils.h"
#import "NNWThumbnailCacheController.h"
#import "NGModalViewPresenter.h"
#import "RSOperationController.h"


NSString *NNWStatusMessageKey = @"statusMessage";
NSString *NNWStatusMessageDidBeginNotification = @"NNWStatusMessageDidBeginNotification";
NSString *NNWStatusMessageDidEndNotification = @"NNWStatusMessageDidEndNotification";
NSString *NNWGoogleUsernameKey = @"grusername";
NSString *NNWGooglePasswordKey = @"grpassword";
NSString *NNWGoogleServiceName = @"GoogleReader";
NSString *NNWSubscriptionsDidUpdateNotification = @"NNWSubscriptionsDidUpdateNotification";
NSString *NNWNewsItemsDidSaveNotification = @"NNWNewsItemsDidSaveNotification";
NSString *NNWNewsItemsKey = @"newsItems";
NSString *NNWWebPageDidAppearNotification = @"NNWWebPageDidAppearNotification";
NSString *NNWArticleDidAppearNotification = @"NNWArticleDidAppearNotification";
NSString *NNWRightPaneViewTypeKey = @"rightPaneViewType";
NSString *NNWWillAnimateRotationToInterfaceOrientation = @"NNWWillAnimateRotationToInterfaceOrientation";
NSString *NNWDidAnimateRotationToInterfaceOrientation = @"NNWDidAnimateRotationToInterfaceOrientation";
NSString *NNWTitleDidChangeNotification = @"NNWTitleDidChangeNotification";

/*State*/

NSString *NNWStateLeftPaneViewControllerKey = @"state-leftPaneViewController";
NSString *NNWStateRightPaneViewControllerKey = @"state-rightPaneViewController";
NSString *NNWStateFeedsLocationInOutlineKey = @"state-locationInOutline";
NSString *NNWStateArticleIDKey = @"state-articleID";
NSString *NNWStateWebPageURLKey = @"state-webpageURL";
NSString *NNWStateNewsKey = @"state-newsProxyID";
NSString *NNWStateNewsProxyIsFolderKey = @"state-newsProxyIsFolder";

NSString *NNWAppDidTerminateCleanlyKey = @"didTerminateCleanly";

NSString *NNWPopoverWillDisplayNotification = @"NNWPopoverWillDisplayNotification";
NSString *NNWPopoverControllerKey = @"popoverController"; /*in userInfo for notification*/


@interface NNWAppDelegate ()
@property (nonatomic, retain, readonly) UIViewController *topLevelViewController;
@property (nonatomic, assign, readwrite) NNWRightPaneViewType rightPaneViewType;
@property (nonatomic, assign, readwrite) BOOL firstRun;
@property (nonatomic, retain) NSString *titleForPopoverButtonItem;

- (void)_startCoreDataThread;
- (BOOL)hasGoogleUsernameAndPassword;
- (void)restoreState;
@end


@implementation NNWAppDelegate

@synthesize window, splitViewController, masterViewController, detailViewController;
@synthesize coreDataThread = _coreDataThread;
@synthesize userAgent;
@synthesize newsListViewController;
@synthesize articleViewController;
@synthesize interfaceOrientation;
@synthesize currentNewsItemsController;
@synthesize currentLeftPaneViewController;
@synthesize rightPaneViewType;
@synthesize firstRun;
@synthesize didRestoreWebpageState;
@synthesize popoverButtonItem;
@synthesize titleForPopoverButtonItem;

- (id)init {
	self = [super init];
	if (!self)
		return nil;
	[NNWDatabaseController sharedController]; // Needs to init before anything else
	return self;
}


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.firstRun = ![[NSUserDefaults standardUserDefaults] boolForKey:@"firstRunHappened"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstRunHappened"];
	
	[self.detailViewController registerContentViewControllerClass:NSClassFromString(@"NNWStartupViewController")];
	[self.detailViewController registerContentViewControllerClass:NSClassFromString(@"NNWArticleViewController")];
	[self.detailViewController registerContentViewControllerClass:NSClassFromString(@"NNWWebPageViewController")];
	
    [NNWThumbnailCacheController sharedController];
	[NNWDatabaseController sharedController];
	[NNWLockedReadDatabase sharedController]; /*creates database if needed*/
	[NNWURLProtocol startup];
	currentNewsItemsController = [[NNWCurrentNewsItemsController alloc] init];

	self.userAgent = [NSString stringWithFormat:@"%@/%@ (iPad; %@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey], [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey], @"http://newsgator.com/", nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleViewDidAppear:) name:NNWArticleDidAppearNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webpageViewDidAppear:) name:NNWWebPageDidAppearNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTitleDidChange:) name:NNWTitleDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePopoverButtonItemDidAppear:) name:RSSplitViewPopoverButtonItemDidAppearNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePopoverButtonItemDidDisappear:) name:RSSplitViewPopoverButtonItemDidDisappearNotification object:nil];

	[self addObserver:self forKeyPath:@"currentLeftPaneViewController" options:NSKeyValueObservingOptionInitial context:nil];

	self.currentLeftPaneViewController = self.masterViewController;
	self.newsListViewController = [[[NNWNewsListTableController alloc] init] autorelease];
	self.articleViewController = [[[NNWArticleViewController alloc] init] autorelease];
	
	[self _startCoreDataThread];

    // Add the split view controller's view to the window and display.
    [window addSubview:splitViewController.view];
    [window makeKeyAndVisible];

	BOOL needsStartupLogin = ![self hasGoogleUsernameAndPassword];
	if (needsStartupLogin)
		[self performSelectorOnMainThread:@selector(showStartupLogin) withObject:nil waitUntilDone:NO];
	else
		[self performSelectorOnMainThread:@selector(_startupAfterEnsuringGoogleAccountExists) withObject:nil waitUntilDone:NO];
	
	[self restoreState]; // Sets up default state if no state to restore

	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NNWAppDidTerminateCleanlyKey]; /*Set to yes on clean quit*/
	[[NSUserDefaults standardUserDefaults] synchronize];
	
    return YES;
}


- (void)saveState {
	[self.masterViewController saveState];
	NNWLeftPaneViewType viewType = NNWLeftPaneViewFeeds;
	if ([currentLeftPaneViewController isKindOfClass:[NNWNewsListTableController class]])
		viewType = NNWLeftPaneViewNews;
	[[NSUserDefaults standardUserDefaults] setInteger:viewType forKey:NNWStateLeftPaneViewControllerKey];
	NNWRightPaneViewType rightViewType = NNWRightPaneViewNone;
	[[NSUserDefaults standardUserDefaults] setInteger:rightViewType forKey:NNWStateRightPaneViewControllerKey];
	/*Above pref may get overwritten by contentViewController*/
	UIViewController *contentViewController = self.detailViewController.contentViewController;
	if ([contentViewController respondsToSelector:@selector(saveState)])
		[contentViewController performSelector:@selector(saveState)];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	application.applicationIconBadgeNumber = 0;
	_stopped = YES; /*Saves Managed Object Context in thread*/
	[[NNWMainViewController sharedViewController] saveOutlineToDisk];
	[NNWFavicon saveFaviconMap];
	[self saveState];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NNWAppDidTerminateCleanlyKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	[[RSOperationController sharedController] setSuspended:YES];
	application.applicationIconBadgeNumber = 0;
	[[NNWMainViewController sharedViewController] saveOutlineToDisk];
	[NNWFavicon saveFaviconMap];
	[self saveState];
	[[NSUserDefaults standardUserDefaults] synchronize];	
	[self saveManagedObjectContext];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[RSOperationController sharedController] setSuspended:NO];
}


- (UIViewController *)currentRightPaneViewController {
	UIViewController *vc = self.detailViewController.contentViewController;
	if (vc == nil)
		return self.detailViewController;
	return vc;
}


#pragma mark -
#pragma mark State Restoring

- (void)restoreState {
	@try {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:NNWAppDidTerminateCleanlyKey])
			[self.masterViewController restoreState];
	}
	@catch (id obj) {
		NSLog(@"app delegate restore state error: %@", obj);
	}
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [splitViewController release];
    [window release];
	[popoverButtonItem release];
    [super dealloc];
}


#pragma mark Status Message

- (void)sendStatusMessageDidBegin:(NSString *)message {
	if (_stopped)
		return;
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(sendStatusMessageDidBegin:) withObject:message waitUntilDone:NO];
		return;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWStatusMessageDidBeginNotification object:nil userInfo:[NSDictionary dictionaryWithObject:message forKey:NNWStatusMessageKey]];
}


- (void)sendStatusMessageDidEnd:(NSString *)message {
	if (_stopped)
		return;
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(sendStatusMessageDidEnd:) withObject:message waitUntilDone:NO];
		return;
	}
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:NNWStatusMessageDidEndNotification object:nil userInfo:[NSDictionary dictionaryWithObject:message forKey:NNWStatusMessageKey]] waitUntilDone:NO];
}


#pragma mark Login

- (UIViewController *)topLevelViewController {
#if RS_IPAD
	return self.splitViewController;
#else
	return self.navigationController;
#endif
}


- (void)showStartupLogin {
	NNWLoginViewController *loginViewController = [[[NNWLoginViewController alloc] initWithNibName:@"Login" bundle:nil] autorelease];
	loginViewController.callbackDelegate = self;
	
	_modalViewPresenter = [[[NGModalViewPresenter alloc]initWithViewController:loginViewController] retain];
	_modalViewPresenter.delegate = self;
	[_modalViewPresenter presentModalView];
}

-(void)modalViewDidDismiss:(UIViewController*)viewController
{
	[_modalViewPresenter release];
	_modalViewPresenter = nil;
}

- (void)loginSuccess {
	/* Called from NNWLoginViewController */
	[self performSelectorOnMainThread:@selector(_startupAfterEnsuringGoogleAccountExists) withObject:nil waitUntilDone:NO];
}


#pragma mark Modal View Controllers

- (void)dismissModalViewController {
	if(_modalViewPresenter)
		[_modalViewPresenter dismissModalView];
	else
		[self.topLevelViewController dismissModalViewControllerAnimated:YES];
}


- (void)runModalViewControllerAsFormSheet:(UIViewController *)modalViewController {
#if RS_IPAD
	modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	modalViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.topLevelViewController presentModalViewController:modalViewController animated:YES];
#endif
}


- (void)runStandardModalViewController:(UIViewController *)modalViewController {
#if RS_IPAD
	[self runModalViewControllerAsFormSheet:modalViewController];
#else
	[self topLevelViewController presentModalViewController:viewController animated:YES];
#endif
}


#pragma mark Layout

//- (NSInteger)windowHeight {
//	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
//		return kNNWWindowHeightPortrait;
//	return kNNWWindowHeightLandscape;	
//}


//- (NSInteger)rightPaneWidth {
//	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
//		return kNNWRightPaneWidthPortrait;
//	return kNNWRightPaneWidthLandscape;
//}


//- (NSInteger)detailViewHeight {
//	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
//		return kNNWDetailHeightPortrait;
//	return kNNWDetailHeightLandscape;	
//}


- (BOOL)interfaceOrientationIsLandscape {
	return UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}


#pragma mark Defaults Prompt

- (void)defaultFeedsPromptDidEnd:(NNWAddDefaultsViewController *)viewController {
	[viewController performSelector:@selector(autorelease) withObject:viewController afterDelay:5.0]; /*because of weird downloading crashes sometimes*/
	[[NNWRefreshController sharedController] runRefreshSession];
	[self dismissModalViewController];
}


- (void)runDefaultsAfterBriefDelay {
	if (self.topLevelViewController.modalViewController) {
		[self performSelector:@selector(runDefaultsAfterBriefDelay) withObject:nil afterDelay:0.1];
		return;
	}
	NNWAddDefaultsViewController *viewController = [[NNWAddDefaultsViewController alloc] initWithCallbackDelegate:self];
	[self runStandardModalViewController:viewController];
}


- (void)runDefaultsPrompt {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(runDefaultsPrompt) withObject:nil waitUntilDone:NO];
		return;
	}
	static BOOL didRunDefaultsPrompt = NO;
	if (didRunDefaultsPrompt)
		return;
	didRunDefaultsPrompt = YES;
	[self runDefaultsAfterBriefDelay];
}


#pragma mark Refreshing

- (void)startRefreshing {
	[[NNWRefreshController sharedController] runRefreshSession];
}


- (void)startRefreshingIfNeeded {
	NSDate *lastRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:NNWLastRefreshDateKey];
	if (!lastRefreshDate)
		lastRefreshDate = [NSDate distantPast];
	NSDate *dateFiveMinutesAgo = [NSDate dateWithTimeIntervalSinceNow:-(5 * 60)];
	if ([dateFiveMinutesAgo earlierDate:lastRefreshDate] == lastRefreshDate)
		[self startRefreshing];
}


#pragma mark Data

- (void)_doDataStartup {
	[NNWSyncActionsController sharedController]; /*starts it up*/
	[self startRefreshingIfNeeded];
}


- (void)_startupAfterEnsuringGoogleAccountExists {
	[self performSelectorOnMainThread:@selector(_doDataStartup) withObject:nil waitUntilDone:NO];	
}


#pragma mark -
#pragma mark Notifications

- (void)articleViewDidAppear:(NSNotification *)note {
	self.rightPaneViewType = NNWRightPaneViewArticle;
}


- (void)webpageViewDidAppear:(NSNotification *)note {
	self.rightPaneViewType = NNWRightPaneViewWebPage;
}


- (void)updatePopoverButtonWithTitle:(NSString *)aTitle {
	if (aTitle == nil)
		aTitle = @"";
	static const NSUInteger maximumNumberOfTitleCharacters = 16;
	if ([aTitle length] > maximumNumberOfTitleCharacters) {
		aTitle = [aTitle substringToIndex:maximumNumberOfTitleCharacters - 1];
		aTitle = [NSString stringWithFormat:@"%@…", aTitle];
	}
	self.popoverButtonItem.title = aTitle;
}


- (void)handleTitleDidChange:(NSNotification *)note {
	NSString *updatedTitle = [[note userInfo] objectForKey:@"title"];
	id obj = [note object];
	if (obj == self.currentLeftPaneViewController)
		[self updatePopoverButtonWithTitle:updatedTitle];
}


- (void)syncPopoverButtonTitleAndCurrentLeftPaneViewController {
	[self updatePopoverButtonWithTitle:self.currentLeftPaneViewController.title];
}


- (void)handlePopoverButtonItemDidAppear:(NSNotification *)note {
	self.popoverButtonItem = [[note userInfo] objectForKey:@"popoverButtonItem"];
	[self syncPopoverButtonTitleAndCurrentLeftPaneViewController];
}


- (void)handlePopoverButtonItemDidDisappear:(NSNotification *)note {
	self.popoverButtonItem = nil;
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"currentLeftPaneViewController"])
		[self syncPopoverButtonTitleAndCurrentLeftPaneViewController];
}


#pragma mark -
#pragma mark Saving

- (IBAction)saveAction:(id)sender {
	[self saveManagedObjectContext];
}


- (void)exitNowBecauseOfCoreDataError:(NSError *)error {
	NSLog(@"Unresolved Core Data error %@, %@", error, [error userInfo]);
	exit(-1);
}


- (void)saveManagedObjectContext:(NSManagedObjectContext *)moc {
	NSError *error = nil;
	if ([moc hasChanges] && ![moc save:&error])
		[self performSelectorOnMainThread:@selector(exitNowBecauseOfCoreDataError:) withObject:error waitUntilDone:NO];	
}


- (void)saveManagedObjectContext {
	if ([NSThread currentThread] != self.coreDataThread) {
		[self performSelector:@selector(saveManagedObjectContext) onThread:self.coreDataThread withObject:nil waitUntilDone:YES];
		return;
	}
//	[self sendBigUIStartNotification];
	NSError *error = nil;
	if ([managedObjectContext hasChanges] && ![[self managedObjectContext] save:&error])
		[self performSelectorOnMainThread:@selector(exitNowBecauseOfCoreDataError:) withObject:error waitUntilDone:NO];
//	[self sendBigUIEndNotification];
}


#pragma mark -
#pragma mark Core Data stack

- (void)_startCoreDataThread {
	[NSThread detachNewThreadSelector:@selector(_runCoreDataThread) toTarget:self withObject:nil];
}


- (void)_runCoreDataThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.coreDataThread = [NSThread currentThread];
	[self.coreDataThread setName:@"Core Data Thread - nnw"];
	
	NSArray *allFeeds = [[NNWDataController sharedController] fetchAllObjectsForEntityName:@"Feed" moc:self.managedObjectContext];
	[NNWFeedProxy createProxiesForFeeds:allFeeds];
	
	if (!_stopped) {
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!_stopped);
    }
	[self saveManagedObjectContext];
	[pool drain];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	exit(-1);
}


- (NSManagedObjectContext *) managedObjectContext {
	if ([NSThread currentThread] != self.coreDataThread) {
		NSLog(@"managedObjectContext referenced not on main thread!");
		return nil;		
	}
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
	[managedObjectContext setUndoManager:nil];
    return managedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


- (NSString *)applicationDocumentsDirectory {	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	@synchronized(self) {
		if (persistentStoreCoordinator != nil) {
			return persistentStoreCoordinator;
		}
		
		NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"nnw.coredata"]];
		
		/* http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/CoreData/Articles/cdPersistentStores.html*/
		
		NSMutableDictionary *pragmaOptions = [NSMutableDictionary dictionary];
		[pragmaOptions setObject:@"OFF" forKey:@"synchronous"];
		[pragmaOptions setObject:@"0" forKey:@"fullfsync"];
		NSDictionary *storeOptions = [NSDictionary dictionaryWithObject:pragmaOptions forKey:NSSQLitePragmasOption];
		
		NSError *error = nil;
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
		if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:storeOptions error:&error]) {
			// Handle error
			NSLog(@"persistentStoreCoordinator setup error");
		}		
	}
	return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Credentials

- (NSString *)googleUsername {
	return [[NSUserDefaults standardUserDefaults] stringForKey:NNWGoogleUsernameKey];
}


- (NSString *)passwordWithUsername:(NSString *)username {
	NSError *error = nil;
	return [SFHFKeychainUtils getPasswordForUsername:username andServiceName:NNWGoogleServiceName error:&error];
}


- (NSDictionary *)googleUsernameAndPasswordDictionary {
	NSString *username = [self googleUsername];
	if (RSStringIsEmpty(username))
		return nil;
	NSString *password = [self passwordWithUsername:username];
	NSMutableDictionary *credentials = [NSMutableDictionary dictionaryWithCapacity:2];
	[credentials setObject:username forKey:NNWGoogleUsernameKey];
	[credentials safeSetObject:password forKey:NNWGooglePasswordKey];
	return credentials;
}


- (BOOL)hasGoogleUsernameAndPassword {
	NSDictionary *credentials = [self googleUsernameAndPasswordDictionary];
	if (RSIsEmpty(credentials))
		return NO;
	return !RSStringIsEmpty([credentials objectForKey:NNWGooglePasswordKey]);
}


#pragma mark Alerts

- (void)showAlertWithDictionary:(NSDictionary *)errorDict {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(showAlertWithDictionary:) withObject:errorDict waitUntilDone:NO];
		return;
	}
	UIAlertView *alertView = [[[UIAlertView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
	alertView.title = [errorDict objectForKey:@"title"];
	NSString *baseMessage = [errorDict objectForKey:@"baseMessage"];
	NSError *error = [errorDict objectForKey:@"error"];
	NSString *errorDescription = [error localizedDescription];
	if (RSStringIsEmpty(errorDescription))
		errorDescription = [error localizedFailureReason];
	if (RSStringIsEmpty(errorDescription))
		errorDescription = @"which is, unfortunately, unknown";
	alertView.message = [NSString stringWithFormat:baseMessage, errorDescription];
	alertView.delegate = [errorDict objectForKey:@"delegate"];
	[alertView addButtonWithTitle:@"OK"];
	[alertView show];	
}


- (void)showAlertWithError:(NSError *)error {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
	[alert show];
	[alert release];	
}


- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	UIAlertView *alertView = [[[UIAlertView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
	alertView.title = title;
	alertView.message = message;
	[alertView addButtonWithTitle:@"OK"];
	[alertView show];
}


#pragma mark Fetching

- (NSArray *)googleIDsForNNWProxy:(NNWProxy *)nnwProxy {
	if ([nnwProxy isFolder])
		return [NSArray arrayWithArray:((NNWFolderProxy *)nnwProxy).googleIDsOfDescendants];
	if ([nnwProxy isKindOfClass:[NNWFeedProxy class]])
		return [NSArray arrayWithObject:nnwProxy.googleID];
	return nil;
}


- (void)fetchNewsItemsForNNWProxy:(NNWProxy *)nnwProxy {
	if ([nnwProxy isKindOfClass:[NNWLatestNewsItemsProxy class]])
		[self.currentNewsItemsController fetchLatestNewsItems];
	else if ([nnwProxy isKindOfClass:[NNWStarredItemsProxy class]])
		[self.currentNewsItemsController fetchStarredNewsItems];
	else
		[self.currentNewsItemsController fetchNewsItemsForSourceIDs:[self googleIDsForNNWProxy:nnwProxy]];	
}


#pragma mark URLs

- (BOOL)_urlStringIsProbablyMP4:(NSString *)urlString {
	return [urlString hasSuffix:@".mp4"] || [urlString hasSuffix:@".mov"];
}


- (BOOL)shouldOpenURLInMoviePlayer:(NSURL *)url {
	NSString *urlScheme = [[url scheme] lowercaseString];
	if (![urlScheme isEqualToString:@"http"] && ![urlScheme isEqualToString:@"https"])
		return NO;
	NSString *urlString = [url absoluteString];
	if ([self _urlStringIsProbablyMP4:urlString])
		return YES;
	/*Deal with ?foo=bar as suffix*/
	if ([urlString rangeOfString:@"?" options:0].location == NSNotFound)
		return NO;
	NSArray *stringComponents = [urlString componentsSeparatedByString:@"?"];
	for (NSString *oneString in stringComponents) {
		if ([self _urlStringIsProbablyMP4:oneString])
			return YES;		
	}
	return NO;
}


- (BOOL)shouldNavigateToURL:(NSURL *)url {
	
	/*Code courtesy Craig Hockenberry, via email. 10 Aug 2008*/	
	NSString *urlScheme = [[url scheme] lowercaseString];
	
	if ([[url absoluteString] caseInsensitiveContains:@"file:"] && [[url absoluteString] hasSuffix:@"/about-voices.html"])
		return YES;
	/*URL schemes such as tel:, sms:, or even twitterrific: should go in their own apps*/
	if (![urlScheme isEqualToString:@"http"] && ![urlScheme isEqualToString:@"https"] && ![urlScheme isEqualToString:@"ftp"] && ![urlScheme isEqualToString:@"javascript"] && ![urlScheme isEqualToString:@"about"] && ![urlScheme isEqualToString:@"data"])
		return NO;
	
	/*Some http: URL schemes are handled by apps, too*/
	if ([urlScheme isEqualToString:@"http"]) {
		NSString *urlHost = [[url host] lowercaseString];
		if ([urlHost isEqualToString:@"phobos.apple.com"] || [urlHost isEqualToString:@"maps.google.com"])
			return NO;
		if ([urlHost isEqualToString:@"youtube.com"] || [urlHost isEqualToString:@"www.youtube.com"]) {
			if ([[url path] hasPrefix:@"/v/"] || [[url path] isEqualToString:@"/watch"])
				return NO;
		}
	}	
	return YES;
}


@end


@implementation NNWNavigationBar
- (void)drawRect:(CGRect)rect {
	if ([self rs_inPopover])
		[super drawRect:rect];
	else {
		self.barStyle = UIBarStyleBlack;
		UIImage *image = [UIImage imageNamed: @"Toolbar.png"];
		[image drawInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
	}
}
@end

static BOOL rs_inDetailView(UIView *view) {
	/*Total hack*/
	UIView *nomad = view;
	while (nomad != nil) {
		NSString *className = NSStringFromClass([nomad class]);
		if ([className caseInsensitiveContains:@"detail"])
			return YES;
		nomad = nomad.superview;
	}
	return NO;	
}


@implementation UIToolbar (NNW)

- (void)drawRect:(CGRect)rect {
	if ([self rs_inPopover]) {
		[super drawRect:rect];
		return;
	}
	if (rs_inDetailView(self)) {
		self.barStyle = UIBarStyleBlack;
		UIImage *image = [UIImage imageNamed:@"Toolbar.png"];
		[image drawInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];		
	}
	else { // Feeds toolbar
		self.barStyle = UIBarStyleBlack;
		UIImage *image = [UIImage imageNamed:@"FeedsToolbar.png"];
		[image drawInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
	}
}
@end


@implementation NNWNavigationController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end
