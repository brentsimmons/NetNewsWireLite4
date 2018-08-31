//
//  RSGlobalAccount.h
//  nnw
//
//  Created by Brent Simmons on 1/18/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSRefreshProtocols.h"
#import "RSTreeNode.h"

/*Manages the items like all-unread and today.*/

@class RSGlobalFeed;

@interface RSGlobalAccount : NSObject <RSAccount, RSTreeNodeRepresentedObject> {
@private
    RSGlobalFeed *allUnreadFeed;
    RSGlobalFeed *todayFeed;
    NSArray *childTreeNodes;
    RSTreeNode *accountTreeNode;
    NSTimer *todayUnreadCountTimer;
}


+ (RSGlobalAccount *)globalAccount; //just one

@property (nonatomic, strong, readonly) NSArray *childTreeNodes;


@end
