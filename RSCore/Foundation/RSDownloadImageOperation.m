//
//  RSDownloadImageOperation.m
//  libTapLynx
//
//  Created by Brent Simmons on 12/3/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSDownloadImageOperation.h"


NSString *RSDownloadImageOperationDidCompleteNotification = @"RSDownloadImageOperationDidCompleteNotification";


@interface RSDownloadImageOperation ()
@property (nonatomic, retain, readwrite) UIImage *image;
@end


@implementation RSDownloadImageOperation

@synthesize image;

#pragma mark Init

- (id)initWithURL:(NSURL *)aURL delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector parser:(id)aParser useWebCache:(BOOL)useWebCacheFlag {
	self = [super initWithURL:aURL delegate:aDelegate callbackSelector:aCallbackSelector parser:nil useWebCache:useWebCacheFlag];
	if (!self)
		return nil;
	self.operationType = RSOperationTypeDownloadImage;
	self.operationObject = aURL;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[image release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)main {
	if (!self.useWebCache || ![self fetchCachedObject]) /*Short-circuit is significant*/
		[self download];
	if (self.responseBody != nil)
		self.image = [UIImage imageWithData:self.responseBody];
	if (self.image != nil)
		[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSDownloadImageOperationDidCompleteNotification object:self userInfo:nil];
	[self notifyObserversThatOperationIsComplete];
}


@end
