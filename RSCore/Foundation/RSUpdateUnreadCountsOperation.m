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

@property (nonatomic, strong, readwrite) NSURL *feedURL;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;
@end


@implementation RSUpdatedUnreadCount

@synthesize feedURL;
@synthesize unreadCount;


#pragma mark Dealloc



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
    unreadCounts = [NSMutableArray array];
    accountID = anAccountID;
    feedURLs = someFeedURLs;
    return self;
}


#pragma mark Dealloc



#pragma mark Unread Counts

- (void)updateUnreadCountForFeedURL:(NSURL *)aFeedURL moc:(NSManagedObjectContext *)moc {
    @autoreleasepool {
        NSUInteger unreadCount = [RSDataArticle unreadCountForArticlesWithFeedURL:aFeedURL accountID:self.accountID moc:moc];
        [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSUnreadCountDidCalculateNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:aFeedURL, RSURLKey, [NSNumber numberWithUnsignedInteger:unreadCount], @"unreadCount", nil]];
    }
}


#pragma mark RSOperation

- (void)main {
    if (![self isCancelled]) {
        @autoreleasepool {
            NSManagedObjectContext *moc = rs_app_delegate.temporaryManagedObjectContext;
            for (NSURL *oneFeedURL in self.feedURLs) {
                if ([self isCancelled])
                    break;
                [self updateUnreadCountForFeedURL:oneFeedURL moc:moc];
            }
        }
    }
    [super main];
}


@end
