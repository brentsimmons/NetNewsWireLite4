//
//  RSRefreshController.m
//  padlynx
//
//  Created by Brent Simmons on 9/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSRefreshController.h"
#import "RSDataAccount.h"
#import "RSFeed.h"
#import "RSOperationController.h"
#import "RSRefreshProtocols.h"


NSString *RSRefreshSessionDidBeginNotification = @"RSRefreshSessionDidBeginNotification";
NSString *RSRefreshSessionDidEndNotification = @"RSRefreshSessionDidEndNotification";
NSString *RSRefreshDidUpdateFeedNotification = @"RSRefreshDidUpdateFeedNotification";


@interface RSRefreshController ()

@property (nonatomic, retain) NSMutableArray *accountRefreshers;
@property (nonatomic, retain, readwrite) RSOperationController *refreshOperationController;

- (id<RSAccountRefresher>)refresherForAccount:(id<RSAccount>)accountToRefresh;

@end


@implementation RSRefreshController

@synthesize accountRefreshers;
@synthesize refreshOperationController;


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	refreshOperationController = [[RSOperationController alloc] init];
	refreshOperationController.tracksOperations = YES;
	refreshOperationController.name = @"Refresh";
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshOperationsDidBegin:) name:RSOperationControllerDidBeginOperationsNotification object:refreshOperationController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshOperationsDidEnd:) name:RSOperationControllerDidEndOperationsNotification object:refreshOperationController];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[refreshOperationController cancelAllOperations];
	[refreshOperationController release];
	[accountRefreshers release];
	[super dealloc];
}


#pragma mark API

- (void)refreshAllInAccounts:(NSArray *)accountsToRefresh {
	for (id<RSAccount> oneAccount in accountsToRefresh) {
		id<RSAccountRefresher> accountRefresher = [self refresherForAccount:oneAccount];
		[accountRefresher refreshAll:oneAccount operationController:self.refreshOperationController];
	}
}


- (void)refreshFeeds:(NSArray *)feeds {
	for (RSFeed *oneFeed in feeds) {
		id<RSAccountRefresher> accountRefresher = [self refresherForAccount:oneFeed.account];
		if (oneFeed.URL == nil)
			continue;
		[accountRefresher refreshFeeds:[NSArray arrayWithObject:oneFeed] account:oneFeed.account operationController:self.refreshOperationController];		
	}
}


- (void)registerAccountRefresher:(id<RSAccountRefresher>)accountRefresher {
	if (self.accountRefreshers == nil)
		self.accountRefreshers = [NSMutableArray array];
	if ([self.accountRefreshers indexOfObjectIdenticalTo:accountRefresher] == NSNotFound)
		[self.accountRefreshers addObject:accountRefresher];
}


- (void)cancelSession {
	//TODO: cancel session
}

#pragma mark Refreshers

- (id<RSAccountRefresher>)refresherForAccount:(id<RSAccount>)accountToRefresh {
	for (id<RSAccountRefresher> oneAccountRefresher in self.accountRefreshers) {
		if ([oneAccountRefresher wantsToRefreshAccount:accountToRefresh])
			return oneAccountRefresher;
	}
	return nil;
}


#pragma mark Notifications

- (void)refreshOperationsDidBegin:(NSNotification *)note {
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSRefreshSessionDidBeginNotification object:self userInfo:nil];
}


- (void)refreshOperationsDidEnd:(NSNotification *)note {
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSRefreshSessionDidEndNotification object:self userInfo:nil];
}


@end
