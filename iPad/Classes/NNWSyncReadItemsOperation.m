//
//  NNWSyncReadItemsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 1/2/10.
//  Copyright 2010 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWSyncReadItemsOperation.h"
#import "NNWDatabaseController.h"
#import "NNWGoogleAPI.h"
#import "NNWOperationConstants.h"
#import "RSGoogleItemIDsParser.h"


@interface NNWSyncReadItemsOperation ()
@property (nonatomic, retain) NSMutableArray *heldItemIDs;
@end


@implementation NNWSyncReadItemsOperation

@synthesize heldItemIDs;

#pragma mark Init

static NSString *NNWSyncReadItemsNumberOfIDsToDownload = @"10000";

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	RSGoogleItemIDsParser *googleItemIDsParser = [[[RSGoogleItemIDsParser alloc] init] autorelease];
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query safeSetObject:NNWGoogleReadState forKey:NNWGoogleStatesParameterName];
	[query setObject:NNWSyncReadItemsNumberOfIDsToDownload forKey:NNWGoogleLimitParameterName];
	self = [super initWithBaseURL:[NSURL URLWithString:@"http://www.google.com/reader/api/0/stream/items/ids"] queryDict:query postBodyDict:nil delegate:aDelegate callbackSelector:aCallbackSelector parser:googleItemIDsParser];
	if (!self)
		return nil;
	googleItemIDsParser.delegate = self;
	self.operationType = NNWOperationTypeDownloadReadItemIDs;
	heldItemIDs = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[heldItemIDs release];
	[super dealloc];
}


#pragma mark Google Item IDs Parser Delegate

- (void)processHeldItemIDs {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NNWDatabaseController sharedController] markItemIDsAsRead:self.heldItemIDs];
	//TODO: update news items proxies
	[self.heldItemIDs removeAllObjects];
	[pool drain];
}


- (void)holdItemID:(NSString *)itemID {
	[self.heldItemIDs safeAddObject:itemID];
	if ([self.heldItemIDs count] > 100) /*batches*/
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

