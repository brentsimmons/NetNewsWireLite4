//
//  NNWLockedReadDatabase.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWLockedReadDatabase.h"
#import "FMDatabase.h"
#import "NNWAppDelegate.h"
#import "NNWGoogleAPI.h"
#import "RSOperationController.h"


@implementation NNWLockedReadDatabase


#pragma mark Class methods

+ (NNWLockedReadDatabase *)sharedController {	
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	self = [super initWithDatabaseFileName:@"LockedRead.sqlite3" createTableStatement:@"CREATE TABLE lockedRead (googleItemID TEXT UNIQUE, dateArrived DATE);"];
	if (!self)
		return nil;
	/*TODO: index on dateArrived*/
	[self performSelectorInBackground:@selector(deleteOldItems) withObject:nil];
	return self;
}


#pragma mark Lookups

- (BOOL)googleItemIDIsLockedRead:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleItemID))
		return NO;
	googleItemID = NNWGoogleLongItemIDForShortItemID(googleItemID);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL isLockedRead = NO;
	@synchronized(self) {
		FMResultSet *rs = [[self database] executeQuery:@"select googleItemID in lockedRead where googleItemID = ? limit 1;", googleItemID];
		if (rs && [rs next])
			isLockedRead = YES;
		[rs close];
	}
	[pool release];
	return isLockedRead;
}


#pragma mark Adding Item

- (void)addLockedReadGoogleItemID:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleItemID))
		return;
	googleItemID = NNWGoogleLongItemIDForShortItemID(googleItemID);
	@synchronized(self) {
		[[self database] executeUpdate:@"insert or replace into lockedRead (googleItemID, dateArrived) values (?, ?);", googleItemID, [NSDate date]];
	}
}


- (void)addLockedReadGoogleItemIDsInArray:(NSArray *)googleItemIDs {
	if (RSIsEmpty(googleItemIDs))
		return;
	@synchronized(self) {
		[self beginTransaction];
		for (NSString *oneGoogleItemID in googleItemIDs)
			[self addLockedReadGoogleItemID:oneGoogleItemID];
		[self endTransaction];
	}
}


- (void)runAddLockedReadGoogleItemIDsAsOperation:(NSArray *)googleItemIDs {
	NSInvocationOperation *addLockedReadGoogleItemIDsOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addLockedReadGoogleItemIDsInArray:) object:googleItemIDs] autorelease];
	[addLockedReadGoogleItemIDsOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	[[RSOperationController sharedController] addOperation:addLockedReadGoogleItemIDsOperation];																  
}


#pragma mark Sync Utility

- (NSArray *)allLockedItemIDs {
	NSMutableArray *lockedItemIDs = [NSMutableArray array];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@synchronized(self) {
		FMResultSet *rs = [[self database] executeQuery:@"select googleItemID from lockedRead;"];
		while (rs && [rs next])
			[lockedItemIDs safeAddObject:[rs stringForColumnIndex:0]];
		[rs close];
	}
	[pool drain];
	return lockedItemIDs;
}


- (void)removeLockedReadItemsFromLongItemIDs:(NSMutableArray *)googleItemIDs {
	/*googleItemIDs must be long IDs*/
	if (RSIsEmpty(googleItemIDs))
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *allLockedItemIDs = [self allLockedItemIDs];
	if (!RSIsEmpty(allLockedItemIDs))
		[googleItemIDs removeObjectsInArray:allLockedItemIDs];
	[pool drain];
}


- (void)removeLockedItemsFromSet:(NSMutableSet *)itemIDs {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	/* select googleItemID from lockedRead where googleItemID in ('1744a7ff566ee7af', '18fc344a8ee1fdf2'); */	
	NSMutableString *sql = [NSMutableString stringWithString:@"select googleItemID from lockedRead where googleItemID in ("];
	NSUInteger numberOfItemIDs = [itemIDs count];
	NSUInteger indexOfItemID = 0;
	for (NSString *oneString in itemIDs) {		
		[sql appendString:@"'"];
		[sql appendString:oneString];
		[sql appendString:@"'"];
		if (indexOfItemID < numberOfItemIDs - 1)
			[sql appendString:@", "];
		indexOfItemID++;
	}
	[sql appendString:@");"];
	NSMutableSet *lockedItems = [NSMutableSet set];
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [[self database] executeQuery:sql];
		while (rs && [rs next])
			[lockedItems rs_addObject:[rs stringForColumnIndex:0]];
		[rs close];
		[self endTransaction];
	}
	[itemIDs minusSet:lockedItems];
	[pool drain];
}


#pragma mark Cleanup

- (void)deleteOldItems {
	/*So the database doesn't just grow forever, delete items older than 60 days. They'll come back if they're still in the system.*/
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDate *date30DaysAgo = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * 60)];
	@synchronized(self) {
		[[self database] executeUpdate:@"delete from lockedRead where dateArrived < ?;", date30DaysAgo];
	}
	[pool drain];
}

@end
