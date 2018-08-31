//
//  RSTodayFeedCountUnreadOperation.h
//  nnw
//
//  Created by Brent Simmons on 1/19/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSOperation.h"


@interface RSTodayFeedCountUnreadOperation : RSOperation {
@private
	NSString *accountID;
	NSUInteger unreadCount;	
}


- (id)initWithAccountID:(NSString *)anAccountID delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@property (nonatomic, assign, readonly) NSUInteger unreadCount;


@end
