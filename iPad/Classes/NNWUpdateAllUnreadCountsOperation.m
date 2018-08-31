//
//  NNWUpdateAllUnreadCountsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWUpdateAllUnreadCountsOperation.h"
#import "NNWDatabaseController.h"
#import "NNWFeedProxy.h"
#import "NNWFolderProxy.h"
#import "NNWOperationConstants.h"
#import "RSParsedGoogleUnreadCount.h"


@implementation NNWUpdateAllUnreadCountsOperation

#pragma mark Init

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:nil callbackSelector:nil];
	if (!self)
		return nil;
	operationType = NNWOperationTypeCountUnreadForAllFeeds;
	return self;
}


#pragma mark NSOperation

- (void)main {
 	if ([self isCancelled])
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSInteger totalUnreadCount = 0;
	@synchronized([NNWDatabaseController sharedController]) {
		[[NNWDatabaseController sharedController] beginTransaction];
		for (NNWFeedProxy *oneFeedProxy in [NNWFeedProxy feedProxies]) {
			if (!oneFeedProxy.unreadCountIsValid) {
				NSUInteger unreadCount = [[NNWDatabaseController sharedController] unreadCountForGoogleSourceID:oneFeedProxy.googleID];
				oneFeedProxy.unreadCount = unreadCount;
//				if ([oneFeedProxy respondsToSelector:@selector(sendUnreadCountDidUpdateNotification)])
//					[oneFeedProxy performSelectorOnMainThread:@selector(sendUnreadCountDidUpdateNotification) withObject:nil waitUntilDone:NO];					
			}
			totalUnreadCount += oneFeedProxy.unreadCount;
		}
		[[NNWDatabaseController sharedController] endTransaction];
	}
	[NNWFolderProxy updateUnreadCountsForAllFolders];
	[[NNWLatestNewsItemsProxy proxy] updateUnreadCount];
	/*Total unread count notification*/
	[self rs_enqueueNotificationOnMainThread:NNWTotalUnreadCountDidUpdateNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:totalUnreadCount] forKey:NNWTotalUnreadCountKey]];
//	[self rs_postNotificationOnMainThread:NNWTotalUnreadCountDidUpdateNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:totalUnreadCount] forKey:NNWTotalUnreadCountKey]];
	[pool drain];
	[super main];
}


@end
