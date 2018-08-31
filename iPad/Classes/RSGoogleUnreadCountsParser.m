//
//  RSGoogleUnreadCountsParser.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleUnreadCountsParser.h"
#import "RSParsedGoogleUnreadCount.h"


@interface RSGoogleUnreadCountsParser ()
@property (nonatomic, retain, readwrite) NSMutableArray *unreadCounts;
@property (nonatomic, assign) BOOL inUnreadCountsList;
@property (nonatomic, assign) NSUInteger currentNameSpecifier;
@property (nonatomic, retain, readonly) RSParsedGoogleUnreadCount *currentUnreadCount;
@end


@implementation RSGoogleUnreadCountsParser

@synthesize unreadCounts, inUnreadCountsList, currentNameSpecifier;

#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	unreadCounts = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[unreadCounts release];
	[super dealloc];
}


#pragma mark Parsed Objects

- (void)addUnreadCount {
	[self.unreadCounts addObject:[[[RSParsedGoogleUnreadCount alloc] init] autorelease]];
}


- (RSParsedGoogleUnreadCount *)currentUnreadCount {
	return [self.unreadCounts lastObject];
}


#pragma mark Parser

enum RSGoogleSubsTagSpecifier {
	RSGoogleUnreadCountsUnknown,
	RSGoogleUnreadCountsObject,
	RSGoogleUnreadCountsList,
	RSGoogleUnreadCountsString,
	RSGoogleUnreadCountsNumber
};

static const char *kObjectTag = "object";
static const NSUInteger kObjectTagLength = 7;
static const char *kListTag = "list";
static const NSUInteger kListTagLength = 5;
static const char *kStringTag = "string";
static const NSUInteger kStringTagLength = 7;
static const char *kNumberTag = "number";
static const NSUInteger kNumberTagLength = 7;

static NSUInteger tagSpecifierWithNameAndPrefix(const xmlChar *localName, const xmlChar *prefix) {
	if (prefix != nil)
		return RSGoogleUnreadCountsUnknown;
	if (_xmlEqualTags(localName, kObjectTag, kObjectTagLength))
		return RSGoogleUnreadCountsObject;
	if (_xmlEqualTags(localName, kListTag, kListTagLength))
		return RSGoogleUnreadCountsList;
	if (_xmlEqualTags(localName, kStringTag, kStringTagLength))
		return RSGoogleUnreadCountsString;
	if (_xmlEqualTags(localName, kNumberTag, kNumberTagLength))
		return RSGoogleUnreadCountsNumber;
	return RSGoogleUnreadCountsUnknown;
}


enum RSGoogleSubsNameSpecifier {
	RSGoogleUnreadCountsNoName,
	RSGoogleUnreadCountsMax,
	RSGoogleUnreadCountsUnreadCounts,
	RSGoogleUnreadCountsID,
	RSGoogleUnreadCountsCount,
	RSGoogleUnreadCountsNewestItemTimestampUsec
};

static const char *kNameTag = "name";
static const NSUInteger kNameTagLength = 5;

static const char *kMaxValue = "max";
static NSUInteger kMaxValueLength = 3;
static const char *kUnreadCountsValue = "unreadcounts";
static NSUInteger kUnreadCountsValueLength = 12;

static const char *kIDValue = "id";
static NSUInteger kIDValueLength = 2;
static const char *kCountValue = "count";
static NSUInteger kCountValueLength = 5;
static const char *kNewestItemTimestampUsecValue = "newestItemTimestampUsec";
static NSUInteger kNewestItemTimestampUsecValueLength = 23;


static NSUInteger nameAttributeValueSpecifier(int numberOfAttributes, const xmlChar **attributes) {
	if (numberOfAttributes < 1 || attributes == nil)
		return RSGoogleUnreadCountsNoName;
	int i, j;
	for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {
		/*Not nil-terminated*/
		NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
		if (memcmp(kNameTag, (const void *)attributes[j], kNameTagLength - 1) != 0)
			continue;
		if (lenValue == kIDValueLength && memcmp(kIDValue, (const void *)attributes[j + 3], kIDValueLength) == 0)
			return RSGoogleUnreadCountsID;
		if (lenValue == kMaxValueLength && memcmp(kMaxValue, (const void *)attributes[j + 3], kMaxValueLength) == 0)
			return RSGoogleUnreadCountsMax;
		if (lenValue == kCountValueLength && memcmp(kCountValue, (const void *)attributes[j + 3], kCountValueLength) == 0)
			return RSGoogleUnreadCountsCount;
		if (lenValue == kUnreadCountsValueLength && memcmp(kUnreadCountsValue, (const void *)attributes[j + 3], kUnreadCountsValueLength) == 0)
			return RSGoogleUnreadCountsUnreadCounts;
		if (lenValue == kNewestItemTimestampUsecValueLength && memcmp(kNewestItemTimestampUsecValue, (const void *)attributes[j + 3], kNewestItemTimestampUsecValueLength) == 0)
			return RSGoogleUnreadCountsNewestItemTimestampUsec;
	}
	return RSGoogleUnreadCountsNoName;
	
}


- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUInteger tagSpecifier = tagSpecifierWithNameAndPrefix(localName, prefix);
	
	NSUInteger nameSpecifier = nameAttributeValueSpecifier(numberOfAttributes, attributes);
	
	if (tagSpecifier == RSGoogleUnreadCountsObject) {
		if (self.inUnreadCountsList)
			[self addUnreadCount];
	}
	
	else if (tagSpecifier == RSGoogleUnreadCountsList) {
		if (nameSpecifier == RSGoogleUnreadCountsUnreadCounts)
			self.inUnreadCountsList = YES;
	}
	
	else if (tagSpecifier == RSGoogleUnreadCountsString) {
		if (nameSpecifier == RSGoogleUnreadCountsID) {
			[self startStoringCharacters];
			self.currentNameSpecifier = nameSpecifier;
		}			
	}
	
	else if (tagSpecifier == RSGoogleUnreadCountsNumber) {
		if (nameSpecifier == RSGoogleUnreadCountsCount || nameSpecifier == RSGoogleUnreadCountsNewestItemTimestampUsec) {
			[self startStoringCharacters];
			self.currentNameSpecifier = nameSpecifier;
		}
	}
	
	[pool drain];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUInteger tagSpecifier = tagSpecifierWithNameAndPrefix(localName, prefix);
	
	if (tagSpecifier == RSGoogleUnreadCountsList)
		self.inUnreadCountsList = NO;
	
	else if (tagSpecifier == RSGoogleUnreadCountsString || tagSpecifier == RSGoogleUnreadCountsNumber) {
		if (self.inUnreadCountsList) {
			if (self.currentNameSpecifier == RSGoogleUnreadCountsID)
				self.currentUnreadCount.googleID = [self currentString];
			else if (self.currentNameSpecifier == RSGoogleUnreadCountsCount)
				self.currentUnreadCount.unreadCount = [[self currentString] integerValue];
			else if (self.currentNameSpecifier == RSGoogleUnreadCountsNewestItemTimestampUsec)
				[self.currentUnreadCount setGoogleCrawlDateOfMostRecentUnreadItemWithString:[self currentString]];
		}
	}
	
	self.currentNameSpecifier = RSGoogleUnreadCountsNoName;
	[self endStoringCharacters];
	[pool drain];
}

@end


/*Sample:

 <object><number name="max">1000</number><list name="unreadcounts">
 
 <object>
 <string name="id">feed/http://www.red-sweater.com/blog/feed/</string>
 <number name="count">8</number>
 <number name="newestItemTimestampUsec">1262153409151274</number>
 </object>


*/