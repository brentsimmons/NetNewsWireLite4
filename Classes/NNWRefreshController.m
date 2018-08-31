//
//  NNWRefreshController.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWRefreshController.h"
#import "NNWConstants.h"
#import "RSDownloadableFeedRefresher.h"
#import "RSFeed.h"
#import "RSLocalAccountRefresher.h"
#import "RSOperationController.h"


static NSString *NNWRefreshFeedsIntervalDefaultsKey = @"refreshFeedsInterval";

@implementation NNWRefreshController

#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	[self.refreshOperationController.operationQueue setMaxConcurrentOperationCount:20];
	RSLocalAccountRefresher *localAccountRefresher = [[[RSLocalAccountRefresher alloc] init] autorelease];
	[self registerAccountRefresher:localAccountRefresher];
	[localAccountRefresher registerFeedRefresher:[[[RSDownloadableFeedRefresher alloc] init] autorelease]];
	
	NSDictionary *defaultPreferences = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:30] forKey:NNWRefreshFeedsIntervalDefaultsKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedAdded:) name:NNWFeedAddedNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark Notifications


- (void)feedAdded:(NSNotification *)note {
	RSFeed *feedAdded = [[note userInfo] objectForKey:NNWFeedKey];
	[self refreshFeeds:[NSArray arrayWithObject:feedAdded]];
}


@end
