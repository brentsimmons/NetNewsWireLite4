//
//  RSParsedNewsItem.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSParsedNewsItem.h"
#import "RSDateParser.h"


@interface RSParsedNewsItem ()
@property (nonatomic, assign) BOOL didCalculateThumbnailURL;
@end


@implementation RSParsedNewsItem

@synthesize read, googleReadStateLocked;
@synthesize starred, titleIsHTML, guid, categories;
@synthesize title, enclosures, link, permalink;
@synthesize plainTextTitle;
@synthesize xmlBaseURLForContent, content;
@synthesize xmlBaseURLForSummary, summary;
@synthesize author;
@synthesize googleCrawlTimestamp, googleCrawlTimestampString;
@synthesize googleSourceID;
@synthesize pubDate, pubDateString, sourceTitle;
@synthesize preview;
@synthesize movieURL, audioURL;
@synthesize thumbnailURL;
@synthesize didCalculateThumbnailURL;
@synthesize mediaThumbnailURL;

//static NSDateFormatter *gDateFormatter = nil;

//+ (void)initialize {
//	@synchronized([RSParsedNewsItem class]) {
//		if (gDateFormatter == nil) {
//			gDateFormatter = [[NSDateFormatter alloc] init];
//			[gDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
//			[gDateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
//			[gDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
//			[gDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
//		}
//	}
//}


#pragma mark Dealloc

- (void)dealloc {
	[guid release];
	[categories release];
	[title release];
	[plainTextTitle release];
	[enclosures release];
	[link release];
	[permalink release];
	[xmlBaseURLForContent release];
	[content release];
	[xmlBaseURLForSummary release];
	[summary release];
	[author release];
	[googleCrawlTimestamp release];
	[googleCrawlTimestampString release];
	[googleSourceID release];
	[pubDate release];
	[pubDateString release];
	[sourceTitle release];
	[preview release];
	[hashOfReadOnlyAttributes release];
	[audioURL release];
	[movieURL release];
	[thumbnailURL release];
	[mediaThumbnailURL release];
	[super dealloc];
}


#pragma mark Categories

- (void)addCategory:(NSString *)category {
	if (self.categories == nil)
		self.categories = [NSMutableArray array];
	[self.categories safeAddObject:category];
}


#pragma mark Enclosures

- (void)addEnclosure:(NSDictionary *)enclosure {
	if (self.enclosures == nil)
		self.enclosures = [NSMutableArray array];
	[self.enclosures safeAddObject:enclosure];
}


//#pragma mark Google Crawl Timestamp
//
//- (void)setGoogleCrawlTimestampWithString:(NSString *)timestampString {
//	if (timestampString != nil)
//		self.googleCrawlTimestamp = [NSDate dateWithTimeIntervalSince1970:([timestampString doubleValue] / 1000.000f)];
//}


#pragma mark PubDate

//static NSString *RSZSuffix = @"Z";

- (NSDate *)pubDate {
	/*Because this may not be needed -- because the item may not get saved, for instance -- this is calculated lazily. Small performance optimization.*/
	if (pubDate != nil)
		return pubDate;
	NSString *dateString = self.pubDateString;
	if (!RSStringIsEmpty(dateString))
		self.pubDate = RSDateWithString(dateString);
//	if (dateString != nil && [dateString hasSuffix:RSZSuffix]) {
//		dateString = [NSString stripSuffix:dateString suffix:RSZSuffix];
//		self.pubDate = [gDateFormatter dateFromString:dateString];
//	}
	return pubDate;
}


#pragma mark Hash

static NSString *RSParsedNewsItemEmptyString = @"";

- (NSData *)hashOfReadOnlyAttributes {
	if (hashOfReadOnlyAttributes != nil)
		return hashOfReadOnlyAttributes;
	NSMutableString *s = [NSMutableString stringWithString:RSParsedNewsItemEmptyString];
	[s rs_appendString:self.guid];
	[s rs_appendString:self.title];
	[s rs_appendString:self.link];
	[s rs_appendString:self.content];
	[s rs_appendString:self.summary];
	[s rs_appendString:self.author];
	[s rs_appendString:self.googleSourceID];
	if (!RSIsEmpty(self.categories))
		[s rs_appendString:[self.categories componentsJoinedByString:RSParsedNewsItemEmptyString]];
	[hashOfReadOnlyAttributes autorelease];
	hashOfReadOnlyAttributes = [[NSData hashWithString:s] retain];
//	hashOfReadOnlyAttributes = [[NSString onewayHashOfString:s] retain];
	return hashOfReadOnlyAttributes;
}


#pragma mark Calculated

- (NSString *)htmlText {
	if (RSStringIsEmpty(self.content))
		return self.summary;
	return self.content;
}


- (NSString *)xmlBaseURL {
	if (RSStringIsEmpty(self.xmlBaseURLForContent))
		return self.xmlBaseURLForSummary;
	return self.xmlBaseURLForContent;
}


- (NSDate *)googleCrawlTimestamp {
	if (googleCrawlTimestamp != nil)
		return googleCrawlTimestamp;
	if (self.googleCrawlTimestampString != nil)
		self.googleCrawlTimestamp = [NSDate dateWithTimeIntervalSince1970:([self.googleCrawlTimestampString doubleValue] / 1000.000f)];
	return googleCrawlTimestamp;
}


static NSString *RSHTMLLeftCaret = @"<";
static NSString *RSHTMLItalicTagStart = @"<i>";
static NSString *RSHTMLItalicTagEnd = @"</i>";
static NSString *RSHTMLBoldTagStart = @"<b>";
static NSString *RSHTMLBoldTagEnd = @"</b>";
static NSString *RSHTMLBRTag = @"<br>";
static NSString *RSHTMLBRSlashTag = @"<br/>";

- (NSString *)plainTextTitle {
	if (plainTextTitle != nil)
		return plainTextTitle;
	NSMutableString *s = [[self.title mutableCopy] autorelease];
	[s replaceXMLCharacterReferences];
	if ([s caseSensitiveContains:RSHTMLLeftCaret]) {
		[s replaceOccurrencesOfString:RSHTMLItalicTagStart withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLItalicTagEnd withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBoldTagStart withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBoldTagEnd withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBRTag withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:RSHTMLBRSlashTag withString:RSEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
	}
	[s collapseWhitespace];
	self.plainTextTitle = s;
	return plainTextTitle;
}


- (NSString *)preview {
	if (preview != nil)
		return preview;
	NSString *previewSource = RSStringIsEmpty(self.summary) ? self.content : self.summary;
	if (!RSStringIsEmpty(previewSource)) {
		NSMutableString *strippedPreview = [NSMutableString rs_mutableStringWithStrippedHTML:previewSource maxCharacters:400];
		[strippedPreview collapseWhitespace];
		self.preview = strippedPreview;
	}
	return preview;
}


- (NSString *)thumbnailURL {
	/*May be set directly, in the case where the thumbnail URL is present in the feed as media:thumbnail. Otherwise calculated from the description.*/
	if (self.mediaThumbnailURL != nil)
		return self.mediaThumbnailURL;
	if (thumbnailURL != nil || self.didCalculateThumbnailURL)
		return thumbnailURL;
	self.didCalculateThumbnailURL = YES;
	self.thumbnailURL = RSFirstImgURLStringInHTML(self.htmlText);
	return thumbnailURL;
}

@end
