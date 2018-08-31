//
//  NNWFeedProxy.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFeedProxy.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWDatabaseController.h"
#import "NNWFeed.h"
#import "NNWFolder.h"
#import "NNWFolderProxy.h"
#import "NNWUpdateAllUnreadCountsOperation.h"
#if NNW_MOST_RECENT_ITEM_IN_FEEDS_LIST
#import "NNWUpdateInvalidatedMostRecentItemsOperation.h"
#endif
#import "RSOperationController.h"
#import "RSParsedGoogleSub.h"
#import "RSParsedNewsItem.h"


NSString *NNWTotalUnreadCountDidUpdateNotification = @"NNWTotalUnreadCountDidUpdateNotification";
NSString *NNWTotalUnreadCountKey = @"totalUnreadCount";


@implementation NNWFeedProxy

@synthesize mostRecentItem = _mostRecentItem, mostRecentItemIsValid = _mostRecentItemIsValid;
@synthesize firstItemMsec, managedObjectID, managedObjectURI;
@synthesize userExcludes;

static NSMutableDictionary *gFeedProxyCache = nil;

+ (void)initialize {
	@synchronized([NNWFeedProxy class]) {
		if (gFeedProxyCache == nil)
			gFeedProxyCache = [[NSMutableDictionary alloc] init];
		static BOOL gDidRegisterForNotifications = NO;
		if (!gDidRegisterForNotifications) {
			gDidRegisterForNotifications = YES;
//			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDidMarkOneOrMoreItemsInFeedAsRead:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newsItemsDidSave:) name:NNWNewsItemsDidSaveNotification object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadCountInvalidated:) name:NNWUnreadCountInvalidatedNotification object:nil];
		}		
	}
}


+ (NSArray *)feedProxies {
	NSMutableArray *feedProxies = [NSMutableArray array];
	@synchronized([NNWFeedProxy class]) {
		for (NSString *oneKey in gFeedProxyCache)
			[feedProxies safeAddObject:[gFeedProxyCache objectForKey:oneKey]];
	}
	return feedProxies;
}


+ (NNWFeedProxy *)cachedFeedProxyWithGoogleID:(NSString *)googleID {
	if (RSStringIsEmpty(googleID))
		return nil;
	NNWFeedProxy *feedProxy = nil;
	@synchronized([NNWFeedProxy class]) {
		feedProxy = [[[gFeedProxyCache objectForKey:googleID] retain] autorelease];
	}
	return feedProxy;
}


+ (void)invalidateAllUnreadCounts {
	NSArray *feedProxies = [[self feedProxies] copy];
	for (NNWFeedProxy *oneFeedProxy in feedProxies)
		oneFeedProxy.unreadCountIsValid = NO;
	[feedProxies release];
	return;
}


+ (void)newsItemsDidSave:(NSNotification *)note {
	NSArray *newsItems = [[note userInfo] objectForKey:NNWNewsItemsKey];
	if (RSIsEmpty(newsItems))
		return;
	BOOL atLeastOneInvalidated = NO;
	@synchronized([NNWFeedProxy class]) {
		for (RSParsedNewsItem *oneNewsItem in newsItems) {
			NNWFeedProxy *oneFeedProxy = [self cachedFeedProxyWithGoogleID:oneNewsItem.googleSourceID];
			oneFeedProxy.unreadCountIsValid = NO;
			atLeastOneInvalidated = YES;
		}
	}
	if (atLeastOneInvalidated)
		[self performSelectorOnMainThread:@selector(updateUnreadCounts) withObject:nil waitUntilDone:NO];
}


+ (void)handleUserDidMarkOneOrMoreItemsInFeedAsRead:(NSNotification *)note {
	NSMutableArray *googleFeedIDs = [NSMutableArray array];
	NSArray *newsItems = [[note userInfo] objectForKey:RSNewsItemsKey];
	if (RSIsEmpty(newsItems))
		return;
	@synchronized([NNWFeedProxy class]) {
		for (NSDictionary *oneNewsItem in newsItems) {
			NSString *oneGoogleFeedID = [oneNewsItem objectForKey:RSDataGoogleFeedID];
			if (oneGoogleFeedID && ![googleFeedIDs containsObject:oneGoogleFeedID])
				[googleFeedIDs addObject:oneGoogleFeedID];
		}
		for (NSString *oneGoogleFeedID in googleFeedIDs) {
			NNWFeedProxy *cachedFeedProxy = [gFeedProxyCache objectForKey:oneGoogleFeedID];
			if (cachedFeedProxy)
				[cachedFeedProxy invalidateUnreadCount];
		}
	}
	[self updateUnreadCounts];
}


+ (void)handleNewsItemAdded:(NSNotification *)note {
	@synchronized([NNWFeedProxy class]) {
		NNWFeedProxy *cachedFeedProxy = [gFeedProxyCache safeObjectForKey:[[note userInfo] safeObjectForKey:RSDataGoogleFeedID]];
		if (cachedFeedProxy) {
			[cachedFeedProxy invalidateUnreadCount];	
			[cachedFeedProxy invalidateMostRecentItem];
		}
	}
}


+ (NNWFeedProxy *)feedProxyWithGoogleID:(NSString *)googleID {
	if (RSStringIsEmpty(googleID))
		return nil;
	NNWFeedProxy *feedProxy = nil;
	@synchronized([NNWFeedProxy class]) {
		if ([gFeedProxyCache objectForKey:googleID])
			return [[[gFeedProxyCache objectForKey:googleID] retain] autorelease];
		feedProxy = [[[NNWFeedProxy alloc] initWithGoogleID:googleID] autorelease];
		[gFeedProxyCache setObject:feedProxy forKey:googleID];
	}
	return feedProxy;
}


+ (NSString *)titleOfFeedWithGoogleID:(NSString *)googleID {
	NNWFeedProxy *feedProxy = nil;
	NSString *title = nil;
	@synchronized([NNWFeedProxy class]) {
		feedProxy = [self feedProxyWithGoogleID:googleID];
		title = [[feedProxy.title retain] autorelease];
	}
	return title;
}


+ (void)createProxiesForFeeds:(NSArray *)feeds {
	@synchronized([NNWFeedProxy class]) {
		for (NNWFeed *oneFeed in feeds) {
			NSString *googleID = oneFeed.googleID;
			if (googleID == nil)
				continue;
			NNWFeedProxy *oneProxy = [NNWFeedProxy feedProxyWithGoogleID:googleID];
			oneProxy.userExcludes = [oneFeed.userExcludes boolValue];
			if (![[oneFeed objectID] isTemporaryID])
				oneProxy.managedObjectID = [oneFeed objectID];
			oneProxy.firstItemMsec = oneFeed.firstitemmsec;
		}
	}
}


static NSString *NNWMostRecentItemKey = @"mostRecentItemSpecifier";
static NSString *NNWManagedObjectURIKey = @"managedObjectURI";
static NSString *NNWFirstItemMSecKey = @"firstItemMSec";

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	if (managedObjectURI != nil)
		[coder encodeObject:managedObjectURI forKey:NNWManagedObjectURIKey];
	if (firstItemMsec != nil)
		[coder encodeObject:firstItemMsec forKey:NNWFirstItemMSecKey];
	if (_mostRecentItem != nil)
		[coder encodeObject:_mostRecentItem forKey:NNWMostRecentItemKey];
}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	firstItemMsec = [[coder decodeObjectForKey:NNWFirstItemMSecKey] retain];
	managedObjectURI = [[coder decodeObjectForKey:NNWManagedObjectURIKey] retain];
	_mostRecentItem = [[coder decodeObjectForKey:NNWMostRecentItemKey] retain];
	_mostRecentItemIsValid = NO;
	[gFeedProxyCache setObject:self forKey:_googleID];
	return self;
}

- (void)dealloc {
	[_mostRecentItem release];
	[managedObjectID release];
	[managedObjectURI release];
	[firstItemMsec release];
	[super dealloc];
}


- (BOOL)mostRecentItemIsValid {
	return _mostRecentItemIsValid && self.mostRecentItem;
}


- (void)userSetUserExcludes:(BOOL)flag {
	self.userExcludes = flag;
	[NNWFeed userSetExcluded:flag forFeedWithGoogleID:self.googleID];
}


#pragma mark Unread Count

static NSTimer *updateUnreadCountsTimer = nil;
static NSDate *lastUnreadCountUpdate = nil;

static void invalidateUnreadCountsTimer(void) {
	if (updateUnreadCountsTimer == nil)
		return;
	[updateUnreadCountsTimer invalidateIfValid];
	[updateUnreadCountsTimer release];
	updateUnreadCountsTimer = nil;
}


+ (void)scheduledUpdateUnreadCounts {
	invalidateUnreadCountsTimer();
	[lastUnreadCountUpdate autorelease];
	lastUnreadCountUpdate = [[NSDate date] retain];
	NNWUpdateAllUnreadCountsOperation *updateAllUnreadCountsOperation = [[[NNWUpdateAllUnreadCountsOperation alloc] init] autorelease];
	[updateAllUnreadCountsOperation setQueuePriority:NSOperationQueuePriorityHigh];
	RSAddOperationIfNotInQueue(updateAllUnreadCountsOperation);		
}


+ (void)updateUnreadCounts {
	/*Reschedule so we don't run this expensive operation too often*/
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateUnreadCounts) withObject:nil waitUntilDone:NO];
		return;
	}
	NSDate *previousUpdate = lastUnreadCountUpdate;
	if (previousUpdate == nil)
		previousUpdate = [NSDate distantPast];
	if ([previousUpdate earlierDate:[NSDate dateWithTimeIntervalSinceNow:-0.5]] == previousUpdate)
		[self scheduledUpdateUnreadCounts];
	else {
		invalidateUnreadCountsTimer();
		updateUnreadCountsTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(scheduledUpdateUnreadCounts) userInfo:nil repeats:NO] retain];
	}
}


+ (void)unreadCountInvalidated:(NSNotification *)note {
	[self updateUnreadCounts];
}


#pragma mark Most Recent Item

- (void)setMostRecentItem:(NNWMostRecentItemSpecifier *)anItem {
#if NNW_MOST_RECENT_ITEM_IN_FEEDS_LIST
	[_mostRecentItem autorelease];
	_mostRecentItem = [anItem retain];
	self.mostRecentItemIsValid = YES;
	[self rs_enqueueNotificationOnMainThread:NNWFeedDidUpdateMostRecentItemNotification object:nil userInfo:nil];
#endif
}


- (void)updateMostRecentItemInBackground {
#if NNW_MOST_RECENT_ITEM_IN_FEEDS_LIST
	NNWUpdateInvalidatedMostRecentItemsOperation *updateInvalidatedMostRecentItemsOperation = [[[NNWUpdateInvalidatedMostRecentItemsOperation alloc] initWithDelegate:nil callbackSelector:nil] autorelease];
	if (updateInvalidatedMostRecentItemsOperation) {
		[updateInvalidatedMostRecentItemsOperation setQueuePriority:NSOperationQueuePriorityHigh];
		RSAddOperationIfNotInQueue(updateInvalidatedMostRecentItemsOperation);
	}
#endif
}


- (void)invalidateMostRecentItem {
#if NNW_MOST_RECENT_ITEM_IN_FEEDS_LIST
	self.mostRecentItemIsValid = NO;
	[self performSelectorOnMainThread:@selector(updateMostRecentItemInBackground) withObject:nil waitUntilDone:NO];
#endif
}


- (NNWFeed *)managedObjectWithID:(NSManagedObjectID *)objectID moc:(NSManagedObjectContext *)moc {
	if (objectID == nil)
		return nil;
	NSError *error = nil;
	return (NNWFeed *)[moc existingObjectWithID:objectID error:&error];
}


- (NNWFeed *)managedObjectInContext:(NSManagedObjectContext *)moc {
	if (self.managedObjectID != nil) {
		NNWFeed *feed = [self managedObjectWithID:self.managedObjectID moc:moc];
		if (feed != nil)
			return feed;
		self.managedObjectID = nil; /*Must be broken*/
	}
	if (self.managedObjectURI != nil) {
		NSManagedObjectID *objectID = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:self.managedObjectURI];
		NNWFeed *feed = [self managedObjectWithID:objectID moc:moc];
		if (feed != nil)
			return feed;
		self.managedObjectURI = nil; /*URI is broken*/
	}
	NNWFeed *feed = (NNWFeed *)[[NNWDataController sharedController] objectWithUniqueGoogleID:self.googleID entityName:RSDataEntityFeed managedObjectContext:moc];
	self.managedObjectID = feed.objectID;
	self.managedObjectURI = [managedObjectID URIRepresentation];
	return feed;
}


static BOOL googleIDIsFeedID(NSString *googleID) {
	return [googleID isKindOfClass:[NSString class]] && !RSStringIsEmpty(googleID) && [googleID hasPrefix:@"feed/"];
}


- (void)updateUnreadCount {
	NSUInteger unreadCount = 0;
	@synchronized([NNWDatabaseController sharedController]) {
		[[NNWDatabaseController sharedController] beginTransaction];
		unreadCount = [[NNWDatabaseController sharedController] unreadCountForGoogleSourceID:self.googleID];
		[[NNWDatabaseController sharedController] endTransaction];
	}
	self.unreadCount = unreadCount;
}

- (NNWFeed *)updateWithParsedSubscription:(RSParsedGoogleSub *)parsedSub moc:(NSManagedObjectContext *)moc {
	NSString *googleID = parsedSub.googleID;
	if (!googleIDIsFeedID(googleID))
		return nil;
	NNWFeed *feed = [self managedObjectInContext:moc];
	if (feed == nil)
		return nil; /*shouldn't happen*/
	if (![self.firstItemMsec isEqualToString:parsedSub.firstItemMsec]) {
		self.firstItemMsec = parsedSub.firstItemMsec;
		[feed setPrimitiveFirstitemmsec:parsedSub.firstItemMsec];
	}
	if (![self.title isEqualToString:parsedSub.title]) {
		self.title = parsedSub.title;
		[feed setPrimitiveTitle:parsedSub.title];
	}
	
	NSArray *categories = parsedSub.categories;
	if (RSIsEmpty(categories)) {
		if (!RSIsEmpty([feed primitiveFolders]))
			feed.folders = [NSSet set];
	}
	else {
		NSMutableSet *categoriesSet = [[[NSMutableSet alloc] init] autorelease];
		for (RSParsedGoogleCategory *oneCategory in categories) {
			if ([oneCategory isEmpty])
				continue;
			NSManagedObject *oneFolder = [NNWFolder folderWithGoogleDictionary:oneCategory managedObjectContext:moc];
			if (oneFolder)
				[categoriesSet addObject:oneFolder];
		}
		feed.folders = categoriesSet;
	}
	return feed;
}


@end


@implementation NNWStarredItemsProxy

static NNWStarredItemsProxy *gStarredItemsProxy = nil;

+ (NNWStarredItemsProxy *)proxy {
	if (!gStarredItemsProxy)
		gStarredItemsProxy = [[NNWStarredItemsProxy alloc] initWithGoogleID:nil];
	return gStarredItemsProxy;
}


- (NSInteger)unreadCount {
	return 0;
}


- (BOOL)unreadCountIsValid {
	return YES;
}


- (BOOL)mostRecentItemIsValid {
	return YES;
}

static NSString *NNWStarredItemsProxyTitle = @"Starred Items";

- (NSString *)title {
	return NNWStarredItemsProxyTitle;
}


- (UIImage *)proxyFeedImage {
	return [UIImage imageNamed:@"staricon.png"];
}


- (void)updateUnreadCount {
	;
}

@end


@implementation NNWLatestNewsItemsProxy

static NNWLatestNewsItemsProxy *gLatestNewsItemsProxy = nil;

+ (NNWLatestNewsItemsProxy *)proxy {
	if (!gLatestNewsItemsProxy)
		gLatestNewsItemsProxy = [[NNWLatestNewsItemsProxy alloc] initWithGoogleID:nil];
	return gLatestNewsItemsProxy;
}


- (BOOL)mostRecentItemIsValid {
	return YES;
}


- (void)updateUnreadCount {
	self.unreadCount = [[NNWDatabaseController sharedController] unreadCountForLatestItems];
}


static NSString *NNWLatestNewsItemsProxyTitle = @"Latest News (24 hours)";

- (NSString *)title {
	return NNWLatestNewsItemsProxyTitle;
}


@end




