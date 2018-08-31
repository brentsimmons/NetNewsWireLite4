//
//  RSTodayFeedCountUnreadOperation.m
//  nnw
//
//  Created by Brent Simmons on 1/19/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSTodayFeedCountUnreadOperation.h"
#import "RSDataArticle.h"


@interface RSTodayFeedCountUnreadOperation ()

@property (nonatomic, retain) NSString *accountID;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;
@end


@implementation RSTodayFeedCountUnreadOperation

@synthesize accountID;
@synthesize unreadCount;


#pragma mark Init

- (id)initWithAccountID:(NSString *)anAccountID delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
	if (self == nil)
		return nil;
	accountID = [anAccountID retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[accountID release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)main {
	if (![self isCancelled])
		self.unreadCount = [RSDataArticle countOfUnreadArticlesPublishedTodayInAccountWithID:self.accountID moc:rs_app_delegate.temporaryManagedObjectContext];	
	[super main];
}


@end
