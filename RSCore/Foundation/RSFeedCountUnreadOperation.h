//
//  RSFeedCountUnreadOperation.h
//  nnw
//
//  Created by Brent Simmons on 1/6/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSOperation.h"


@interface RSFeedCountUnreadOperation : RSOperation {
@private
	NSURL *feedURL;
	NSString *accountID;
	NSUInteger unreadCount;
}


- (id)initWithFeedURL:(NSURL *)aFeedURL accountID:(NSString *)anAccountID delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@property (nonatomic, retain, readonly) NSURL *feedURL;
@property (nonatomic, assign, readonly) NSUInteger unreadCount;
@property (nonatomic, retain, readonly) NSString *accountID;

@end
