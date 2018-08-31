//
//  RSUnreadCountNotifications.h
//  RSCoreTests
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString *RSUnreadCountDidChangeNotification;

/*[notification object] will conform to RSUnreadCountSource.*/

@protocol RSUnreadCountSource <NSObject>

@required
@property (nonatomic, assign, readonly) NSUInteger unreadCount; //could be on-demand, but consider it's probably called on main thread

@optional
@property (nonatomic, assign, readonly) BOOL unreadCountIsGlobal;


@end


@interface RSUnreadCountNotifications : NSObject

/*The RSUnreadCountDidChangeNotification is always posted on the main thread, so it's safe for UI observers.
 Notifications are enqueued/coalesced (per unreadCountSource -- [notification object]) for efficiency and performance.*/

+ (void)sendUnreadCountDidChangeNotification:(id<RSUnreadCountSource>)unreadCountSource;


@end
