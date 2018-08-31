//
//  RSGoogleMetadataCache.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSGoogleReaderMetadataCache.h"
#import "FMDatabase.h"
#import "RSFileUtilities.h"
#import "RSGoogleReaderUtilities.h"
#import "RSOperationController.h"


/*The cache is deleted every two weeks, which is an easy and effective way of making sure
 it doesn't grow forever and slow things down.*/

//TODO: factor out the common code. There's a bunch.
 
static NSString *RSGoogleMetadataCacheFileName = @"GoogleReaderSyncMetadataCache.sqlite3";
static NSString *RSGoogleMetadataCacheDeleteDateKey = @"dateLastDeletedGRSyncMetadataCache";

/*Schema:
	CREATE TABLE lockedRead (shortItemID TEXT UNIQUE);
	CREATE TABLE feedIDs (shortItemID TEXT UNIQUE, longFeedID);
	CREATE TABLE downloaded (shortItemID TEXT UNIQUE);
*/



@implementation RSGoogleReaderMetadataCache

#pragma mark Class Methods

+ (RSGoogleReaderMetadataCache *)sharedCache {
	static RSGoogleReaderMetadataCache *gMyInstance = nil;
	if (gMyInstance == nil)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}

#pragma mark Init

- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement {
	self = [super init];
	if (self == nil)
		return nil;
	
	if (RSLockCreateRecursive(&databaseLock) != 0)
		return nil;
	
	databaseKey = [[NSString stringWithFormat:@"%@_cachedDatabaseKey", databaseName] retain];
	refcountKey = [[NSString stringWithFormat:@"%@_cachedRefCountKey", databaseName] retain];
	
	NSString *folderPath = RSCacheFolderForApp(YES);
	if (RSStringIsEmpty(folderPath))
		return nil;
	databaseFilePath = [[folderPath stringByAppendingPathComponent:RSGoogleMetadataCacheFileName] retain];
	if (RSStringIsEmpty(databaseFilePath))
		return nil;
	NSDate *dateLastDeletedCache = [[NSUserDefaults standardUserDefaults] objectForKey:RSGoogleMetadataCacheDeleteDateKey];
	if (dateLastDeletedCache == nil)
		dateLastDeletedCache = [NSDate distantPast];
	NSDate *dateToDeleteCache = [dateLastDeletedCache addTimeInterval:60 * 60 * 24 * 7 * 2]; //two weeks
	if ([dateToDeleteCache earlierDate:[NSDate date]] == dateToDeleteCache) {
		RSFileDelete(databaseFilePath);
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:RSGoogleMetadataCacheDeleteDateKey];
	}
	[self ensureDatabaseFileExists:createTableStatement];
	
	return self;
}


- (id)init {
	self = [self initWithDatabaseFileName:RSGoogleMetadataCacheFileName createTableStatement:@"CREATE TABLE lockedRead (shortItemID TEXT UNIQUE);"];
	if (self == nil)
		return nil;
	[[self database] executeUpdate:@"CREATE TABLE feedIDs (shortItemID TEXT UNIQUE, longFeedID TEXT);"];
	[[self database] executeUpdate:@"CREATE TABLE downloaded (shortItemID TEXT UNIQUE);"];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	pthread_mutex_destroy(&databaseLock);	
	[super dealloc];
}


#pragma mark Updates

- (void)addLockedReadGoogleItemID:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleItemID))
		return;
	googleItemID = RSGoogleReaderShortItemIDForLongItemID(googleItemID);
	pthread_mutex_lock(&databaseLock);
	[[self database] executeUpdate:@"insert or replace into lockedRead (shortItemID) values (?);", googleItemID];
	pthread_mutex_unlock(&databaseLock);
}


- (void)addLockedReadGoogleItemIDsInArray:(NSArray *)googleItemIDs {
	if (RSIsEmpty(googleItemIDs))
		return;
	pthread_mutex_lock(&databaseLock);
	[self beginTransaction];
	for (NSString *oneGoogleItemID in googleItemIDs)
		[self addLockedReadGoogleItemID:oneGoogleItemID];
	[self endTransaction];
	pthread_mutex_unlock(&databaseLock);
}


- (void)runAddLockedReadGoogleItemIDsAsOperation:(NSArray *)googleItemIDs {
	NSInvocationOperation *addLockedReadGoogleItemIDsOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addLockedReadGoogleItemIDsInArray:) object:googleItemIDs] autorelease];
	[[RSOperationController sharedController] addOperation:addLockedReadGoogleItemIDsOperation];																  
}


- (void)saveLockedReadGoogleItemIDs:(NSArray *)googleItemIDs {
	[self runAddLockedReadGoogleItemIDsAsOperation:googleItemIDs];
}


- (void)addDownloadedItemID:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleItemID))
		return;
	googleItemID = RSGoogleReaderShortItemIDForLongItemID(googleItemID);
	pthread_mutex_lock(&databaseLock);
	[[self database] executeUpdate:@"insert or replace into downloaded (shortItemID) values (?);", googleItemID];
	pthread_mutex_unlock(&databaseLock);
}


- (void)addDownloadedItemIDsInArray:(NSArray *)googleItemIDs {
	if (RSIsEmpty(googleItemIDs))
		return;
	pthread_mutex_lock(&databaseLock);
	[self beginTransaction];
	for (NSString *oneGoogleItemID in googleItemIDs)
		[self addDownloadedItemID:oneGoogleItemID];
	[self endTransaction];
	pthread_mutex_unlock(&databaseLock);
}


- (void)runAddDownloadedGoogleItemIDsAsOperation:(NSArray *)googleItemIDs {
	NSInvocationOperation *addDownloadedGoogleItemIDsOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addDownloadedItemIDsInArray:) object:googleItemIDs] autorelease];
	[[RSOperationController sharedController] addOperation:addDownloadedGoogleItemIDsOperation];																  
}


- (void)saveDownloadedGoogleItemIDs:(NSArray *)googleItemIDs {
	[self runAddDownloadedGoogleItemIDsAsOperation:googleItemIDs];
}


- (void)mapFeedID:(NSString *)googleFeedID googleItemID:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleFeedID) || RSStringIsEmpty(googleItemID))
		return;
	googleItemID = RSGoogleReaderShortItemIDForLongItemID(googleItemID);
	pthread_mutex_lock(&databaseLock);
	[[self database] executeUpdate:@"insert or replace into feedIDs (shortItemID, longFeedID) values (?, ?);", googleItemID, googleFeedID];
	pthread_mutex_unlock(&databaseLock);
}


#pragma mark Queries

- (BOOL)googleItemIDIsLockedRead:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleItemID))
		return NO;
	
	googleItemID = RSGoogleReaderShortItemIDForLongItemID(googleItemID);
	BOOL isLockedRead = NO;
	
	pthread_mutex_lock(&databaseLock);
	FMResultSet *rs = [[self database] executeQuery:@"select 1 in lockedRead where shortItemID = ? limit 1;", googleItemID];
	if (rs && [rs next])
		isLockedRead = YES;
	[rs close];
	pthread_mutex_unlock(&databaseLock);
	
	return isLockedRead;
}


- (BOOL)googleItemIDHasBeenDownloaded:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleItemID))
		return NO;
	
	googleItemID = RSGoogleReaderShortItemIDForLongItemID(googleItemID);
	BOOL downloaded = NO;
	
	pthread_mutex_lock(&databaseLock);
	FMResultSet *rs = [[self database] executeQuery:@"select 1 in downloaded where shortItemID = ? limit 1;", googleItemID];
	if (rs && [rs next])
		downloaded = YES;
	[rs close];
	pthread_mutex_unlock(&databaseLock);
	
	return downloaded;
}


- (NSString *)feedIDForGoogleItemID:(NSString *)googleItemID {
	if (RSStringIsEmpty(googleItemID))
		return nil;
	googleItemID = RSGoogleReaderShortItemIDForLongItemID(googleItemID);
	NSString *longFeedID = nil;
	
	pthread_mutex_lock(&databaseLock);
	FMResultSet *rs = [[self database] executeQuery:@"select longFeedID in feedIDs where shortItemID = ? limit 1;", googleItemID];
	if (rs && [rs next])
		longFeedID = [rs stringForColumnIndex:0];
	[rs close];
	pthread_mutex_unlock(&databaseLock);
	
	return longFeedID;
}


#pragma mark Sets - Removing Items

- (NSSet *)setWithSQLQuery:(NSString *)sqlQuery columnIndex:(NSInteger)columnIndex {

	NSMutableSet *aSet = [NSMutableSet set];
	
	pthread_mutex_lock(&databaseLock);
	[self beginTransaction];

	FMResultSet *rs = [[self database] executeQuery:sqlQuery];	
	while (rs && [rs next])
		[aSet rs_addObject:[rs stringForColumnIndex:(int)columnIndex]];	
	[rs close];
	
	[self endTransaction];
	pthread_mutex_unlock(&databaseLock);
	
	return aSet;
}


- (NSString *)partialSQLStringWithValuesSet:(NSSet *)values {
	
	NSUInteger numberOfValues = [values count];
	NSUInteger indexOfValue = 0;
	NSMutableString *sql = [NSMutableString stringWithString:@""];
	
	for (NSString *oneString in values) {		
		[sql appendString:@"'"];
		[sql appendString:oneString];
		[sql appendString:@"'"];
		if (indexOfValue < numberOfValues - 1)
			[sql appendString:@", "];
		indexOfValue++;
	}
	
	return sql;
}


- (NSString *)SQLStringWithStart:(NSString *)start valuesSet:(NSSet *)values {
	if (RSStringIsEmpty(start) || RSIsEmpty(values))
		return nil;	
	NSMutableString *sql = [NSMutableString stringWithString:start];
	NSString *valuesAsSQL = [self partialSQLStringWithValuesSet:values];
	if (RSStringIsEmpty(valuesAsSQL))
		return nil;
	[sql appendString:valuesAsSQL];
	[sql appendString:@");"];
	return sql;
}


- (void)removeItemsFromSet:(NSMutableSet *)aSet withSQLQuery:(NSString *)sqlQuery {
	if (RSStringIsEmpty(sqlQuery))
		return;
	NSSet *fetchedItems = [self setWithSQLQuery:sqlQuery columnIndex:0];
	if (!RSIsEmpty(fetchedItems))
		[aSet minusSet:fetchedItems];
}


- (void)removeLockedItemsFromSet:(NSMutableSet *)shortItemIDs {
	NSString *sql = [self SQLStringWithStart:@"select shortItemID from lockedRead where shortItemID in (" valuesSet:shortItemIDs];
	[self removeItemsFromSet:shortItemIDs withSQLQuery:sql];
}


- (void)removeDownloadedItemsFromSet:(NSMutableSet *)shortItemIDs {
	NSString *sql = [self SQLStringWithStart:@"select shortItemID from downloaded where shortItemID in (" valuesSet:shortItemIDs];
	[self removeItemsFromSet:shortItemIDs withSQLQuery:sql];
}


- (void)removeLockedAndDownloadedItemsFromSet:(NSMutableSet *)shortItemIDs {
	[self removeLockedItemsFromSet:shortItemIDs];
	[self removeDownloadedItemsFromSet:shortItemIDs];
}


@end
