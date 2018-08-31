//
//  RSAtomParser.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/2/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSAtomParser.h"
#import "RSFoundationExtras.h"
#import "RSParsedNewsItem.h"


@interface RSAtomParser ()

@property (nonatomic, assign) BOOL inSource;
@property (nonatomic, assign) BOOL inXHTML;
@property (nonatomic, assign) BOOL parsingAuthor;
@property (nonatomic, strong) NSURL *xmlBaseURLForEntry;
@property (nonatomic, strong) NSURL *xmlBaseURLForFeed;
@end

@implementation RSAtomParser

@synthesize inSource;
@synthesize inXHTML;
@synthesize parsingAuthor;
@synthesize xmlBaseURLForEntry;
@synthesize xmlBaseURLForFeed;

#pragma mark Dealloc



#pragma mark Parser

- (void)processID {
    self.newsItem.guid = [self currentString];
}


static NSString *rs_term = @"term";

- (void)processCategory {
    NSString *category = [self.xmlAttributesDict objectForKey:rs_term];
    if (!RSStringIsEmpty(category))
        [self.newsItem addCategory:category];
}


static NSString *rs_type = @"type";
static NSString *rs_html = @"html";
static NSString *rs_xhtml = @"xhtml";

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

static NSString *rs_http_prefix = @"http";

- (NSString *)expandedURLString:(NSString *)aURLString {
    /*Expand with xml:base*/
    if (RSStringIsEmpty(aURLString) || [aURLString hasPrefix:rs_http_prefix] || self.xmlBaseURLForEntry == nil)
        return aURLString;
    NSURL *expandedURL = [NSURL URLWithString:aURLString relativeToURL:self.xmlBaseURLForEntry];
    if (expandedURL == nil)
        return aURLString;
    return [expandedURL absoluteString];
}


- (void)processLink {
    NSDictionary *atts = self.xmlAttributesDict;
    NSString *rel = [atts objectForKey:rs_rel];
    NSString *href = [atts objectForKey:rs_href];
    if (RSStringIsEmpty(href))
        return;
    if (RSStringIsEmpty(rel) || [rel isEqualToString:rs_alternate])
        self.newsItem.permalink = [self expandedURLString:href];
    else if ([rel isEqualToString:rs_related])
        self.newsItem.link = [self expandedURLString:href];
    else if ([rel isEqualToString:rs_enclosure])
        [self processEnclosure];
    else if ([rel isEqualToString:rs_image])
        [self addThumbnailURLIfNoThumbnail:href];
}


- (void)processHeaderLink {
    if (self.feedHomePageURL != nil)
        return;
    NSDictionary *atts = self.xmlAttributesDict;
    NSString *rel = [atts objectForKey:rs_rel];
    if (rel == nil || ![rel isEqualToString:rs_alternate])
        return;
    NSString *href = [atts objectForKey:rs_href];
    if (RSStringIsEmpty(href))
        return;
    self.feedHomePageURL = href;
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


- (void)processFeedTag {
    NSString *xmlBaseURL = [self.xmlAttributesDict objectForKey:rs_xmlBase];
    if (!RSStringIsEmpty(xmlBaseURL))
        self.xmlBaseURLForFeed = [NSURL URLWithString:xmlBaseURL];
}


- (void)addNewsItem {
    [super addNewsItem];
    NSString *xmlBaseURL = [self.xmlAttributesDict objectForKey:rs_xmlBase];
    if (RSStringIsEmpty(xmlBaseURL) && self.xmlBaseURLForFeed == nil) {
        self.xmlBaseURLForEntry = nil;
        return;
    }
    if (self.xmlBaseURLForFeed == nil) {
        self.xmlBaseURLForEntry = [NSURL URLWithString:xmlBaseURL];
        return;
    }
    if (xmlBaseURL == nil)
        self.xmlBaseURLForEntry = self.xmlBaseURLForFeed;
    else
        self.xmlBaseURLForEntry = [NSURL URLWithString:xmlBaseURL relativeToURL:self.xmlBaseURLForFeed];            
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
    //self.newsItem.pubDateString = [self currentString];
}


static const char *kIDTag = "id";
static const NSUInteger kIDTagLength = 3;
static const char *kCategoryTag = "category";
static const NSUInteger kCategoryTagLength = 9;
static const char *kTitleTag = "title";
static const NSUInteger kTitleTagLength = 6;
static const char *kPublishedTag = "published";
static const NSUInteger kPublishedTagLength = 10;
static const char *kIssuedTag = "issued"; //Atom 0.3
static const NSUInteger kIssuedTagLength = 7;
static const char *kUpdatedTag = "updated";
static const NSUInteger kUpdatedTagLength = 8;
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
        else if (_xmlEqualTags(localName, kPublishedTag, kPublishedTagLength) || _xmlEqualTags(localName, kIssuedTag, kIssuedTagLength))
            [self processDatePublished];
        else if (_xmlEqualTags(localName, kUpdatedTag, kUpdatedTagLength))
            self.newsItem.dateModified = [self currentDate];
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


static const char *kEntryTag = "entry";
static const NSUInteger kEntryTagLength = 6;
static const char *kSourceTag = "source";
static const NSUInteger kSourceTagLength = 7;
static const char *kFeedTag = "feed";
static const NSUInteger kFeedTagLength = 5;


- (BOOL)parserWantsAttributesForTagWithLocalName:(const char *)localName prefix:(const char *)prefix {
    if (prefix == nil)
        return _xmlEqualTags(localName, kCategoryTag, kCategoryTagLength) || _xmlEqualTags(localName, kTitleTag, kTitleTagLength) || _xmlEqualTags(localName, kLinkTag, kLinkTagLength) || _xmlEqualTags(localName, kContentTag, kContentTagLength) || _xmlEqualTags(localName, kSummaryTag, kSummaryTagLength) || _xmlEqualTags(localName, kEntryTag, kEntryTagLength) || _xmlEqualTags(localName, kFeedTag, kFeedTagLength);
    /*media:thumbnail and media:content*/
    if (_xmlEqualTags(prefix, kMediaTagPrefix, kMediaTagPrefixLength) && (_xmlEqualTags(localName, kThumbnailTag, kThumbnailTagLength) || _xmlEqualTags(localName, kContentTag, kContentTagLength)))
        return YES;
    return NO;
}


//static const char *kLabelTag = "label";
//static const NSUInteger kLabelTagLength = 6;
//static const char *kSchemeTag = "scheme";
//static const NSUInteger kSchemeTagLength = 7;
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
static const char *kXMLTag = "xml";
static const NSUInteger kXMLTagLength = 4;
static const char *kBaseTag = "base";
static const NSUInteger kBaseTagLength = 5;


- (NSString *)staticNameForLocalName:(const char *)localName prefix:(const char *)prefix {
    if (prefix == nil) {
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
    
    if (_xmlEqualTags(prefix, kXMLTag, kXMLTagLength) && _xmlEqualTags(localName, kBaseTag, kBaseTagLength))
        return rs_xmlBase;
    
    return nil;
}


#pragma mark Handle Inline XHTML

static const char *kLeftCaret = "<";
static const NSUInteger kLeftCaretLength = 1;
static const char *kColon = ":";
static const NSUInteger kColonLength = 1;
static const char *kSpace = " ";
static const NSUInteger kSpaceLength = 1;
static const char *kEqualsDoubleQuote = "=\"";
static const NSUInteger kEqualsDoubleQuoteLength = 2;
static const char *kDoubleQuote = "\"";
static const NSUInteger kDoubleQuoteLength = 1;
static const char *kRightCaret = ">";
static const NSUInteger kRightCaretLength = 1;

static NSString *doubleQuote = @"\"";
static NSString *doubleQuoteEntity = @"&quot;";

- (void)addInlineElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
    /*Recreate the start of the tag with its attributes. Add as data to the current character buffer. This is part of handling Atom XHTML, which appears inline rather than escaped or in CDATA.*/
    /*Add <localName att="value" att2="value2">*/
    if (localName == nil)
        return;
    [self appendCharacters:kLeftCaret length:kLeftCaretLength]; // <
    if (prefix != nil) {
        [self appendUTF8String:(const char *)prefix];// <prefix
        [self appendCharacters:kColon length:kColonLength]; // <prefix:
    }
    [self appendUTF8String:(const char *)localName]; // <prefix:tag

    @autoreleasepool {
        if (numberOfAttributes > 0 && attributes != nil) {
            NSInteger i = 0, j = 0;
            for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {
                [self appendCharacters:kSpace length:kSpaceLength]; // <prefix:tag 
                const char *attPrefix = (const char *)attributes[j + 1];
                const char *attName = (const char *)attributes[j];
                if (attName == nil)
                    continue;
                NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
                if (lenValue < 1)
                    continue;            
                if (attPrefix != nil) {
                    [self appendUTF8String:attPrefix]; // <prefix:tag attPrefix
                    [self appendCharacters:kColon length:kColonLength]; // <prefix:tag attPrefix:
                }
                [self appendUTF8String:attName]; // <prefix:tag attPrefix:attName
                [self appendCharacters:kEqualsDoubleQuote length:kEqualsDoubleQuoteLength]; // <prefix:tag attPrefix:attName="
                /*if value contains a " character, we need to escape it with &quot;*/
                const char *value = (const char *)attributes[j + 3];
                if (strchr(value, '"') != nil) {
                    NSMutableString *valueMutable = [[NSMutableString alloc] initWithBytes:(const void *)value length:lenValue encoding:NSUTF8StringEncoding];
                    [valueMutable replaceOccurrencesOfString:doubleQuote withString:doubleQuoteEntity options:NSLiteralSearch range:NSMakeRange(0, [valueMutable length])];
                    [self appendUTF8String:[valueMutable UTF8String]]; // <prefix:tag attPrefix:attName="va&quot;lue                
                }
                else //fast way if no quotes
                    [self appendCharacters:value length:lenValue]; // <prefix:tag attPrefix:attName="value
                [self appendCharacters:kDoubleQuote length:kDoubleQuoteLength]; // <prefix:tag attPrefix:attName="value"
            }
        }
        [self appendCharacters:kRightCaret length:kRightCaretLength]; // <prefix:tag attPrefix:attName="value">
    }
}


static const char *kLeftCaretSlash = "</";
static const NSUInteger kLeftCaretSlashLength = 2;

- (void)addInlineEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
    if (localName == nil)
        return;
    [self appendCharacters:kLeftCaretSlash length:kLeftCaretSlashLength]; // </
    if (prefix != nil) {
        [self appendUTF8String:(const char *)prefix]; // </prefix
        [self appendCharacters:kColon length:kColonLength]; // </prefix:
    }
    [self appendUTF8String:(const char *)localName];  // </prefix:tag
    [self appendCharacters:kRightCaret length:kRightCaretLength];
}


#pragma mark SAX Parsing Callbacks

static const char *kAuthorTag = "author";
static const NSUInteger kAuthorTag_Length = 7;

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
    
    if (self.inXHTML) {
        [self addInlineElement:localName prefix:prefix uri:uri numberOfNamespaces:numberOfNamespaces namespaces:namespaces numberOfAttributes:numberOfAttributes numberDefaulted:numberDefaulted attributes:attributes];
        return;
    }
    
    [super xmlStartElement:localName prefix:prefix uri:uri numberOfNamespaces:numberOfNamespaces namespaces:namespaces numberOfAttributes:numberOfAttributes numberDefaulted:numberDefaulted attributes:attributes];
    
    @autoreleasepool {
        if (prefix == nil && _xmlEqualTags(localName, kSourceTag, kSourceTagLength))
            self.inSource = YES;
        else if (prefix == nil && _xmlEqualTags(localName, kEntryTag, kEntryTagLength)) {
            [self addNewsItem];
            self.parsingNewsItem = YES;
        }
        else if (prefix == nil && _xmlEqualTags(localName, kAuthorTag, kAuthorTag_Length))
            self.parsingAuthor = YES;
        else if (prefix == nil && (_xmlEqualTags(localName, kContentTag, kContentTagLength) || _xmlEqualTags(localName, kSummaryTag, kSummaryTagLength))) {
            NSString *contentType = [self.xmlAttributesDict objectForKey:rs_type];
            if (contentType != nil && [contentType isEqualToString:rs_xhtml])
                self.inXHTML = YES;
        }
        if (!self.inSource && (self.parsingNewsItem || (_xmlEqualTags(localName, kTitleTag, kTitleTagLength)))) //Want title from header
            [self startStoringCharacters];
        
        if (!self.parsingNewsItem && _xmlEqualTags(localName, kLinkTag, kLinkTagLength)) //home page URL
            [self processHeaderLink];
        if (!self.parsingNewsItem && _xmlEqualTags(localName, kFeedTag, kFeedTagLength)) //xml:base
            [self processFeedTag];
    }
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
    if (self.inXHTML) {
        if (_xmlEqualTags(localName, kContentTag, kContentTagLength) || _xmlEqualTags(localName, kSummaryTag, kSummaryTagLength)) { //done with inline xhtml?
            if (self.parsingNewsItem)
                [self addNewsItemElement:(const char *)localName prefix:(const char *)prefix];
            self.inXHTML = NO;
            return;
        }
        /*Not done with inline. Add close tag.*/
        [self addInlineEndElement:localName prefix:prefix uri:uri];
        return;
    }
    [super xmlEndElement:localName prefix:prefix uri:uri];
    if (_xmlEqualTags(localName, kAuthorTag, kAuthorTag_Length))
        self.parsingAuthor = NO;
    if (_xmlEqualTags(localName, kEntryTag, kEntryTagLength)) {
        self.parsingNewsItem = NO;
        [self removeNewsItemIfDelegateWishes];
    }
    else if (self.parsingNewsItem && !self.inSource)
        [self addNewsItemElement:(const char *)localName prefix:(const char *)prefix];
    else if (_xmlEqualTags(localName, kFeedTag, kFeedTagLength))
        [self notifyDelegateThatFeedParserDidComplete];
    else if (!self.parsingNewsItem)
        [self addHeaderItem:(const char *)localName prefix:(const char *)prefix];
    
    if (self.inSource) {
        if (_xmlEqualTags(localName, kSourceTag, kSourceTagLength))
            self.inSource = NO;
    }
    
}

@end
