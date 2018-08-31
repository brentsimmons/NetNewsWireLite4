//
//  NNWSourceListTreeBuilder.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSourceListTreeBuilder.h"
#import "RSDataAccount.h"
#import "RSDataController.h"
#import "RSFeed.h"
#import "RSGlobalAccount.h"
#import "RSTree.h"
#import "RSTreeNode.h"


@interface NNWGlobalNodeRepresentedObject : NSObject <RSTreeNodeRepresentedObject> {
@private
    NSString *nameForDisplay;
}

@property (nonatomic, strong) NSString *nameForDisplay;
@end


@implementation NNWGlobalNodeRepresentedObject

@synthesize nameForDisplay;

#pragma mark Dealloc



@end


#pragma mark -


@interface NNWSourceListTreeBuilder ()

@property (nonatomic, strong) RSDataController *dataController;
@property (nonatomic, strong) RSTreeNode *localAccountNode;

@end


@implementation NNWSourceListTreeBuilder

@synthesize tree;
@synthesize dataController;
@synthesize localAccountNode;


static id gMyInstance = nil;

#pragma mark Class Methods

+ (NNWSourceListTreeBuilder *)sharedTreeBuilder {
    return gMyInstance;
}


#pragma mark Init

- (id)initWithDataController:(RSDataController *)aDataController {
    self = [super init];
    if (self == nil)
        return nil;
    dataController = aDataController;
    gMyInstance = self;
    return self;
}


#pragma mark Dealloc



#pragma mark Building

//- (void)addGlobalNodes {
//    NNWGlobalNodeRepresentedObject *allUnreadRepresentedObject = [[[NNWGlobalNodeRepresentedObject alloc] init] autorelease];
//    allUnreadRepresentedObject.nameForDisplay = @"All Unread";
//    RSTreeNode *allUnreadTreeNode = [RSTreeNode treeNodeWithParent:self.tree representedObject:allUnreadRepresentedObject];
//    allUnreadTreeNode.allowsDragging = NO;
//    [self.tree addChild:allUnreadTreeNode];
//    
//    NNWGlobalNodeRepresentedObject *todayRepresentedObject = [[[NNWGlobalNodeRepresentedObject alloc] init] autorelease];
//    todayRepresentedObject.nameForDisplay = @"Today";
//    RSTreeNode *todayTreeNode = [RSTreeNode treeNodeWithParent:self.tree representedObject:todayRepresentedObject];
//    todayTreeNode.allowsDragging = NO;
//    [self.tree addChild:todayTreeNode];
//}


- (void)addOneFeed:(RSFeed *)oneFeed toNode:(RSTreeNode *)parentNode {
    RSTreeNode *oneFeedNode = [RSTreeNode treeNodeWithParent:parentNode representedObject:oneFeed];
    [parentNode addChild:oneFeedNode];
}


- (void)addFeeds:(NSArray *)feeds toNode:(RSTreeNode *)parentNode {
    for (id oneObject in feeds) {
        if ([oneObject isKindOfClass:[RSFeed class]])
            [self addOneFeed:oneObject toNode:parentNode];
    }
    parentNode.sortKeyForOrderingChildren = @"name";
}


- (void)addAccounts {
    [self.tree addChildren:self.dataController.globalAccount.childTreeNodes];
    [self.tree addChild:self.dataController.localAccount.accountTreeNode];
}


- (void)rebuildTree {
    self.tree = [[RSTree alloc] init];
//    [self addGlobalNodes];
    [self addAccounts];
}


#pragma mark Searching

- (NSArray *)treeNodesForRepresentedObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject {
    return [self.tree treeNodesForRepresentedObject:aRepresentedObject];
}


- (RSTreeNode *)treeNodeWithCountForDisplayAfter:(RSTreeNode *)aTreeNode {
    NSArray *treeNodes = [self.tree flatItemsRespectingExpansionState];
    NSUInteger indexOfTreeNode = [treeNodes indexOfObjectIdenticalTo:aTreeNode];
    if (indexOfTreeNode == NSNotFound)
        return nil; //shouldn't happen
    if (indexOfTreeNode == [treeNodes count] - 1) //last?
        return nil;
    NSUInteger i = 0;
    for (i = indexOfTreeNode + 1; i < [treeNodes count]; i++) {
        RSTreeNode *oneTreeNode = [treeNodes objectAtIndex:i];
        if ([oneTreeNode.representedObject respondsToSelector:@selector(countForDisplay)] && oneTreeNode.representedObject.countForDisplay > 0)
            return oneTreeNode;
    }
    return nil;
}


- (RSTreeNode *)firstTreeNodeWithCountForDisplay {
    NSArray *treeNodes = [self.tree flatItemsRespectingExpansionState];
    NSUInteger i = 0;
    for (i = 0; i < [treeNodes count]; i++) {
        RSTreeNode *oneTreeNode = [treeNodes objectAtIndex:i];
        if ([oneTreeNode.representedObject respondsToSelector:@selector(countForDisplay)] && oneTreeNode.representedObject.countForDisplay > 0)
            return oneTreeNode;
    }
    return nil;
}


- (RSTreeNode *)treeNodeForAccount:(id<RSAccount>)anAccount {
    NSArray *treeNodes = [self treeNodesForRepresentedObject:(id<RSTreeNodeRepresentedObject>)anAccount];
    if (RSIsEmpty(treeNodes))
        return nil;
    return [treeNodes objectAtIndex:0];
}


- (RSTreeNode *)treeNodeForFolderName:(NSString *)folderName inAccount:(id<RSAccount>)anAccount {
    RSTreeNode *accountNode = [self treeNodeForAccount:anAccount];
    if (accountNode == nil)
        return nil;
    
    for (RSTreeNode *oneTreeNode in accountNode.children) {
        if (!oneTreeNode.isGroup || oneTreeNode.isSpecialGroup)
            continue;
        if ([[oneTreeNode.representedObject nameForDisplay] caseInsensitiveCompare:folderName] == NSOrderedSame)
            return oneTreeNode;
    }
    return nil;
}


- (NSArray *)feedsForTreeNode:(RSTreeNode *)aTreeNode {
    if (!aTreeNode.isGroup && !aTreeNode.isSpecialGroup)
        return [NSArray arrayWithObject:aTreeNode.representedObject];
    NSMutableArray *feeds = [NSMutableArray array];
    for (RSTreeNode *oneTreeNode in aTreeNode.flatItems) {
        if (oneTreeNode.isGroup || oneTreeNode.isSpecialGroup)
            continue;
        [feeds addObject:oneTreeNode.representedObject];        
    }
    return feeds;
}


#pragma mark Invalidate Caches

- (void)invalidateAllCaches {
    NSArray *flatItems = [self.tree.flatItems copy];
    for (RSTreeNode *oneTreeNode in flatItems) {
        [oneTreeNode invalidateCaches];
        [oneTreeNode invalidateFlatItemCache];
    }
}


@end


