//
//  NNWDatabaseController.h
//  nnwiphone
//
//  Created by Brent Simmons on 10/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWSQLite3DatabaseController.h"


@class RSParsedNewsItem, NNWMostRecentItemSpecifier;
@class FMResultSet;
@class NNWNewsItemProxy;

@interface NNWDatabaseController : NNWSQLite3DatabaseController {
}


+ (NNWDatabaseController *)sharedController;

- (void)saveNewsItems:(NSArray *)newsItems;

- (NSArray *)feedIDsForCurrentItems;
- (NSUInteger)unreadCountForGoogleSourceID:(NSString *)googleSourceID;
- (NNWMostRecentItemSpecifier *)mostRecentItemForGoogleSourceID:(NSString *)googleSourceID;
- (NSArray *)allUnreadCounts;
- (void)markItemIDsAsRead:(NSArray *)itemIDs;
- (void)markOneItemIDAsRead:(NSString *)itemID;
- (void)markItemIDs:(NSArray *)itemIDs starred:(BOOL)starred;
- (void)markSetOfItemIDs:(NSSet *)itemIDs starred:(BOOL)starred;

- (void)removeExistingItemsFromSet:(NSMutableSet *)itemIDs;

- (NSMutableArray *)newsItemsWithGoogleSourceIDs:(NSArray *)googleSourceIDs;

- (NNWNewsItemProxy *)thinNewsItemWithThinRow:(FMResultSet *)rs;
- (FMResultSet *)thinResultSetWithGoogleSourceIDs:(NSArray *)googleSourceIDs;
- (void)inflateNewsItem:(NNWNewsItemProxy *)newsItem;

- (FMResultSet *)thinResultSetOfStarredItems;
- (FMResultSet *)thinResultSetOfLatestItems;
- (NSInteger)unreadCountForLatestItems;

- (NSSet *)idsOfStarredItems;

@end


@interface NNWMostRecentItemSpecifier : NSObject <NSCoding> {
	@private
	NSString *plainTextTitle;
	NSString *displayDate;
}

@property (nonatomic, retain, readonly) NSString *plainTextTitle;
@property (nonatomic, retain, readonly) NSString *displayDate;

@end