//
//  NNWDownloadsSQLite3DatabaseController.m
//  NetNewsWire
//
//  Created by Brent Simmons on 4/2/08.
//  Copyright 2008 NewsGator Technologies, Inc. All rights reserved.
//


#import "RSDownloadsDatabase.h"
#import "FMDatabase.h"
#import "RSFoundationExtras.h"


//TODO: vacuum periodically

@interface RSDownloadsDatabase ()

+ (RSDownloadsDatabase *)sharedController;

- (void)addURLString:(NSString *)urlString;
- (void)removeURLString:(NSString *)urlString;
- (BOOL)didDownloadURLString:(NSString *)urlString;

@end


@implementation RSDownloadsDatabase


#pragma mark Class methods

+ (RSDownloadsDatabase *)sharedController {	
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
	}


#pragma mark Init

- (id)init {
	self = [super initWithDatabaseFileName:@"FileDownloads.sqlite3" createTableStatement:@"CREATE TABLE downloads (url TEXT UNIQUE);"];
	if (self == nil)
		return nil;
	initLockOrExit(&databaseLock, @"Error creating RSDownloadsDatabase lock.");
	return self;
	}


#pragma mark Updates

- (void)addURLString:(NSString *)urlString {
	if (RSIsEmpty(urlString))
		return;
	lockOrExit(&databaseLock, @"Error locking RSDownloadsDatabase lock.");
	[[self database] executeUpdate:@"insert or replace into downloads (url) values (?);", urlString];
	unlockOrExit(&databaseLock, @"Error unlocking RSDownloadsDatabase lock.");
	}
	

- (void)removeURLString:(NSString *)urlString {
	if (RSIsEmpty(urlString))
		return;
	lockOrExit(&databaseLock, @"Error locking RSDownloadsDatabase lock.");
	[[self database] executeUpdate:@"delete from downloads where url = ?;", urlString];
	unlockOrExit(&databaseLock, @"Error unlocking RSDownloadsDatabase lock.");
}
	

#pragma mark Queries

- (BOOL)didDownloadURLString:(NSString *)urlString {
	if (RSIsEmpty(urlString))
		return NO;
	BOOL success = NO;
	lockOrExit(&databaseLock, @"Error locking RSDownloadsDatabase lock.");
	FMResultSet *rs = [[self database] executeQuery:@"select 1 from downloads where url = ? limit 1;", urlString];
	success = [rs hasAnotherRow];
	[rs close];
	unlockOrExit(&databaseLock, @"Error unlocking RSDownloadsDatabase lock.");
	return success;	
	}


@end

#pragma mark -
#pragma mark C

/*Use these*/

void RSDownloadsDatabaseAddURL(NSString *url) {
	[[RSDownloadsDatabase sharedController] addURLString:url];
}


void RSDownloadsDatabaseRemoveURL(NSString *url) {
	[[RSDownloadsDatabase sharedController] removeURLString:url];
}


BOOL RSDownloadsDatabaseDidDownloadURL(NSString *url) {
	return [[RSDownloadsDatabase sharedController] didDownloadURLString:url];
}

