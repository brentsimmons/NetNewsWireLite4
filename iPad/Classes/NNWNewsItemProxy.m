//
//  NNWNewsItemProxy.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/28/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWNewsItemProxy.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "NNWDatabaseController.h"


@interface NNWNewsItemProxy()
@property (nonatomic, retain, readwrite) NSString *displayDate;
//@property (nonatomic, retain, readwrite) NSString *displaySectionName;
//- (void)buildDisplayDate;
//- (void)buildDisplaySectionName;
@end

static NSDateFormatter *gDisplayDateFormatter = nil;
//static NSDateFormatter *gDisplaySectionNameDateFormatter = nil;
static NSDate *aLittleWhileAgo = nil;


@implementation NNWNewsItemProxy

@synthesize plainTextTitle = _plainTextTitle, datePublished = _datePublished, /*movieURLString = _movieURLString, audioURLString = _audioURLString,*/ googleFeedID = _googleFeedID, googleFeedTitle = _googleFeedTitle, thumbnailURLString = _thumbnailURLString, read = _read, starred = _starred, preview = _preview, displayDate = _displayDate, /*displaySectionName = _displaySectionName,*/ permalink = _permalink, inflated = _inflated;
@synthesize author;

@synthesize htmlContent, link;

+ (void)initialize {
	@synchronized([NNWProxy class]) {
		if (gDisplayDateFormatter == nil) {
			gDisplayDateFormatter = [[NSDateFormatter alloc] init];
			[gDisplayDateFormatter setDateStyle:kCFDateFormatterLongStyle];
			[gDisplayDateFormatter setTimeStyle:kCFDateFormatterShortStyle];		
		}
//		if (gDisplaySectionNameDateFormatter == nil) {
//			gDisplaySectionNameDateFormatter = [[NSDateFormatter alloc] init];
//			[gDisplaySectionNameDateFormatter setDateStyle:kCFDateFormatterFullStyle];
//			[gDisplaySectionNameDateFormatter setTimeStyle:kCFDateFormatterNoStyle];		
//		}
		if (aLittleWhileAgo == nil)
			aLittleWhileAgo = [[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * 7)] retain];
	}
}


- (void)dealloc {
	[_plainTextTitle release];
	[_datePublished release];
#if MEDIA_PLAYBACK
	[_movieURLString release];
	[_audioURLString release];
#endif
	[_googleFeedID release];
	[_googleFeedTitle release];
	[_thumbnailURLString release];
	[_preview release];
	[_displayDate release];
	//[_displaySectionName release];
	[_permalink release];
	[htmlContent release];
	[author release];
	[link release];
	[super dealloc];	
}


//- (void)inflateWithDictionary:(NSDictionary *)d {
//	self.plainTextTitle = [d objectForKey:RSDataPlainTextTitle];
//	self.datePublished = [d objectForKey:RSDataDatePublished];
//#if MEDIA_PLAYBACK
//	self.movieURLString = [d objectForKey:RSDataMovieURL];
//	self.audioURLString = [d objectForKey:RSDataAudioURL];
//#endif
//	self.googleFeedID = [d objectForKey:RSDataGoogleFeedID];
//	self.googleFeedTitle = [d objectForKey:RSDataGoogleFeedTitle];
//
//	self.preview = [d objectForKey:RSDataPreview];
//	self.permalink = [d objectForKey:RSDataPermalink];
//	self.read = [d boolForKey:RSDataRead];
//	self.starred = [d boolForKey:RSDataStarred];
//	[self buildDisplayDate];
//	[self buildDisplaySectionName];
//	self.inflated = YES;	
//}


//- (void)buildDisplayDate {
//	self.displayDate = [gDisplayDateFormatter stringFromDate:self.datePublished];
//}


- (NSString *)displayDate {
	if (_displayDate != nil)
		return _displayDate;
	_displayDate = [[gDisplayDateFormatter stringFromDate:self.datePublished] retain];
	return _displayDate;
}


//- (void)buildDisplaySectionName {
//	NSDate *d = self.datePublished;	
//	if ([aLittleWhileAgo earlierDate:d] == d) {
//		NSDateComponents *dc = [[NSCalendar currentCalendar] components: NSYearCalendarUnit | NSMonthCalendarUnit fromDate:d];
//		NSString *monthName = [[gDisplaySectionNameDateFormatter monthSymbols] safeObjectAtIndex:[dc month] - 1];
//		self.displaySectionName = [NSString stringWithFormat:@"%@ %d", monthName, [dc year]];
//	}
//	else
//		self.displaySectionName = [gDisplaySectionNameDateFormatter stringFromDate:d];
//}


- (NSDictionary *)itemDictForStatusNotification {
	NSMutableDictionary *itemDict = [[[NSMutableDictionary alloc] initWithCapacity:2] autorelease];
	[itemDict safeSetObject:self.googleFeedID forKey:RSDataGoogleFeedID];
	[itemDict safeSetObject:self.googleID forKey:RSDataGoogleID];
	return itemDict;
}


- (NSDictionary *)userInfoForStatusNotification {
	NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
	NSDictionary *itemDict = [self itemDictForStatusNotification];
	[userInfo setObject:[NSArray arrayWithObject:itemDict] forKey:RSNewsItemsKey];
	return userInfo;
}


+ (NSDictionary *)userInfoForMultipleItemsStatusNotification:(NSArray *)itemDicts {
	NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
	[userInfo setObject:itemDicts forKey:RSNewsItemsKey];
	return userInfo;	
}


+ (void)markItemIDsAsReadInDatabase:(NSArray *)googleIDs {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NNWDatabaseController sharedController] markItemIDsAsRead:googleIDs];
	[pool release];
}


+ (void)userMarkNewsItemsAsRead:(NSArray *)newsItems {
	NSMutableArray *itemDictsForStatusNotification = [NSMutableArray array];
	NSMutableArray *googleIDs = [NSMutableArray array];
	for (NNWNewsItemProxy *oneNewsItem in newsItems) {
		if (oneNewsItem.read)
			continue;
		[itemDictsForStatusNotification safeAddObject:[oneNewsItem itemDictForStatusNotification]];
		[googleIDs safeAddObject:oneNewsItem.googleID];
		oneNewsItem.read = YES;
	}
	if (RSIsEmpty(googleIDs))
		return;
	[self performSelectorInBackground:@selector(markItemIDsAsReadInDatabase:) withObject:googleIDs];
	NSDictionary *userInfo = [self userInfoForMultipleItemsStatusNotification:itemDictsForStatusNotification];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:self userInfo:userInfo];
}


- (void)userMarkAsRead {
	if (self.read)
		return;
	self.read = YES;
	[[NNWDatabaseController sharedController] markOneItemIDAsRead:self.googleID];
	if (!RSStringIsEmpty(self.googleFeedID) && !RSStringIsEmpty(self.googleID))
		[[NSNotificationCenter defaultCenter] postNotificationName:NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification object:self userInfo:[self userInfoForStatusNotification]];
}


- (void)userMarkAsStarred {
	if (self.starred || RSIsEmpty(self.googleID))
		return;
	self.starred = YES;
	[[NNWDatabaseController sharedController] markItemIDs:[NSArray arrayWithObject:self.googleID] starred:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWUserDidMarkOneOrMoreItemsInFeedAsStarredNotification object:self userInfo:[self userInfoForStatusNotification]];
}


- (void)userMarkAsUnstarred {
	if (!self.starred || RSIsEmpty(self.googleID))
		return;
	self.starred = NO;
	[[NNWDatabaseController sharedController] markItemIDs:[NSArray arrayWithObject:self.googleID] starred:NO];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWUserDidMarkOneOrMoreItemsInFeedAsUnstarredNotification object:self userInfo:[self userInfoForStatusNotification]];
}


- (void)userToggleStarred {
	if (self.starred)
		[self userMarkAsUnstarred];
	else
		[self userMarkAsStarred];
	
}

@end
