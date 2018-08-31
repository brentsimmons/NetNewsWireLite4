//
//  NNWDataController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *NNWUserDidMarkOneOrMoreItemsInFeedAsReadNotification;
extern NSString *NNWUserDidMarkOneOrMoreItemsInFeedAsStarredNotification;
extern NSString *NNWUserDidMarkOneOrMoreItemsInFeedAsUnstarredNotification;
extern NSString *NNWFeedDidUpdateMostRecentItemNotification;


@class NNWFeed;

@interface NNWDataController : NSObject {
@private
	NSMutableDictionary *_uniqueObjects;
}


+ (id)sharedController;

/*Creates if needed. Feeds, folders, and news items all have a googleID attribute.*/

- (NSArray *)fetchAllObjectsForEntityName:(NSString *)entityName moc:(NSManagedObjectContext *)moc;

- (NSManagedObject *)objectWithUniqueGoogleID:(NSString *)googleID entityName:(NSString *)entityName didCreate:(BOOL *)didCreate managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSManagedObject *)fetchObjectWithGoogleID:(NSString *)googleID entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (NSManagedObject *)createObjectWithGoogleID:(NSString *)googleID entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (NSManagedObject *)objectWithUniqueGoogleID:(NSString *)googleID entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NNWFeed *)existingFeedWithGoogleID:(NSString *)googleID moc:(NSManagedObjectContext *)moc;

- (NSArray *)allFolders;
- (NSArray *)allFeeds;
- (NSArray *)allFeedsInManagedObjectContext:(NSManagedObjectContext *)moc;


@end
