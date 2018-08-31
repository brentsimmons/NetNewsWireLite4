//
//  RSRSSParser.m
//  nnw
//
//  Created by Brent Simmons on 2/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSRSSParser.h"
#import "RSFoundationExtras.h"
#import "RSParsedNewsItem.h"


@interface RSRSSParser ()
@property (nonatomic, assign) BOOL inImageTree;
@end


@implementation RSRSSParser

@synthesize inImageTree;


#pragma mark Parser

static NSString *RSRSSSourceURL = @"url";

- (void)processSource {
	self.newsItem.originalSourceName = [self currentString];
	self.newsItem.originalSourceURL = [self.xmlAttributesDict objectForKey:RSRSSSourceURL];
}


static NSString *RSRSSGuidIsPermalink = @"isPermaLink";
static NSString *RSRSSGuidIsPermalinkFalseValue = @"false";

- (void)processGuid {
	if ([self.characterBuffer length] < 1) //ignore empty guids
		return;
	self.newsItem.guid = [self currentString];
	NSString *guidIsPermalinkString = [self.xmlAttributesDict objectForKey:RSRSSGuidIsPermalink];
	BOOL guidIsPermalink = YES; //Guids default to being permalinks
	if (!RSStringIsEmpty(guidIsPermalinkString) && [guidIsPermalinkString isEqualToString:RSRSSGuidIsPermalinkFalseValue])
		guidIsPermalink = NO;
	self.newsItem.guidIsPermalink = guidIsPermalink;
	if (guidIsPermalink)
		self.newsItem.permalink = self.newsItem.guid;
}


static const char *kSourceTag = "source";
static const NSUInteger kSourceTagLength = 7;
static const char *kGuidTag = "guid";
static const NSUInteger kGuidTagLength = 5;
static const char *kEnclosureTag = "enclosure";
static const NSUInteger kEnclosureTagLength = 10;
static const char *kMediaTagPrefix = "media";
static const NSUInteger kMediaTagPrefixLength = 6;
static const char *kThumbnailTag = "thumbnail";
static const NSUInteger kThumbnailTagLength = 10;
static const char *kCreditTag = "credit";
static const NSUInteger kCreditTagLength = 7;
static const char *kContentTag = "content";
static const NSUInteger kContentTagLength = 8;
static const char *kCategoryTag = "category";
static const NSUInteger kCategoryTagLength = 9;
static const char *kDCTagPrefix = "dc";
static const NSUInteger kDCTagPrefixLength = 3;
static const char *kSubjectTag = "subject";
static const NSUInteger kSubjectTagLength = 8;
static const char *kCreatorTag = "creator";
static const NSUInteger kCreatorTagLength = 8;
static const char *kDateTag = "date";
static const NSUInteger kDateTagLength = 5;
static const char *kAuthorTag = "author";
static const NSUInteger kAuthorTagLength = 7;
static const char *kLinkTag = "link";
static const NSUInteger kLinkTagLength = 5;
static const char *kPubDateTag = "pubDate";
static const NSUInteger kPubDateTagLength = 8;
static const char *kTitleTag = "title";
static const NSUInteger kTitleTagLength = 6;
static const char *kDescriptionTag = "description";
static const NSUInteger kDescriptionTagLength = 12;
static const char *kEncodedTag = "encoded";
static const NSUInteger kEncodedTagLength = 8;
static const char *kiTunesTag = "itunes";
static const NSUInteger kiTunesTagLength = 7;
static const char *kSummaryTag = "summary";
static const NSUInteger kSummaryTagLength = 8;
static const char *kSubtitleTag = "subtitle";
static const NSUInteger kSubtitleTagLength = 9;

- (void)addNewsItemElement:(const char *)localName prefix:(const char *)prefix {

	if (prefix == nil) {
		if (_xmlEqualTags(localName, kSourceTag, kSourceTagLength))
			[self processSource];
		else if (_xmlEqualTags(localName, kGuidTag, kGuidTagLength))
			[self processGuid];
		else if (_xmlEqualTags(localName, kEnclosureTag, kEnclosureTagLength))
			[self processEnclosure];
		else if (_xmlEqualTags(localName, kCategoryTag, kCategoryTagLength))
			[self.newsItem addCategory:[self currentString]];
		else if (_xmlEqualTags(localName, kPubDateTag, kPubDateTagLength))
			self.newsItem.pubDate = [self currentDate];
		else if (_xmlEqualTags(localName, kAuthorTag, kAuthorTagLength))
			self.newsItem.authorEmail = [self currentString];
		else if (_xmlEqualTags(localName, kLinkTag, kLinkTagLength))
			self.newsItem.link = [self currentString];
		else if (_xmlEqualTags(localName, kTitleTag, kTitleTagLength))
			self.newsItem.title = [self currentString];
		else if (_xmlEqualTags(localName, kDescriptionTag, kDescriptionTagLength)) {
			/*Don't overwrite content if already set -- was probably set by content:encoded, which tends to be complete.*/
			if (RSStringIsEmpty(self.newsItem.content))
				self.newsItem.content = [self currentString];
		}
		return;
	}
	
	else if (_xmlEqualTags(prefix, kDCTagPrefix, kDCTagPrefixLength)) {
		if (_xmlEqualTags(localName, kSubjectTag, kSubjectTagLength)) //dc:subject
			[self.newsItem addCategory:[self currentString]];
		else if (_xmlEqualTags(localName, kCreatorTag, kCreatorTagLength)) // dc:creator
			self.newsItem.author = [self currentString];
		else if (_xmlEqualTags(localName, kDateTag, kDateTagLength)) //dc:date
			self.newsItem.pubDate = [self currentDate];
//			self.newsItem.pubDateString = [self currentString];
		return;
	}

	else if (_xmlEqualTags(prefix, kMediaTagPrefix, kMediaTagPrefixLength)) { //media
		if (_xmlEqualTags(localName, kThumbnailTag, kThumbnailTagLength))
			[self processMediaThumbnail];
		else if (_xmlEqualTags (localName, kContentTag, kContentTagLength))
			[self processEnclosure];
		else if (_xmlEqualTags(localName, kTitleTag, kTitleTagLength))
			self.newsItem.mediaTitle = [self currentString];
		else if (_xmlEqualTags(localName, kCreditTag, kCreditTagLength))
			[self processMediaCredit];
		return;
	}

	else if (_xmlEqualTags(prefix, kContentTag, kContentTagLength) && _xmlEqualTags(localName, kEncodedTag, kEncodedTagLength)) { //content:encoded
		self.newsItem.content = [self currentString];
		return;
	}
			
	else if (prefix != nil && _xmlEqualTags(prefix, kiTunesTag, kiTunesTagLength)) { //itunes: summary and subtitle
		if (_xmlEqualTags(localName, kSummaryTag, kSummaryTagLength))
			self.newsItem.itunesSummary = [self currentString];
		else if (_xmlEqualTags(localName, kSubtitleTag, kSubtitleTagLength))
			self.newsItem.itunesSubtitle = [self currentString];
		return;
	}
}


static const char *kItemTag = "item";
static const NSUInteger kItemTag_Length = 5;

- (BOOL)parserWantsAttributesForTagWithLocalName:(const char *)localName prefix:(const char *)prefix {
	if (prefix == nil)
		return _xmlEqualTags(localName, kGuidTag, kGuidTagLength) || _xmlEqualTags(localName, kEnclosureTag, kEnclosureTagLength) || _xmlEqualTags(localName, kSourceTag, kSourceTagLength) || _xmlEqualTags(localName, kItemTag, kItemTag_Length); //item tag because RSS 1.0. has rdf:about as the guid
	/*media:thumbnail and media:content*/
	if (_xmlEqualTags(prefix, kMediaTagPrefix, kMediaTagPrefixLength) && (_xmlEqualTags(localName, kThumbnailTag, kThumbnailTagLength) || _xmlEqualTags(localName, kContentTag, kContentTagLength) || _xmlEqualTags(localName, kCreditTag, kCreditTagLength)))
		return YES;
	return NO;		
}


static const char *kurlTag = "url";
static const NSUInteger kurlTagLength = 4;
static NSString *rs_url = @"url";

static const char *kisPermaLinkTag = "isPermaLink";
static const NSUInteger kisPermaLinkTagLength = 12;
static NSString *rs_isPermaLink = @"isPermaLink";

static const char *kLengthTag = "length";
static const NSUInteger kLengthTagLength = 7;
static NSString *rs_length = @"length";

static const char *kTypeTag = "type";
static const NSUInteger kTypeTagLength = 5;
static NSString *rs_type = @"type";

static const char *kWidthTag = "width";
static const NSUInteger kWidthTagLength = 6;
static NSString *rs_width = @"width";

static const char *kFileSizeTag = "fileSize";
static const NSUInteger kFileSizeTagLength = 9;
static NSString *rs_fileSize = @"fileSize";

static const char *kBitRateTag = "bitrate";
static const NSUInteger kBitRateTagLength = 8;
static NSString *rs_bitrate = @"bitrate";

static const char *kMediumTag = "medium";
static const NSUInteger kMediumTagLength = 7;
static NSString *rs_medium = @"medium";

static const char *kHeightTag = "height";
static const NSUInteger kHeightTagLength = 7;
static NSString *rs_height = @"height";

static const char *kRDFPrefix = "rdf";
static const NSUInteger kRDFPrefixLength = 4;
static const char *kAboutTag = "about";
static const NSUInteger kAboutTagLength = 6;
static NSString *rs_rdfAbout = @"rdf:about";

- (NSString *)staticNameForLocalName:(const char *)localName prefix:(const char *)prefix {
	if (_xmlEqualTags(localName, kurlTag, kurlTagLength))
		return rs_url;
	if (_xmlEqualTags(localName, kisPermaLinkTag, kisPermaLinkTagLength))
		return rs_isPermaLink;
	if (_xmlEqualTags(localName, kLengthTag, kLengthTagLength))
		return rs_length;
	if (_xmlEqualTags(localName, kTypeTag, kTypeTagLength))
		return rs_type;
	if (_xmlEqualTags(localName, kWidthTag, kWidthTagLength))
		return rs_width;
	if (_xmlEqualTags(localName, kFileSizeTag, kFileSizeTagLength))
		return rs_fileSize;
	if (_xmlEqualTags(localName, kBitRateTag, kBitRateTagLength))
		return rs_bitrate;
	if (_xmlEqualTags(localName, kMediumTag, kMediumTagLength))
		return rs_medium;
	if (_xmlEqualTags(localName, kHeightTag, kHeightTagLength))
		return rs_height;
	if (prefix != nil && _xmlEqualTags(prefix, kRDFPrefix, kRDFPrefixLength) && _xmlEqualTags(localName, kAboutTag, kAboutTagLength))
		return rs_rdfAbout;
	return nil;
}


- (void)addHeaderItem:(const char *)localName prefix:(const char *)prefix {
	if (prefix != nil)
		return;
	if (_xmlEqualTags(localName, kLinkTag, kLinkTagLength)) {
		if (RSStringIsEmpty(self.feedHomePageURL))
			self.feedHomePageURL = [self currentString];
	}
	else if (_xmlEqualTags(localName, kTitleTag, kTitleTagLength)) {
		if (RSStringIsEmpty(self.feedTitle))
			self.feedTitle = [self currentString];
	}
	[self endStoringCharacters];	
}


#pragma mark SAX Parsing Callbacks

static const char *kImageTag = "image";
static const NSUInteger kImageTag_Length = 6;

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	[super xmlStartElement:localName prefix:prefix uri:uri numberOfNamespaces:numberOfNamespaces namespaces:namespaces numberOfAttributes:numberOfAttributes numberDefaulted:numberDefaulted attributes:attributes];

    if (prefix == nil && _xmlEqualTags(localName, kItemTag, kItemTag_Length)) {
		[self addNewsItem];
		self.parsingNewsItem = YES;
		NSString *rdfAboutGuid = [self.xmlAttributesDict objectForKey:rs_rdfAbout];
		if (!RSStringIsEmpty(rdfAboutGuid))
			self.newsItem.guid = rdfAboutGuid;
		return;
	}	
	else if (prefix == nil && _xmlEqualTags(localName, kImageTag, kImageTag_Length))
		self.inImageTree = YES;
	if (!self.inImageTree)
		[self startStoringCharacters];
}


static const char *kRSSTag = "rss";
static const NSUInteger kRSSTagLength = 4;

- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	[super xmlEndElement:localName prefix:prefix uri:uri];
	if (_xmlEqualTags(localName, kRSSTag, kRSSTagLength)) {
		[self notifyDelegateThatFeedParserDidComplete];
		return;
	}
	if (_xmlEqualTags(localName, kImageTag, kImageTag_Length))
		self.inImageTree = NO;
	else if (_xmlEqualTags(localName, kItemTag, kItemTag_Length)) {
		self.parsingNewsItem = NO;
		[self removeNewsItemIfDelegateWishes];
	}
	else if (self.parsingNewsItem)
		[self addNewsItemElement:(const char *)localName prefix:(const char *)prefix];
	else
		[self addHeaderItem:(const char *)localName prefix:(const char *)prefix];
}


@end

