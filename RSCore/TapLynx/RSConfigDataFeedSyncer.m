//
//  RSConfigDataFeedSyncer.m
//  RSCoreTests
//
//  Created by Brent Simmons on 9/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSConfigDataFeedSyncer.h"
#import "RSDataAccount.h"
#import "RSFeed.h"


@implementation RSConfigDataFeedSyncer

@synthesize configFeedURLs;
@synthesize account;


#pragma mark Dealloc

- (void)dealloc {
	[configFeedURLs release];
	[account release];
	[super dealloc];
}


#pragma mark Public API

- (BOOL)syncStoredFeedsWithConfigFeeds {
	
	[self.account lockAccount];
	
	/*Create a list of URLs that don't exist in local storage.*/
	NSMutableSet *setOfConfigFeedURLs = [NSMutableSet setWithArray:self.configFeedURLs];
	NSSet *setOfStoredFeedURLs = [NSSet setWithArray:self.account.feedURLs];
	[setOfConfigFeedURLs minusSet:setOfStoredFeedURLs];
	
	/*Create a list of URLs that exist in storage but not in config data.*/
	NSMutableSet *extraFeedURLsInStorage = [[setOfStoredFeedURLs mutableCopy] autorelease];
	[extraFeedURLsInStorage minusSet:[NSSet setWithArray:self.configFeedURLs]];
	
	BOOL madeChanges = NO;
	
	/*Delete feeds no longer in config file.*/
	for (NSURL *oneFeedURL in extraFeedURLsInStorage) {
		[self.account deleteFeedWithURL:oneFeedURL];
		madeChanges = YES;
	}
	
	/*Add feeds new in config file.*/
	for (NSURL *oneNewFeedURL in setOfConfigFeedURLs) {
		[self.account addFeedWithURL:oneNewFeedURL];
		madeChanges = YES;
	}
	
	[self.account unlockAccount];
	
	return madeChanges;
}


@end
