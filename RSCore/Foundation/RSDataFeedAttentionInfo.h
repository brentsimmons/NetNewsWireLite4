//
//  NNWFeedAttionInfo.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


/*No relationships to anything else. These don't get deleted, even.
 Look up by feedURL. Feeds in different accounts share attention data.*/


@interface RSDataFeedAttentionInfo : NSManagedObject {
}

@property (nonatomic, retain) NSString *feedURL;
@property (nonatomic, retain) NSNumber *numberOfItemsEverFollowed;
@property (nonatomic, retain) NSNumber *numberOfItemsEverSharedGenerically;
@property (nonatomic, retain) NSNumber *numberOfItemsEverStarred;
@property (nonatomic, retain) NSNumber *scriptedAttentionScore;

- (void)incremementNumberOfItemsEverFollowed;
- (void)incrementNumberOfItemsEverSharedGenerically;
- (void)incrementNumberOfItemsEverStarred;

+ (RSDataFeedAttentionInfo *)fetchOrInsertFeedAttentionInfoWithURL:(NSString *)aURL moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate;


@end
