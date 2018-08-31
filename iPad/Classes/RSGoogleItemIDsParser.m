//
//  RSGoogleItemIDsParser.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleItemIDsParser.h"


@interface RSGoogleItemIDsParser ()
@property (nonatomic, retain, readwrite) NSMutableArray *itemIDs;
@property (nonatomic, assign) BOOL inItemID;
@end


@implementation RSGoogleItemIDsParser

@synthesize itemIDs, inItemID, delegate;

#pragma mark Init

- (id)init {
	self = [super init];
	if (!self)
		return nil;
	itemIDs = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[itemIDs release];
	[super dealloc];
}


#pragma mark Parser

- (NSString *)currentStringWithoutReplacingReferences {
	if ([_characterBuffer length] < 1)
		return nil;
	return [[[NSString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding] autorelease];
}


static NSString *RSGoogleItemIDHexFormat = @"%016qx";
static NSString *RSGoogleItemIDLeadingZeroFormat = @"0%@";

- (NSString *)parsedItemID {
	NSString *signed64bitID = [self currentStringWithoutReplacingReferences];
	if (RSStringIsEmpty(signed64bitID))
		return nil;
	NSString *hexValue = [NSString stringWithFormat:RSGoogleItemIDHexFormat, [signed64bitID longLongValue]]; //@"%qx"
//	NSString *hexValueOrig = [NSString stringWithFormat:@"%qx", [signed64bitID longLongValue]];
//	if (![hexValue isEqualToString:hexValueOrig])
//		NSLog(@"%@ - %@", hexValue, hexValueOrig);
	while ([hexValue length] < 16)
		hexValue = [NSString stringWithFormat:RSGoogleItemIDLeadingZeroFormat, hexValue]; //@"0%@"
	return hexValue;
}


static const void *kItemIDNameValue = "id";
static const NSUInteger kItemIDNameValue_Length = 2;
static const void *kItemIDNameKey = "name";
static const NSUInteger kItemIDNameKey_Length = 4;

- (BOOL)hasExpectedNameAttribute:(int)numberOfAttributes attributes:(const xmlChar **)attributes {
	if (numberOfAttributes < 1 || attributes == nil)
		return NO;
	int i, j;
	for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {
		NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
		if (lenValue != kItemIDNameValue_Length)
			continue;
		if (memcmp(kItemIDNameValue, (const void *)attributes[j + 3], kItemIDNameValue_Length) != 0)
			continue;
		if (memcmp(kItemIDNameKey, (const void *)attributes[j], kItemIDNameKey_Length) == 0)
			return YES;
	}
	return NO;
}

#pragma mark SAX Parsing Callbacks

static const char *kNumberTag = "number";
static const NSUInteger kNumberTag_Length = 7;

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	if (_xmlEqualTags(localName, kNumberTag, kNumberTag_Length) && [self hasExpectedNameAttribute:numberOfAttributes attributes:attributes]) {
		self.inItemID = YES;
		[self startStoringCharacters];
	}
	else
		self.inItemID = NO;
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	if (_xmlEqualTags(localName, kNumberTag, kNumberTag_Length) && self.inItemID) {
		NSString *parsedItemID = [self parsedItemID];
		BOOL shouldSaveItemID = YES;
		if (self.delegate != nil && [self.delegate itemIDsParser:self didParseItemID:parsedItemID])
			shouldSaveItemID = NO;
		if (shouldSaveItemID)
			[self.itemIDs safeAddObject:parsedItemID];
		[self endStoringCharacters];
		self.inItemID = NO;
	}
}


- (void)xmlEndDocument {
	if (self.delegate != nil)
		[self.delegate itemIDsParserDidComplete:self];
}


@end
