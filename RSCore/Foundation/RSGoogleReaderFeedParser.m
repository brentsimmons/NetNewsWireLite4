//
//  RSGoogleReaderFeedParser.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/2/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleReaderFeedParser.h"
#import "RSFoundationExtras.h"
#import "RSParsedNewsItem.h"


@interface RSGoogleReaderFeedParser ()
@property (nonatomic, assign) BOOL parsingAuthor;
@property (nonatomic, assign) BOOL parsingSource;
@end


@implementation RSGoogleReaderFeedParser

@synthesize parsingAuthor;
@synthesize parsingSource;


#pragma mark Parser

- (void)addNewsItem {
	[super addNewsItem];
	self.newsItem.googleSynced = YES;
}


- (void)processID {
	self.newsItem.guid = [self currentString];//RSGoogleShortItemIDForLongItemID([self currentString]);
}


static NSString *rs_label = @"label";
static NSString *rs_read = @"read";
static NSString *rs_starred = @"starred";

- (void)processStatusCategory {
	NSString *label = [self.xmlAttributesDict objectForKey:rs_label];
	if (RSStringIsEmpty(label))
		return;
	if ([label caseInsensitiveCompare:rs_read] == NSOrderedSame)
		self.newsItem.read = YES;
	else if ([label caseInsensitiveCompare:rs_starred] == NSOrderedSame)
		self.newsItem.starred = YES;
}


static NSString *rs_scheme = @"scheme";
static NSString *rs_googleComSlashReader = @"google.com/reader";
static NSString *rs_term = @"term";

- (void)processCategory {
	NSDictionary *atts = self.xmlAttributesDict;
	NSString *scheme = [atts objectForKey:rs_scheme];
	if (!RSStringIsEmpty(scheme) && [scheme rs_caseInsensitiveContains:rs_googleComSlashReader]) {
		[self processStatusCategory];
		return;
	}
	NSString *category = [atts objectForKey:rs_term];
	if (!RSStringIsEmpty(category))
		[self.newsItem addCategory:category];
}


static NSString *rs_type = @"type";
static NSString *rs_html = @"html";

- (void)processTitle {
	NSString *title = [self currentString];
	if (RSStringIsEmpty(title))
		return;
	NSString *type = [self.xmlAttributesDict objectForKey:rs_type];
	if (type && [type isEqualToString:rs_html])
		self.newsItem.titleIsHTML = YES;
	self.newsItem.title = title;
}


static NSString *rs_rel = @"rel";
static NSString *rs_href = @"href";
static NSString *rs_alternate = @"alternate";
static NSString *rs_related = @"related";
static NSString *rs_enclosure = @"enclosure";
static NSString *rs_image = @"image";

- (void)processLink {
	NSDictionary *atts = self.xmlAttributesDict;
	NSString *rel = [atts objectForKey:rs_rel];
	if (RSStringIsEmpty(rel))
		return;
	NSString *href = [atts objectForKey:rs_href];
	if (RSStringIsEmpty(href))
		return;
	if ([rel isEqualToString:rs_alternate])
		self.newsItem.permalink = href;
	else if ([rel isEqualToString:rs_related])
		self.newsItem.link = href;
	else if ([rel isEqualToString:rs_enclosure])
		[self processEnclosure];
	else if ([rel isEqualToString:rs_image])
		[self addThumbnailURLIfNoThumbnail:href];
}


static NSString *rs_xmlBase = @"xml:base";

- (void)processContent {
	NSString *content = [self currentString];
	if (RSStringIsEmpty(content))
		return;
	self.newsItem.xmlBaseURLForContent = [self.xmlAttributesDict objectForKey:rs_xmlBase];
	self.newsItem.content = content;
}


- (void)processSummary {
	NSString *summary = [self currentString];
	if (RSStringIsEmpty(summary))
		return;
	self.newsItem.xmlBaseURLForSummary = [self.xmlAttributesDict objectForKey:rs_xmlBase];
	self.newsItem.summary = summary;
}


static NSString *rs_unknown = @"unknown";

- (void)processAuthor {
	NSString *authorName = [self currentString];
	if (RSStringIsEmpty(authorName) || [authorName rs_caseInsensitiveContains:rs_unknown])
		return;
	self.newsItem.author = authorName;
}


- (void)processDatePublished {
	self.newsItem.pubDate = [self currentDate];
//	self.newsItem.pubDateString = [self currentString];
}


static const char *kIDTag = "id";
static const NSUInteger kIDTagLength = 3;
static const char *kCategoryTag = "category";
static const NSUInteger kCategoryTagLength = 9;
static const char *kTitleTag = "title";
static const NSUInteger kTitleTagLength = 6;
static const char *kPublishedTag = "published";
static const NSUInteger kPublishedTagLength = 10;
static const char *kLinkTag = "link";
static const NSUInteger kLinkTagLength = 5;
static const char *kNameTag = "name";
static const NSUInteger kNameTagLength = 5;
static const char *kSummaryTag = "summary";
static const NSUInteger kSummaryTagLength = 8;
static const char *kContentTag = "content";
static const NSUInteger kContentTagLength = 8;
static const char *kMediaTagPrefix = "media";
static const NSUInteger kMediaTagPrefixLength = 6;
static const char *kThumbnailTag = "thumbnail";
static const NSUInteger kThumbnailTagLength = 10;


- (void)addNewsItemElement:(const char *)localName prefix:(const char *)prefix {
	if (prefix == nil) {
		if (_xmlEqualTags(localName, kIDTag, kIDTagLength))
			[self processID];
		else if (_xmlEqualTags(localName, kCategoryTag, kCategoryTagLength))
			[self processCategory];
		else if (_xmlEqualTags(localName, kTitleTag, kTitleTagLength))
			[self processTitle];
		else if (_xmlEqualTags(localName, kPublishedTag, kPublishedTagLength))
			[self processDatePublished];
		else if (_xmlEqualTags(localName, kLinkTag, kLinkTagLength))
			[self processLink];
		else if (self.parsingAuthor && _xmlEqualTags(localName, kNameTag, kNameTagLength))
			[self processAuthor];
		else if (_xmlEqualTags(localName, kSummaryTag, kSummaryTagLength))
			[self processSummary];
		else if (_xmlEqualTags(localName, kContentTag, kContentTagLength))
			[self processContent];
		return;
	}
	else if (_xmlEqualTags(prefix, kMediaTagPrefix, kMediaTagPrefixLength)) {
		if (_xmlEqualTags(localName, kContentTag, kContentTagLength))
			[self processEnclosure];
		else if (_xmlEqualTags(localName, kThumbnailTag, kThumbnailTagLength))
			[self processMediaThumbnail];
	}
}


static NSString *rs_grStreamID = @"gr:stream-id";

- (void)processSourceStreamID {
	self.newsItem.googleSourceID = [self.xmlAttributesDict objectForKey:rs_grStreamID];
}


static NSString *rs_grIsReadStateLocked = @"gr:is-read-state-locked";
static NSString *rs_true = @"true";

- (void)processReadStateLocked {
	NSString *isReadStateLocked = [self.xmlAttributesDict objectForKey:rs_grIsReadStateLocked];
	if (isReadStateLocked != nil && [isReadStateLocked isEqualToString:rs_true])
		self.newsItem.googleReadStateLocked = YES;
}


static NSString *rs_grCrawlTimestampMsec = @"gr:crawl-timestamp-msec";

- (void)processCrawlTimestamp {
	self.newsItem.googleCrawlTimestampString = [self.xmlAttributesDict objectForKey:rs_grCrawlTimestampMsec];
}


- (void)addSourceElement:(const char *)localName prefix:(const char *)prefix {
	if (_xmlEqualTags(localName, kTitleTag, kTitleTagLength))
		self.newsItem.sourceTitle = [self currentString];
}


static const char *kEntryTag = "entry";
static const NSUInteger kEntryTagLength = 6;
static const char *kSourceTag = "source";
static const NSUInteger kSourceTagLength = 7;


- (BOOL)parserWantsAttributesForTagWithLocalName:(const char *)localName prefix:(const char *)prefix {
	if (prefix == nil)
		return _xmlEqualTags(localName, kCategoryTag, kCategoryTagLength) || _xmlEqualTags(localName, kTitleTag, kTitleTagLength) || _xmlEqualTags(localName, kLinkTag, kLinkTagLength) || _xmlEqualTags(localName, kContentTag, kContentTagLength) || _xmlEqualTags(localName, kSummaryTag, kSummaryTagLength) || _xmlEqualTags(localName, kEntryTag, kEntryTagLength) || _xmlEqualTags(localName, kSourceTag, kSourceTagLength);
	/*media:thumbnail and media:content*/
	if (_xmlEqualTags(prefix, kMediaTagPrefix, kMediaTagPrefixLength) && (_xmlEqualTags(localName, kThumbnailTag, kThumbnailTagLength) || _xmlEqualTags(localName, kContentTag, kContentTagLength)))
		return YES;
	return NO;
}


static const char *kLabelTag = "label";
static const NSUInteger kLabelTagLength = 6;
static const char *kSchemeTag = "scheme";
static const NSUInteger kSchemeTagLength = 7;
static const char *kTypeTag = "type";
static const NSUInteger kTypeTagLength = 5;
static const char *kTermTag = "term";
static const NSUInteger kTermTagLength = 5;
static const char *kHrefTag = "href";
static const NSUInteger kHrefTagLength = 5;
static const char *kurlTag = "url";
static const NSUInteger kurlTagLength = 4;
static NSString *rs_url = @"url";
static const char *kLengthTag = "length";
static const NSUInteger kLengthTagLength = 7;
static NSString *rs_length = @"length";
static const char *kRelTag = "rel";
static const NSUInteger kRelTagLength = 4;
static const char *kGRTag = "gr";
static const NSUInteger kGRTagLength = 3;
static const char *kStreamIDTag = "stream-id";
static const NSUInteger kStreamIDTagLength = 10;
static const char *kCrawlTimestampTag = "crawl-timestamp-msec";
static const NSUInteger kCrawlTimestampTagLength = 21;
static const char *kReadStateLockedTag = "is-read-state-locked";
static const NSUInteger kReadStateLockedTagLength = 21;
static const char *kXMLTag = "xml";
static const NSUInteger kXMLTagLength = 4;
static const char *kBaseTag = "base";
static const NSUInteger kBaseTagLength = 5;

		 
- (NSString *)staticNameForLocalName:(const char *)localName prefix:(const char *)prefix {
	if (prefix == nil) {
		if (_xmlEqualTags(localName, kLabelTag, kLabelTagLength))
			return rs_label;
		if (_xmlEqualTags(localName, kSchemeTag, kSchemeTagLength))
			return rs_scheme;
		if (_xmlEqualTags(localName, kTermTag, kTermTagLength))
			return rs_term;
		if (_xmlEqualTags(localName, kTypeTag, kTypeTagLength))
			return rs_type;
		if (_xmlEqualTags(localName, kHrefTag, kHrefTagLength))
			return rs_href;
		if (_xmlEqualTags(localName, kurlTag, kurlTagLength))
			return rs_url;
		if (_xmlEqualTags(localName, kLengthTag, kLengthTagLength))
			return rs_length;
		if (_xmlEqualTags(localName, kRelTag, kRelTagLength))
			return rs_rel;
		return nil;
	}

	if (_xmlEqualTags(prefix, kGRTag, kGRTagLength)) {
		if (_xmlEqualTags(localName, kStreamIDTag, kStreamIDTagLength))
			return rs_grStreamID;
		if (_xmlEqualTags(localName, kCrawlTimestampTag, kCrawlTimestampTagLength))
			return rs_grCrawlTimestampMsec;
		if (_xmlEqualTags(localName, kReadStateLockedTag, kReadStateLockedTagLength))
			return rs_grIsReadStateLocked;
		return nil;
	}
	
	if (_xmlEqualTags(prefix, kXMLTag, kXMLTagLength) && _xmlEqualTags(localName, kBaseTag, kBaseTagLength))
		return rs_xmlBase;

	return nil;
}



#pragma mark SAX Parsing Callbacks

static const char *kAuthorTag = "author";
static const NSUInteger kAuthorTag_Length = 7;


- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	[super xmlStartElement:localName prefix:prefix uri:uri numberOfNamespaces:numberOfNamespaces namespaces:namespaces numberOfAttributes:numberOfAttributes numberDefaulted:numberDefaulted attributes:attributes];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (prefix == nil && _xmlEqualTags(localName, kEntryTag, kEntryTagLength)) {
		[self addNewsItem];
		self.parsingNewsItem = YES;
	}
	else if (prefix == nil && _xmlEqualTags(localName, kAuthorTag, kAuthorTag_Length))
		self.parsingAuthor = YES;
	else if (prefix == nil && _xmlEqualTags(localName, kSourceTag, kSourceTagLength))
		self.parsingSource = YES;
	
	if (self.parsingNewsItem)
		[self startStoringCharacters];
	
	[pool drain];
}


static const char *kFeedTag = "feed";
static const NSUInteger kFeedTagLength = 5;


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[super xmlEndElement:localName prefix:prefix uri:uri];
	if (_xmlEqualTags(localName, kAuthorTag, kAuthorTag_Length))
		self.parsingAuthor = NO;
	if (_xmlEqualTags(localName, kSourceTag, kSourceTagLength)) {
		[self processSourceStreamID];
		self.parsingSource = NO;
	}
	if (_xmlEqualTags(localName, kEntryTag, kEntryTagLength)) {
		[self processReadStateLocked];
		[self processCrawlTimestamp];
		self.parsingNewsItem = NO;
		[self removeNewsItemIfDelegateWishes];
	}
	else if (self.parsingNewsItem && !self.parsingSource)
		[self addNewsItemElement:(const char *)localName prefix:(const char *)prefix];
	else if (self.parsingSource)
		[self addSourceElement:(const char *)localName prefix:(const char *)prefix];
	else if (_xmlEqualTags(localName, kFeedTag, kFeedTagLength))
		[self notifyDelegateThatFeedParserDidComplete];
	[pool drain];
}

@end
