//
//  NNWLatestItemsFetchOperation.m
//  nnwipad
//
//  Created by Brent Simmons on 3/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWLatestItemsFetchOperation.h"
#import "NNWDatabaseController.h"


@implementation NNWLatestItemsFetchOperation


#pragma mark Init

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	return [super initWithSourceIDs:nil delegate:aDelegate callbackSelector:aCallbackSelector];
}


#pragma mark Fetching

- (FMResultSet *)fetchResultSet {
	return [[NNWDatabaseController sharedController] thinResultSetOfLatestItems];	
}



@end
