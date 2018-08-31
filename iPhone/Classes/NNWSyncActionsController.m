//
//  NNWGoogleDatabase.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/18/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWSyncActionsController.h"
#import "FMDatabase+Extras.h"
#import "FMDatabase.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWGoogleAPI.h"
#import "NNWHTTPResponse.h"


#define kNNWGoogleUnstarred 0
#define kNNWGoogleStarred 1

NSString *_NNWOldGoogleFolderName = @"oldGoogleFolderName";
NSString *_NNWNewGoogleFolderName = @"newGoogleFolderName";
NSString *_NNWGoogleFolderName = @"googleFolderName";

@interface NNWSyncActionsController ()
@property (nonatomic, retain) NSThread *backgroundThread;
@property (nonatomic, retain) NSTimer *sendToGoogleTimer;
@property (assign, readwrite) BOOL hasPendingMarkReadChanges;
@property (assign, readwrite) BOOL hasPendingMarkStarredChanges;
- (void)_deleteChangeIDs:(NSArray *)changeIDs fromTable:(NSString *)tableName;
@end

@implementation NNWSyncActionsController

@synthesize backgroundThread = _backgroundThread, sendToGoogleTimer = _sendToGoogleTimer, hasPendingMarkReadChanges = _hasPendingMarkReadChanges, hasPendingMarkStarredChanges = _hasPendingMarkStarredChanges;

#pragma mark Class methods

+ (NNWSyncActionsController *)sharedController {	
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


static NSString *NNWPrefixForGoogleReaderGuid = @"tag:google.com,";
static NSString *NNWGoogleReaderGuidMustContain = @"reader/item/";

+ (BOOL)guidIsFromGoogleReader:(NSString *)guid {
	return [guid hasPrefix:NNWPrefixForGoogleReaderGuid] && [guid caseSensitiveContains:NNWGoogleReaderGuidMustContain];
}


#pragma mark Init

- (id)init {
	self = [super initWithDatabaseFileName:@"SyncActions.sqlite3" createTableStatement:@"CREATE TABLE readActions (changeID INTEGER PRIMARY KEY AUTOINCREMENT, googleItemID TEXT UNIQUE, googleFeedID TEXT, changeDate DATE, status INTEGER);"];
	if (!self)
		return nil;
	[[self database] executeUpdate:@"CREATE TABLE if not exists starActions (changeID INTEGER PRIMARY KEY AUTOINCREMENT, googleItemID TEXT UNIQUE, googleFeedID TEXT, changeDate DATE, status INTEGER);"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDidMarkOneOrMoreNewsItemsAsRead:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDidMarkOneOrMoreNewsItemsAsStarred:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsStarredNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDidMarkOneOrMoreNewsItemsAsUnstarred:) name:NNWUserDidMarkOneOrMoreItemsInFeedAsUnstarredNotification object:nil];
	[self performSelectorOnMainThread:@selector(_start) withObject:nil waitUntilDone:NO];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_backgroundThread release];
	[super dealloc];
}


#pragma mark NNWSQLite3DatabaseController

- (FMDatabase *)_createDatabase {
	FMDatabase *db = [FMDatabase openDatabaseWithPath:_databaseFilePath];
	[db executeUpdate:@"PRAGMA synchronous = 0;"];
	[db setBusyRetryTimeout:100];
	[db setShouldCacheStatements:YES];
	return db;
}


- (void)beginTransaction {
	;
}


- (void)endTransaction {
	;
}


#pragma mark Thread

- (void)_start {
	[NSThread detachNewThreadSelector:@selector(_runThread) toTarget:self withObject:nil];
}


- (void)_googleSyncActionsTimerDidFireAfterAYear:(NSTimer *)timer {
	;
}


- (void)_runThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.backgroundThread = [NSThread currentThread];
	NSTimer *longTimer = [NSTimer timerWithTimeInterval:60 * 60 * 24 * 7 * 52 target:self selector:@selector(_googleSyncActionsTimerDidFireAfterAYear:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:longTimer forMode:NSDefaultRunLoopMode];
	NSTimer *startupTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(_sendNextChangesToGoogle) userInfo:nil repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:startupTimer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] run];
	[pool release];
}


#pragma mark Pending Changes - for Subscriptions Syncing

- (BOOL)hasPendingSubscriptionChanges {
	BOOL hasChanges = NO;
	@synchronized(self) {
		FMResultSet *rs = [[self database] executeQuery:@"select * from subscribeActions limit 1;"];
		hasChanges = rs && [rs next];
		[rs close];
	}
	return hasChanges;
}


#pragma mark Notifications

- (void)handleUserDidMarkOneOrMoreNewsItemsAsRead:(NSNotification *)note {
	NSArray *newsItems = [[note userInfo] objectForKey:RSNewsItemsKey];
	if (!RSIsEmpty(newsItems))
		[self performSelector:@selector(saveOneOrMoreNewsItemsMarkedRead:) onThread:self.backgroundThread withObject:newsItems waitUntilDone:NO];
}


- (void)handleUserDidMarkOneOrMoreNewsItemsAsStarred:(NSNotification *)note {
	NSArray *newsItems = [[note userInfo] objectForKey:RSNewsItemsKey];
	if (!RSIsEmpty(newsItems))
		[self performSelector:@selector(saveOneOrMoreNewsItemsMarkedStarred:) onThread:self.backgroundThread withObject:newsItems waitUntilDone:NO];	
}


- (void)handleUserDidMarkOneOrMoreNewsItemsAsUnstarred:(NSNotification *)note {
	NSArray *newsItems = [[note userInfo] objectForKey:RSNewsItemsKey];
	if (!RSIsEmpty(newsItems))
		[self performSelector:@selector(saveOneOrMoreNewsItemsMarkedUnstarred:) onThread:self.backgroundThread withObject:newsItems waitUntilDone:NO];		
}


#pragma mark Timer

- (void)_scheduleSendToGoogleTimer {
	if (self.sendToGoogleTimer)
		[self.sendToGoogleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
	else
		self.sendToGoogleTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(_sendNextChangesToGoogle) userInfo:nil repeats:NO];
}


#pragma mark Saving Action to Database

- (void)_saveGoogleNewsItem:(NSDictionary *)newsItemDict status:(BOOL)status tableName:(NSString *)tableName {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *googleItemID = [newsItemDict objectForKey:RSDataGoogleID];
	NSString *googleFeedID = [newsItemDict objectForKey:RSDataGoogleFeedID];
	NSString *updateString = [NSString stringWithFormat:@"insert or replace into %@ (googleItemID, googleFeedID, changeDate, status) values (?, ?, ?, ?);", tableName];
	if (!RSStringIsEmpty(googleItemID) && !RSStringIsEmpty(googleFeedID)) {
		@synchronized(self) {
			[[self database] executeUpdate:updateString, googleItemID, googleFeedID, [NSDate date], [NSNumber numberWithBool:status]];
		}
		[self _scheduleSendToGoogleTimer];
	}
	[pool drain];	
}


- (void)saveOneOrMoreNewsItemStatusChanges:(NSArray *)newsItems status:(BOOL)status tableName:(NSString *)tableName {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	for (NSDictionary *oneNewsItem in newsItems)
		[self _saveGoogleNewsItem:oneNewsItem status:status tableName:tableName];
	[pool drain];
	
}


- (void)saveOneOrMoreNewsItemsMarkedRead:(NSArray *)newsItems {
	[self saveOneOrMoreNewsItemStatusChanges:newsItems status:YES tableName:@"readActions"];
	self.hasPendingMarkReadChanges = YES;
}


- (void)saveOneOrMoreNewsItemsMarkedUnstarred:(NSArray *)newsItems {
	[self saveOneOrMoreNewsItemStatusChanges:newsItems status:NO tableName:@"starActions"];
	self.hasPendingMarkStarredChanges = YES;	
}


- (void)saveOneOrMoreNewsItemsMarkedStarred:(NSArray *)newsItems {
	[self saveOneOrMoreNewsItemStatusChanges:newsItems status:YES tableName:@"starActions"];
	self.hasPendingMarkStarredChanges = YES;
}


#pragma mark Send to Google



- (NSDictionary *)_nextStarChange {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	@synchronized(self) {
		FMResultSet *rs = [[self database] executeQuery:@"select * from starActions order by changeDate ASC limit 1;"];
		if (!rs || ![rs next]) {
			[rs close];
			return nil;
		}
		[d safeSetObject:[rs stringForColumn:@"changeID"] forKey:@"changeID"];
		[d safeSetObject:[rs stringForColumn:@"googleItemID"] forKey:NNWGoogleItemIDsParameterName];
		[d safeSetObject:[rs stringForColumn:@"googleFeedID"] forKey:NNWGoogleFeedIDsParameterName];
		[d safeSetObject:[NSNumber numberWithInteger:[rs intForColumn:@"status"]] forKey:@"status"];
		[rs close];
	}
	return d;		
}


- (NSDictionary *)_nextChangesForReadStatus:(BOOL)read {
	/*Two arrays in dictionary: changeIDs and googleItemIDs*/
	NSMutableDictionary *changes = [NSMutableDictionary dictionaryWithCapacity:2];
	NSMutableArray *changeIDs = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray *googleItemIDs = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray *googleFeedIDs = [NSMutableArray arrayWithCapacity:10];
	[changes setObject:changeIDs forKey:@"changeIDs"];
	[changes setObject:googleItemIDs forKey:NNWGoogleItemIDsParameterName];
	[changes setObject:googleFeedIDs forKey:NNWGoogleFeedIDsParameterName];
	NSMutableArray *badItemsToDelete = [NSMutableArray array]; /*shouldn't happen*/
	@synchronized(self) {
		FMResultSet *rs = [[self database] executeQuery:@"select changeID, googleItemID, googleFeedID from readActions where status = ? order by changeDate ASC limit 10;", [NSNumber numberWithBool:read]];
		if (!rs)
			return nil;
		while ([rs next]) {
			NSString *guid = [rs stringForColumnIndex:1];
			NSString *googleFeedID = [rs stringForColumnIndex:2];
			if (RSStringIsEmpty(guid) || ![NNWSyncActionsController guidIsFromGoogleReader:guid] || RSStringIsEmpty(googleFeedID)) {
				[badItemsToDelete safeAddObject:[rs stringForColumnIndex:0]];
				continue;
			}
			[changeIDs addObject:[rs stringForColumnIndex:0]];
			[googleItemIDs addObject:guid];
			[googleFeedIDs addObject:googleFeedID];
		}
		[rs close];
	}
	if (!RSIsEmpty(badItemsToDelete))
		[self _deleteChangeIDs:badItemsToDelete fromTable:@"readActions"];
	return RSIsEmpty(googleItemIDs) ? nil : changes;		
}


- (NSDictionary *)_nextMarkedUnreadChanges {
	return [self _nextChangesForReadStatus:NO];
}


- (NSDictionary *)_nextChangeSet {
	NSDictionary *markReadChanges = [self _nextChangesForReadStatus:YES];
	if (RSIsEmpty(markReadChanges))
		self.hasPendingMarkReadChanges = NO;
	return markReadChanges;
}


- (BOOL)_sendChangesetToGoogle:(NSDictionary *)changes {
	NSInteger numberOfChanges = [[changes objectForKey:NNWGoogleItemIDsParameterName] count];
	NSString *statusMessage = @"Syncing read item change";
	if (numberOfChanges != 1)
		statusMessage = [NSString stringWithFormat:@"Syncing %d read item changes", numberOfChanges];
	[app_delegate sendStatusMessageDidBegin:statusMessage];
	NNWHTTPResponse *response = [NNWGoogleAPI markItemsRead:[changes objectForKey:NNWGoogleItemIDsParameterName] feedIDs:[changes objectForKey:NNWGoogleFeedIDsParameterName]];
	[app_delegate sendStatusMessageDidEnd:statusMessage];
	return response && (response.okResponse || response.statusCode == 400 || response.statusCode == 500);
}


- (void)_deleteChangeIDs:(NSArray *)changeIDs fromTable:(NSString *)tableName {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (!RSStringIsEmpty(tableName)) {
		NSString *s = [NSString stringWithFormat:@"delete from %@ where changeID = ?", tableName];
		@synchronized(self) {
			[self beginTransaction];
			for (NSString *oneChangeID in changeIDs)
				[[self database] executeUpdate:s, oneChangeID];
			[self endTransaction];
		}
	}
	[pool drain];
}


- (BOOL)tableHasPendingChanges:(NSString *)tableName {
	BOOL hasChanges = NO;
	@synchronized(self) {
		FMResultSet *rs = [[self database] executeQuery:[NSString stringWithFormat:@"select * from %@ limit 1;", tableName]];
		hasChanges = rs && [rs next];
		[rs close];
	}
	return hasChanges;
}


- (void)_deleteChangesetFromDatabase:(NSArray *)changeIDs {
	[self _deleteChangeIDs:changeIDs fromTable:@"readActions"];
}


- (BOOL)_sendStarChangeToGoogle:(NSDictionary *)change {
	NSString *googleID = [change objectForKey:NNWGoogleItemIDsParameterName];
	NSString *feedID = [change objectForKey:NNWGoogleFeedIDsParameterName];
	if (RSStringIsEmpty(googleID) || RSStringIsEmpty(feedID))
		return YES; /*so it gets deleted -- but this should never happen*/
	[app_delegate sendStatusMessageDidBegin:@"Syncing starred item"];
	NNWHTTPResponse *response = [NNWGoogleAPI updateNewsItem:googleID feedID:feedID starStatus:[change boolForKey:@"status"]];
	[app_delegate sendStatusMessageDidEnd:@"Syncing starred item"];
	return response && !response.networkError;
}


- (void)_sendNextChangesToGoogle {
	
	/*Grab a set of changes. If no changes, return.
	 Send changes to Google.
	 If successful, delete changes from database.
	 Then call this method again for the next changes.*/
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	BOOL didSendOneChange = NO;
	BOOL sendChangeDidSucceed = NO;
//	@try {

		NSDictionary *changeSet = [self _nextChangeSet];
		if (RSIsEmpty(changeSet))
			self.hasPendingMarkReadChanges = NO;
		else {
			didSendOneChange = YES;
			if ([self _sendChangesetToGoogle:changeSet]) {
				sendChangeDidSucceed = YES;
				[self _deleteChangesetFromDatabase:[changeSet objectForKey:@"changeIDs"]];
				self.hasPendingMarkReadChanges = [self tableHasPendingChanges:@"readActions"];
			}
		}


		if (!didSendOneChange) { /*Star/unstar*/
			NSDictionary *change = [self _nextStarChange];
			
			if (change) {
				//didSendOneChange = YES;
				if ([self _sendStarChangeToGoogle:change]) {
					sendChangeDidSucceed = YES;
					[self _deleteChangeIDs:[NSArray arrayWithObject:[change objectForKey:@"changeID"]] fromTable:@"starActions"];
				}
			}		
		}
		
//		}
	
//	@catch(id obj) {
//		;
//		NSLog(@"_sendNextChangesToGoogle error: %@", obj);
//		//[self performSelectorOnMainThread:@selector(_displayWeirdError:) withObject:obj waitUntilDone:NO];
//	}
	
	BOOL hasAnyPendingChanges = self.hasPendingMarkReadChanges || self.hasPendingMarkStarredChanges;
	if (sendChangeDidSucceed && hasAnyPendingChanges)
		[self performSelector:@selector(_sendNextChangesToGoogle) withObject:nil afterDelay:0.1];
	else if (hasAnyPendingChanges)
		[self performSelector:@selector(_sendNextChangesToGoogle) withObject:nil afterDelay:60];
		
	if (self.sendToGoogleTimer) {
		if ([self.sendToGoogleTimer isValid])
			[self.sendToGoogleTimer invalidate];
		self.sendToGoogleTimer = nil;
	}
	
	[pool drain];
}


@end
