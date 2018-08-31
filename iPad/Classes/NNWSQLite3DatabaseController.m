//
//  NNWSQLite3DatabaseController.m
//  NetNewsWire
//
//  Created by Brent Simmons on 4/1/08.
//  Copyright 2008 NewsGator Technologies, Inc. All rights reserved.
//


#import "NNWSQLite3DatabaseController.h"
#import "FMDatabase+Extras.h"
#import "FMDatabase.h"


@interface NNWSQLite3DatabaseController (Forward)
- (void)_ensureDatabaseFileExists:(NSString *)createTableStatement;
@end


@implementation NNWSQLite3DatabaseController

#pragma mark Class Methods

+ (BOOL)databaseFileExistsOnDisk:(NSString *)databaseName {
	return [[NSFileManager defaultManager] fileExistsAtPath:RSApplicationSupportFile(databaseName)];
	}


#pragma mark Init

- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement {
	if (![super init])
		return nil;
	_databaseFilePath = [RSApplicationSupportFile(databaseName) retain];
	_databaseName = [databaseName retain];
	[self _ensureDatabaseFileExists:createTableStatement];
	return self;
	}
	

#pragma mark Setup

- (void)_ensureDatabaseFileExists:(NSString *)createTableStatement {
	if ([[NSFileManager defaultManager] fileExistsAtPath:_databaseFilePath])
		return;
	_databaseIsNew = YES;
	@synchronized(self) {
		[[self database] executeUpdate:createTableStatement];
		}
	}
	

#pragma mark Database

- (NSString *)_cachedDatabaseKey {
	return [NSString stringWithFormat:@"%@_cachedDatabaseKey", _databaseName];
	}


- (FMDatabase *)_createDatabase {
	FMDatabase *db = [FMDatabase openDatabaseWithPath:_databaseFilePath];
	[db setShouldCacheStatements:YES];
	[db setBusyRetryTimeout:10000];
	[db executeUpdate:@"PRAGMA synchronous = 0;"];
	return db;
	}
	
	
- (FMDatabase *)database {
	FMDatabase *db = [[[NSThread currentThread] threadDictionary] objectForKey:[self _cachedDatabaseKey]];
	if (db)
		return db;
	db = [self _createDatabase];
	if (db)
		[[[NSThread currentThread] threadDictionary] setObject:db forKey:[self _cachedDatabaseKey]];
	return db;
	}
	

- (void)newDatabase {
	FMDatabase *db = [self _createDatabase];
	if (db)
		[[[NSThread currentThread] threadDictionary] setObject:db forKey:[self _cachedDatabaseKey]];
	}
	

- (BOOL)databaseIsNew {
	return _databaseIsNew;
	}
	

#pragma mark Transactions

- (NSString *)_cachedRefCountKey {
	return [NSString stringWithFormat:@"%@_cachedRefCountKey", _databaseName];
	}


- (void)beginTransaction {
	@synchronized(self) {
		NSInteger transactionRefCount = [[[NSThread currentThread] threadDictionary] integerForKey:[self _cachedRefCountKey]];
		if (transactionRefCount < 0)
			transactionRefCount = 0;
		transactionRefCount++;
		[[[NSThread currentThread] threadDictionary] setInteger:transactionRefCount forKey:[self _cachedRefCountKey]];
		if (transactionRefCount == 1) {
			[[self database] beginTransaction];
			}	
		}
	}


- (void)endTransaction {
	@synchronized(self) {
		NSInteger transactionRefCount = [[[NSThread currentThread] threadDictionary] integerForKey:[self _cachedRefCountKey]];
		transactionRefCount--;
		if (transactionRefCount < 1)
			transactionRefCount = 0;
		[[[NSThread currentThread] threadDictionary] setInteger:transactionRefCount forKey:[self _cachedRefCountKey]];
		if (transactionRefCount == 0) {
			[[self database] commit];
			}
		}
	}


@end
