//
//  RSGoogleReaderItemIDsParser.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleReaderItemIDsParser.h"
#import "RSFoundationExtras.h"


@interface RSParsedGoogleItemID ()

@property (nonatomic, retain, readwrite) NSString *itemID;
@property (nonatomic, retain, readwrite) NSMutableArray *directStreamIDs;
@property (nonatomic, assign, readwrite) NSTimeInterval timestamp;
@property (nonatomic, assign, readwrite) BOOL read;
@property (nonatomic, assign, readwrite) BOOL starred;

- (void)addDirectStreamID:(NSString *)streamID;
//- (void)reset; // So we can use this more than once: saves some memory alloc + dealloc.

@end

@implementation RSParsedGoogleItemID

@synthesize itemID;
@synthesize directStreamIDs;
@synthesize timestamp;
@synthesize read;
@synthesize starred;


- (void)dealloc {
	[itemID release];
	[directStreamIDs release];
	[super dealloc];
}


- (void)addDirectStreamID:(NSString *)streamID {
	if ([streamID hasSuffix:@"/state/com.google/starred"] && [streamID hasPrefix:@"user/"]) {
		self.starred = YES;
		return;
	}
	if ([streamID hasSuffix:@"/state/com.google/read"] && [streamID hasPrefix:@"user/"]) {
		self.read = YES;
		return;
	}
	if (RSIsEmpty(self.directStreamIDs))
		self.directStreamIDs = [NSMutableArray array];
	[self.directStreamIDs rs_safeAddObject:streamID];
}


- (NSString *)description {
	return [NSString stringWithFormat:@"%@ - %@ - %f - %@", [super description], self.itemID, self.timestamp, self.directStreamIDs];
}


@end


@interface RSGoogleReaderItemIDsParser ()
@property (nonatomic, retain, readwrite) NSMutableArray *itemIDs;
@property (nonatomic, assign) BOOL inList;
@property (nonatomic, assign) BOOL inItemID;
@property (nonatomic, assign) BOOL inTimestamp;
@property (nonatomic, retain) RSParsedGoogleItemID *currentID;
@property (nonatomic, assign, readonly) NSTimeInterval oldestAllowedTimestamp;
@property (nonatomic, assign) NSUInteger listLevel;
@end


@implementation RSGoogleReaderItemIDsParser

@synthesize itemIDs;
@synthesize inList;
@synthesize inItemID;
@synthesize inTimestamp;
@synthesize currentID;
@synthesize delegate;
@synthesize oldestAllowedTimestamp;
@synthesize shouldParseStreamIDs;
@synthesize shouldParseTimestamps;
@synthesize listLevel;

#pragma mark Init

- (id)init {
	self = [super init];
	if (!self)
		return nil;
	itemIDs = [[NSMutableArray array] retain];
	// Items older than this are ignored, because they're locked by Google.
	oldestAllowedTimestamp = [[NSDate rs_dateWithNumberOfDaysInThePast:30] timeIntervalSince1970];
//	currentID = [[RSParsedGoogleItemID alloc] init]; // Gets re-used rather than re-allocated
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[itemIDs release];
	[currentID release];
	[super dealloc];
}


#pragma mark Parser

- (NSString *)currentStringWithoutReplacingReferences {
	if ([_characterBuffer length] < 1)
		return nil;
	return [[[NSString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding] autorelease];
}


static NSString *RSGoogleItemIDHexFormat = @"%016qx";

- (NSString *)parsedItemID {
	NSString *signed64bitID = [self currentStringWithoutReplacingReferences];
	if (RSStringIsEmpty(signed64bitID)) {
		NSLog(@"signed64bitID is empty: %@", signed64bitID);
		return nil;
	}
	NSString *parsedValue = [NSString stringWithFormat:RSGoogleItemIDHexFormat, [signed64bitID longLongValue]]; // @"%016qx" -- 016 does zero-padding to 16 digits
	if (parsedValue == nil)
		NSLog(@"Can't get parsedItemID for %@", signed64bitID);
	return parsedValue;
}


- (NSTimeInterval)parsedTimestamp {
	NSString *timestampUsecString = [self currentStringWithoutReplacingReferences];
	if (RSStringIsEmpty(timestampUsecString))
		return 0;
	if ([timestampUsecString length] > 10) // It appears to be always 16, but check, just in case: we just want 10-digit timestamp
		timestampUsecString = [timestampUsecString substringWithRange:NSMakeRange(0, 10)];
	return [timestampUsecString doubleValue];
}


static const void *kItemIDNameValue = "id";
static const NSUInteger kItemIDNameValue_Length = 2;
static const void *kItemRefsNameValue = "itemRefs";
static const NSUInteger kItemRefsNameValue_Length = 8;
static const void *kTimestampNameValue = "timestampUsec";
static const NSUInteger kTimestampNameValueLength = 13;
static const void *kItemIDNameKey = "name";
static const NSUInteger kItemIDNameKey_Length = 4;

- (BOOL)hasNameAttributeWithValue:(const void *)nameValue nameValueLength:(NSUInteger)nameValueLength numberOfAttributes:(int)numberOfAttributes attributes:(const xmlChar **)attributes {
	if (numberOfAttributes < 1 || attributes == nil)
		return NO;
	int i, j;
	for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {
		NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
		if (lenValue != nameValueLength)
			continue;
		if (memcmp(nameValue, (const void *)attributes[j + 3], nameValueLength) != 0)
			continue;
		if (memcmp(kItemIDNameKey, (const void *)attributes[j], kItemIDNameKey_Length) == 0)
			return YES;
	}
	return NO;
}


#pragma mark SAX Parsing Callbacks

static const char *kNumberTag = "number";
static const NSUInteger kNumberTag_Length = 7;
static const char *kListTag = "list";
static const NSUInteger kListTagLength = 5;
static const char *kObjectTag = "object";
static const NSUInteger kObjectTagLength = 7;
static const char *kStringTag = "string";
static const NSUInteger kStringTagLength = 7;

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	BOOL inListOnEntry = self.inList;
	BOOL shouldStartStoringCharacters = NO;
	self.inItemID = NO;
	self.inTimestamp = NO;
	
	if (!inListOnEntry && _xmlEqualTags(localName, kListTag, kListTagLength) && [self hasNameAttributeWithValue:kItemRefsNameValue nameValueLength:kItemRefsNameValue_Length numberOfAttributes:numberOfAttributes attributes:attributes]) { // <list name="itemRefs">
		self.inList = YES;
		self.listLevel = 1;
	}
	else if (inListOnEntry && _xmlEqualTags(localName, kListTag, kListTagLength))
		self.listLevel = self.listLevel + 1;
	else if (inListOnEntry && _xmlEqualTags(localName, kObjectTag, kObjectTagLength)) // <object>
		self.currentID = [[[RSParsedGoogleItemID alloc] init] autorelease];
//		[self.currentID reset]; 
	else if (inListOnEntry && _xmlEqualTags(localName, kNumberTag, kNumberTag_Length) && [self hasNameAttributeWithValue:kItemIDNameValue nameValueLength:kItemIDNameValue_Length numberOfAttributes:numberOfAttributes attributes:attributes]) { // <number name="id">
		self.inItemID = YES;
		shouldStartStoringCharacters = YES;
	}
	else if (inListOnEntry && self.shouldParseTimestamps && _xmlEqualTags(localName, kNumberTag, kNumberTag_Length) && [self hasNameAttributeWithValue:kTimestampNameValue nameValueLength:kTimestampNameValueLength numberOfAttributes:numberOfAttributes attributes:attributes]) { // <number name="timestampUsec">
		self.inTimestamp = YES;
		shouldStartStoringCharacters = YES;
	}
	else if (inListOnEntry && self.shouldParseStreamIDs && _xmlEqualTags(localName, kStringTag, kStringTagLength)) // <string>
		shouldStartStoringCharacters = YES;
	
	if (shouldStartStoringCharacters)
		 [self startStoringCharacters];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {

	if (_xmlEqualTags(localName, kListTag, kListTagLength)) {
		self.listLevel = self.listLevel - 1;
		if (self.listLevel < 1 && self.inList)
			self.inList = NO;
	}
	else if (self.inList && _xmlEqualTags(localName, kObjectTag, kObjectTagLength)) { // </object> -- Save (or not) the current ID.
		BOOL shouldSaveItemID = YES;
		// If too old (more than 30 days) it's actually a Google-locked item. We don't even give the delegate the option to look at it.
		if (self.shouldParseTimestamps && self.currentID.timestamp < self.oldestAllowedTimestamp)
			shouldSaveItemID = NO;
		else if (self.delegate != nil && [self.delegate itemIDsParser:self didParseItemID:self.currentID])
			shouldSaveItemID = NO;
		if (shouldSaveItemID)
			[self.itemIDs rs_safeAddObject:self.currentID.itemID];
		self.currentID = [[[RSParsedGoogleItemID alloc] init] autorelease];
	}
	
	else if (_xmlEqualTags(localName, kNumberTag, kNumberTag_Length)) { // </number>
		if (self.inItemID)
			self.currentID.itemID = [self parsedItemID];
		else if (self.inTimestamp && self.shouldParseTimestamps)
			self.currentID.timestamp = [self parsedTimestamp];
	}

	else if (self.shouldParseStreamIDs && _xmlEqualTags(localName, kStringTag, kStringTagLength)) // </string>
		[self.currentID addDirectStreamID:[self currentString]];
		
	self.inItemID = NO;
	self.inTimestamp = NO;
	[self endStoringCharacters];
}


- (void)xmlEndDocument {
	if (self.delegate != nil)
		[self.delegate itemIDsParserDidComplete:self];
}


@end
