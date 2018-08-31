//
//  NNWProxy.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/28/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *NNWUnreadCountInvalidatedNotification;
extern NSString *NNWDidUpdateUnreadCountNotification;


@interface NNWProxy : NSObject <NSCoding> {
@protected
	NSString *_googleID;
	NSString *_title;
	NSInteger _unreadCount;
	BOOL _unreadCountIsValid;
}

- (id)initWithGoogleID:(NSString *)googleID;

@property (retain) NSString *googleID;
@property (assign, readonly) BOOL isFolder;
@property (retain) NSString *title;
@property (assign) NSInteger unreadCount;
@property (assign) BOOL unreadCountIsValid;

- (void)invalidateUnreadCount;

@end
