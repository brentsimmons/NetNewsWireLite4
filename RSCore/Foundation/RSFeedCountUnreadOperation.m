//
//  RSFeedCountUnreadOperation.m
//  nnw
//
//  Created by Brent Simmons on 1/6/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeedCountUnreadOperation.h"
#import "RSDataArticle.h"


@interface RSFeedCountUnreadOperation ()

@property (nonatomic, retain, readwrite) NSString *accountID;
@property (nonatomic, retain, readwrite) NSURL *feedURL;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;
@end


@implementation RSFeedCountUnreadOperation

@synthesize accountID;
@synthesize feedURL;
@synthesize unreadCount;


#pragma mark Init

- (id)initWithFeedURL:(NSURL *)aFeedURL accountID:(NSString *)anAccountID delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
	if (self == nil)
		return nil;
	accountID = [anAccountID retain];
	feedURL = [aFeedURL retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[accountID release];
	[feedURL release];
	[super dealloc];
}


#pragma mark RSOperation

- (void)main {
	if (![self isCancelled])
		self.unreadCount = [RSDataArticle unreadCountForArticlesWithFeedURL:self.feedURL accountID:self.accountID moc:rs_app_delegate.temporaryManagedObjectContext];	
	[super main];
}


@end
