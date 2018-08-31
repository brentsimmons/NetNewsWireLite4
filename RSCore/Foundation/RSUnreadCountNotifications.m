//
//  RSUnreadCountNotifications.m
//  RSCoreTests
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSUnreadCountNotifications.h"


NSString *RSUnreadCountDidChangeNotification = @"RSUnreadCountDidChangeNotification";


@implementation RSUnreadCountNotifications

+ (void)enqueueNotificationOnMainThread:(NSNotification *)notification {
	if (![NSThread isMainThread]) {
		[self enqueueNotificationOnMainThread:notification];
		return;
	}
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
}


+ (void)sendUnreadCountDidChangeNotification:(id<RSUnreadCountSource>)unreadCountSource {
	NSAssert(unreadCountSource != nil, @"unreadCountSource should not be nil");
	[self enqueueNotificationOnMainThread:[NSNotification notificationWithName:RSUnreadCountDidChangeNotification object:unreadCountSource]];
}


@end
