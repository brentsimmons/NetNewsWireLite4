//
//  NNWDatabaseController.m
//  nnwiphone
//
//  Created by Brent Simmons on 10/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWDatabaseController.h"
#import "FMDatabase+Extras.h"
#import "FMDatabase.h"
#import "NNWAppDelegate.h"
#import "NNWNewsItemProxy.h"
#import "RSParsedGoogleUnreadCount.h"
#import "RSParsedNewsItem.h"


@interface NNWMostRecentItemSpecifier ()
@property (nonatomic, retain, readwrite) NSString *plainTextTitle;
@property (nonatomic, retain, readwrite) NSString *displayDate;
@end


@implementation NNWMostRecentItemSpecifier

@synthesize plainTextTitle, displayDate;

static NSString *NNWMostRecentItemSpecifierPlainTextTitleKey = @"plainTextTitle";
static NSString *NNWMostRecentItemSpecifierDisplayDateKey = @"displayDate";

- (void)encodeWithCoder:(NSCoder *)coder {
	if (plainTextTitle != nil)
		[coder encodeObject:plainTextTitle forKey:NNWMostRecentItemSpecifierPlainTextTitleKey];
	if (displayDate != nil)
		[coder encodeObject:displayDate forKey:NNWMostRecentItemSpecifierDisplayDateKey];
}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	plainTextTitle = [[coder decodeObjectForKey:NNWMostRecentItemSpecifierPlainTextTitleKey] retain];
	displayDate = [[coder decodeObjectForKey:NNWMostRecentItemSpecifierDisplayDateKey] retain];
	return self;
}


- (void)dealloc {
	[plainTextTitle release];
	[displayDate release];
	[super dealloc];
}

@end


#pragma mark Schema

/*
 CREATE TABLE newsItems (googleID TEXT UNIQUE, googleReadStateLocked INTEGER, read INTEGER, starred INTEGER, titleIsHTML INTEGER, title TEXT, plainTextTitle TEXT, link TEXT, permalink TEXT, pubDate DATE, xmlBaseURL TEXT, htmlText TEXT, preview TEXT, author TEXT, categories TEXT, enclosures BLOB, audioURL TEXT, movieURL TEXT, googleSourceID TEXT, googleSourceTitle TEXT, googleCrawlTimestamp DATE, ha BLOB);
 CREATE INDEX currentFeedsIndex on newsItems (googleSourceID, read, googleReadStateLocked, googleCrawlTimestamp);"];
 CREATE INDEX starredLockedTimestampIndex on newsItems (starred, googleReadStateLocked, googleCrawlTimestamp);"];
 CREATE INDEX haIndex on newsItems (ha);
 */


enum NNWNewsItemDataColumnIndex {
	NNWColumnIndexGoogleID,
	NNWColumnIndexGoogleReadStateLocked,
	NNWColumnIndexRead,
	NNWColumnIndexStarred,
	NNWColumnIndexTitleIsHTML,
	NNWColumnIndexTitle,
	NNWColumnIndexPlainTextTitle,
	NNWColumnIndexLink,
	NNWColumnIndexPermalink,
	NNWColumnIndexPubDate,
	NNWColumnIndexXMLBaseURL,
	NNWColumnIndexHTMLText,
	NNWColumnIndexPreview,
	NNWColumnIndexAuthor,
	NNWColumnIndexCategories,
	NNWColumnIndexEnclosures,
	NNWColumnIndexAudioURL,
	NNWColumnIndexMovieURL,
	NNWColumnIndexGoogleSourceID,
	NNWColumnIndexGoogleSourceTitle,
	NNWColumnIndexCrawlTimestamp,
	NNWColumnIndexThumbnailURL,
	NNWColumnIndexHa
};


@implementation NNWDatabaseController


#pragma mark Class Methods

+ (NNWDatabaseController *)sharedController {	
	static id gMyInstance = nil;
	if (gMyInstance == nil)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	self = [super initWithDatabaseFileName:@"NewsItems.sqlite3" createTableStatement:@"CREATE TABLE newsItems (googleID TEXT UNIQUE NOT NULL, googleReadStateLocked INTEGER, read INTEGER, starred INTEGER, titleIsHTML INTEGER, title TEXT, plainTextTitle TEXT, link TEXT, permalink TEXT, pubDate DATE, xmlBaseURL TEXT, htmlText TEXT, preview TEXT, author TEXT, categories TEXT, enclosures TEXT, audioURL TEXT, movieURL TEXT, googleSourceID TEXT, googleSourceTitle TEXT, googleCrawlTimestamp NUMERIC, thumbnailURL TEXT, ha BLOB);"];
	if (!self)
		return nil;
	[[self database] executeUpdate:@"CREATE INDEX if not exists currentFeedsIndex on newsItems (googleSourceID, read, googleReadStateLocked, googleCrawlTimestamp);"];
	[[self database] executeUpdate:@"CREATE INDEX if not exists starredLockedTimestampIndex on newsItems (starred, googleReadStateLocked, googleCrawlTimestamp);"];
	[[self database] executeUpdate:@"CREATE INDEX if not exists haIndex on newsItems (ha);"];
	[self performSelectorInBackground:@selector(deleteOldItems) withObject:nil];
	return self;
}


#pragma mark Database

static NSString *NNWDatabaseKey = @"NewsItemsDatabaseKey";

- (NSString *)_cachedDatabaseKey {
	return NNWDatabaseKey;
}


#pragma mark Feeds

static NSString *NNWGoogleFeedIDPrefix = @"feed/";

static BOOL NNWGoogleIDIsFeedID(NSString *googleID) {
	return [googleID isKindOfClass:[NSString class]] && !RSStringIsEmpty(googleID) && [googleID hasPrefix:NNWGoogleFeedIDPrefix];
}


#pragma mark News Items

static NSString *NNWCategoryArraySeparator = @" | ";
static NSString *NNWEmptyString = @"";
static NSString *NNWSingleSpaceString = @" ";

static NSString *NNWCategoryArrayToString(NSArray *categories) {
	if (RSIsEmpty(categories))
		return nil;
	NSMutableString *categoryString = [NSMutableString stringWithString:NNWEmptyString];
	for (NSString *oneCategory in categories) {
		if ([oneCategory caseSensitiveContains:NNWCategoryArraySeparator])
			oneCategory = RSStringReplaceAll(oneCategory, NNWCategoryArraySeparator, NNWSingleSpaceString);
		[categoryString appendString:oneCategory];
		[categoryString appendString:NNWCategoryArraySeparator];
	}
	return [NSString stripSuffix:categoryString suffix:NNWCategoryArraySeparator];
}


static NSData *NNWEnclosuresDictionaryToPlistData(NSArray *enclosures) {
	if (RSIsEmpty(enclosures))
		return nil;
	NSString *errorDescription = nil;
	return [NSPropertyListSerialization dataFromPropertyList:enclosures format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorDescription];
}


static NSString *NNWDatabaseUpdateSQLFormatString = @"insert or replace into newsItems (googleID, googleReadStateLocked, read, starred, titleIsHTML, title, plainTextTitle, link, permalink, pubDate, xmlBaseURL, htmlText, preview, author, categories, enclosures, audioURL, movieURL, googleSourceID, googleSourceTitle, googleCrawlTimestamp, thumbnailURL, ha) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

- (BOOL)saveNewsItem:(RSParsedNewsItem *)newsItem {
	if (RSStringIsEmpty(newsItem.guid) || RSStringIsEmpty(newsItem.googleSourceID))
		return NO; /*Bogus: shouldn't happen*/
	/*If item with same hash exists, don't bother to save.*/
	BOOL didSaveNewsItem = NO;
	@synchronized(self) {
		//[self beginTransaction];
		NSData *hashOfReadOnlyAttributes = newsItem.hashOfReadOnlyAttributes;
		if (hashOfReadOnlyAttributes == nil)
			return NO;
		FMResultSet *rs = [self.database executeQuery:@"select 1 from newsItems where ha == ? limit 1;", hashOfReadOnlyAttributes];
		BOOL foundExistingItem = rs && [rs next];
		[rs close];
		if (foundExistingItem)
			return NO; /*Didn't need to save*/
		
		NSString *title = newsItem.title;
		if (title == nil)
			title = RSEmptyString;
		NSString *plainTextTitle = newsItem.plainTextTitle;
		if (plainTextTitle == nil)
			plainTextTitle = RSEmptyString;
		NSString *link = newsItem.link;
		if (link == nil)
			link = RSEmptyString;
		NSString *permalink = newsItem.permalink;
		if (permalink == nil)
			permalink = RSEmptyString;
		NSDate *pubDate = newsItem.pubDate;
		if (pubDate == nil)
			pubDate = (id)RSEmptyString;
		NSString *xmlBaseURL = newsItem.xmlBaseURL;
		if (xmlBaseURL == nil)
			xmlBaseURL = RSEmptyString;
		NSString *htmlText = newsItem.htmlText;
		if (htmlText == nil)
			htmlText = RSEmptyString;
		NSString *preview = nil;//newsItem.preview;
		if (preview == nil)
			preview = RSEmptyString;
		NSString *author = newsItem.author;
		if (author == nil)
			author = RSEmptyString;
		NSString *categories = NNWCategoryArrayToString(newsItem.categories);
		if (categories == nil)
			categories = RSEmptyString;
		NSData *enclosures = NNWEnclosuresDictionaryToPlistData(newsItem.enclosures);
		if (enclosures == nil)
			enclosures = (id)RSEmptyString;
		NSString *googleSourceID = newsItem.googleSourceID;
		if (googleSourceID == nil)
			return NO; /*Required*/
		NSString *sourceTitle = newsItem.sourceTitle;
		if (sourceTitle == nil)
			sourceTitle = RSEmptyString;
		NSDate *googleCrawlTimestamp = newsItem.googleCrawlTimestamp;
		if (googleCrawlTimestamp == nil)
			return NO; /*Required*/
		NSString *thumbnailURL = newsItem.thumbnailURL;
		if (thumbnailURL == nil)
			thumbnailURL = RSEmptyString;
		didSaveNewsItem = [self.database executeUpdate:NNWDatabaseUpdateSQLFormatString, newsItem.guid, [NSNumber numberWithBool:newsItem.isGoogleReadStateLocked], [NSNumber numberWithBool:newsItem.read], [NSNumber numberWithBool:newsItem.starred], [NSNumber numberWithBool:newsItem.titleIsHTML], title, plainTextTitle, link, permalink, pubDate, xmlBaseURL, htmlText, preview, author, categories, enclosures, RSEmptyString /*audioURL*/, RSEmptyString /*movieURL*/, googleSourceID, sourceTitle, googleCrawlTimestamp, thumbnailURL, hashOfReadOnlyAttributes];
		//[self endTransaction];
	}
	return didSaveNewsItem;
}


- (void)saveNewsItems:(NSArray *)newsItems {
	@synchronized(self) {
		[self beginTransaction];
		for (RSParsedNewsItem *oneNewsItem in newsItems)
			[self saveNewsItem:oneNewsItem];
		[self endTransaction];
	}
	if (!RSIsEmpty(newsItems)) {
		NSArray *newsItemsCopy = [[newsItems copy] autorelease];
		[self rs_postNotificationOnMainThread:NNWNewsItemsDidSaveNotification object:self userInfo:[NSDictionary dictionaryWithObject:newsItemsCopy forKey:NNWNewsItemsKey]];
	}
}


static NSString *NNWDatabaseLastDeleteOldReadItemsDateKey = @"lastDeleteOldItemsDate";

- (void)deleteOldItems {
	/*So the database doesn't just grow forever, delete items older than 30 days. They'll come back if they're still in the system.*/
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDate *date30DaysAgo = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * 30)];
	NSDate *date7DaysAgo = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * 7)];
	NSDate *date1HourAgo = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 1)];
	/*Delete old read items once an hour at most.*/
	NSDate *dateOfLastDeleteOldReadItems = [[NSUserDefaults standardUserDefaults] objectForKey:NNWDatabaseLastDeleteOldReadItemsDateKey];
	if (dateOfLastDeleteOldReadItems == nil)
		dateOfLastDeleteOldReadItems = [NSDate distantPast];
	BOOL shouldDeleteOldReadItems = [date1HourAgo earlierDate:dateOfLastDeleteOldReadItems] == dateOfLastDeleteOldReadItems;
	/*TODO: don't delete item-to-restore.*/
	/*TODO: make this an operation that runs before all other operations*/
	//NSInteger numberOfRowsDeleted = 0;
	@synchronized(self) {
		[self beginTransaction];
		[self.database executeUpdate:@"delete from newsItems where starred = 0 and googleCrawlTimestamp < ?;", date30DaysAgo];
//		numberOfRowsDeleted = [self.database changes];
		[self.database executeUpdate:@"delete from newsItems where starred = 0 and googleReadStateLocked = 1;"];
//		numberOfRowsDeleted = [self.database changes];
		if (shouldDeleteOldReadItems)
			[self.database executeUpdate:@"delete from newsItems where starred = 0 and read = 1 and googleCrawlTimestamp < ?;", date7DaysAgo];
//			NSInteger numberOfRowsDeleted = [self.database changes];
//			NSLog(@"numberOfRowsDeleted: %d", numberOfRowsDeleted);
		[self endTransaction];
	}
	if (shouldDeleteOldReadItems)
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NNWDatabaseLastDeleteOldReadItemsDateKey];
	[pool drain];
	
}


- (NNWMostRecentItemSpecifier *)mostRecentItemForGoogleSourceID:(NSString *)googleSourceID {
	if (RSStringIsEmpty(googleSourceID))
		return nil;
	NNWMostRecentItemSpecifier *mostRecentItemSpecifier = nil;
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [self.database executeQuery:@"select plainTextTitle, pubDate from newsItems where googleSourceID = ? and googleReadStateLocked = 0 order by pubDate DESC limit 1;", googleSourceID];
		if (rs == nil)
			return nil;
		if ([rs next]) {
			mostRecentItemSpecifier = [[[NNWMostRecentItemSpecifier alloc] init] autorelease];
			mostRecentItemSpecifier.plainTextTitle = [rs stringForColumnIndex:0];
			mostRecentItemSpecifier.displayDate = [NSDate contextualDateStringWithDate:[rs dateForColumnIndex:1]];		
		}
		[rs close];
		[self endTransaction];
	}
	return mostRecentItemSpecifier;
}


- (NSArray *)arrayForSingleColumnResultSet:(FMResultSet *)rs {
	NSMutableArray *tempArray = [NSMutableArray array];
	while ([rs next])
		[tempArray safeAddObject:[rs stringForColumnIndex:0]];
	return tempArray;
}


- (NSSet *)setForSingleColumnResultSet:(FMResultSet *)rs {
	NSMutableSet *tempSet = [NSMutableSet set];
	while ([rs next])
		[tempSet rs_addObject:[rs stringForColumnIndex:0]];
	return tempSet;
}


- (NSArray *)feedIDsForCurrentItems {
	/*A current item is unread but not locked-read. Or it's read and crawled within 24 hours but not locked read.*/
	NSDate *date24HoursAgo = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * 1)];
	NSArray *feedIDs = nil;
	@synchronized(self) {
		FMResultSet *rs = [self.database executeQuery:@"select distinct googleSourceID from newsItems where (read = 0 or googleCrawlTimestamp > ?) and googleReadStateLocked = 0;", date24HoursAgo];
		feedIDs = [self arrayForSingleColumnResultSet:rs];
		[rs close];
	}
	return feedIDs;
}


- (NSArray *)allUnreadCounts {
	NSMutableArray *unreadCounts = [NSMutableArray array]; /*Array of RSParsedGoogleUnreadCount*/
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [self.database executeQuery:@"select googleSourceID, count(*) as count from newsItems where read == 0 and googleReadStateLocked == 0 group by googleSourceID;"];
		while ([rs next]) {
			RSParsedGoogleUnreadCount *unreadCountSpecifier = [[[RSParsedGoogleUnreadCount alloc] init] autorelease];
			unreadCountSpecifier.googleID = [rs stringForColumnIndex:0];
			unreadCountSpecifier.unreadCount = [rs intForColumnIndex:1];
			[unreadCounts addObject:unreadCountSpecifier];
		}
		[rs close];
		[self endTransaction];
	}
	return unreadCounts;
}


- (NSUInteger)unreadCountForGoogleSourceID:(NSString *)googleSourceID {
	if (RSStringIsEmpty(googleSourceID))
		return 0;
	NSUInteger unreadCount = 0;
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [self.database executeQuery:@"select count(*) from newsItems where googleSourceID = ? and read = 0 and googleReadStateLocked = 0 limit 1001;", googleSourceID];
		[rs next];
		unreadCount = [rs intForColumnIndex:0];
		[rs close];
		[self endTransaction];
	}
	return unreadCount;
}


static NSString *arrayToSQLValuesList(NSArray *anArray, BOOL escapeSingleQuotes) {
	NSMutableString *sql = [NSMutableString stringWithString:@"("];
	NSUInteger numberOfItems = [anArray count];
	NSUInteger indexOfItem = 0;
	for (NSString *oneString in anArray) {		
		[sql appendString:@"'"];
		if (escapeSingleQuotes)
			oneString = RSStringReplaceAll(oneString, @"'", @"''");
		[sql appendString:oneString];
		[sql appendString:@"'"];
		if (indexOfItem < numberOfItems - 1)
			[sql appendString:@", "];
		indexOfItem++;
	}
	[sql appendString:@")"];
	return sql;
}


static NSString *NNWDatabaseSemicolon = @";";

- (NSString *)sqlStringWithBase:(NSString *)sqlBaseStatement arrayOfValues:(NSArray *)values {
	if (RSIsEmpty(values))
		return nil;
	NSMutableString *sql = [NSMutableString stringWithString:sqlBaseStatement];
	[sql rs_appendString:arrayToSQLValuesList(values, NO)];
	[sql appendString:NNWDatabaseSemicolon];
	return sql;
}


- (void)runSQLStringInSynchronizedTransaction:(NSString *)sql {
	if (RSStringIsEmpty(sql))
		return;
	@synchronized(self) {
		[self beginTransaction];
		[[self database] executeUpdate:sql];
		[self endTransaction];
	}	
}


static NSString *NNWDatabaseMarkReadSQL = @"update newsItems set read = 1 where googleID in ";

- (void)markItemIDsAsRead:(NSArray *)itemIDs {
	if (RSIsEmpty(itemIDs))
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self runSQLStringInSynchronizedTransaction:[self sqlStringWithBase:NNWDatabaseMarkReadSQL arrayOfValues:itemIDs]];
	[pool release];
}


- (void)markOneItemIDAsRead:(NSString *)itemID {
	if (RSStringIsEmpty(itemID))
		return;
	[self markItemIDsAsRead:[NSArray arrayWithObject:itemID]];
}


static NSString *NNWDatabaseMarkStarredSQL = @"update newsItems set starred = 1 where googleID in ";
static NSString *NNWDatabaseMarkUnstarredSQL = @"update newsItems set starred = 0 where googleID in ";

- (void)markItemIDs:(NSArray *)itemIDs starred:(BOOL)starred {
	if (RSIsEmpty(itemIDs))
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self runSQLStringInSynchronizedTransaction:[self sqlStringWithBase:starred ? NNWDatabaseMarkStarredSQL : NNWDatabaseMarkUnstarredSQL arrayOfValues:itemIDs]];
//	NSString *sqlBase = starred ? NNWDatabaseMarkStarredSQL : NNWDatabaseMarkUnstarredSQL;
//	NSMutableString *sql = [NSMutableString stringWithString:sqlBase];
//	[sql rs_appendString:arrayToSQLValuesList(itemIDs)];
//	[sql appendString:@";"];
//	
//	@synchronized(self) {
//		[self beginTransaction];
//		[[self database] executeUpdate:sql];
//		[self endTransaction];
//	}
	[pool release];
}


//static NSString *setToSQLValuesList(NSSet *aSet) {
//	NSMutableString *sql = [NSMutableString stringWithString:@"("];
//	NSUInteger numberOfItems = [aSet count];
//	NSUInteger indexOfItem = 0;
//	for (NSString *oneString in aSet) {		
//		[sql appendString:@"'"];
//		[sql appendString:oneString];
//		[sql appendString:@"'"];
//		if (indexOfItem < numberOfItems - 1)
//			[sql appendString:@", "];
//		indexOfItem++;
//	}
//	[sql appendString:@")"];
//	return sql;	
//}

- (void)markSetOfItemIDs:(NSSet *)itemIDs starred:(BOOL)starred {
	if (RSIsEmpty(itemIDs))
		return;
	NSArray *itemIDsArrayContainer = NNWSetSeparatedIntoArraysOfLength(itemIDs, 50);
	for (NSArray *oneArrayOfItemsIDs in itemIDsArrayContainer)
		[self markItemIDs:oneArrayOfItemsIDs starred:starred];
}



- (void)removeExistingItemsFromSet:(NSMutableSet *)itemIDs {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	/* select googleID from newsItems where googleID in ('1744a7ff566ee7af', '18fc344a8ee1fdf2'); */	
	NSMutableString *sql = [NSMutableString stringWithString:@"select googleID from newsItems where googleID in "];
	[sql rs_appendString:arrayToSQLValuesList((NSArray *)itemIDs, NO)];
	[sql appendString:@";"];
	NSMutableSet *existingItems = [NSMutableSet set];
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [[self database] executeQuery:sql];
		while (rs && [rs next])
			[existingItems rs_addObject:[rs stringForColumnIndex:0]];
		[rs close];
		[self endTransaction];
	}
	[itemIDs minusSet:existingItems];
	[pool drain];
}


- (void)updateNewsItem:(NNWNewsItemProxy *)newsItem withRow:(FMResultSet *)rs {
	newsItem.plainTextTitle = [rs stringForColumnIndex:NNWColumnIndexPlainTextTitle];
	newsItem.datePublished = [rs dateForColumnIndex:NNWColumnIndexPubDate];
	newsItem.googleFeedID = [rs stringForColumnIndex:NNWColumnIndexGoogleSourceID];
	newsItem.googleFeedTitle = [rs stringForColumnIndex:NNWColumnIndexGoogleSourceTitle];
	newsItem.preview = [rs stringForColumnIndex:NNWColumnIndexPreview];
	newsItem.permalink = [rs stringForColumnIndex:NNWColumnIndexPermalink];
	newsItem.link = [rs stringForColumnIndex:NNWColumnIndexLink];
	newsItem.read = [rs boolForColumnIndex:NNWColumnIndexRead];
	newsItem.starred = [rs boolForColumnIndex:NNWColumnIndexStarred];
	newsItem.htmlContent = [rs stringForColumnIndex:NNWColumnIndexHTMLText];
	newsItem.thumbnailURLString = [rs stringForColumnIndex:NNWColumnIndexThumbnailURL];
	newsItem.author = [rs stringForColumnIndex:NNWColumnIndexAuthor];
//	[newsItem buildDisplayDate];
//	[newsItem buildDisplaySectionName];
	newsItem.inflated = YES;	
}


- (NNWNewsItemProxy *)newsItemWithRow:(FMResultSet *)rs {
	/*Caller has synchronized access*/
	NSString *googleID = [rs stringForColumnIndex:NNWColumnIndexGoogleID];
	if (googleID == nil)
		return nil;
	NNWNewsItemProxy *newsItem = [[[NNWNewsItemProxy alloc] initWithGoogleID:googleID] autorelease];
	[self updateNewsItem:newsItem withRow:rs];
	return newsItem;
}


- (void)inflateNewsItem:(NNWNewsItemProxy *)newsItem {
	/*Re-fetches everything.*/
	NSString *googleID = newsItem.googleID;
	if (RSStringIsEmpty(googleID))
		return;
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [[self database] executeQuery:@"select * from newsItems where googleID = ?", googleID];
		if (rs != nil && [rs next])
			[self updateNewsItem:newsItem withRow:rs];
		[rs close];
		[self endTransaction];
	}	
}


enum NNWThinNewsItemDataColumnIndex {
	NNWThinColumnIndexGoogleID,
	NNWThinColumnIndexRead,
	NNWThinColumnIndexStarred,
	NNWThinColumnIndexPlainTextTitle,
	NNWThinColumnIndexLink,
	NNWThinColumnIndexPermalink,
	NNWThinColumnIndexPubDate,
	NNWThinColumnIndexPreview,
	NNWThinColumnIndexGoogleSourceID,
	NNWThinColumnIndexGoogleSourceTitle,
	NNWThinColumnIndexThumbnailURL
};


static NSString *NNWDatabaseThinResultSQLQuery = @"select googleID, read, starred, plainTextTitle, link, permalink, pubDate, preview, googleSourceID, googleSourceTitle, thumbnailURL from newsItems where googleSourceID in ";
static NSString *NNWDatabaseThinResultSQLQueryForOneSourceID = @"select googleID, read, starred, plainTextTitle, link, permalink, pubDate, preview, googleSourceID, googleSourceTitle, thumbnailURL from newsItems where googleSourceID == ?;";

- (NNWNewsItemProxy *)thinNewsItemWithThinRow:(FMResultSet *)rs {
	/*Caller has synchronized access*/
	NSString *googleID = [rs stringForColumnIndex:NNWThinColumnIndexGoogleID];
	if (googleID == nil)
		return nil;
	NNWNewsItemProxy *newsItem = [[[NNWNewsItemProxy alloc] initWithGoogleID:googleID] autorelease];
	newsItem.plainTextTitle = [rs stringForColumnIndex:NNWThinColumnIndexPlainTextTitle];
	newsItem.datePublished = [rs dateForColumnIndex:NNWThinColumnIndexPubDate];
	newsItem.googleFeedID = [rs stringForColumnIndex:NNWThinColumnIndexGoogleSourceID];
	newsItem.googleFeedTitle = [rs stringForColumnIndex:NNWThinColumnIndexGoogleSourceTitle];
	newsItem.preview = RSEmptyString;//[rs stringForColumnIndex:NNWThinColumnIndexPreview];
	newsItem.permalink = [rs stringForColumnIndex:NNWThinColumnIndexPermalink];
	newsItem.link = [rs stringForColumnIndex:NNWThinColumnIndexLink];
	newsItem.read = [rs boolForColumnIndex:NNWThinColumnIndexRead];
	newsItem.starred = [rs boolForColumnIndex:NNWThinColumnIndexStarred];
	newsItem.thumbnailURLString = [rs stringForColumnIndex:NNWThinColumnIndexThumbnailURL];
//	[newsItem buildDisplayDate];
	//[newsItem buildDisplaySectionName];
	newsItem.inflated = NO;
	return newsItem;	
}


- (FMResultSet *)thinResultSetWithGoogleSourceIDs:(NSArray *)googleSourceIDs {
	/*Caller has synchronized access*/
	if (RSIsEmpty(googleSourceIDs))
		return nil;
	if ([googleSourceIDs count] == 1)
		return [[self database] executeQuery:NNWDatabaseThinResultSQLQueryForOneSourceID, [googleSourceIDs safeObjectAtIndex:0]];
	NSMutableString *sql = [NSMutableString stringWithString:NNWDatabaseThinResultSQLQuery];
	[sql rs_appendString:arrayToSQLValuesList(googleSourceIDs, YES)];
	[sql appendString:@";"];
	return [[self database] executeQuery:sql];
}


static NSString *NNWDatabaseThinStarredItemsSQLQuery = @"select googleID, read, starred, plainTextTitle, link, permalink, pubDate, preview, googleSourceID, googleSourceTitle, thumbnailURL from newsItems where starred = 1;";

- (FMResultSet *)thinResultSetOfStarredItems {
	/*Caller has synchronized access*/
	return [[self database] executeQuery:NNWDatabaseThinStarredItemsSQLQuery];
}


static NSString *NNWDatabaseIDsOfStarredItemsSQLQuery = @"select googleID from newsItems where starred = 1;";

- (NSSet *)idsOfStarredItems {
	NSSet *starredItemIDs = nil;
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [[self database] executeQuery:NNWDatabaseIDsOfStarredItemsSQLQuery];
		starredItemIDs = [self setForSingleColumnResultSet:rs];
		[self endTransaction];
	}
	return starredItemIDs;
}


static NSString *NNWDatabaseThinLatestItemsSQLQuery = @"select googleID, read, starred, plainTextTitle, link, permalink, pubDate, preview, googleSourceID, googleSourceTitle, thumbnailURL from newsItems where pubDate > ?;";

- (FMResultSet *)thinResultSetOfLatestItems {
	/*Caller has synchronized access*/
	return [[self database] executeQuery:NNWDatabaseThinLatestItemsSQLQuery, [NSDate dateWithTimeIntervalSinceNow:-(24 * 60 * 60)]];	
}


static NSString *NNWDatabaseLatestItemsUnreadCountSQLQuery = @"select count(*) from newsItems where read = 0 and pubDate > ?;";

- (NSInteger)unreadCountForLatestItems {
	NSInteger unreadCount = 0;
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [self.database executeQuery:NNWDatabaseLatestItemsUnreadCountSQLQuery, [NSDate dateWithTimeIntervalSinceNow:-(24 * 60 * 60)]];
		[rs next];
		unreadCount = [rs intForColumnIndex:0];
		[rs close];
		[self endTransaction];
	}
	return unreadCount;
}


- (NSMutableArray *)newsItemsWithGoogleSourceIDs:(NSArray *)googleSourceIDs {
	NSMutableArray *newsItems = [NSMutableArray array];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableString *sql = [NSMutableString stringWithString:@"select * from newsItems where googleSourceID in "];
	[sql rs_appendString:arrayToSQLValuesList(googleSourceIDs, YES)];
	[sql appendString:@";"];
	@synchronized(self) {
		[self beginTransaction];
		FMResultSet *rs = [[self database] executeQuery:sql];
		while (rs && [rs next])
			[newsItems safeAddObject:[self newsItemWithRow:rs]];
		[rs close];
		[self endTransaction];
	}
	[pool drain];
	return newsItems;
}


@end
