//
//  NNWCurrentFeedsManager.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/17/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWCurrentFeedsManager.h"


@interface NNWCurrentFeedsManager ()
@property (nonatomic, retain) NSMutableDictionary *feedIDs;
@end


@implementation NNWCurrentFeedsManager

@synthesize feedIDs;


#pragma mark Init

- (id)initWithFeedIDs:(NSArray *)someFeedIDs {
	if (![super init])
		return nil;
	feedIDs = [[NSMutableDictionary alloc] init];
	for (NSString *oneFeedID in someFeedIDs)
		[feedIDs setBool:YES forKey:oneFeedID];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[feedIDs release];
	[super dealloc];
}


#pragma mark Accessors

- (NSArray *)currentFeedIDs {
	return [self.feedIDs allKeys];
}


#pragma mark Adding/Removed Feed IDs

- (void)ensureFeedIDIsIncluded:(NSString *)feedID {
	if (RSStringIsEmpty(feedID))
		return;
	if ([self.feedIDs objectForKey:feedID] == nil) {
		[self.feedIDs setBool:YES forKey:feedID];
	}
}


- (void)ensureFeedIDRemoved:(NSString *)feedID {
	if (RSStringIsEmpty(feedID))
		return;
	if ([self.feedIDs objectForKey:feedID] != nil)
		[self.feedIDs removeObjectForKey:feedID];
}


@end
