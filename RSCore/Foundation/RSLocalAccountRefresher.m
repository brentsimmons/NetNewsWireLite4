//
//  RSLocalAccountRefresher.m
//  padlynx
//
//  Created by Brent Simmons on 9/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSLocalAccountRefresher.h"


@interface RSLocalAccountRefresher ()

@property (nonatomic, retain) NSMutableArray *feedRefreshers;

- (id<RSFeedRefresher>)feedRefresherForFeed:(id)feed accountToRefresh:(id<RSAccount>)accountToRefresh;
@end


@implementation RSLocalAccountRefresher

@synthesize feedRefreshers;

#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	feedRefreshers = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[feedRefreshers release];
	[super dealloc];
}


#pragma mark RSAccountRefresher

- (BOOL)wantsToRefreshAccount:(id<RSAccount>)anAccount {
	return anAccount.accountType == RSAccountTypeLocal; 
}


- (void)refreshAll:(id<RSAccount>)accountToRefresh operationController:(id)operationController {
	[self refreshFeeds:accountToRefresh.allFeedsThatCanBeRefreshed account:accountToRefresh operationController:operationController];
}


- (void)refreshFeeds:(NSArray *)feedsToRefresh account:(id<RSAccount>)accountToRefresh operationController:(id)operationController {
	for (id oneFeed in feedsToRefresh) {
		id<RSFeedRefresher> feedRefresher = [self feedRefresherForFeed:oneFeed accountToRefresh:accountToRefresh];
		if (feedRefresher != nil)
			[feedRefresher refreshFeed:oneFeed account:accountToRefresh operationController:operationController];
	}
}


#pragma mark Feed Refreshers

- (void)registerFeedRefresher:(id<RSFeedRefresher>)feedRefresher {
	[self.feedRefreshers rs_safeAddObject:feedRefresher];
}


- (id<RSFeedRefresher>)feedRefresherForFeed:(id)feed accountToRefresh:(id<RSAccount>)accountToRefresh {
	for (id<RSFeedRefresher> oneFeedRefresher in self.feedRefreshers) {
		if ([oneFeedRefresher wantsToRefreshFeed:feed accountToRefresh:accountToRefresh])
			return oneFeedRefresher;
	}
	return nil;
}


@end
