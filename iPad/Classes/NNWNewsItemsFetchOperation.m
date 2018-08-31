//
//  NNWNewsItemsFetchOperation.m
//  nnwipad
//
//  Created by Brent Simmons on 2/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWNewsItemsFetchOperation.h"
#import "FMDatabase.h"
#import "NNWDatabaseController.h"
#import "NNWOperationConstants.h"


static NSString *NNWNewsItemsSortDirectionKey = @"sortArticlesDirection";

@interface NNWNewsItemsFetchOperation ()
@property (retain, readwrite) NSMutableArray *newsItems;
@property (retain, readwrite) NSArray *sourceIDs;
- (void)runFetch;
@end

//TODO: fetch starred items, fetch latest 24 hours

@implementation NNWNewsItemsFetchOperation

@synthesize newsItems, sourceIDs;

#pragma mark Class Method

static NSString *datePublishedKey = @"datePublished";
static NSArray *gSortDescriptors = nil;

+ (void)initialize {
	@synchronized([NNWNewsItemsFetchOperation class]) {
		if (gSortDescriptors == nil) {
			BOOL ascending = [[NSUserDefaults standardUserDefaults] integerForKey:NNWNewsItemsSortDirectionKey] == 1;
			NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:datePublishedKey ascending:ascending] autorelease];
			gSortDescriptors = [[NSArray arrayWithObject:sortDescriptor] retain];
		}
	}
}


#pragma mark Init

- (id)initWithSourceIDs:(NSArray *)someSourceIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
	if (!self)
		return nil;
	self.operationType = NNWOperationTypeFetchNewsItems;
	self.operationObject = someSourceIDs;
	sourceIDs = [someSourceIDs retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[newsItems release];
	[sourceIDs release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)main {
	[self runFetch];
	[super main];
}


#pragma mark Fetching

- (void)sortNewsItems:(NSMutableArray *)fetchedNewsItems {
	if (![self isCancelled])
		[fetchedNewsItems sortUsingDescriptors:gSortDescriptors];
}


- (FMResultSet *)fetchResultSet {
	/*Caller has synchronized access*/
	if (RSIsEmpty(self.sourceIDs))
		return nil;
	return [[NNWDatabaseController sharedController] thinResultSetWithGoogleSourceIDs:self.sourceIDs];
}


- (void)runFetch {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray *fetchedNewsItems = [NSMutableArray array];
	@synchronized([NNWDatabaseController sharedController]) {
		[[NNWDatabaseController sharedController] beginTransaction];
		FMResultSet *rs = [self fetchResultSet];
		while (rs && [rs next]) {
			if ([self isCancelled])
				break;
			[fetchedNewsItems safeAddObject:[[NNWDatabaseController sharedController] thinNewsItemWithThinRow:rs]];
		}
		[rs close];
		[[NNWDatabaseController sharedController] endTransaction];
	}
	[self sortNewsItems:fetchedNewsItems];
	if (![self isCancelled])
		self.newsItems = fetchedNewsItems;
	[pool drain];
}


@end
