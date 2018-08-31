//
//  RSAbstractFeedParser.m
//  RSCoreTests
//
//  Created by Brent Simmons on 5/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSAbstractFeedParser.h"
#import "RSFoundationExtras.h"
#import "RSParsedEnclosure.h"
#import "RSParsedNewsItem.h"


@implementation RSAbstractFeedParser

@synthesize headerItems;
@synthesize newsItems;
@synthesize newsItem;
@synthesize delegate;
@synthesize delegateRespondsToDidParseNewsItem;
@synthesize parsingNewsItem;
@synthesize feedTitle;
@synthesize feedHomePageURL;


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	headerItems = [[NSMutableDictionary dictionary] retain];
	newsItems = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[feedTitle release];
	[feedHomePageURL release];
	[headerItems release];
	[newsItems release];
	[newsItem release];
	[super dealloc];
}


#pragma mark Delegate

- (void)setDelegate:(id<RSFeedParserDelegate>)aDelegate {
	delegate = aDelegate;
	self.delegateRespondsToDidParseNewsItem = [(id)delegate respondsToSelector:@selector(feedParser:didParseNewsItem:)];
}


- (BOOL)callDelegateWithNewsItem {
	if (self.delegateRespondsToDidParseNewsItem)
		return [self.delegate feedParser:self didParseNewsItem:self.newsItem];
	return NO;
}


- (void)removeNewsItemIfDelegateWishes {
	if ([self callDelegateWithNewsItem]) {
		self.newsItem = nil;
		[self.newsItems removeLastObject];
	}
}


- (void)notifyDelegateThatFeedParserDidComplete {
	if (self.delegate != nil && [(id)(self.delegate) respondsToSelector:@selector(feedParserDidComplete:)])
		[self.delegate feedParserDidComplete:self];
}


#pragma mark -
#pragma mark Parser

- (void)addHeaderItem:(const char *)localName prefix:(const char *)prefix {
	[self addItemToDictionary:localName prefix:prefix dictionary:self.headerItems];
}


- (void)addNewsItem {
	self.newsItem = [[[RSParsedNewsItem alloc] init] autorelease];
	[self.newsItems addObject:self.newsItem];
}


- (BOOL)hasEnclosureWithURLString:(NSString *)urlString {
	if (RSStringIsEmpty(urlString))
		return NO;
	for (RSParsedEnclosure *oneEnclosure in self.newsItem.enclosures) {
		if ([urlString isEqualToString:oneEnclosure.urlString])
			return YES;
	}
	return NO;
}


static NSString *rs_href = @"href";
static NSString *rs_url = @"url";

- (void)processEnclosure {
	NSString *enclosureURLString = [self.xmlAttributesDict objectForKey:rs_url];
	if (RSStringIsEmpty(enclosureURLString))
		enclosureURLString = [self.xmlAttributesDict objectForKey:rs_href];	
	if (![self hasEnclosureWithURLString:enclosureURLString])
		[self.newsItem addEnclosure:[[[RSParsedEnclosure alloc] initWithFeedEnclosureDictionary:self.xmlAttributesDict] autorelease]];
}


- (void)addThumbnailURLIfNoThumbnail:(NSString *)urlString {
	if (RSStringIsEmpty(self.newsItem.mediaThumbnailURL))
		self.newsItem.mediaThumbnailURL = urlString;
}


- (void)processMediaThumbnail {
	/*Spec says first thumbnail is most important <http://search.yahoo.com/mrss/>*/
	[self addThumbnailURLIfNoThumbnail:[self.xmlAttributesDict objectForKey:rs_url]];
}


static NSString *RSMediaCreditRoleKey = @"role";
static NSString *RSMediaCreditPhotographer = @"photographer";

- (void)processMediaCredit {
	BOOL newsItemHasMediaCredit = !RSStringIsEmpty(self.newsItem.mediaCredit);
	if (newsItemHasMediaCredit && self.newsItem.mediaCreditRoleIsPhotographer)
		return;
	NSString *role = [self.xmlAttributesDict objectForKey:RSMediaCreditRoleKey];
	NSString *credit = [self currentString];
	if (role != nil && [role caseInsensitiveCompare:RSMediaCreditPhotographer] == NSOrderedSame && !RSStringIsEmpty(credit)) {
		self.newsItem.mediaCredit = credit;
		self.newsItem.mediaCreditRoleIsPhotographer = YES;
		return;
	}
	if (!newsItemHasMediaCredit)
		self.newsItem.mediaCredit = credit;
}


- (void)addNewsItemElement:(const char *)localName prefix:(const char *)prefix {
}


- (BOOL)parserWantsAttributesForTagWithLocalName:(const char *)localName prefix:(const char *)prefix {
	return NO;
}


- (NSString *)staticNameForLocalName:(const char *)localName prefix:(const char *)prefix {
	return nil;
}


- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.xmlAttributesDict = nil;
	BOOL didAddToAttributesDict = NO;
	if (numberOfAttributes > 0 && attributes != nil && [self parserWantsAttributesForTagWithLocalName:(const char *)localName prefix:(const char *)prefix]) {
		/*Uses special CFMutableDictionary that does not copy keys, eliminating needless cycles and memory allocation.
		 Because of toll-free bridging, it's okay that it's treated like an NSMutableDictionary elsewhere,
		 since this is the only place where values are added to the dictionary.*/
		CFMutableDictionaryRef attributesDict = CFDictionaryCreateMutable(kCFAllocatorDefault, numberOfAttributes, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		int i = 0, j = 0;
		for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {			
			NSString *attName = [self staticNameForLocalName:(const char *)attributes[j] prefix:(const char *)attributes[j + 1]];
			if (attName == nil)
				continue;
			NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
			NSMutableString *value = [[[NSMutableString alloc] initWithBytes:(const void *)attributes[j + 3] length:lenValue encoding:NSUTF8StringEncoding] autorelease];
			if (value == nil)
				continue;
			CFStringTrimWhitespace((CFMutableStringRef)value);
			CFDictionarySetValue(attributesDict, (CFStringRef)attName, (CFStringRef)value); //Must use CFDictionarySetValue to avoid key-copying
			didAddToAttributesDict = YES;
		}
		self.xmlAttributesDict = didAddToAttributesDict ? (__bridge_transfer NSMutableDictionary *)attributesDict : nil;
		//CFRelease(attributesDict);
	}
	[_xmlAttributesStack addObject:didAddToAttributesDict ? (id)self.xmlAttributesDict : (id)[NSNull null]];
	[pool drain];
}


@end
