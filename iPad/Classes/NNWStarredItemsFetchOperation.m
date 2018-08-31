//
//  NNWStarredItemsFetchOperation.m
//  nnwipad
//
//  Created by Brent Simmons on 3/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWStarredItemsFetchOperation.h"
#import "NNWDatabaseController.h"


@implementation NNWStarredItemsFetchOperation


#pragma mark Init

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	return [super initWithSourceIDs:nil delegate:aDelegate callbackSelector:aCallbackSelector];
}


#pragma mark Fetching

- (FMResultSet *)fetchResultSet {
	return [[NNWDatabaseController sharedController] thinResultSetOfStarredItems];	
}


@end
