//
//  RSUpdateUnreadCountsOperation.h
//  nnw
//
//  Created by Brent Simmons on 1/10/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSOperation.h"


/*userInfo has RSURLKey and @"unreadCount" -- NSURL and NSNumber (unsignedInteger)
 It gets called for each feed.*/

extern NSString *RSUnreadCountDidCalculateNotification;

@interface RSUpdatedUnreadCount : NSObject {
@private
    NSURL *feedURL;
    NSUInteger unreadCount;
}


@property (nonatomic, strong, readonly) NSURL *feedURL;
@property (nonatomic, assign, readonly) NSUInteger unreadCount;

@end



@interface RSUpdateUnreadCountsOperation : RSOperation {
@private
    NSArray *feedURLs;
    NSString *accountID;
    NSMutableArray *unreadCounts;    
}

- (id)initWithFeedURLs:(NSArray *)someFeedURLs accountID:(NSString *)anAccountID delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@property (nonatomic, strong, readonly) NSArray *feedURLs;
@property (nonatomic, strong, readonly) NSString *accountID;

@property (nonatomic, strong, readonly) NSMutableArray *unreadCounts; //array of RSUpdatedUnreadCount

@end
