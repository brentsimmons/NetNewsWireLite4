//
//  RSArticleListController.m
//  nnw
//
//  Created by Brent Simmons on 1/6/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSArticleListController.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSFeed.h"
#import "RSFolder.h"
#import "RSGlobalFeed.h"


@interface RSArticleListController ()

@property (nonatomic, strong, readwrite) NSArray *articles;
@end


@implementation RSArticleListController

@synthesize articles;
@synthesize feedsAndFolders;
@synthesize sortAscending;
@synthesize sortKey;
@synthesize includesMultipleFeeds;


#pragma mark Init

- (id)init {
    self = [super init];
    if (self == nil)
        return nil;
    sortKey = @"dateForDisplay";
    return self;
}


#pragma mark Dealloc



#pragma mark Update List of Articles

- (void)addFeedsToArray:(NSMutableArray *)anArray {
    for (id oneObject in self.feedsAndFolders) {
        if (![oneObject isKindOfClass:[RSFolder class]])
            [anArray addObject:oneObject];
    }
}


- (void)addFeedChildrenOfFolder:(RSFolder *)aFolder toArray:(NSMutableArray *)anArray {
    NSArray *feedChildren = aFolder.allDescendantsThatAreFeeds;
    if (!RSIsEmpty(feedChildren))
        [anArray addObjectsFromArray:feedChildren];
}


- (void)addFeedsFromFoldersToArray:(NSMutableArray *)anArray {
    for (id oneObject in self.feedsAndFolders) {
        if ([oneObject isKindOfClass:[RSFolder class]])
            [self addFeedChildrenOfFolder:oneObject toArray:anArray];
    }
}


- (void)updateArticles:(NSArray *)articlesToForceInclusion {
    
    //TODO: REMEMBER THAT THIS IS A GODDAMN OBJECT-ORIENTED FRAMEWORK AND LANGUAGE AND THIS METHOD SUCKS.
    
    /*For feeds we get all of the items. For folders we get just the unread items from the feeds in that folder.
     For the folders in the feedsAndFolders array, we flatten them out into the feedsToFetchUnreadOnly array.*/
    
    NSMutableArray *feedsToFetch = [NSMutableArray array];
    NSMutableArray *feedsToFetchUnreadOnly = [NSMutableArray array];
    NSMutableArray *feedsAlreadyFetched = [NSMutableArray array];
    NSString *accountID = nil;
    
    [self addFeedsToArray:feedsToFetch];
    [self addFeedsFromFoldersToArray:feedsToFetchUnreadOnly];
    
    NSMutableArray *combinedArrayOfArticles = [NSMutableArray array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:self.sortKey ascending:self.sortAscending];
    
    NSManagedObjectContext *moc = rs_app_delegate.mainThreadManagedObjectContext;
    
    NSMutableArray *feedURLStrings = [NSMutableArray array];
    for (RSFeed *oneFeed in feedsToFetch) {
        if ([feedsAlreadyFetched rs_containsObjectIdenticalTo:oneFeed])
            continue;
        if (![oneFeed respondsToSelector:@selector(URL)] || oneFeed.URL == nil)
            continue;
        [feedsAlreadyFetched addObject:oneFeed];
        if (RSStringIsEmpty(accountID))
            accountID = oneFeed.account.identifier;
        [feedURLStrings rs_safeAddObject:[oneFeed.URL absoluteString]];
    }
    if (!RSIsEmpty(feedURLStrings) && !RSStringIsEmpty(accountID))
        combinedArrayOfArticles = [[RSDataArticle sortedArticlesForFeedsWithURLs:feedURLStrings accountID:accountID sortDescriptor:sortDescriptor moc:moc] mutableCopy];
    
    /*Handle special feeds -- non RSFeed-feeds.*/
    
    for (RSFeed *oneFeed in feedsToFetch) {
        if ([feedsAlreadyFetched rs_containsObjectIdenticalTo:oneFeed])
            continue; //fetched above
        /*oneFeed must be special*/
        if ([oneFeed respondsToSelector:@selector(fetchArticlesWithSortDescriptor:moc:)]) {
            NSArray *oneFeedArticles = [(RSGlobalFeed *)oneFeed fetchArticlesWithSortDescriptor:sortDescriptor moc:moc];
            if (RSIsEmpty(combinedArrayOfArticles))
                combinedArrayOfArticles = [oneFeedArticles mutableCopy];
            else
                [combinedArrayOfArticles rs_addObjectsThatAreNotIdentical:oneFeedArticles];                
        }
    }
    
    
    NSMutableArray *unreadFeedURLStrings = [NSMutableArray array];
    for (RSFeed *oneFeed in feedsToFetchUnreadOnly) {
        if (RSStringIsEmpty(accountID))
            accountID = oneFeed.account.identifier;
        if ([feedsAlreadyFetched rs_containsObjectIdenticalTo:oneFeed])
            continue;
        [feedsAlreadyFetched addObject:oneFeed];
        if (oneFeed.URL == nil || oneFeed.account == nil)
            continue;
        [unreadFeedURLStrings rs_safeAddObject:[oneFeed.URL absoluteString]];
        //[combinedArrayOfArticles rs_addObjectsThatAreNotIdentical:oneFeedArticles];
    }
    if (!RSIsEmpty(unreadFeedURLStrings) && !RSStringIsEmpty(accountID)) {
        NSArray *unreadArticles = [RSDataArticle unreadArticlesForFeedsWithURLs:unreadFeedURLStrings accountID:accountID sortDescriptor:sortDescriptor moc:moc];
        if (RSIsEmpty(combinedArrayOfArticles))
            combinedArrayOfArticles = [unreadArticles mutableCopy];
        else
            [combinedArrayOfArticles rs_addObjectsThatAreNotIdentical:unreadArticles];
    }
    
    if (!RSIsEmpty(articlesToForceInclusion)) {

        BOOL didAddAtLeastOneArticle = NO;
        
        for (id oneArticle in articlesToForceInclusion) {
            if (![combinedArrayOfArticles rs_containsObjectIdenticalTo:oneArticle]) {
                didAddAtLeastOneArticle = YES;
                [combinedArrayOfArticles addObject:oneArticle];
            }
        }
        
        if (didAddAtLeastOneArticle) //bummer - re-sorting for just one or a few articles is a performance hit
            [combinedArrayOfArticles sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    }
    
    self.articles = combinedArrayOfArticles;
}


#pragma mark Attributes

- (BOOL)hasAnyUnreadItems {
    return self.firstUnreadArticle != nil;
}


- (RSDataArticle *)firstUnreadArticle {
    if (RSIsEmpty(self.articles))
        return nil;
    for (RSDataArticle *oneArticle in self.articles)
        if ([oneArticle.read boolValue] == NO)
            return oneArticle;
    return nil;
}


- (BOOL)articleIsInList:(RSDataArticle *)anArticle {
    return self.articles != nil && [self.articles rs_containsObjectIdenticalTo:anArticle];
}


#pragma mark API

- (void)markAllAsRead {
    for (RSDataArticle *oneArticle in self.articles)
        [oneArticle markAsRead:YES];
}


@end
