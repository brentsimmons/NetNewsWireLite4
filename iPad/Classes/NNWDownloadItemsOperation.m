//
//  NNWDownloadItemsOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/18/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWDownloadItemsOperation.h"
#import "NNWAppDelegate.h"
#import "NNWDatabaseController.h"
#import "NNWGoogleAPI.h"
#import "NNWOperationConstants.h"
#import "RSGoogleFeedParser.h"
#import "RSParsedNewsItem.h"


@interface NNWDownloadItemsOperation ()
@property (nonatomic, retain) NSArray *itemIDs;
@property (nonatomic, retain) NSArray *allGoogleFeedIDs;
@property (nonatomic, retain, readwrite) NSMutableArray *lockedReadItemIDs;
@property (nonatomic, retain) NSMutableArray *heldNewsItems;
//@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@end


@implementation NNWDownloadItemsOperation

@synthesize itemIDs, allGoogleFeedIDs, lockedReadItemIDs, /* managedObjectContext, */ heldNewsItems;

#pragma mark Init

- (id)initWithItemIDs:(NSArray *)someItemIDs allFeedIDs:(NSArray *)allFeedIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	RSGoogleFeedParser *googleFeedParser = [RSGoogleFeedParser xmlParser];
	googleFeedParser.delegate = self;
	NSMutableDictionary *aPostBodyDict = [NSMutableDictionary dictionary];
	[aPostBodyDict setObject:NNWGoogleLongItemIDsForShortItemIDs(someItemIDs) forKey:NNWGoogleItemIDsParameterName]; // @"i"
	self = [super initWithBaseURL:[NSURL URLWithString:NNWGoogleFetchItemsByIDURL] queryDict:nil postBodyDict:aPostBodyDict delegate:aDelegate callbackSelector:aCallbackSelector parser:googleFeedParser];
	if (!self)
		return nil;
	itemIDs = [someItemIDs retain];
	allGoogleFeedIDs = [allFeedIDs retain];
	lockedReadItemIDs = [[NSMutableArray array] retain];
	self.operationType = NNWOperationTypeDownloadItems;
	self.operationObject = someItemIDs;
	heldNewsItems = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[itemIDs release];
	[lockedReadItemIDs release];
	[allGoogleFeedIDs release];
	[heldNewsItems release];
//	[managedObjectContext release];
	[super dealloc];
}


#pragma mark NSOperation

//- (void)main {
//	[super main];
//	if (self.managedObjectContext && [self.managedObjectContext hasChanges]) {
//		NSError *saveError = nil;
//		[[self managedObjectContext] save:&saveError];
//	}
//	self.managedObjectContext = nil;
//}


#pragma mark Saving

- (void)saveHeldNewsItems {
	[[NNWDatabaseController sharedController] saveNewsItems:self.heldNewsItems];
	[self.heldNewsItems removeAllObjects];	
}


- (void)holdNewsItem:(RSParsedNewsItem *)newsItem {
	/*Save temporarily -- batch them up so they can be saved n at a time inside an SQLite transaction, for performance reasons.*/
	[self.heldNewsItems safeAddObject:newsItem];
	if ([self.heldNewsItems count] > 4)
		[self saveHeldNewsItems];
}


#pragma mark Feed Parser Delegate

- (BOOL)feedParser:(id)feedParser didParseNewsItem:(RSParsedNewsItem *)newsItem {
	/*Save all items either unread, starred, or both. Save ids of locked-read items in separate database.*/
	if ([self isCancelled]) {
		((RSGoogleFeedParser *)feedParser).delegate = nil;
		return YES;
	}
	if (newsItem.starred) {
		[self holdNewsItem:newsItem];
//		[self saveNewsItem:newsItem];
		return YES;
	}
	if (newsItem.isGoogleReadStateLocked) {
		[self.lockedReadItemIDs safeAddObject:newsItem.guid];
		return YES;
	}
	if (newsItem.read)
		return YES;
	NSString *feedID = newsItem.googleSourceID;
	if (RSStringIsEmpty(feedID) || ![self.allGoogleFeedIDs containsObject:feedID])
		return YES;
	[self holdNewsItem:newsItem];
//	[self saveNewsItem:newsItem];
	return YES;
}


- (void)feedParserDidComplete:(id)feedParser {
	[self saveHeldNewsItems];
	self.heldNewsItems = nil;
}


@end
