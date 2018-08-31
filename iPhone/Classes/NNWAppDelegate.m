//
//  nnwiphoneAppDelegate.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright NewsGator Technologies, Inc. 2009. All rights reserved.
//

#import "NNWAppDelegate.h"
#import "BCDownloadManager.h"
#import "BCFeedbackHUDViewController.h"
#import "NNWDataController.h"
#import "NNWFavicon.h"
#import "NNWFeed.h"
#import "NNWGoogleAPI.h"
#import "NNWGoogleLoginController.h"
#import "NNWHTTPResponse.h"
#import "NNWMainViewController.h"
#import "NNWRefreshController.h"
#import "NNWRefreshController.h"
#import "NNWURLProtocol.h"
#import "SFHFKeychainUtils.h"


NSString *NNWGoogleUsernameKey = @"grusername";
NSString *NNWGooglePasswordKey = @"grpassword";
NSString *NNWStatusMessageKey = @"statusMessage";
NSString *NNWStatusMessageDidBeginNotification = @"NNWStatusMessageDidBeginNotification";
NSString *NNWStatusMessageDidEndNotification = @"NNWStatusMessageDidEndNotification";
NSString *NNWSortNewsItemsAscendingKey = @"sortNewsItemsAscending";

@interface NNWAppDelegate ()
@property (nonatomic, retain, readwrite) NSString *userAgent;
@property (nonatomic, retain, readwrite) NNWGoogleLoginController *loginController;
@property (nonatomic, retain, readwrite) UIBarButtonItem *backArrowButtonItem;
@property (nonatomic, assign, readwrite) BOOL appIsActive;
@property (nonatomic, assign, readwrite) BOOL sortNewsItemsAscending;
- (void)_startCoreDataThread;
@end

@implementation NNWAppDelegate

@synthesize window, navigationController, userAgent = _userAgent, loginController = _loginController, backArrowButtonItem = _backArrowButtonItem, appIsActive = _appIsActive, coreDataThread = _coreDataThread, originalWindowBackgroundColor = _originalWindowBackgroundColor, offline = _offline, sortNewsItemsAscending = _sortNewsItemsAscending;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    

	application.applicationIconBadgeNumber = 0;
	self.userAgent = [NSString stringWithFormat:@"%@/%@ (iPhone; %@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey], [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey], @"http://newsgator.com/", nil];

	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
	
	self.backArrowButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"DirectionsBack.png"] style:UIBarButtonItemStyleBordered target:nil action:nil];

	self.originalWindowBackgroundColor = self.window.backgroundColor;
	if (!self.originalWindowBackgroundColor)
		self.originalWindowBackgroundColor = [UIColor whiteColor];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectedToInternet:) name:BCConnectedToInternetNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotConnectedToInternet:) name:BCNotConnectedToInternetNotification object:nil];
	[self startDownloaderManager];
	self.sortNewsItemsAscending = [[NSUserDefaults standardUserDefaults] boolForKey:NNWSortNewsItemsAscendingKey];
}


- (void)startDownloaderManager {
	/*Okay to call multiple times: only starts it up once*/
	[[BCDownloadManager sharedManager] start];	
}


- (void)startRefreshing {
	[self startDownloaderManager];
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


- (void)applicationWillTerminate:(UIApplication *)application {
	application.applicationIconBadgeNumber = 0;
	_stopped = YES; /*Saves Managed Object Context in thread*/
	[[NNWMainViewController sharedViewController] saveState];
	[[NNWMainViewController sharedViewController] saveOutlineToDisk];
	[NNWFavicon saveFaviconMap];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	self.appIsActive = YES;
	[[BCDownloadManager sharedManager] resume];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	application.applicationIconBadgeNumber = 0;
	self.appIsActive = NO;
	[[BCDownloadManager sharedManager] suspendWithNoTimeout];
	[self saveManagedObjectContext];
	[[NNWMainViewController sharedViewController] saveState];
	[[NNWMainViewController sharedViewController] saveOutlineToDisk];
	[NNWFavicon saveFaviconMap];
}


- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[NSDate handleSignificantDateTimeChange];
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[NNWDataController sharedController] performSelector:@selector(uncacheObjects) onThread:self.coreDataThread withObject:nil waitUntilDone:NO];
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


- (void)saveManagedObjectContext {
	if ([NSThread currentThread] != self.coreDataThread) {
		[self performSelector:@selector(saveManagedObjectContext) onThread:self.coreDataThread withObject:nil waitUntilDone:YES];
		return;
	}
	[self sendBigUIStartNotification];
	NSError *error = nil;
	if ([managedObjectContext hasChanges] && ![[self managedObjectContext] save:&error])
		[self performSelectorOnMainThread:@selector(exitNowBecauseOfCoreDataError:) withObject:error waitUntilDone:NO];
	[self sendBigUIEndNotification];
}



#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [_backArrowButtonItem release];
	[navigationController release];
	[window release];
	[super dealloc];
}



#pragma mark Network Activity Indicator

- (void)incrementNetworkActivity {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(incrementNetworkActivity) withObject:nil waitUntilDone:NO];
		return;
	}
	_networkActivityCount++;
	if (_networkActivityCount > 0)
		([UIApplication sharedApplication]).networkActivityIndicatorVisible = YES;
}


- (void)decrementNetworkActivity {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(decrementNetworkActivity) withObject:nil waitUntilDone:NO];
		return;
	}
	_networkActivityCount--;
	if (_networkActivityCount < 0)
		_networkActivityCount = 0;
	if (_networkActivityCount < 1)
		([UIApplication sharedApplication]).networkActivityIndicatorVisible = NO;
}


#pragma mark -

#pragma mark Notifications

- (void)handleConnectedToInternet:(NSNotification *)note {
	self.offline = NO;
}


- (void)handleNotConnectedToInternet:(NSNotification *)note {
	self.offline = YES;
}


#pragma mark -
#pragma mark Credentials

- (NSString *)googleUsername {
	return [[NSUserDefaults standardUserDefaults] stringForKey:NNWGoogleUsernameKey];
}


NSString *NNWGoogleServiceName = @"GoogleReader";

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


#pragma mark Feedback

- (void)displayFeedbackMessage:(NSString *)message {
	[BCFeedbackHUDViewController displayWithMessage:message duration:3.5 useActivityIndicator:NO];
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


#pragma mark About Overlay

- (void)displayAboutOverlay:(id)sender {
	NSString *formatString = @"You’re using NetNewsWire %@";
#if NNW_PREMIUM
	formatString = @"You’re using NetNewsWire Premium %@";
#endif
	[BCFeedbackHUDViewController displayWithMessage:[NSString stringWithFormat:formatString, [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]] duration:3.0 useActivityIndicator:NO];	
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

