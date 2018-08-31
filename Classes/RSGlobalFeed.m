//
//  RSGlobalFeed.m
//  nnw
//
//  Created by Brent Simmons on 1/18/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSGlobalFeed.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSFeed.h"


@implementation RSGlobalFeed

@synthesize account;
@synthesize globalFeedType;
@synthesize nameForDisplay;
@synthesize unreadCount;


#pragma mark Dealloc




#pragma mark Accessors

- (void)setUnreadCount:(NSUInteger)anUnreadCount {
    if (anUnreadCount == unreadCount)
        return;
    unreadCount = anUnreadCount;
    [[NSNotificationCenter defaultCenter] postNotificationName:RSFeedUnreadCountDidChangeNotification object:self userInfo:nil];
}


#pragma mark Fetching Articles

- (NSArray *)fetchAllUnreadArticlesWithSortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc {
    return [RSDataArticle unreadArticlesInAccountWithID:[RSDataAccount localAccount].identifier sortDescriptor:aSortDescriptor moc:moc];
}


- (NSArray *)fetchTodayArticlesWithSortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc {
    return [RSDataArticle articlesPublishedTodayInAccountWithID:[RSDataAccount localAccount].identifier sortDescriptor:aSortDescriptor moc:moc];
}


- (NSArray *)fetchArticlesWithSortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc {
    if (self.globalFeedType == RSGlobalFeedTypeAllUnread)
        return [self fetchAllUnreadArticlesWithSortDescriptor:aSortDescriptor moc:moc];
    return [self fetchTodayArticlesWithSortDescriptor:aSortDescriptor moc:moc];
}


#pragma mark RSTreeNodeRepresentedObject

- (NSURL *)associatedURL {
    return nil;
}


- (NSUInteger)countForDisplay {
    return self.unreadCount;
}

@end
