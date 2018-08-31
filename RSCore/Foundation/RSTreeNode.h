//
//  RSTreeNode.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *RSTreeDidDeleteItemsNotification;

@protocol RSTreeNodeRepresentedObject <NSObject>

@required
@property (nonatomic, retain) NSString *nameForDisplay;

@optional
@property (nonatomic, assign, readonly) NSUInteger countForDisplay;
@property (nonatomic, retain, readonly) NSURL *associatedURL; //home page URL, for instance
@property (nonatomic, assign, readonly) BOOL nameIsEditable; //will do obj.nameForDisplay = @"some name" on end editing
@property (nonatomic, assign, readonly) BOOL canBeDeleted;

@end


@class RSTree;

@interface RSTreeNode : NSObject {
@private
    NSMutableArray *children;
    NSArray *orderedChildren;
    NSString *sortKeyForOrderingChildren;
    BOOL isSpecialGroup;
    BOOL isGroup;
    RSTreeNode *__weak parent;
    id<RSTreeNodeRepresentedObject> representedObject;
    RSTree *__weak tree;
    BOOL expanded;
    NSArray *flatItems;
    NSArray *flatItemsRespectingExpansionState;
    NSUInteger numberOfFlatItemsRespectingExpansionState;
    BOOL allowsDragging; //YES by default, since most nodes can be dragged (in theory)
}


+ (RSTreeNode *)treeNodeWithParent:(RSTreeNode *)aParent representedObject:(id<RSTreeNodeRepresentedObject>)anObject;

@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) BOOL isGroup;
@property (nonatomic, assign) BOOL isSpecialGroup;
@property (nonatomic, assign) NSUInteger numberOfFlatItemsRespectingExpansionState;
@property (nonatomic, weak) RSTree *tree;
@property (nonatomic, weak) RSTreeNode *parent;
@property (nonatomic, assign, readonly) BOOL hasChildren;
@property (nonatomic, assign, readonly) NSUInteger numberOfChildren;
@property (nonatomic, strong) NSArray *flatItems;
@property (nonatomic, strong) NSArray *flatItemsRespectingExpansionState;
@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, strong) NSString *sortKeyForOrderingChildren;
@property (nonatomic, strong) id<RSTreeNodeRepresentedObject> representedObject;
@property (nonatomic, strong, readonly) NSArray *orderedChildren; //sorted alphabetically by default
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, assign) BOOL allowsDragging;

- (void)addChild:(RSTreeNode *)childToAdd;
- (void)addChildren:(NSArray *)childrenToAdd;
- (void)insertChild:(RSTreeNode *)childToInsert atIndex:(NSUInteger)insertionIndex;
- (void)insertChildren:(NSArray *)childrenToInsert atIndex:(NSUInteger)insertionIndex;

- (void)removeChild:(RSTreeNode *)childToRemove;
- (void)removeChildren:(NSArray *)childrenToRemove;
- (void)removeAllChildren;

- (RSTreeNode *)childAtIndex:(NSUInteger)anIndex;
- (RSTreeNode *)flatItemAtIndex:(NSUInteger)anIndex respectingExpansionState:(BOOL)respectingExpansionState;

- (RSTreeNode *)orderedChildAtIndex:(NSUInteger)anIndex;
- (NSUInteger)numberOfOrderedChildren;

- (BOOL)isDescendedFrom:(RSTreeNode *)possibleAncestorNode;
- (NSUInteger)orderedIndexForPotentialChild:(RSTreeNode *)potentialChild;  //where it *would* be, were it a child

- (void)moveChildren:(NSArray *)someChildren; //move from current home to here: divorces parents first
- (NSArray *)treeNodesForRepresentedObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject; //searches self and all children

- (RSTreeNode *)nextOrderedSibling;

- (void)invalidateCaches;
- (void)invalidateFlatItemCache;

- (void)detach;

@end
