//
//  RSDownloadableFeedRefresher.m
//  padlynx
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDownloadableFeedRefresher.h"
#import "RSDownloadConstants.h"
#import "RSFeed.h"
#import "RSRefreshFeedOperation.h"


@implementation RSDownloadableFeedRefresher

- (BOOL)wantsToRefreshFeed:(id)feed accountToRefresh:(id<RSAccount>)accountToRefresh {
	return accountToRefresh.accountType == RSAccountTypeLocal && RSURLIsDownloadable(((RSFeed *)feed).URL);
}


- (void)refreshFeed:(RSFeed *)feed account:(id<RSAccount>)accountToRefresh operationController:(id)operationController {
	RSRefreshFeedOperation *refreshFeedOperation = [[[RSRefreshFeedOperation alloc] initWithFeedURL:((RSFeed *)feed).URL accountIdentifier:accountToRefresh.identifier] autorelease];
	refreshFeedOperation.username = feed.username;
	if (feed.username != nil)
		refreshFeedOperation.password = feed.password;
	[operationController addOperation:refreshFeedOperation];
}


@end
