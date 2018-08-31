//
//  NNWGoogleProcessSubscriptionsOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"


@interface NNWProcessSubscriptionsOperation : RSOperation {
@private
	NSArray *subscriptions;
	NSArray *allGoogleFeedIDs;
	NSManagedObjectContext *moc;
	BOOL hasAtLeastOneFeed;
}


- (id)initWithSubscriptions:(NSArray *)someSubscriptions delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@property (nonatomic, assign) BOOL hasAtLeastOneFeed;
@property (nonatomic, retain, readonly) NSArray *allGoogleFeedIDs;

@end
