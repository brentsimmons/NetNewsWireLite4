//
//  RSOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/15/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSOperation.h"
#import "RSFoundationExtras.h"


NSString *RSOperationDidCompleteNotification = @"RSOperationDidCompleteNotification";

@implementation RSOperation

@synthesize delegate, callbackSelector;
@synthesize operationType, operationObject;


#pragma mark Init

- (id)initWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super init];
	if (!self)
		return nil;
	delegate = aDelegate;
	callbackSelector = aCallbackSelector;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[operationObject release];
	[super dealloc];
}


#pragma mark Notifications

- (void)postOperationDidCompleteNotification {
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSOperationDidCompleteNotification object:self userInfo:nil];
}


#pragma mark Delegate Callback

- (void)callDelegate {
	if (![self isCancelled] && self.delegate != nil && [self.delegate respondsToSelector:self.callbackSelector])
		[self.delegate performSelectorOnMainThread:self.callbackSelector withObject:self waitUntilDone:NO];
}


#pragma mark NSOperation

- (BOOL)isConcurrent {
	return NO;
}


- (void)cancel {
	[self postOperationDidCompleteNotification];
	[super cancel];
}


- (void)main {
	[self notifyObserversThatOperationIsComplete];
}


- (void)notifyObserversThatOperationIsComplete {
	[self callDelegate];
	[self postOperationDidCompleteNotification];	
}


@end
