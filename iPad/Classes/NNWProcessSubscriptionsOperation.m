//
//  NNWGoogleProcessSubscriptionsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWProcessSubscriptionsOperation.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWFeed.h"
#import "NNWFeedProxy.h"
#import "NNWOperationConstants.h"
#import "RSParsedGoogleSub.h"


@interface NNWProcessSubscriptionsOperation ()
@property (nonatomic, retain) NSArray *subscriptions;
@property (nonatomic, retain, readwrite) NSArray *allGoogleFeedIDs;
@property (nonatomic, retain) NSManagedObjectContext *moc;
@end


@implementation NNWProcessSubscriptionsOperation

@synthesize subscriptions, allGoogleFeedIDs, hasAtLeastOneFeed, moc;

#pragma mark Init

- (id)initWithSubscriptions:(NSArray *)someSubscriptions delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
	if (!self)
		return nil;
	subscriptions = [someSubscriptions retain];
	self.operationType = NNWOperationTypeProcessSubscriptions;
	self.operationObject = someSubscriptions;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[subscriptions release];
	[allGoogleFeedIDs release];
	[moc release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)processSubscriptions {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.hasAtLeastOneFeed = NO;
	NSMutableArray *feeds = [NSMutableArray array];
	NSMutableArray *allFeedIDs = [NSMutableArray array];
	for (RSParsedGoogleSub *oneSubscription in self.subscriptions) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		NNWFeedProxy *oneFeedProxy = [NNWFeedProxy feedProxyWithGoogleID:oneSubscription.googleID];
		NNWFeed *oneFeed = [oneFeedProxy updateWithParsedSubscription:oneSubscription moc:app_delegate.managedObjectContext];
		if (oneFeed != nil)
			self.hasAtLeastOneFeed = YES;
		[feeds safeAddObject:oneFeed];
		[allFeedIDs safeAddObject:oneSubscription.googleID];
		[pool2 drain];
	}
	[NNWFeed deleteFeedsExceptFor:feeds managedObjectContext:app_delegate.managedObjectContext];
	[app_delegate saveManagedObjectContext:app_delegate.managedObjectContext];
	self.allGoogleFeedIDs = allFeedIDs;
	[pool drain];
}


- (void)main {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	self.moc = [[[NSManagedObjectContext alloc] init] autorelease];
//	[self.moc setPersistentStoreCoordinator:[app_delegate persistentStoreCoordinator]];
//	[self.moc setUndoManager:nil];
	[self performSelector:@selector(processSubscriptions) onThread:app_delegate.coreDataThread withObject:nil waitUntilDone:YES];
//	[self processSubscriptions];
//	self.moc = nil;
	[super main];
	[pool drain];
}


@end
