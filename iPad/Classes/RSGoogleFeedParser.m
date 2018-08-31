//
//  RSGoogleFeedParser.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/2/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleFeedParser.h"
#import "NNWAppDelegate.h"
//#import "RSFeedDefinitions.h"
#import "RSMimeTypes.h"
#import "RSParsedNewsItem.h"


@interface RSGoogleFeedParser ()
@property (nonatomic, retain) RSParsedNewsItem *newsItem;
@property (nonatomic, assign) BOOL parsingNewsItem;
@property (nonatomic, assign) BOOL parsingAuthor;
@property (nonatomic, assign) BOOL parsingSource;
@property (nonatomic, assign) BOOL delegateRespondsToDidParseNewsItem;
@end


@implementation RSGoogleFeedParser

@synthesize newsItems, newsItem;
@synthesize parsingNewsItem, parsingAuthor;
@synthesize parsingSource, delegate;
@synthesize delegateRespondsToDidParseNewsItem;

//static NSDateFormatter *gDateFormatter = nil;
//
//+ (void)initialize {
//	@synchronized([RSGoogleFeedParser class]) {
//		if (gDateFormatter == nil) {
//			gDateFormatter = [[NSDateFormatter alloc] init];
//			[gDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
//			[gDateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
//			[gDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
//			[gDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
//		}
//	}
//}


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	newsItems = [[NSMutableArray arrayWithCapacity:50] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[newsItems release];
	[newsItem release];
	[super dealloc];
}


#pragma mark Delegate

- (void)setDelegate:(id<RSGoogleFeedParserDelegate>)aDelegate {
	delegate = aDelegate;
	self.delegateRespondsToDidParseNewsItem = [(id)delegate respondsToSelector:@selector(feedParser:didParseNewsItem:)];
}



#pragma mark -

#pragma mark Parser

//- (void)parseData:(NSData *)data error:(NSError **)error {
//	NSLog(@"%@", [NSString stringWithUTF8EncodedData:data]);
//	[super parseData:data error:error];
//}
//
//
//- (void)parseChunk:(NSData *)data error:(NSError **)error {
//	NSLog(@"%@", [NSString stringWithUTF8EncodedData:data]);
//	[super parseChunk:data error:error];
//}
//
//
//- (void)startParsing:(NSData *)initialChunk {
//	NSLog(@"%@", [NSString stringWithUTF8EncodedData:initialChunk]);
//	[super startParsing:initialChunk];
//}


- (void)addNewsItem:(RSParsedNewsItem *)aNewsItem {
	[self.newsItems addObject:aNewsItem];
	self.newsItem = aNewsItem;
}


static NSString *uniquePartOfGoogleItemID(NSString *itemID) {
	/*Strip off the non-unique part from: tag:google.com,2005:reader/item/7155b6e5ed5871b8*/
	if (RSStringIsEmpty(itemID))
		return itemID;
	NSUInteger lengthOfID = [itemID length];
	if (lengthOfID == 16)
		return itemID;
	if (lengthOfID > 32)
		return [itemID substringFromIndex:32];
	if (![itemID caseSensitiveContains:@"/"]) /*Shouldn't get here*/
		return itemID;
	return [[itemID componentsSeparatedByString:@"/"] lastObject];
}


- (void)processID {
	self.newsItem.guid = uniquePartOfGoogleItemID([self currentString]);
}


- (void)processStatusCategory {
	NSString *label = [self.xmlAttributesDict objectForKey:RSFeedLabel];
	if (RSStringIsEmpty(label))
		return;
	if ([label caseInsensitiveCompare:RSFeedRead] == NSOrderedSame)
		self.newsItem.read = YES;
	else if ([label caseInsensitiveCompare:RSFeedStarred] == NSOrderedSame)
		self.newsItem.starred = YES;
}


- (void)processCategory {
	NSDictionary *atts = self.xmlAttributesDict;
	NSString *scheme = [atts objectForKey:RSFeedScheme];
	if (!RSStringIsEmpty(scheme) && [scheme caseInsensitiveContains:RSFeedGoogleComSlashReader]) {
		[self processStatusCategory];
		return;
	}
	NSString *category = [atts objectForKey:RSFeedTerm];
	if (!RSStringIsEmpty(category))
		[self.newsItem addCategory:category];
}


- (void)processTitle {
	NSString *title = [self currentString];
	if (RSStringIsEmpty(title))
		return;
	NSString *type = [self.xmlAttributesDict objectForKey:RSFeedType];
	if (type && [type isEqualToString:RSFeedHTML])
		self.newsItem.titleIsHTML = YES;
	self.newsItem.title = title;
}


- (NSString *)mimeTypeForURLString:(NSString *)urlString {
	urlString = [NSString stringWithQueryStripped:urlString];
	if ([urlString hasSuffix:RSJJPEGSUffix])
		return RSJPEGMimeType;
	if ([urlString hasSuffix:RSPNGSuffix])
		return RSPNGMimeType;
	if ([urlString hasSuffix:RSGIFSuffix])
		return RSGIFMimeType;
	if ([urlString hasSuffix:RSMOVSuffix] || [urlString hasSuffix:RSQTSuffix])
		return RSVideoQuicktimeMimeType;
	if ([urlString hasSuffix:RSMPGSuffix])
		return RSVideoMpegMimeType;
	if ([urlString hasSuffix:RSMP4Suffix])
		return RSVideoMP4MimeType;
	if ([urlString hasSuffix:RSAIFFSuffix])
		return RSAudioAIFFMimeType;
	if ([urlString hasSuffix:RSMP3Suffix])
		return RSAudioMP3MimeType;
	if ([urlString hasSuffix:RSM4ASuffix])
		return RSAudioXM4AMimeType;
	if ([urlString hasSuffix:RSM4VSuffix])
		return RSVideoXM4VMimeType;
	return nil;
}


- (NSMutableDictionary *)enclosureDictWithURLString:(NSString *)urlString {
	for (NSMutableDictionary *oneEnclosure in self.newsItem.enclosures) {
		if ([[oneEnclosure objectForKey:RSFeedEnclosureURL] isEqualToString:urlString])
			return oneEnclosure;
	}
	NSMutableDictionary *enclosureDict = [NSMutableDictionary dictionary];
	[enclosureDict setObject:urlString forKey:RSFeedEnclosureURL];
	[self.newsItem addEnclosure:enclosureDict];
	return enclosureDict;
}


- (void)processEnclosure {
	NSDictionary *atts = self.xmlAttributesDict;
	NSString *href = [atts objectForKey:RSFeedHref];
	if (RSStringIsEmpty(href))
		return;
	NSMutableDictionary *d = [self enclosureDictWithURLString:href];
	[d safeSetObject:[atts objectForKey:RSFeedLength] forKey:RSFeedEnclosureLength];
	NSString *enclosureType = [atts objectForKey:RSFeedType];
	if (RSStringIsEmpty(enclosureType))
		enclosureType = [self mimeTypeForURLString:href];
	[d safeSetObject:enclosureType forKey:RSFeedEnclosureType];
}


- (void)processMediaContent {
	NSDictionary *atts = self.xmlAttributesDict;
	NSString *href = [atts objectForKey:RSFeedURL];
	if (RSStringIsEmpty(href))
		return;
	NSMutableDictionary *d = [self enclosureDictWithURLString:href];
	if (RSStringIsEmpty([d objectForKey:RSFeedEnclosureType])) {
		NSString *enclosureType = [self mimeTypeForURLString:href];
		[d safeSetObject:enclosureType forKey:RSFeedEnclosureType];
	}
}


- (void)processMediaThumbnail {
	if (self.newsItem.mediaThumbnailURL != nil) // Spec says first thumbnail is most important <http://search.yahoo.com/mrss/>
		return;
	self.newsItem.mediaThumbnailURL = [self.xmlAttributesDict objectForKey:RSFeedURL];
}


- (void)processLink {
	NSDictionary *atts = self.xmlAttributesDict;
	NSString *rel = [atts objectForKey:RSFeedRel];
	if (RSStringIsEmpty(rel))
		return;
	NSString *href = [atts objectForKey:RSFeedHref];
	if (RSStringIsEmpty(href))
		return;
	if ([rel isEqualToString:RSFeedAlternate])
		self.newsItem.permalink = href;
	else if ([rel isEqualToString:RSFeedRelated])
		self.newsItem.link = href;
	else if ([rel isEqualToString:RSFeedEnclosure])
		[self processEnclosure];
}


- (void)processContent {
	NSString *content = [self currentString];
	if (RSStringIsEmpty(content))
		return;
	self.newsItem.xmlBaseURLForContent = [self.xmlAttributesDict objectForKey:RSFeedXMLBase];
	self.newsItem.content = content;
}


- (void)processSummary {
	NSString *summary = [self currentString];
	if (RSStringIsEmpty(summary))
		return;
	self.newsItem.xmlBaseURLForSummary = [self.xmlAttributesDict objectForKey:RSFeedXMLBase];
	self.newsItem.summary = summary;
}


- (void)processAuthor {
	NSString *authorName = [self currentString];
	if (RSStringIsEmpty(authorName) || [authorName caseInsensitiveContains:RSFeedUnknown])
		return;
	self.newsItem.author = authorName;
}


//static NSString *RSZSuffix = @"Z";

- (void)processDatePublished {
	self.newsItem.pubDateString = [self currentString];
//	NSString *dateString = [self currentString];
//	if (dateString != nil && [dateString hasSuffix:RSZSuffix]) {
//		dateString = [NSString stripSuffix:dateString suffix:RSZSuffix];
//		self.newsItem.pubDate = [gDateFormatter dateFromString:dateString];
//	}
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
			[self processMediaContent];
		else if (_xmlEqualTags(localName, kThumbnailTag, kThumbnailTagLength))
			[self processMediaThumbnail];
	}
}


- (void)processSourceStreamID {
	self.newsItem.googleSourceID = [self.xmlAttributesDict objectForKey:RSFeedGoogleStreamID];
}


- (void)processReadStateLocked {
	NSString *isReadStateLocked = [self.xmlAttributesDict objectForKey:RSFeedGoogleIsReadStateLocked];
	if (isReadStateLocked != nil && [isReadStateLocked isEqualToString:RSFeedTrue])
		self.newsItem.googleReadStateLocked = YES;
}


- (void)processCrawlTimestamp {
	self.newsItem.googleCrawlTimestampString = [self.xmlAttributesDict objectForKey:RSFeedGoogleCrawlTimestamp];
//	[self.newsItem setGoogleCrawlTimestampWithString:[self.xmlAttributesDict objectForKey:RSFeedGoogleCrawlTimestamp]];
}


//static NSString *RSHTMLLeftCaret = @"<";
//static NSString *RSHTMLItalicTagStart = @"<i>";
//static NSString *RSHTMLItalicTagEnd = @"</i>";
//static NSString *RSHTMLBoldTagStart = @"<b>";
//static NSString *RSHTMLBoldTagEnd = @"</b>";
//static NSString *RSHTMLEmptyString = @"";
//
//- (void)addPlainTextElements {
//	NSMutableString *plainTextTitle = [[self.newsItem.title mutableCopy] autorelease];
//	
//	if (!RSStringIsEmpty(plainTextTitle)) {
//		if ([plainTextTitle caseSensitiveContains:RSHTMLLeftCaret]) {
//			[plainTextTitle replaceOccurrencesOfString:RSHTMLItalicTagStart withString:RSHTMLEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [plainTextTitle length])];
//			[plainTextTitle replaceOccurrencesOfString:RSHTMLItalicTagEnd withString:RSHTMLEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [plainTextTitle length])];
//			[plainTextTitle replaceOccurrencesOfString:RSHTMLBoldTagStart withString:RSHTMLEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [plainTextTitle length])];
//			[plainTextTitle replaceOccurrencesOfString:RSHTMLBoldTagEnd withString:RSHTMLEmptyString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [plainTextTitle length])];
//		}
//		[plainTextTitle collapseWhitespace];
//		self.newsItem.plainTextTitle = plainTextTitle;
//	}
//	NSString *preview = self.newsItem.summary;
//	if (RSStringIsEmpty(preview))
//		preview = self.newsItem.content;
//	if (!RSStringIsEmpty(preview)) {
//		NSMutableString *s = [NSMutableString rs_mutableStringWithStrippedHTML:preview maxCharacters:600];
//		[s collapseWhitespace];
//		self.newsItem.preview = s;
//	}
//}


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

	if (_xmlEqualTags(prefix, kMediaTagPrefix, kMediaTagPrefixLength) && _xmlEqualTags(localName, kContentTag, kContentTagLength))
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
static const char *kLengthTag = "length";
static const NSUInteger kLengthTagLength = 7;
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
			return RSFeedLabel;
		if (_xmlEqualTags(localName, kSchemeTag, kSchemeTagLength))
			return RSFeedScheme;
		if (_xmlEqualTags(localName, kTermTag, kTermTagLength))
			return RSFeedTerm;
		if (_xmlEqualTags(localName, kTypeTag, kTypeTagLength))
			return RSFeedType;
		if (_xmlEqualTags(localName, kHrefTag, kHrefTagLength))
			return RSFeedHref;
		if (_xmlEqualTags(localName, kurlTag, kurlTagLength))
			return RSFeedURL;
		if (_xmlEqualTags(localName, kLengthTag, kLengthTagLength))
			return RSFeedLength;
		if (_xmlEqualTags(localName, kRelTag, kRelTagLength))
			return RSFeedRel;
		return nil;
	}

	if (_xmlEqualTags(prefix, kGRTag, kGRTagLength)) {
		if (_xmlEqualTags(localName, kStreamIDTag, kStreamIDTagLength))
			return RSFeedGoogleStreamID;
		if (_xmlEqualTags(localName, kCrawlTimestampTag, kCrawlTimestampTagLength))
			return RSFeedGoogleCrawlTimestamp;
		if (_xmlEqualTags(localName, kReadStateLockedTag, kReadStateLockedTagLength))
			return RSFeedGoogleIsReadStateLocked;
		return nil;
	}
	
	if (_xmlEqualTags(prefix, kXMLTag, kXMLTagLength) && _xmlEqualTags(localName, kBaseTag, kBaseTagLength))
		return RSFeedXMLBase;

	return nil;
}


#pragma mark Delegate

- (BOOL)callDelegateWithNewsItem:(RSParsedNewsItem *)aNewsItem {
	if (self.delegateRespondsToDidParseNewsItem)
		return [self.delegate feedParser:self didParseNewsItem:aNewsItem];
	return NO;
}


#pragma mark SAX Parsing Callbacks

static const char *kAuthorTag = "author";
static const NSUInteger kAuthorTag_Length = 7;


- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	self.xmlAttributesDict = nil;
	BOOL didAddToAttributesDict = NO;
	if (numberOfAttributes > 0 && attributes != nil && [self parserWantsAttributesForTagWithLocalName:(const char *)localName prefix:(const char *)prefix]) {
		NSMutableDictionary *attributesDict = [NSMutableDictionary dictionaryWithCapacity:numberOfAttributes];
		int i = 0, j = 0;
		for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {			
			NSString *attName = [self staticNameForLocalName:(const char *)attributes[j] prefix:(const char *)attributes[j + 1]];
			if (attName == nil)
				continue;
			NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
			NSMutableString *value = [[[NSMutableString alloc] initWithBytes:(const void *)attributes[j + 3] length:lenValue encoding:NSUTF8StringEncoding] autorelease];
			if (value)
				CFStringTrimWhitespace((CFMutableStringRef)value);
			[attributesDict setObject:value forKey:attName];
			didAddToAttributesDict = YES;
		}
		self.xmlAttributesDict = didAddToAttributesDict ? attributesDict : nil;
	}
	[_xmlAttributesStack addObject:didAddToAttributesDict ? (id)self.xmlAttributesDict : (id)[NSNull null]];
	
	if (prefix == nil && _xmlEqualTags(localName, kEntryTag, kEntryTagLength)) {
		[self addNewsItem:[[[RSParsedNewsItem alloc] init] autorelease]];
		self.parsingNewsItem = YES;
		goto _xmlStartElement_exit;
	}
	if (prefix == nil && _xmlEqualTags(localName, kAuthorTag, kAuthorTag_Length)) {
		self.parsingAuthor = YES;
		goto _xmlStartElement_exit;
	}
	if (prefix == nil && _xmlEqualTags(localName, kSourceTag, kSourceTagLength)) {
		self.parsingSource = YES;
		goto _xmlStartElement_exit;
	}
	if (self.parsingNewsItem)
		[self startStoringCharacters];
	
_xmlStartElement_exit:
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
		//[self addPlainTextElements];
		self.parsingNewsItem = NO;
		if (self.delegate && self.delegateRespondsToDidParseNewsItem) {
			if ([self callDelegateWithNewsItem:[self.newsItems lastObject]]) {
				[self.newsItems removeLastObject]; /*delegate consumes news items, to save memory*/			
				self.newsItem = nil;
			}
		}
	}
	else if (self.parsingNewsItem && !self.parsingSource)
		[self addNewsItemElement:(const char *)localName prefix:(const char *)prefix];
	else if (self.parsingSource)
		[self addSourceElement:(const char *)localName prefix:(const char *)prefix];
	else if (_xmlEqualTags(localName, kFeedTag, kFeedTagLength))
		[self.delegate feedParserDidComplete:self];
	[pool drain];
}

@end
