//
//  RSGoogleReaderSubsListParser.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/27/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleReaderSubsListParser.h"
#import "RSGoogleReaderParsedSub.h"
#import "RSFoundationExtras.h"


@interface RSGoogleReaderSubsListParser ()
@property (nonatomic, assign) NSUInteger currentNameSpecifier;
@property (nonatomic, assign) BOOL inSubsList;
@property (nonatomic, assign) BOOL inSub;
@property (nonatomic, assign) BOOL inCategories;
@property (nonatomic, retain, readonly) RSGoogleReaderParsedSub *currentSub;
@property (nonatomic, retain) NSString *lastCategoryID;
@property (nonatomic, retain) NSString *lastCategoryLabel;
@end


@implementation RSGoogleReaderSubsListParser

@synthesize subs, currentNameSpecifier, inSubsList, inSub, inCategories, lastCategoryID, lastCategoryLabel;


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	subs = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[RSGoogleReaderParsedCategory emptyCategoryCache];
	[subs release];
	[lastCategoryID release];
	[lastCategoryLabel release];
	[super dealloc];
}


#pragma mark Parsed Objects

- (void)addSub {
	[self.subs addObject:[[[RSGoogleReaderParsedSub alloc] init] autorelease]];
}


- (RSGoogleReaderParsedSub *)currentSub {
	return [self.subs lastObject];
}


#pragma mark Parser

enum RSGoogleSubsTagSpecifier {
	RSGoogleSubsUnknown,
	RSGoogleSubsObject,
	RSGoogleSubsList,
	RSGoogleSubsString,
	RSGoogleSubsNumber
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
		return RSGoogleSubsUnknown;
	if (_xmlEqualTags(localName, kObjectTag, kObjectTagLength))
		return RSGoogleSubsObject;
	if (_xmlEqualTags(localName, kListTag, kListTagLength))
		return RSGoogleSubsList;
	if (_xmlEqualTags(localName, kStringTag, kStringTagLength))
		return RSGoogleSubsString;
	if (_xmlEqualTags(localName, kNumberTag, kNumberTagLength))
		return RSGoogleSubsNumber;
	return RSGoogleSubsUnknown;
}


enum RSGoogleSubsNameSpecifier {
	RSGoogleSubsNoName,
	RSGoogleSubsID,
	RSGoogleSubsTitle,
	RSGoogleSubsCategories,
	RSGoogleSubsLabel,
	RSGoogleSubsSortID,
	RSGoogleSubsFirstItemMsec,
	RSGoogleSubsSubscriptions
};

static const char *kNameTag = "name";
static const NSUInteger kNameTagLength = 5;

static const char *kIDValue = "id";
static NSUInteger kIDValueLength = 2;
static const char *kTitleValue = "title";
static NSUInteger kTitleValueLength = 5;
static const char *kCategoriesValue = "categories";
static NSUInteger kCategoriesValueLength = 10;
static const char *kLabelValue = "label";
static NSUInteger kLabelValueLength = 5;
static const char *kFirstItemMMsecValue = "firstitemmsec";
static NSUInteger kFirstItemMMsecValueLength = 13;
static const char *kSubscriptionsValue = "subscriptions";
static NSUInteger kSubscriptionsValueLength = 13;

static NSUInteger nameAttributeValueSpecifier(int numberOfAttributes, const xmlChar **attributes) {
	if (numberOfAttributes < 1 || attributes == nil)
		return RSGoogleSubsNoName;
	int i, j;
	for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {
		/*Not nil-terminated*/
		NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
		if (lenValue == kNameTagLength - 1 && memcmp(kNameTag, (const void *)attributes[j], kNameTagLength - 1) == 0)
			continue;
		if (lenValue == kIDValueLength && memcmp(kIDValue, (const void *)attributes[j + 3], kIDValueLength) == 0)
			return RSGoogleSubsID;
		if (lenValue == kTitleValueLength && memcmp(kTitleValue, (const void *)attributes[j + 3], kTitleValueLength) == 0)
			return RSGoogleSubsTitle;
		if (lenValue == kCategoriesValueLength && memcmp(kCategoriesValue, (const void *)attributes[j + 3], kCategoriesValueLength) == 0)
			return RSGoogleSubsCategories;
		if (lenValue == kLabelValueLength && memcmp(kLabelValue, (const void *)attributes[j + 3], kLabelValueLength) == 0)
			return RSGoogleSubsLabel;
		if (lenValue == kFirstItemMMsecValueLength && memcmp(kFirstItemMMsecValue, (const void *)attributes[j + 3], kFirstItemMMsecValueLength) == 0)
			return RSGoogleSubsFirstItemMsec;
		if (lenValue == kSubscriptionsValueLength && memcmp(kSubscriptionsValue, (const void *)attributes[j + 3], kSubscriptionsValueLength) == 0)
			return RSGoogleSubsSubscriptions;
	}
	return RSGoogleSubsNoName;
	
}


- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUInteger tagSpecifier = tagSpecifierWithNameAndPrefix(localName, prefix);
	
	NSUInteger nameSpecifier = nameAttributeValueSpecifier(numberOfAttributes, attributes);
	
	if (tagSpecifier == RSGoogleSubsObject) {
		self.lastCategoryID = nil;
		self.lastCategoryLabel = nil;
		if (self.inSubsList && !self.inCategories)
			[self addSub];
	}
	
	else if (tagSpecifier == RSGoogleSubsList) {
		if (nameSpecifier == RSGoogleSubsSubscriptions)
			self.inSubsList = YES;
		else if (nameSpecifier == RSGoogleSubsCategories)
			self.inCategories = YES;
	}
	
	else if (tagSpecifier == RSGoogleSubsString) {
		if (nameSpecifier == RSGoogleSubsID || nameSpecifier == RSGoogleSubsTitle || nameSpecifier == RSGoogleSubsLabel) {
			[self startStoringCharacters];
			self.currentNameSpecifier = nameSpecifier;
		}			
	}
	
	else if (tagSpecifier == RSGoogleSubsNumber && nameSpecifier == RSGoogleSubsFirstItemMsec) {
		[self startStoringCharacters];
		self.currentNameSpecifier = nameSpecifier;
	}
	
	[pool drain];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUInteger tagSpecifier = tagSpecifierWithNameAndPrefix(localName, prefix);

	if (tagSpecifier == RSGoogleSubsObject && self.inCategories) {
		if (!RSStringIsEmpty(self.lastCategoryID)) {
			RSGoogleReaderParsedCategory *category = [RSGoogleReaderParsedCategory categoryWithGoogleID:self.lastCategoryID];
			[category setLabelIfNotSet:self.lastCategoryLabel];
			[self.currentSub addCategory:category];
		}
	}
	
	else if (tagSpecifier == RSGoogleSubsList) {
		if (self.inCategories)
			self.inCategories = NO;
		else
			self.inSubsList = NO;
	}
	
	else if (tagSpecifier == RSGoogleSubsString || tagSpecifier == RSGoogleSubsNumber) {
		if (self.inCategories) {
			if (self.currentNameSpecifier == RSGoogleSubsID)
				self.lastCategoryID = [self currentString];
			else if (self.currentNameSpecifier == RSGoogleSubsLabel)
				self.lastCategoryLabel = [self currentString];
		}
		else if (self.inSubsList) {
			if (self.currentNameSpecifier == RSGoogleSubsID)
				self.currentSub.googleID = [self currentString];
			else if (self.currentNameSpecifier == RSGoogleSubsTitle)
				self.currentSub.title = [self currentString];
			else if (self.currentNameSpecifier == RSGoogleSubsFirstItemMsec)
				self.currentSub.firstItemMsec = [self currentString];
		}
	}
	
	self.currentNameSpecifier = RSGoogleSubsNoName;
	[self endStoringCharacters];
	[pool drain];
}


@end


/*Sample:

 <object><list name="subscriptions">
 
 <object>
	<string name="id">feed/http://adventuresinnewfield.blogspot.com/feeds/posts/default</string>
	<string name="title">Adventures in Newfield</string>
	<list name="categories">
		<object>
			<string name="id">user/17882419235735304147/label/Family</string>
			<string name="label">Family</string>
		</object>
	</list>
	<string name="sortid">A09D9CA8</string>
	<number name="firstitemmsec">1251139776067</number>
 </object>

 */
