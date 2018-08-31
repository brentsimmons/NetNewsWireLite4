//
//  NNWSyncUnreadItemsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 1/2/10.
//  Copyright 2010 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWSyncUnreadItemsOperation.h"
#import "NNWDatabaseController.h"
#import "NNWGoogleAPI.h"
#import "NNWLockedReadDatabase.h"
#import "NNWOperationConstants.h"


@interface NNWSyncUnreadItemsOperation ()
@property (nonatomic, retain) NSMutableSet *heldItemIDs;
@end


@implementation NNWSyncUnreadItemsOperation

@synthesize heldItemIDs, didParseItemsDelegate;

#pragma mark Init

static NSString *NNWSyncUnreadItemsNumberOfIDsToDownload = @"10000";

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	RSGoogleItemIDsParser *googleItemIDsParser = [[[RSGoogleItemIDsParser alloc] init] autorelease];
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query safeSetObject:NNWGoogleReadingListState forKey:NNWGoogleStatesParameterName];
	[query safeSetObject:NNWGoogleReadState forKey:NNWGoogleExcludeParameterName];
	[query setObject:NNWSyncUnreadItemsNumberOfIDsToDownload forKey:NNWGoogleLimitParameterName];
	self = [super initWithBaseURL:[NSURL URLWithString:@"http://www.google.com/reader/api/0/stream/items/ids"] queryDict:query postBodyDict:nil delegate:aDelegate callbackSelector:aCallbackSelector parser:googleItemIDsParser];
	if (!self)
		return nil;
	googleItemIDsParser.delegate = self;
	self.operationType = NNWOperationTypeDownloadUnreadItemIDs;
	heldItemIDs = [[NSMutableSet set] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[heldItemIDs release];
	[super dealloc];
}


#pragma mark Google Item IDs Parser Delegate

- (void)processHeldItemIDs {
	/*Ignore items that are locked according to locked-read database or that we already have.*/
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NNWLockedReadDatabase sharedController] removeLockedItemsFromSet:self.heldItemIDs];
	if (!RSIsEmpty(self.heldItemIDs))
		[[NNWDatabaseController sharedController] removeExistingItemsFromSet:self.heldItemIDs];
	if (self.didParseItemsDelegate && !RSIsEmpty(self.heldItemIDs))
		[self.didParseItemsDelegate syncUnreadItemsOperation:self didParseUnreadItemIDs:[[self.heldItemIDs copy] autorelease]];
	[self.heldItemIDs removeAllObjects];
	[pool drain];
}



- (void)holdItemID:(NSString *)itemID {
	[self.heldItemIDs rs_addObject:itemID];
	if ([self.heldItemIDs count] >= 100) /*batches*/
		[self processHeldItemIDs];
}


- (BOOL)itemIDsParser:(id)itemIDsParser didParseItemID:(NSString *)itemID {
	[self holdItemID:itemID];
	return YES; /*Return YES to consume itemID: saves a bit of memory*/
}


- (void)itemIDsParserDidComplete:(id)itemIDsParser {
	[self processHeldItemIDs];
	self.heldItemIDs = nil;
}


@end
