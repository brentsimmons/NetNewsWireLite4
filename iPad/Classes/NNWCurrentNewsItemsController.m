//
//  NNWCurrentNewsItemsController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWCurrentNewsItemsController.h"
#import "NNWLatestItemsFetchOperation.h"
#import "NNWNewsItemsFetchOperation.h"
#import "NNWStarredItemsFetchOperation.h"
#import "RSOperationController.h"


NSString *NNWCurrentNewsItemsDidUpdateNotification = @"NNWCurrentNewsItemsDidUpdateNotification";
NSString *NNWCurrentNewsItemsKey = @"newsItems";

@interface NNWCurrentNewsItemsController ()
@property (nonatomic, retain) RSOperationController *fetchNewsItemsOperationController;
@property (nonatomic, retain) NNWNewsItemsFetchOperation *currentNewsItemsFetchOperation;
@end


@implementation NNWCurrentNewsItemsController

@synthesize newsItems, fetchNewsItemsOperationController;
@synthesize currentNewsItemsFetchOperation;


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	fetchNewsItemsOperationController = [[RSOperationController alloc] init];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[fetchNewsItemsOperationController cancelAllOperations];
	[fetchNewsItemsOperationController release];
	[newsItems release];
	[super dealloc];
}


#pragma mark Fetching

- (void)fetchNewsItemsForSourceIDs:(NSArray *)sourceIDs {
	[self.fetchNewsItemsOperationController cancelAllOperations];
	NNWNewsItemsFetchOperation *newsItemsFetchOperation = [[[NNWNewsItemsFetchOperation alloc] initWithSourceIDs:sourceIDs delegate:self callbackSelector:@selector(newsItemsDidFetch:)] autorelease];
	[newsItemsFetchOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	self.currentNewsItemsFetchOperation = newsItemsFetchOperation;
	[self.fetchNewsItemsOperationController addOperationIfNotInQueue:newsItemsFetchOperation];
}


- (void)fetchStarredNewsItems {
	[self.fetchNewsItemsOperationController cancelAllOperations];
	NNWStarredItemsFetchOperation *newsItemsFetchOperation = [[[NNWStarredItemsFetchOperation alloc] initWithDelegate:self callbackSelector:@selector(newsItemsDidFetch:)] autorelease];
	[newsItemsFetchOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	self.currentNewsItemsFetchOperation = newsItemsFetchOperation;
	[self.fetchNewsItemsOperationController addOperationIfNotInQueue:newsItemsFetchOperation];	
}


- (void)fetchLatestNewsItems {
	[self.fetchNewsItemsOperationController cancelAllOperations];
	NNWLatestItemsFetchOperation *newsItemsFetchOperation = [[[NNWLatestItemsFetchOperation alloc] initWithDelegate:self callbackSelector:@selector(newsItemsDidFetch:)] autorelease];
	[newsItemsFetchOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	self.currentNewsItemsFetchOperation = newsItemsFetchOperation;
	[self.fetchNewsItemsOperationController addOperationIfNotInQueue:newsItemsFetchOperation];	
}


#pragma mark Callback


- (void)newsItemsDidFetch:(NNWNewsItemsFetchOperation *)newsItemsFetchOperation {
	if (newsItemsFetchOperation != self.currentNewsItemsFetchOperation)
		return;
	self.newsItems = newsItemsFetchOperation.newsItems;
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo safeSetObject:self.newsItems forKey:NNWCurrentNewsItemsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWCurrentNewsItemsDidUpdateNotification object:self userInfo:userInfo];
	self.currentNewsItemsFetchOperation = nil;
}


@end
