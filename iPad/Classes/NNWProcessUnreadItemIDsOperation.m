//
//  NNWProcessUnreadItemIDsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/25/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWProcessUnreadItemIDsOperation.h"
#import "NNWGoogleAPI.h"
#import "NNWLockedReadDatabase.h"
#import "NNWOperationConstants.h"


@interface NNWProcessUnreadItemIDsOperation ()
@property (nonatomic, retain, readonly) NSArray *unreadItemIDs;
@property (nonatomic, retain, readwrite) NSArray *itemIDsToDownload;
@end


@implementation NNWProcessUnreadItemIDsOperation

@synthesize unreadItemIDs, itemIDsToDownload;


#pragma mark Init

- (id)initWithItemIDs:(NSArray *)someItemIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
	if (!self)
		return nil;
	unreadItemIDs = [someItemIDs retain];
	self.operationType = NNWOperationTypeProcessUnreadItemIDs;
	self.operationObject = someItemIDs;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[unreadItemIDs release];
	[itemIDsToDownload release];
	[super dealloc];
}



#pragma mark Data

- (NSSet *)removeUnreadItemsFromListAlreadyInLocalDatabase:(NSArray *)itemIDs {
	NSMutableSet *serverOnlyItemIDs = [NSMutableSet setWithArray:itemIDs];
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	NSArray *localItemIDs = [[NNWMainViewController sharedViewController] allNewsItemIDs]; /*TODO: a better way*/
//	NSMutableSet *shortLocalItemIDs = [[[NSMutableSet alloc] init] autorelease];
//	for (NSString *oneLocalItemID in localItemIDs) {
//		if ([oneLocalItemID length] == 48)
//			[shortLocalItemIDs rs_addObject:[oneLocalItemID substringFromIndex:32]];
//	}
//	[serverOnlyItemIDs minusSet:shortLocalItemIDs];
//	[pool drain];
	return serverOnlyItemIDs;
}



#pragma mark NSOperation

- (void)main {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSSet *serverOnlyUnreadItemIDs = [self removeUnreadItemsFromListAlreadyInLocalDatabase:self.unreadItemIDs];
	NSMutableArray *longServerOnlyUnreadItemIDs = [[NNWGoogleArrayOfLongItemIDsForSetOfShortItemIDs(serverOnlyUnreadItemIDs) mutableCopy] autorelease];
	[[NNWLockedReadDatabase sharedController] removeLockedReadItemsFromLongItemIDs:longServerOnlyUnreadItemIDs];
	self.itemIDsToDownload = longServerOnlyUnreadItemIDs;
	[super main];
	[pool drain];
}


@end
