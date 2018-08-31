//
//  RSParsedGoogleSub.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/27/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSParsedGoogleSub.h"


@implementation RSParsedGoogleSub

@synthesize googleID, title, categories, firstItemMsec;

- (void)dealloc {
	[googleID release];
	[title release];
	[categories release];
	[firstItemMsec release];
	[super dealloc];
}


- (void)addCategory:(RSParsedGoogleCategory *)category {
	if (self.categories == nil)
		self.categories = [NSMutableArray array];
	[self.categories safeAddObject:category];
}


@end



#pragma mark -

@implementation RSParsedGoogleCategory

@synthesize googleID, label;

static NSMutableDictionary *categoryCache = nil;

#pragma mark Class Methods

+ (void)initialize {
	@synchronized([self class]) {
		if (categoryCache == nil)
			categoryCache = [[NSMutableDictionary dictionary] retain];
	}
}


+ (RSParsedGoogleCategory *)categoryWithGoogleID:(NSString *)googleID {
	if (RSStringIsEmpty(googleID))
		return nil;
	RSParsedGoogleCategory *category = [[[categoryCache objectForKey:googleID] retain] autorelease];
	if (category != nil)
		return category;
	category = [[[self alloc] init] autorelease];
	category.googleID = googleID;
	[categoryCache safeSetObject:category forKey:googleID];
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

@end