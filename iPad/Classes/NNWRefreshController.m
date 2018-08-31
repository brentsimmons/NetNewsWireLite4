//
//  NNWRefreshController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/11/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWRefreshController.h"
#import "NNWAppDelegate.h"
#import "NNWDownloadItemsOperation.h"
#import "NNWGoogleAPI.h"
#import "NNWGoogleAPICallOperation.h"
#import "NNWGoogleLoginOperation.h"
#import "NNWLockedReadDatabase.h"
#import "NNWOperationConstants.h"
#import "NNWProcessStarredItemIDsOperation.h"
#import "NNWProcessSubscriptionsOperation.h"
#import "NNWProcessUnreadItemIDsOperation.h"
#import "NNWSyncReadItemsOperation.h"
#import "RSGoogleItemIDsParser.h"
#import "RSGoogleSubsListParser.h"
#import "RSGoogleUnreadCountsParser.h"
#import "RSOperationController.h"


NSString *NNWLastRefreshDateKey = @"lastRefreshDate";
NSString *NNWRefreshSessionDidBeginNotification = @"NNWRefreshSessionDidBeginNotification";
NSString *NNWRefreshSessionDidEndNotification = @"NNWRefreshSessionDidEndNotification";
NSString *NNWRefreshSessionNoSubsFoundNotification = @"NNWRefreshSessionNoSubsFoundNotification";
NSString *NNWRefreshSessionSubsFoundNotification = @"NNWRefreshSessionSubsFoundNotification";


@interface NNWRefreshController ()
@property (nonatomic, retain) NSArray *allGoogleFeedIDs;
@property (nonatomic, assign) BOOL syncSessionIsRunning;
- (void)startSync;
- (void)verifyLogin;
- (void)runDownloadItemsOperationsWithItemIDs:(NSSet *)itemIDsToDownload;
- (BOOL)anySyncOperationIsRunning;
- (void)noteSyncDidEnd;
- (void)endSyncIfThereAreNoMoreSyncOperations;
- (void)syncReadItems;
- (void)syncUnreadItems;
@end


@implementation NNWRefreshController

@synthesize allGoogleFeedIDs, syncSessionIsRunning;

#pragma mark Class Methods

+ (NNWRefreshController *)sharedController {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	refreshOperationController = [[RSOperationController alloc] init];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[allGoogleFeedIDs release];
	[refreshOperationController cancelAllOperations];
	[refreshOperationController release];
	[super dealloc];
}


#pragma mark Refresh Session

- (BOOL)runRefreshSession {
	if (self.syncSessionIsRunning) /*One session at a time.*/
		return NO;
	self.syncSessionIsRunning = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWRefreshSessionDidBeginNotification object:nil];
	[self startSync];
	return YES;	
}

static BOOL NNWOperationTypeIsSyncOperation(NNWOperationType operationType) {
	return operationType == NNWOperationTypeGoogleLogin || operationType == NNWOperationTypeDownloadSubscriptions || operationType == NNWOperationTypeProcessSubscriptions || operationType == NNWOperationTypeDownloadStarredItemIDs || operationType == NNWOperationTypeProcessStarredItemIDs || operationType == NNWOperationTypeDownloadItems || operationType == NNWOperationTypeDownloadReadItemIDs || operationType == NNWOperationTypeDownloadUnreadItemIDs || operationType == NNWOperationTypeProcessUnreadItemIDs || operationType == NNWOperationTypeProcessReadItemIDs;
}


- (void)cancelAllSyncOperations {
	for (RSOperation *oneOperation in refreshOperationController.operations) {
		if ([oneOperation isKindOfClass:[NNWGoogleAPICallOperation class]]) {
			[oneOperation cancel];
			continue;
		}
		if ([oneOperation respondsToSelector:@selector(operationType)] && NNWOperationTypeIsSyncOperation(oneOperation.operationType))
			[oneOperation cancel];
	}
}


- (BOOL)anySyncOperationIsRunning {
	for (RSOperation *oneOperation in refreshOperationController.operations) {
		if ([oneOperation isKindOfClass:[NNWGoogleAPICallOperation class]] || ([oneOperation respondsToSelector:@selector(operationType)] && NNWOperationTypeIsSyncOperation(oneOperation.operationType)))
			return YES;
	}
	return NO;
}


- (void)noteSyncDidEnd {
	if (!self.syncSessionIsRunning)
		return;
	self.syncSessionIsRunning = NO;
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NNWLastRefreshDateKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	RSPostNotificationOnMainThread(NNWRefreshSessionDidEndNotification);
}


- (void)endSync {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(endSync) withObject:nil waitUntilDone:NO];
		return;
	}
	[self cancelAllSyncOperations];
	[self noteSyncDidEnd];
}


- (void)endSyncIfThereAreNoMoreSyncOperations {
	if (self.syncSessionIsRunning && ![self anySyncOperationIsRunning])
		[self noteSyncDidEnd];
}


- (void)checkIfSyncSessionIsOverAfterDelay {
	[self performSelector:@selector(endSyncIfThereAreNoMoreSyncOperations) withObject:nil afterDelay:1.0];
}


#pragma mark Perform Sync

/*Sync session:
 Verify login
 Download subscriptions
 Process subscriptions
 
 The following two run at the same time as operations:
 1. syncStarredItems - downloads and processes starred item IDs
	downloads starred items that aren't local
 2. syncNewsItems - downloads and processes unread news item IDs
	downloads unread news items that aren't local
 */


- (void)startSync {
	RSPostNotificationOnMainThread(NNWRefreshSessionDidBeginNotification);
	[self verifyLogin];
}


#pragma mark Verify Login

- (void)verifyLogin {
	[app_delegate sendStatusMessageDidBegin:@"Logging in"];
	NNWGoogleLoginOperation *googleLoginOperation = [[[NNWGoogleLoginOperation alloc] initWithDelegate:self callbackSelector:@selector(verifyLoginDidComplete:)] autorelease];
	[googleLoginOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	googleLoginOperation.operationType = NNWOperationTypeGoogleLogin;
	[refreshOperationController addOperation:googleLoginOperation];
}


- (void)handleAuthenticationError {
	[app_delegate sendStatusMessageDidEnd:@"Logging in"];
	[self endSync];
	[app_delegate showStartupLogin];
}


- (void)verifyLoginDidComplete:(NNWGoogleLoginOperation *)operation {
	NSInteger statusCode = operation.statusCode;
	if (statusCode == 403) {
		[self performSelectorOnMainThread:@selector(handleAuthenticationError) withObject:nil waitUntilDone:NO];
		return;
		//self.stop = YES;
	}
	[self performSelectorOnMainThread:@selector(downloadSubscriptions) withObject:nil waitUntilDone:NO];
}


#pragma mark Download Subscriptions

- (void)downloadSubscriptions {
	[app_delegate sendStatusMessageDidBegin:@"Downloading subscriptions list"];
	[app_delegate sendStatusMessageDidEnd:@"Logging in"];
	NNWGoogleAPICallOperation *downloadSubscriptionsOperation = [NNWGoogleAPICallOperation downloadSubscriptionsAPICallWithDelegate:self callbackSelector:@selector(downloadSubscriptionsDidComplete:)];
	[downloadSubscriptionsOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	[refreshOperationController addOperationIfNotInQueue:downloadSubscriptionsOperation];
	[self checkIfSyncSessionIsOverAfterDelay];
}


- (void)downloadSubscriptionsDidComplete:(NNWGoogleAPICallOperation *)operation {
	[app_delegate sendStatusMessageDidBegin:@"Storing subscriptions"];
	[app_delegate sendStatusMessageDidEnd:@"Downloading subscriptions list"];
	/*Check for empty subscriptions -- may need to add default subs for new user*/
	NSMutableArray *subs = ((RSGoogleSubsListParser *)(operation.parser)).subs;
	if (operation.okResponse && RSIsEmpty(subs)) {
		[self endSync];
		[[NSNotificationCenter defaultCenter]postNotificationOnMainThread:NNWRefreshSessionNoSubsFoundNotification];
		return;
	}
	if (operation.okResponse && !RSIsEmpty(subs))
	{
		[[NSNotificationCenter defaultCenter]postNotificationOnMainThread:NNWRefreshSessionSubsFoundNotification];
		[self performSelectorOnMainThread:@selector(processSubscriptions:) withObject:subs waitUntilDone:NO];
	}
}


#pragma mark Process Subscriptions

- (void)processSubscriptionsDidComplete:(NNWProcessSubscriptionsOperation *)operation {
	[app_delegate sendStatusMessageDidEnd:@"Storing subscriptions"];
	self.allGoogleFeedIDs = operation.allGoogleFeedIDs;
	[self rs_postNotificationOnMainThread:NNWSubscriptionsDidUpdateNotification object:nil userInfo:nil];
	//[self performSelectorOnMainThread:@selector(downloadUnreadCounts) withObject:nil waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(syncStarredItems) withObject:nil waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(syncNewsItems) withObject:nil waitUntilDone:NO];
}


- (void)processSubscriptions:(NSArray *)subscriptions {
	NNWProcessSubscriptionsOperation *processSubscriptionsOperation = [[[NNWProcessSubscriptionsOperation alloc] initWithSubscriptions:subscriptions delegate:self callbackSelector:@selector(processSubscriptionsDidComplete:)] autorelease];
	[processSubscriptionsOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	[refreshOperationController addOperationIfNotInQueue:processSubscriptionsOperation];
}


#pragma mark Unread Counts

/*TODO: For feeds with zero unread, mark all read in database. Not sure it's necessary.*/

//- (void)downloadUnreadCounts {
//	[app_delegate sendStatusMessageDidBegin:@"Downloading unread counts"];
//	NNWGoogleAPICallOperation *downloadUnreadCountsOperation = [NNWGoogleAPICallOperation downloadUnreadCounts:self callbackSelector:@selector(downloadUnreadCountsDidComplete:)];
//	[downloadUnreadCountsOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
//	[refreshOperationController addOperationIfNotInQueue:downloadUnreadCountsOperation];
//}
//
//
//- (void)downloadUnreadCountsDidComplete:(NNWGoogleAPICallOperation *)operation {
//	[app_delegate sendStatusMessageDidEnd:@"Downloading unread counts"];
//}


#pragma mark Sync Starred Items

- (void)syncStarredItems {
	[app_delegate sendStatusMessageDidBegin:@"Syncing starred items"];
	NNWGoogleAPICallOperation *downloadStarredItemIDsOperation = [NNWGoogleAPICallOperation downloadItemIDsAPICallWithStatesToRetrieve:[NSArray arrayWithObject:NNWGoogleStarredState] statesToIgnore:nil itemIDsToIgnore:nil delegate:self callbackSelector:@selector(downloadStarredItemIDsDidComplete:)];
	[downloadStarredItemIDsOperation setQueuePriority:NSOperationQueuePriorityNormal];
	[refreshOperationController addOperationIfNotInQueue:downloadStarredItemIDsOperation];
	[self checkIfSyncSessionIsOverAfterDelay];
}


- (void)downloadStarredItemIDsDidComplete:(NNWGoogleAPICallOperation *)operation {
	if (operation.statusCode != 200) {
		[app_delegate sendStatusMessageDidEnd:@"Syncing starred items"];
		return;
	}
	NNWProcessStarredItemIDsOperation *processStarredItemIDsOperation = [[[NNWProcessStarredItemIDsOperation alloc] initWithItemIDs:((RSGoogleItemIDsParser *)(operation.parser)).itemIDs delegate:self callbackSelector:@selector(processStarredItemIDsDidComplete:)] autorelease];
	[refreshOperationController addOperationIfNotInQueue:processStarredItemIDsOperation];
	[self checkIfSyncSessionIsOverAfterDelay];
}


- (void)processStarredItemIDsDidComplete:(NNWProcessStarredItemIDsOperation *)operation {
	NSArray *itemIDsToDownload = operation.itemIDsToDownload;
	if (!RSIsEmpty(itemIDsToDownload))
		[self runDownloadItemsOperationsWithItemIDs:[NSSet setWithArray:itemIDsToDownload]];
	[app_delegate sendStatusMessageDidEnd:@"Syncing starred items"];
	[self checkIfSyncSessionIsOverAfterDelay];
}


#pragma mark Sync News Items

- (void)syncNewsItems {
	[self syncReadItems];
	[self syncUnreadItems];
}


#pragma mark Read Item IDs

- (void)syncReadItems {
	[app_delegate sendStatusMessageDidBegin:@"Syncing read items"];
	NNWSyncReadItemsOperation *syncReadItemsOperation = [[[NNWSyncReadItemsOperation alloc] initWithDelegate:self callbackSelector:@selector(syncReadItemsDidComplete:)] autorelease];
	[refreshOperationController addOperationIfNotInQueue:syncReadItemsOperation];
}


- (void)syncReadItemsDidComplete:(NNWSyncReadItemsOperation *)operation {
	[app_delegate sendStatusMessageDidEnd:@"Syncing read items"];
	[self checkIfSyncSessionIsOverAfterDelay];
}


#pragma mark Unread Item IDs

- (void)syncUnreadItems {
	NNWSyncUnreadItemsOperation *syncUnreadItemsOperation = [[[NNWSyncUnreadItemsOperation alloc] initWithDelegate:self callbackSelector:@selector(syncUnreadItemsDidComplete:)] autorelease];
	syncUnreadItemsOperation.didParseItemsDelegate = self;
	[refreshOperationController addOperationIfNotInQueue:syncUnreadItemsOperation];
}


- (void)syncUnreadItemsOperation:(NNWSyncUnreadItemsOperation *)operation didParseUnreadItemIDs:(NSSet *)itemIDs {
	[self runDownloadItemsOperationsWithItemIDs:itemIDs];
}


- (void)syncUnreadItemsDidComplete:(NNWSyncUnreadItemsOperation *)operation {
	[self checkIfSyncSessionIsOverAfterDelay];
}


#pragma mark Download items

- (void)downloadItemsDidComplete:(NNWDownloadItemsOperation *)operation {
	if (!RSIsEmpty(operation.lockedReadItemIDs))
		[[NNWLockedReadDatabase sharedController] runAddLockedReadGoogleItemIDsAsOperation:operation.lockedReadItemIDs];
	[self rs_enqueueNotificationOnMainThread:NNWNewsItemsDidChangeNotification object:nil userInfo:nil];
	[self checkIfSyncSessionIsOverAfterDelay];
//	[self performSelectorOnMainThread:@selector(endSyncIfThereAreNoMoreSyncOperations) withObject:nil waitUntilDone:NO];
}


- (void)runDownloadItemsOperationsWithItemIDs:(NSSet *)itemIDsToDownload { /*or short item IDs*/
	if (RSIsEmpty(itemIDsToDownload)) {
		[self checkIfSyncSessionIsOverAfterDelay];
		return;
	}
	[app_delegate sendStatusMessageDidBegin:@"Downloading articles"];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *itemsIDsSplitIntoGroups = NNWSetSeparatedIntoArraysOfLength(itemIDsToDownload, 100);
	for (NSArray *oneGroupOfItemIDs in itemsIDsSplitIntoGroups) {
		NNWDownloadItemsOperation *downloadItemsOperation = [[[NNWDownloadItemsOperation alloc] initWithItemIDs:oneGroupOfItemIDs allFeedIDs:self.allGoogleFeedIDs delegate:self callbackSelector:@selector(downloadItemsDidComplete:)] autorelease];
		[downloadItemsOperation setQueuePriority:NSOperationQueuePriorityLow];
		[refreshOperationController addOperation:downloadItemsOperation];
	}
	[pool drain];	
}


@end
