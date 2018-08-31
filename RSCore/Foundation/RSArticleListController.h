//
//  RSArticleListController.h
//  nnw
//
//  Created by Brent Simmons on 1/6/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RSDataArticle;

@interface RSArticleListController : NSObject {
@private
    BOOL sortAscending;
    NSArray *articles;
    NSArray *feedsAndFolders; //whatever is selected
    NSString *sortKey;
    BOOL includesMultipleFeeds;
}


/*Fetches articles. There are cases (like updating a current view) where you want to
 force-include one or more articles. (The current selection, for instance.)*/

- (void)updateArticles:(NSArray *)articlesToForceInclusion;

@property (nonatomic, assign) BOOL sortAscending; //default is NO
@property (nonatomic, strong) NSArray *feedsAndFolders;
@property (nonatomic, strong) NSString *sortKey; //default is @"dateForDisplay"
@property (nonatomic, strong, readonly) NSArray *articles;
@property (nonatomic, assign, readonly) BOOL includesMultipleFeeds;
@property (nonatomic, assign, readonly) BOOL hasAnyUnreadItems;
@property (nonatomic, strong, readonly) RSDataArticle *firstUnreadArticle;

- (void)markAllAsRead;

- (BOOL)articleIsInList:(RSDataArticle *)anArticle;


@end
