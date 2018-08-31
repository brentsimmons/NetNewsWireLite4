//
//  RSGoogleReaderParsedSub.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/27/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleReaderParsedSub.h"
#import "RSFoundationExtras.h"



@interface RSGoogleReaderParsedSub ()

@property (nonatomic, assign, readwrite) NSTimeInterval firstItemTimestamp;
@end

@implementation RSGoogleReaderParsedSub

@synthesize googleID, title, categories, firstItemMsec;
@synthesize firstItemTimestamp;

- (void)dealloc {
	[googleID release];
	[title release];
	[categories release];
	[firstItemMsec release];
	[super dealloc];
}


- (void)addCategory:(RSGoogleReaderParsedCategory *)category {
	if (self.categories == nil)
		self.categories = [NSMutableArray array];
	[self.categories rs_safeAddObject:category];
}


- (NSString *)description {
	return [NSString stringWithFormat:@"RSGoogleReaderParsedSub: %@ - %@ - %@ - %@", title, googleID, firstItemMsec, categories];
}


- (NSTimeInterval)firstItemTimestamp {
	if (firstItemTimestamp > 0)
		return firstItemTimestamp;
	if (RSStringIsEmpty(self.firstItemMsec) || [self.firstItemMsec length] != 13)
		return 0;
	self.firstItemTimestamp = [self.firstItemMsec doubleValue] / 1000.000f;
	return firstItemTimestamp;
}


@end



#pragma mark -

@implementation RSGoogleReaderParsedCategory

@synthesize googleID, label;

static NSMutableDictionary *categoryCache = nil;

#pragma mark Class Methods

+ (void)initialize {
	@synchronized([self class]) {
		if (categoryCache == nil)
			categoryCache = [[NSMutableDictionary dictionary] retain];
	}
}


+ (RSGoogleReaderParsedCategory *)categoryWithGoogleID:(NSString *)aGoogleID {
	if (RSStringIsEmpty(aGoogleID))
		return nil;
	RSGoogleReaderParsedCategory *category = [[[categoryCache objectForKey:aGoogleID] retain] autorelease];
	if (category != nil)
		return category;
	category = [[[self alloc] init] autorelease];
	category.googleID = aGoogleID;
	[categoryCache rs_safeSetObject:category forKey:aGoogleID];
	return category;
}


+ (void)emptyCategoryCache {
	[categoryCache removeAllObjects];
}


#pragma mark Dealloc

- (void)dealloc {
	[googleID release];
	[label release];
	[super dealloc];
}


#pragma mark Accessors

- (void)setLabelIfNotSet:(NSString *)aLabel {
	/*Since these are cached and re-used, and the title doesn't change in successive appearances, save time and memory by not setting the title if it's already set.*/
	if (self.label == nil)
		self.label = aLabel;
}


- (BOOL)isEmpty {
	return self.googleID == nil && self.label == nil;
}


- (NSString *)description {
	return [NSString stringWithFormat:@"RSParsedGoogleCategory: %@ - %@", googleID, label];
}


@end