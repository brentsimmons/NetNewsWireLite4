//
//  NNWFeedAttionInfo.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataFeedAttentionInfo.h"
#import "RSCoreDataUtilities.h"
#import "RSDataManagedObjects.h"


@interface RSDataFeedAttentionInfo (CoreDataGeneratedPrimitiveAccessors)
- (NSNumber *)primitiveNumberOfItemsEverFollowed;
- (NSNumber *)primitiveNumberOfItemsEverSharedGenerically;
- (NSNumber *)primitiveNumberOfItemsEverStarred;
@end


@implementation RSDataFeedAttentionInfo

@dynamic feedURL;
@dynamic numberOfItemsEverFollowed;
@dynamic numberOfItemsEverSharedGenerically;
@dynamic numberOfItemsEverStarred;
@dynamic scriptedAttentionScore;


- (void)incremementNumberOfItemsEverFollowed {
	self.numberOfItemsEverFollowed = [[self primitiveNumberOfItemsEverFollowed] numberIncremented];
}


- (void)incrementNumberOfItemsEverSharedGenerically {
	self.numberOfItemsEverSharedGenerically = [[self primitiveNumberOfItemsEverSharedGenerically] numberIncremented];
}


- (void)incrementNumberOfItemsEverStarred {
	self.numberOfItemsEverStarred = [[self primitiveNumberOfItemsEverStarred] numberIncremented];
}


#pragma mark Inserting and Fetching

static NSString *NNWFeedAttentionInfoEntityName = @"FeedAttentionInfo";
static NSString *NNWFeedAttentionInfoUniqueKey = @"feedURL";

+ (RSDataFeedAttentionInfo *)fetchOrInsertFeedAttentionInfoWithURL:(NSString *)aURL moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate {
	return (RSDataFeedAttentionInfo *)RSFetchOrInsertObjectWithValueForKey(NNWFeedAttentionInfoUniqueKey, aURL, NNWFeedAttentionInfoEntityName, moc, didCreate);
}

@end
