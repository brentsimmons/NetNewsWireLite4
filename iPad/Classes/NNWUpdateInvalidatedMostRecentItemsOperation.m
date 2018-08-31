//
//  NNWUpdateInvalidatedMostRecentItemsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 1/2/10.
//  Copyright 2010 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWUpdateInvalidatedMostRecentItemsOperation.h"
#import "NNWDatabaseController.h"
#import "NNWFeedProxy.h"
#import "NNWOperationConstants.h"


@implementation NNWUpdateInvalidatedMostRecentItemsOperation


#pragma mark Init

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:nil callbackSelector:nil];
	if (!self)
		return nil;
	operationType = NNWOperationTypeUpdateInvalidatedMostRecentItems;
	return self;
}


#pragma mark NSOperation

- (void)main {
 	if ([self isCancelled])
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@synchronized([NNWDatabaseController sharedController]) {
		[[NNWDatabaseController sharedController] beginTransaction];
		for (NNWFeedProxy *oneFeedProxy in [NNWFeedProxy feedProxies]) {
			if (!oneFeedProxy.mostRecentItemIsValid) {
				NNWMostRecentItemSpecifier *mostRecentItemSpecifier = [[NNWDatabaseController sharedController] mostRecentItemForGoogleSourceID:oneFeedProxy.googleID];
				[oneFeedProxy performSelectorOnMainThread:@selector(setMostRecentItem:) withObject:mostRecentItemSpecifier waitUntilDone:NO];
			}
		}
		[[NNWDatabaseController sharedController] endTransaction];
	}
	[pool drain];
	[super main];
}


@end
