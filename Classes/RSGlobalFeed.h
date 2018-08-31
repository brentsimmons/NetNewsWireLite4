//
//  RSGlobalFeed.h
//  nnw
//
//  Created by Brent Simmons on 1/18/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSTreeNode.h"
#import "RSRefreshProtocols.h"


typedef enum _RSGlobalFeedType {
	RSGlobalFeedTypeAllUnread,
	RSGlobalFeedTypeToday
} RSGlobalFeedType;


@interface RSGlobalFeed : NSObject <RSTreeNodeRepresentedObject> {
@private
	NSString *nameForDisplay;
	NSUInteger unreadCount;
	RSGlobalFeedType globalFeedType;
	id<RSAccount> account;
}


@property (nonatomic, retain, readwrite) NSString *nameForDisplay;
@property (nonatomic, assign, readonly) NSUInteger countForDisplay;
@property (nonatomic, assign) NSUInteger unreadCount;
@property (nonatomic, assign) RSGlobalFeedType globalFeedType;
@property (nonatomic, retain) id<RSAccount> account;

- (NSArray *)fetchArticlesWithSortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc;

@end

