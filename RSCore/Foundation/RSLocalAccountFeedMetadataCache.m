//
//  RSLocalAccountFeedMetadataCache.m
//  nnw
//
//  Created by Brent Simmons on 12/17/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSLocalAccountFeedMetadataCache.h"
#import "FMDatabase.h"
#import "RSDownloadConstants.h"
#import "RSFileUtilities.h"
#import "RSOperation.h"
#import "RSOperationController.h"


static NSString *RSLocalAccountFeedMetadataCacheFileName = @"LocalAccountMetadataCache.sqlite3";
static NSString *RSLocalAccountFeedMetadataCacheDeleteDateKey = @"dateLastDeletedLocalAccountMetadataCache";



@interface RSDeleteFeedInfoOperation : RSOperation {
@private
	NSURL *feedURL;
}

@property (nonatomic, retain) NSURL *feedURL;

- (id)initWithFeedURL:(NSURL *)aFeedURL;

@end


#pragma mark -


@interface RSSaveConditionalGetInfoOperation : RSOperation {
@private
	RSHTTPConditionalGetInfo *conditionalGetInfo;
	NSURL *feedURL;
}

@property (nonatomic, retain) RSHTTPConditionalGetInfo *conditionalGetInfo;
@property (nonatomic, retain) NSURL *feedURL;

- (id)initWithConditionalGetInfo:(RSHTTPConditionalGetInfo *)someConditionalGetInfo feedURL:(NSURL *)aFeedURL;

@end


#pragma mark -


@interface RSSaveFeedContentHashOperation : RSOperation {
@private
	NSData *feedContentHash;
	NSURL *feedURL;	
}

@property (nonatomic, retain) NSData *feedContentHash;
@property (nonatomic, retain) NSURL *feedURL;

- (id)initWithFeedContentHash:(NSData *)aFeedContentHash feedURL:(NSURL *)aFeedURL;

@end


#pragma mark -


@implementation RSLocalAccountFeedMetadataCache


#pragma mark Class Methods

+ (RSLocalAccountFeedMetadataCache *)sharedCache {
	static RSLocalAccountFeedMetadataCache *gMyInstance = nil;
	if (gMyInstance == nil)
		gMyInstance = [[self alloc] init];
	return gMyInstance;	
}


#pragma mark Init

- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement {
	self = [super init];
	if (self == nil)
		return nil;
	
	if (RSLockCreate(&databaseLock) != 0)
		return nil;
	
	databaseKey = [[NSString stringWithFormat:@"%@_cachedDatabaseKey", databaseName] retain];
	refcountKey = [[NSString stringWithFormat:@"%@_cachedRefCountKey", databaseName] retain];
	
	NSString *folderPath = rs_app_delegate.pathToCacheFolder;//RSCacheFolderForApp(YES);
	if (RSStringIsEmpty(folderPath))
		return nil;
	databaseFilePath = [[folderPath stringByAppendingPathComponent:RSLocalAccountFeedMetadataCacheFileName] retain];
	if (RSStringIsEmpty(databaseFilePath))
		return nil;
	NSDate *dateLastDeletedCache = [[NSUserDefaults standardUserDefaults] objectForKey:RSLocalAccountFeedMetadataCacheDeleteDateKey];
	if (dateLastDeletedCache == nil)
		dateLastDeletedCache = [NSDate distantPast];
	NSDate *dateToDeleteCache = [dateLastDeletedCache dateByAddingTimeInterval:60 * 60 * 24 * 1]; //one day
	if ([dateToDeleteCache earlierDate:[NSDate date]] == dateToDeleteCache) {
		RSFileDelete(databaseFilePath);
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:RSLocalAccountFeedMetadataCacheDeleteDateKey];
	}
	[self ensureDatabaseFileExists:createTableStatement];
	
	return self;
}


- (id)init {
	self = [self initWithDatabaseFileName:RSLocalAccountFeedMetadataCacheFileName createTableStatement:@"CREATE TABLE conditionalGetInfo (URL TEXT UNIQUE, etag TEXT, lastModified TEXT);"];
	if (self == nil)
		return nil;
	[[self database] executeUpdate:@"CREATE TABLE feedContentHash (URL TEXT UNIQUE, hash BLOB);"];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	RSLockDestroy(&databaseLock);
	[super dealloc];
}


#pragma mark Public API

- (RSHTTPConditionalGetInfo *)conditionalGetInfoForFeedURL:(NSURL *)feedURL {
	
	NSParameterAssert(feedURL != nil);
	NSString *urlString = [feedURL absoluteString];
	if (RSStringIsEmpty(urlString))
		return nil;
	
	RSHTTPConditionalGetInfo *conditionalGetInfo = nil;
	
	RSLockLock(&databaseLock);
	
	FMResultSet *rs = [[self database] executeQuery:@"select etag, lastModified from conditionalGetInfo where URL = ? limit 1;", urlString];
	if (rs && [rs next])
		conditionalGetInfo = [RSHTTPConditionalGetInfo conditionalGetInfoWithEtagResponse:[rs stringForColumnIndex:0] lastModifiedResponse:[rs stringForColumnIndex:1]];
	[rs close];
	
	RSLockUnlock(&databaseLock);
	return conditionalGetInfo;
}


- (void)setConditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo forFeedURL:(NSURL *)feedURL {
	RSSaveConditionalGetInfoOperation *saveConditionalGetInfoOperation = [[[RSSaveConditionalGetInfoOperation alloc] initWithConditionalGetInfo:conditionalGetInfo feedURL:feedURL] autorelease];
	[saveConditionalGetInfoOperation setQueuePriority:NSOperationQueuePriorityVeryLow];
	[[RSOperationController sharedController] addOperation:saveConditionalGetInfoOperation];
}


- (void)storeConditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo feedURL:(NSURL *)feedURL {
	
	/*Called from operation running as very low priority background operation.*/
	
	NSParameterAssert(feedURL != nil);
	NSString *urlString = [feedURL absoluteString];
	if (RSStringIsEmpty(urlString))
		return;

	NSString *etag = conditionalGetInfo.httpResponseEtag;
	NSString *lastModified = conditionalGetInfo.httpResponseLastModified;
	
	RSLockLock(&databaseLock);
	[[self database] executeUpdate:@"insert or replace into conditionalGetInfo (URL, etag, lastModified) values (?, ?, ?)", urlString, etag ? etag : @"", lastModified ? lastModified : @""];
	RSLockUnlock(&databaseLock);
}


- (NSData *)contentHashForFeedURL:(NSURL *)feedURL {
	
	NSParameterAssert(feedURL != nil);
	NSString *urlString = [feedURL absoluteString];
	if (RSStringIsEmpty(urlString))
		return nil;
	
	NSData *feedContentHash = nil;
	
	RSLockLock(&databaseLock);
	
	FMResultSet *rs = [[self database] executeQuery:@"select hash from feedContentHash where URL = ? limit 1;", urlString];
	if (rs && [rs next])
		feedContentHash = [rs dataForColumnIndex:0];
	[rs close];
	
	RSLockUnlock(&databaseLock);
	return feedContentHash;	
}


- (void)setContentHash:(NSData *)contentHash forFeedURL:(NSURL *)feedURL {
	RSSaveFeedContentHashOperation *saveFeedContentHashOperation = [[[RSSaveFeedContentHashOperation alloc] initWithFeedContentHash:contentHash feedURL:feedURL] autorelease];
	[saveFeedContentHashOperation setQueuePriority:NSOperationQueuePriorityVeryLow];
	[[RSOperationController sharedController] addOperation:saveFeedContentHashOperation];
}


- (void)storeContentHash:(NSData *)feedContentHash feedURL:(NSURL *)feedURL {
	
	/*Called from operation running as very low priority background operation.*/
	
	NSParameterAssert(feedURL != nil);
	NSString *urlString = [feedURL absoluteString];
	if (RSStringIsEmpty(urlString))
		return;
	if (feedContentHash == nil)
		feedContentHash = [NSData data];
	
	RSLockLock(&databaseLock);
	[[self database] executeUpdate:@"insert or replace into feedContentHash (URL, hash) values (?, ?)", urlString, feedContentHash];
	RSLockUnlock(&databaseLock);
}


- (void)deleteInfoForFeedURL:(NSURL *)feedURL {
	NSParameterAssert(feedURL != nil);
	RSDeleteFeedInfoOperation *deleteFeedInfoOperation = [[[RSDeleteFeedInfoOperation alloc] initWithFeedURL:feedURL] autorelease];
	[deleteFeedInfoOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	[[RSOperationController sharedController] addOperation:deleteFeedInfoOperation];
}


- (void)deleteAllInfoForFeedURL:(NSURL *)feedURL {
	/*Called from operation running as very high priority background operation.*/
	NSParameterAssert(feedURL != nil);
	NSString *urlString = [feedURL absoluteString];
	if (RSStringIsEmpty(urlString))
		return;
	RSLockLock(&databaseLock);
	[[self database] executeUpdate:@"delete from feedContentHash where URL = ?;", urlString];
	[[self database] executeUpdate:@"delete from conditionalGetInfo where URL = ?;", urlString];
	RSLockUnlock(&databaseLock);
}


@end


#pragma mark -

@implementation RSDeleteFeedInfoOperation

@synthesize feedURL;

#pragma mark Init

- (id)initWithFeedURL:(NSURL *)aFeedURL {
	self = [super initWithDelegate:nil callbackSelector:nil];
	if (self == nil)
		return nil;
	feedURL = [aFeedURL retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[feedURL release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)main {
	if (![self isCancelled])
		[[RSLocalAccountFeedMetadataCache sharedCache] deleteAllInfoForFeedURL:self.feedURL];
	[super main];
}


@end


#pragma mark -

@implementation RSSaveConditionalGetInfoOperation

@synthesize conditionalGetInfo;
@synthesize feedURL;

#pragma mark Init

- (id)initWithConditionalGetInfo:(RSHTTPConditionalGetInfo *)someConditionalGetInfo feedURL:(NSURL *)aFeedURL {
	self = [super initWithDelegate:nil callbackSelector:nil];
	if (self == nil)
		return nil;
	conditionalGetInfo = [someConditionalGetInfo retain];
	feedURL = [aFeedURL retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[conditionalGetInfo release];
	[feedURL release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)main {
	if (![self isCancelled])
		[[RSLocalAccountFeedMetadataCache sharedCache] storeConditionalGetInfo:self.conditionalGetInfo feedURL:self.feedURL];
	[super main];
}

@end


#pragma mark -

@implementation RSSaveFeedContentHashOperation

@synthesize feedContentHash;
@synthesize feedURL;	

- (id)initWithFeedContentHash:(NSData *)aFeedContentHash feedURL:(NSURL *)aFeedURL {
	self = [super initWithDelegate:nil callbackSelector:nil];
	if (self == nil)
		return nil;
	feedContentHash = [aFeedContentHash retain];
	feedURL = [aFeedURL retain];
	return self;	
}

#pragma mark Dealloc

- (void)dealloc {
	[feedContentHash release];
	[feedURL release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)main {
	if (![self isCancelled])
		[[RSLocalAccountFeedMetadataCache sharedCache] storeContentHash:self.feedContentHash feedURL:self.feedURL];
	[super main];
}



@end
