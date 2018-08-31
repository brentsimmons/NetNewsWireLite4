//
//  RSUpdateUnreadCountsOperation.m
//  nnw
//
//  Created by Brent Simmons on 1/10/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSUpdateUnreadCountsOperation.h"
#import "RSDataArticle.h"


NSString *RSUnreadCountDidCalculateNotification = @"RSUnreadCountDidCalculateNotification";

@interface RSUpdatedUnreadCount ()

@property (nonatomic, retain, readwrite) NSURL *feedURL;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;
@end


@implementation RSUpdatedUnreadCount

@synthesize feedURL;
@synthesize unreadCount;


#pragma mark Dealloc

- (void)dealloc {
	[feedURL release];
	[super dealloc];
}


@end



@implementation RSUpdateUnreadCountsOperation

@synthesize feedURLs;
@synthesize accountID;
@synthesize unreadCounts;


#pragma mark Init

- (id)initWithFeedURLs:(NSArray *)someFeedURLs accountID:(NSString *)anAccountID delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
	if (self == nil)
		return nil;
	unreadCounts = [[NSMutableArray array] retain];
	accountID = [anAccountID retain];
	feedURLs = [someFeedURLs retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[feedURLs release];
	[accountID release];
	[unreadCounts release];
	[super dealloc];
}


#pragma mark Unread Counts

- (void)updateUnreadCountForFeedURL:(NSURL *)aFeedURL moc:(NSManagedObjectContext *)moc {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUInteger unreadCount = [RSDataArticle unreadCountForArticlesWithFeedURL:aFeedURL accountID:self.accountID moc:moc];
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSUnreadCountDidCalculateNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aFeedURL, RSURLKey, [NSNumber numberWithUnsignedInteger:unreadCount], @"unreadCount", nil]];
	[pool drain];
}


#pragma mark RSOperation

- (void)main {
	if (![self isCancelled]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSManagedObjectContext *moc = rs_app_delegate.temporaryManagedObjectContext;
		for (NSURL *oneFeedURL in self.feedURLs) {
			if ([self isCancelled])
				break;
			[self updateUnreadCountForFeedURL:oneFeedURL moc:moc];
		}
		[pool drain];
	}
	[super main];
}


@end
