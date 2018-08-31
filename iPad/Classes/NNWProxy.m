//
//  NNWProxy.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/28/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWProxy.h"
#import "NNWFeedProxy.h"


NSString *NNWUnreadCountInvalidatedNotification = @"NNWUnreadCountInvalidatedNotification";
NSString *NNWDidUpdateUnreadCountNotification = @"NNWDidUpdateUnreadCountNotification";


@implementation NNWProxy

@synthesize googleID = _googleID, title = _title, unreadCountIsValid = _unreadCountIsValid;


#pragma mark Init

- (id)initWithGoogleID:(NSString *)googleID {
	if (![super init])
		return nil;
	_googleID = [googleID retain];
	_unreadCount = -1;
	return self;
}

static NSString *NNWGoogleIDKey = @"googleID";
static NSString *NNWTitleKey = @"title";
static NSString *NNWUnreadCountKey = @"unreadCount";

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_googleID forKey:NNWGoogleIDKey];
	[coder encodeObject:_title forKey:NNWTitleKey];
	[coder encodeInteger:_unreadCount forKey:NNWUnreadCountKey];
}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	_googleID = [[coder decodeObjectForKey:NNWGoogleIDKey] retain];
	_unreadCount = [coder decodeIntegerForKey:NNWUnreadCountKey];
	_title = [[coder decodeObjectForKey:NNWTitleKey] retain];
	_unreadCountIsValid = NO;
	return self;
}


- (void)dealloc {
	[_googleID release];
	[_title release];
	[super dealloc];
}


- (BOOL)isFolder {
	return NO;
}


- (NSInteger)unreadCount {
	if (_unreadCount == -1)
		return 0;
	return _unreadCount;
}


- (void)sendUnreadCountDidUpdateNotification {
	[self rs_enqueueNotificationOnMainThread:NNWDidUpdateUnreadCountNotification object:nil userInfo:nil];
}


- (void)setUnreadCount:(NSInteger)unreadCount {
	if (unreadCount != _unreadCount) {
		[self sendUnreadCountDidUpdateNotification];
		_unreadCount = unreadCount;
	}
	self.unreadCountIsValid = YES;
}


- (void)invalidateUnreadCount {
	_unreadCountIsValid = NO;
	[self rs_enqueueNotificationOnMainThread:NNWUnreadCountInvalidatedNotification object:nil userInfo:nil];
}


- (BOOL)unreadCountIsValid {
	return _unreadCountIsValid && _unreadCount != -1;
}


- (NSString *)description {
	return [NSString stringWithFormat:@"%@ - %@", [super description], _googleID];
}


@end
