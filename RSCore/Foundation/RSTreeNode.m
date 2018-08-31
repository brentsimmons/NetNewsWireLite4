//
//  RSTreeNode.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSTreeNode.h"
#import "RSFoundationExtras.h"
#import "RSTree.h"


NSString *RSTreeDidDeleteItemsNotification = @"RSTreeDidDeleteItemsNotification";


@interface RSTreeNode ()

@property (nonatomic, retain, readwrite) NSArray *orderedChildren;

- (void)ensureChildrenAreOrphaned;
- (void)ensureChildrenHaveParent;

- (id)initWithParent:(RSTreeNode *)aParent representedObject:(id<RSTreeNodeRepresentedObject>)anObject;

@end


@implementation RSTreeNode

@synthesize allowsDragging;
@synthesize children;
@synthesize expanded;
@synthesize flatItems;
@synthesize flatItemsRespectingExpansionState;
@synthesize isGroup;
@synthesize isSpecialGroup;
@synthesize numberOfFlatItemsRespectingExpansionState;
@synthesize orderedChildren;
@synthesize parent;
@synthesize representedObject;
@synthesize sortKeyForOrderingChildren;
@synthesize tree;


+ (RSTreeNode *)treeNodeWithParent:(RSTreeNode *)aParent representedObject:(id<RSTreeNodeRepresentedObject>)anObject {
	return [[[self alloc] initWithParent:aParent representedObject:anObject] autorelease];
}


#pragma mark Init

- (id)initWithParent:(RSTreeNode *)aParent representedObject:(id<RSTreeNodeRepresentedObject>)anObject {
	self = [super init];
	if (self == nil)
		return nil;
	parent = aParent;
	representedObject = [anObject retain];
	sortKeyForOrderingChildren = [@"nameForDisplay" retain]; //alphabetical by default
	allowsDragging = YES;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self ensureChildrenAreOrphaned];
	[children release];
	parent = nil;
	tree = nil;
	[flatItems release];
	[flatItemsRespectingExpansionState release];
	[orderedChildren release];
	[representedObject release];
	[sortKeyForOrderingChildren release];
	[super dealloc];
	
}


#pragma mark Children

- (NSMutableArray *)children {
	if (!self.isGroup)
		return nil;
	if (children == nil)
		children = [[NSMutableArray array] retain];
	return children;
}


- (void)ensureChildrenAreOrphaned {
	if (self.isGroup)
		[self.children makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	[self invalidateCaches];
}


- (void)ensureChildrenHaveParent {
	if (self.isGroup)
		[self.children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[self invalidateCaches];
}


- (BOOL)hasChildren {
	return self.isGroup && !RSIsEmpty(self.children);
}


- (void)addChild:(RSTreeNode *)childToAdd {
	if (!self.isGroup)
		return;
	childToAdd.parent = self;
	[self.children addObject:childToAdd];
	[self invalidateCaches];
}


- (void)addChildren:(NSArray *)childrenToAdd {
	for (RSTreeNode *oneChildToAdd in childrenToAdd)
		[self addChild:oneChildToAdd];
	[self invalidateCaches];
}


- (void)insertChild:(RSTreeNode *)childToInsert atIndex:(NSUInteger)insertionIndex {
	[self.children insertObject:childToInsert atIndex:insertionIndex];
	[self invalidateCaches];
}


- (void)insertChildren:(NSArray *)childrenToInsert atIndex:(NSUInteger)insertionIndex {
	for (RSTreeNode *oneChildToInsert in childrenToInsert) {
		[self insertChild:oneChildToInsert atIndex:insertionIndex];
		insertionIndex++;
	}
	[self invalidateCaches];
}


- (NSUInteger)indexOfChild:(RSTreeNode *)aChild {
	return [self.children indexOfObjectIdenticalTo:aChild];
}


- (RSTreeNode *)childAtIndex:(NSUInteger)anIndex {
	if (RSIsEmpty(self.children))
		return nil;
	return [self.children rs_safeObjectAtIndex:anIndex];
}


- (RSTreeNode *)orderedChildAtIndex:(NSUInteger)anIndex {
	if (RSIsEmpty(self.orderedChildren))
		return nil;
	return [self.orderedChildren rs_safeObjectAtIndex:anIndex];
}


- (NSUInteger)numberOfChildren {
	if (RSIsEmpty(self.children))
		return 0;
	return [self.children count];
}


- (NSUInteger)numberOfOrderedChildren {
	if (RSIsEmpty(self.orderedChildren))
		return 0;
	return [self.orderedChildren count];	
}


- (BOOL)hasChild:(RSTreeNode *)aChild {
	return [self indexOfChild:aChild] != NSNotFound;
}


- (void)removeChild:(RSTreeNode *)childToRemove {
	[self.children removeObjectIdenticalTo:childToRemove];
	[self invalidateCaches];
}


- (void)removeChildren:(NSArray *)childrenToRemove {
	for (RSTreeNode *oneChild in childrenToRemove)
		[self removeChild:oneChild];
	[self invalidateCaches];
}


- (void)removeAllChildren {
	self.children = [NSMutableArray array];
	[self invalidateCaches];
}


- (void)moveChildren:(NSArray *)someChildren {
	/*They're going from somewhere else to here. They have to divorce their parents first.*/
	[[someChildren retain] autorelease];
	for (RSTreeNode *oneChild in someChildren) {
		RSTreeNode *oneParent = oneChild.parent;
		[oneParent removeChild:oneChild];
	}
	[self addChildren:someChildren];
}


- (void)setSortKeyForOrderingChildren:(NSString *)aSortKey {
	if ([aSortKey isEqualToString:sortKeyForOrderingChildren])
		return;
	self.orderedChildren = nil;
	[sortKeyForOrderingChildren autorelease];
	sortKeyForOrderingChildren = [aSortKey retain];
	[self invalidateCaches];
}


- (NSArray *)arraySortedByCurrentOrder:(NSArray *)anArray {
	if (RSStringIsEmpty(self.sortKeyForOrderingChildren))
		return anArray;
	NSString *sortKey = [NSString stringWithFormat:@"representedObject.%@", self.sortKeyForOrderingChildren];
	return [anArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES selector:@selector(localizedStandardCompare:)]]];	
}


- (void)updateOrderedChildren {
	self.orderedChildren = [self arraySortedByCurrentOrder:self.children];
	[self invalidateFlatItemCache];
}


- (NSArray *)orderedChildren {
	if (RSStringIsEmpty(self.sortKeyForOrderingChildren))
		return self.children;
	if (orderedChildren == nil)
		[self updateOrderedChildren];
	return orderedChildren;
//	NSArray *sortedArray = [self arraySortedByCurrentOrder:self.children];
//	[orderedChildren autorelease];
//	orderedChildren = [sortedArray retain];
//	[self invalidateCaches];
//	return orderedChildren;	
}


- (BOOL)isDescendedFrom:(RSTreeNode *)possibleAncestorNode {
	RSTreeNode *nomad = self;
	while (nomad != nil) {
		if (nomad == possibleAncestorNode)
			return YES;
		nomad = nomad.parent;
	}
	return NO;
}


- (NSUInteger)orderedIndexForPotentialChild:(RSTreeNode *)potentialChild {
	NSMutableArray *anArray = [[self.children mutableCopy] autorelease];
	[anArray addObject:potentialChild];
	NSArray *sortedArray = [self arraySortedByCurrentOrder:anArray];
	return [sortedArray indexOfObjectIdenticalTo:potentialChild];
}


- (RSTreeNode *)nextOrderedSibling {
	NSArray *orderedSiblings = [self.parent orderedChildren];
	NSUInteger indexOfSelf = [orderedSiblings indexOfObjectIdenticalTo:self];
	if (indexOfSelf == NSNotFound) //shouldn't happen
		return nil;
	if (indexOfSelf == [orderedSiblings count] - 1) //last one?
		return nil;
	return [orderedSiblings objectAtIndex:indexOfSelf + 1];
}


- (void)detach {
	[[self retain] autorelease];
	[self.parent removeChild:self];
	self.parent = nil;
}

#pragma mark Expanded

- (void)setExpanded:(BOOL)flag {
	if (expanded != flag) {
		expanded = flag;
		[self invalidateFlatItemCache];
	}
}


#pragma mark Flat Items

- (void)invalidateFlatItemCache {
	self.flatItems = nil;
	self.flatItemsRespectingExpansionState = nil;
	self.numberOfFlatItemsRespectingExpansionState = NSNotFound;
	if (self.parent != nil)
		[self.parent invalidateFlatItemCache];	
}


- (void)invalidateCaches {
	self.orderedChildren = nil;
	self.flatItems = nil;
	self.flatItemsRespectingExpansionState = nil;
	self.numberOfFlatItemsRespectingExpansionState = NSNotFound;
	if (self.parent != nil)
		[self.parent invalidateCaches];
}


- (NSArray *)flatItems {
	if (flatItems != nil)
		return flatItems;
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:3000];
	for (RSTreeNode *oneChildNode in self.orderedChildren) {
		[tempArray addObject:oneChildNode];
		NSArray *grandchildren = oneChildNode.flatItems;
		if (!RSIsEmpty(grandchildren))
			[tempArray addObjectsFromArray:grandchildren];
	}
	self.flatItems = tempArray;
	return flatItems;
}


- (NSArray *)flatItemsRespectingExpansionState {
	if (flatItemsRespectingExpansionState != nil)
		return flatItemsRespectingExpansionState;
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:3000];
	for (RSTreeNode *oneChildNode in self.orderedChildren) {
		[tempArray addObject:oneChildNode];
		if (oneChildNode.expanded) {
			NSArray *grandchildren = oneChildNode.flatItemsRespectingExpansionState;
			if (!RSIsEmpty(grandchildren))
				[tempArray addObjectsFromArray:grandchildren];
		}
	}
	self.flatItemsRespectingExpansionState = tempArray;
	return flatItemsRespectingExpansionState;
}


- (RSTreeNode *)flatItemAtIndex:(NSUInteger)anIndex respectingExpansionState:(BOOL)respectingExpansionState {
	if (respectingExpansionState)
		return [self.flatItemsRespectingExpansionState rs_safeObjectAtIndex:anIndex];
	return [self.flatItems rs_safeObjectAtIndex:anIndex];
}


- (NSUInteger)numberOfFlatItemsRespectingExpansionSate {
	if (numberOfFlatItemsRespectingExpansionState == NSNotFound)
		self.numberOfFlatItemsRespectingExpansionState = [self.flatItemsRespectingExpansionState count];
	return numberOfFlatItemsRespectingExpansionState;
}


- (NSArray *)treeNodesForRepresentedObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject {
	NSMutableArray *tempArray = [NSMutableArray array];
	if (self.representedObject == aRepresentedObject)
		[tempArray addObject:self];
	for (RSTreeNode *oneTreeNode in self.flatItems) {
		if (oneTreeNode.representedObject == aRepresentedObject)
			[tempArray addObject:oneTreeNode];
	}
	return tempArray;
}


#pragma mark Represented Object

- (NSString *)title {
	return self.representedObject.nameForDisplay;
}


@end
