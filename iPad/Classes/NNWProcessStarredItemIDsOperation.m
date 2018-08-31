//
//  NNWGoogleProcessStarredItemIDsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWProcessStarredItemIDsOperation.h"
//#import "NNWAppDelegate.h"
//#import "NNWGoogleAPI.h"
#import "NNWOperationConstants.h"
#import "NNWSyncActionsController.h"
#import "NNWDatabaseController.h"


@interface NNWProcessStarredItemIDsOperation ()
@property (nonatomic, retain) NSArray *starredItemIDs;
@property (nonatomic, retain, readwrite) NSArray *itemIDsToDownload;
@end


@implementation NNWProcessStarredItemIDsOperation

@synthesize starredItemIDs, itemIDsToDownload;

#pragma mark Init

- (id)initWithItemIDs:(NSArray *)someItemIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
	if (!self)
		return nil;
	starredItemIDs = [someItemIDs retain];
	self.operationType = NNWOperationTypeProcessStarredItemIDs;
	self.operationObject = someItemIDs;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[starredItemIDs release];
	[itemIDsToDownload release];
	[super dealloc];
}


#pragma mark NSOperation

static NSArray *arrayWithSet(NSSet *s) {
	NSMutableArray *tempArray = [NSMutableArray array];
	if (!RSIsEmpty(s)) {
		for (id oneObj in s)
			[tempArray safeAddObject:oneObj];
	}
	return tempArray;
}


- (void)main {

	/*Get all local starred item IDs
	 If local starred item is not in list and is not a pending change, un-star it.
	 Make sure all server starred items are starred locally.
	 Make array of server items that aren't local - then generate operation(s) to download them.
	 */
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSSet *downloadedItemIDs = [NSSet setWithArray:self.starredItemIDs];
	NSSet *localStarredItemIDs = [[NNWDatabaseController sharedController] idsOfStarredItems];
	NSSet *pendingStarredItems = [[NNWSyncActionsController sharedController] pendingStarredShortItemIDs:YES];
	if (!pendingStarredItems)
		pendingStarredItems = [NSSet set];
	NSSet *pendingUnstarredItems = [[NNWSyncActionsController sharedController] pendingStarredShortItemIDs:NO];
	if (!pendingUnstarredItems)
		pendingUnstarredItems = [NSSet set];
	
	/*Unstar local items*/
	NSMutableSet *itemIDsToUnstar = [[localStarredItemIDs mutableCopy] autorelease];
	[itemIDsToUnstar minusSet:pendingStarredItems];
	[itemIDsToUnstar minusSet:downloadedItemIDs];	
	if (!RSIsEmpty(itemIDsToUnstar))
		[[NNWDatabaseController sharedController] markSetOfItemIDs:itemIDsToUnstar starred:NO];
	
	/*Star local items*/
	NSMutableSet *itemIDsToStar = [[downloadedItemIDs mutableCopy] autorelease];
	[itemIDsToStar minusSet:pendingUnstarredItems];
	[itemIDsToStar minusSet:localStarredItemIDs];
	if (!RSIsEmpty(itemIDsToStar))
		[[NNWDatabaseController sharedController] markSetOfItemIDs:itemIDsToStar starred:YES];
	
	/*Find IDs of items starred on server that don't exist locally*/
	NSMutableSet *starredItemIDsToDownload = [[downloadedItemIDs mutableCopy] autorelease];
	[[NNWDatabaseController sharedController] removeExistingItemsFromSet:starredItemIDsToDownload];
	self.itemIDsToDownload = arrayWithSet(starredItemIDsToDownload);
	[super main];
	[pool drain];
}


@end
