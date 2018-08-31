//
//  NNWSourceListDelegate.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSourceListDelegate.h"
#import "NNWAppDelegate.h"
#import "NNWArticleListView.h"
#import "NNWGroupItemCell.h"
#import "NNWSourceListCell.h"
#import "NNWSourceListPointerWindow.h"
#import "NNWSourceListTreeBuilder.h"
#import "NNWSubscribeRequest.h"
#import "NNWVerticalScroller.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSFaviconController.h"
#import "RSFeed.h"
#import "RSFolder.h"
#import "RSGlobalFeed.h"
#import "RSImageUtilities.h"
#import "RSTree.h"
#import "RSTreeNode.h"



@interface NNWSourceListValidatedUserInterfaceItem : NSObject <NSValidatedUserInterfaceItem> {
@private
    SEL action;
    NSInteger tag;    
}

@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) NSInteger tag;
@end

@implementation NNWSourceListValidatedUserInterfaceItem

@synthesize action;
@synthesize tag;

@end


@interface NNWDeleteUndoSpecifier : NSObject {
@private
    RSTreeNode *treeNode;
    NSString *folderName;
    NSArray *objectIDsOfDeletedArticles;
}

@property (nonatomic, strong) RSTreeNode *treeNode;
@property (nonatomic, strong) NSString *folderName;
@property (nonatomic, strong) NSArray *objectIDsOfDeletedArticles;
@end


@implementation NNWDeleteUndoSpecifier

@synthesize treeNode;
@synthesize folderName;
@synthesize objectIDsOfDeletedArticles;


#pragma mark Dealloc



@end

NSString *RSSourceListSelectionDidChangeNotification = @"RSSourceListSelectionDidChangeNotification";

@interface NNWSourceListDelegate ()

@property (nonatomic, assign) CGFloat configuredRowHeight;
@property (nonatomic, strong) NNWSourceListTreeBuilder *sourceListTreeBuilder;
@property (nonatomic, strong) NSArray *draggedItems;
@property (nonatomic, strong) RSTreeNode *itemBeingEdited;

- (NSSet *)selectedItemsInOutlineView;
@end


@implementation NNWSourceListDelegate

@synthesize configuredRowHeight;
@synthesize selectedOutlineItems;
@synthesize sourceListOutlineView;
@synthesize sourceListTreeBuilder;
@synthesize draggedItems;
@synthesize splitView;
@synthesize itemBeingEdited;

#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark AwakeFromNib

- (void)awakeFromNib {
    NSTableColumn *tableColumn = [[self.sourceListOutlineView tableColumns] objectAtIndex:0];
    NNWSourceListCell *sourceListCell = [[NNWSourceListCell alloc] init];
    [sourceListCell setDrawsBackground:NO];

    [self.sourceListOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:RSRSSSourceType, NSPasteboardTypeString, NSURLPboardType, nil]];

    [sourceListCell setEditable:YES];
    [tableColumn setDataCell:sourceListCell];
    self.configuredRowHeight = [self.sourceListOutlineView rowHeight];

    self.sourceListTreeBuilder = [NNWSourceListTreeBuilder sharedTreeBuilder]; //should have been inited by app delegate
    [self.sourceListTreeBuilder rebuildTree];
    for (RSTreeNode *oneTopLevelNode in self.sourceListTreeBuilder.tree.children)
        oneTopLevelNode.expanded = YES;
    [self.sourceListOutlineView reloadData];
    [self.sourceListOutlineView expandItem:[self.sourceListOutlineView itemAtRow:2] expandChildren:NO];
    for (RSTreeNode *oneTreeNode in self.sourceListTreeBuilder.tree.flatItems) {
        if (oneTreeNode.isGroup && oneTreeNode.expanded)
            [self.sourceListOutlineView expandItem:oneTreeNode expandChildren:NO];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subscribeDidSucceed:) name:NNWSubscribeDidSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(folderAdded:) name:NNWFolderAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(importDidSucceed:) name:NNWOPMLImportDidSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(faviconDidDownload:) name:RSFaviconDownloadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedDataDidChange:) name:RSFeedDataDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedUnreadCountDidChange:) name:RSFeedUnreadCountDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedUnreadCountDidChange:) name:RSFolderUnreadCountDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:[[self sourceListOutlineView] enclosingScrollView]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NNWMainWindowDidResizeNotification object:nil];
    
    [[self sourceListOutlineView] setFrame:NSMakeRect(0.0f, 0.0f, 20.0f, 20.0f)];
    [[[self sourceListOutlineView] enclosingScrollView] tile];
}


#pragma mark Navigation

- (void)selectTreeNode:(RSTreeNode *)aTreeNode {
    NSInteger row = [self.sourceListOutlineView rowForItem:aTreeNode];
    if (row == -1)
        return; //shouldn't happen
    [self selectRow:(NSUInteger)row];
}


- (void)selectRow:(NSUInteger)aRow {
    NSIndexSet *rowIndexesToSelect = [NSIndexSet indexSetWithIndex:aRow];
    [self.sourceListOutlineView selectRowIndexes:rowIndexesToSelect byExtendingSelection:NO];    
}


#pragma mark Reload Data

- (NSIndexSet *)indexSetForItems:(NSSet *)someItems {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (id oneItem in someItems) {
        NSInteger indexOfOneItem = [self.sourceListOutlineView rowForItem:oneItem];
        if (indexOfOneItem < 0)
            continue;
        [indexSet addIndex:(NSUInteger)indexOfOneItem];
    }
    return indexSet;
}


- (void)restoreSelectionToSelectedOutlineItems:(NSSet *)selectedItems {
    NSIndexSet *indexSetForItems = [self indexSetForItems:selectedItems];
    [self.sourceListOutlineView selectRowIndexes:indexSetForItems byExtendingSelection:NO];
}


- (void)reloadDataPreservingSelection {
    NSSet *selectedItems = [self selectedItemsInOutlineView];
    [self.sourceListOutlineView reloadData];
    [self restoreSelectionToSelectedOutlineItems:selectedItems];
}


- (void)reloadDataAndSelectNone {
    [self.sourceListOutlineView reloadData];
    [self.sourceListOutlineView deselectAll:self];
}


#pragma mark Source List Data Source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return (NSInteger)(self.sourceListTreeBuilder.tree.numberOfChildren);
    return (NSInteger)((RSTreeNode *)item).numberOfOrderedChildren;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)anIndex ofItem:(id)item {
    if (item == nil)
        return [self.sourceListTreeBuilder.tree childAtIndex:(NSUInteger)anIndex];
    return [(RSTreeNode *)item orderedChildAtIndex:(NSUInteger)anIndex];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil)
        return NO;
    return ((RSTreeNode *)item).isGroup;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return ((RSTreeNode *)item).isSpecialGroup;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return !((RSTreeNode *)item).isSpecialGroup;

}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)column byItem:(id)item {
    if (item == nil)
        return nil;
    NSString *name = ((RSTreeNode *)item).representedObject.nameForDisplay;
    if ([name isEqualToString:@"On My Mac"])
        name = @"Feeds";
    if ([self outlineView:outlineView isGroupItem:item])
        name = [name uppercaseString];
    return name;
}


- (NSString *)uniqueNameForFolder:(RSFolder *)aFolder proposedName:(NSString *)proposedName {
    NSUInteger indexOfTries = 0;
    while (true) {
        indexOfTries++;
        NSString *nameToTry = [NSString stringWithFormat:@"%@ %d", proposedName, (long)indexOfTries];
        RSFolder *existingFolderInAccount = [aFolder.account folderWithName:nameToTry];
        if (existingFolderInAccount == nil)
            return nameToTry;
    }
    return nil; //the world will explode before this line executes
}


- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column byItem:(id)item {
    RSTreeNode *treeNode = (RSTreeNode *)item;
    id<RSTreeNodeRepresentedObject> folderOrFeed = treeNode.representedObject;
    if (![folderOrFeed respondsToSelector:@selector(nameIsEditable)] || !folderOrFeed.nameIsEditable)
        return;
    if (![folderOrFeed respondsToSelector:@selector(setNameForDisplay:)])
        return;
    if ([folderOrFeed isKindOfClass:[RSFolder class]]) {
        /*Make sure there isn't already a folder with that name*/
        RSFolder *existingFolderInAccount = [((RSFolder *)(self.itemBeingEdited.representedObject)).account folderWithName:value];
        if (existingFolderInAccount != nil && existingFolderInAccount != self.itemBeingEdited.representedObject)
            value = [self uniqueNameForFolder:folderOrFeed proposedName:value];
    }
    [folderOrFeed setNameForDisplay:value];
    [self.sourceListTreeBuilder invalidateAllCaches];
    [self reloadDataPreservingSelection];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    self.itemBeingEdited = item;
    return [((RSTreeNode *)item).representedObject respondsToSelector:@selector(nameIsEditable)] && ((RSTreeNode *)(item)).representedObject.nameIsEditable;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([self outlineView:outlineView isGroupItem:item])
        return NO;
    return YES;
}


#pragma mark Source List Delegate

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    RSTreeNode *treeNode = [[notification userInfo] objectForKey:@"NSObject"];
    treeNode.expanded = YES;
}


- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    RSTreeNode *treeNode = [[notification userInfo] objectForKey:@"NSObject"];
    treeNode.expanded = NO;    
}


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([self outlineView:outlineView isGroupItem:item])
        return 26.0f;
    return self.configuredRowHeight;
}


- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    static NNWGroupItemCell *groupItemCell = nil;
    if (groupItemCell == nil)
        groupItemCell = [[NNWGroupItemCell alloc] initTextCell:@""];
    if ([self outlineView:outlineView isGroupItem:item])
        return groupItemCell;
    return [tableColumn dataCellForRow:[outlineView rowForItem:item]];
}


CGImageRef NNWFaviconForFeed(NSURL *feedHomePageURL, NSURL *feedFaviconURL, BOOL useDefaultIfNotFound) {
    
    static NSMutableDictionary *faviconCache = nil;
    if (faviconCache == nil)
        faviconCache = [[NSMutableDictionary alloc] init];

    id feedImage = nil;
    
    if (feedFaviconURL != nil)
        feedImage = [faviconCache objectForKey:feedFaviconURL];
    if (feedImage != nil)
        return (CGImageRef)CFBridgingRetain(feedImage);
    
    if (feedHomePageURL != nil)
        feedImage = [faviconCache objectForKey:feedHomePageURL];
    if (feedImage != nil)
        return (CGImageRef)CFBridgingRetain(feedImage);
    
    feedImage = (id)[[RSFaviconController sharedController] faviconForHomePageURL:feedHomePageURL faviconURL:feedFaviconURL];
    if (feedImage != nil) {
        [faviconCache setObject:feedImage forKey:feedFaviconURL ? feedFaviconURL : feedHomePageURL];
        return (CGImageRef)CFBridgingRetain(feedImage);
    }
    
    if (!useDefaultIfNotFound)
        return nil;
    
    static CGImageRef defaultFavicon = nil;
    if (defaultFavicon == nil) {
        NSImage *favicon = [NSImage imageNamed:@"DefaultFavicon"];
        if (favicon != nil) {
            defaultFavicon = [favicon CGImageForProposedRect:NULL context:nil hints:nil];
            if (defaultFavicon != nil)
                CGImageRetain(defaultFavicon);
        }
    }
    return defaultFavicon;
}


- (void)fetchImageForFeed:(RSFeed *)aFeed andAssignToCell:(NNWSourceListCell *)cell {
    cell.smallImage = (__bridge id)NNWFaviconForFeed(aFeed.homePageURL, aFeed.faviconURL, YES);
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {

    NNWSourceListCell *sourceListCell = (NNWSourceListCell *)cell;
    
    if (![cell respondsToSelector:@selector(setSmallImage:)])
        return;    

    sourceListCell.smallImage = nil;
    sourceListCell.selected = [outlineView rs_isItemSelected:item];
    sourceListCell.shouldDrawSmallImage = YES;
    sourceListCell.isFolder = ([self outlineView:outlineView isItemExpandable:item] && ![self outlineView:outlineView isGroupItem:item]);
    if (sourceListCell.isFolder) {
        static CGImageRef folderImage = nil;
        if (folderImage == nil) {
            NSImage *standardFolderImage = [NSImage imageNamed:NSImageNameFolder];
            if (standardFolderImage != nil) {
                NSRect rFolderImage = NSMakeRect(0.0f, 0.0f, 16.0f, 16.0f);
                folderImage = CGImageRetain([standardFolderImage CGImageForProposedRect:&rFolderImage context:nil hints:nil]);
            }
        }
        if (folderImage != nil)
            sourceListCell.smallImage = (id)CFBridgingRelease(folderImage);
    }
    
    id<RSTreeNodeRepresentedObject> representedObject = ((RSTreeNode *)item).representedObject;
    if ([representedObject respondsToSelector:@selector(countForDisplay)])
        sourceListCell.countForDisplay = representedObject.countForDisplay;
    
    if ([representedObject isKindOfClass:[RSFeed class]])
        [self fetchImageForFeed:(RSFeed *)representedObject andAssignToCell:(NNWSourceListCell *)cell];

    if ([outlineView rowForItem:item] < 2)
        sourceListCell.shouldDrawSmallImage = NO;

}


- (void)sendSourceListSelectionDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:RSSourceListSelectionDidChangeNotification object:self.sourceListOutlineView userInfo:nil];
}


- (NSSet *)selectedItemsInOutlineView {
    NSMutableSet *selectedItems = [NSMutableSet set];
    NSIndexSet *selectedRowIndexes = [self.sourceListOutlineView selectedRowIndexes];
    NSUInteger oneIndex = [selectedRowIndexes firstIndex];
    while (oneIndex != NSNotFound) {
        id oneItem = [self.sourceListOutlineView itemAtRow:(NSInteger)oneIndex];
        [selectedItems rs_addObject:oneItem];
        oneIndex = [selectedRowIndexes indexGreaterThanIndex:oneIndex];
    }
    return selectedItems;
}


- (RSTreeNode *)currentTreeNode {
    NSIndexSet *selectedRowIndexes = [self.sourceListOutlineView selectedRowIndexes];
    NSUInteger oneIndex = [selectedRowIndexes firstIndex];
    while (oneIndex != NSNotFound)
        return [self.sourceListOutlineView itemAtRow:(NSInteger)oneIndex];
    return nil;    
}


- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    
    /*The selection indexes may have changed while the actual items didn't change -- for instance, when the tree has changed.
     In that case, don't do anything.*/
    
    NSSet *updatedSelectedItemsInOutlineView = [self selectedItemsInOutlineView];
    if (RSIsEmpty(self.selectedOutlineItems) || ![self.selectedOutlineItems isEqual:updatedSelectedItemsInOutlineView])
        [self sendSourceListSelectionDidChangeNotification];
    self.selectedOutlineItems = updatedSelectedItemsInOutlineView;
}


#pragma mark Source List Drag and Drop

- (NSDictionary *)getInfoFromPasteboard:(NSPasteboard *)pb {
    //TODO: review and improve this ancient code
    NSString *type;
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
    
    type = [pb availableTypeFromArray:[NSArray arrayWithObjects:RSRSSSourceType, WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil]];
    
    if ([type isEqualTo: NSStringPboardType])    
        [d rs_safeSetObject:[pb stringForType:NSStringPboardType] forKey:@"sourceRSSURL"];
    
    else if ([type isEqualTo: NSURLPboardType]) {
        
        NSURL *url = [NSURL URLFromPasteboard: pb];
        NSString *urlString;
        
        if (url == nil)
            return nil;
        
        urlString = [url absoluteString];
        if (urlString == nil)
            return nil;
        
        [d rs_safeSetObject:[[NSURL URLFromPasteboard: pb] absoluteString] forKey:@"sourceRSSURL"];
    }
    
    else if ([type isEqualToString:WebURLsWithTitlesPboardType]) {
        
        NSArray *urlsTitlesArray = [pb propertyListForType:WebURLsWithTitlesPboardType];        
        NSArray *urls = [urlsTitlesArray objectAtIndex:0];
        NSArray *titles = [urlsTitlesArray objectAtIndex:1];
        [d rs_safeSetObject:[urls objectAtIndex:0] forKey:@"sourceRSSURL"];
        [d rs_safeSetObject:[titles objectAtIndex:0] forKey:@"sourceName"];
        if ([urls count] > 1) {
            [d setObject:urls forKey:@"sourceURLsArray"];
            [d setObject:titles forKey:@"sourceTitlesArray"];
        }
    }
    
    else if ([type isEqualTo: RSRSSSourceType]) {
        
        NSArray *sources = [pb propertyListForType: RSRSSSourceType];        
        NSDictionary *source = [sources rs_safeObjectAtIndex: 0];
        NSString *URLString, *name, *container;
        
        URLString = [source objectForKey:@"sourceRSSURL"];
        
        name = [source objectForKey:@"sourceName"];
        
        container = [source objectForKey:@"sourceIsContainer"];
        
        [d rs_safeSetObject:URLString forKey:@"sourceRSSURL"];
        [d rs_safeSetObject:name forKey:@"sourceName"];
        if (container != nil) {        
            NSString *serialNumString = [source objectForKey:@"sourceSessionID"];
            [d rs_safeSetObject:container forKey:@"sourceIsContainer"];
            [d rs_safeSetObject:serialNumString forKey:@"sourceSessionID"];
        }
    }

    /*Translate feed URLs*/
    
    NSString *feedURLString = [d objectForKey:@"sourceRSSURL"];
    if (RSURLIsFeedURL (feedURLString)) {
        feedURLString = RSURLWithFeedURL (feedURLString);
        if (!RSIsEmpty(feedURLString))
            [d setObject:feedURLString forKey:@"sourceRSSURL"];
    }
    
    NSArray *urls = [d objectForKey:@"sourceURLsArray"];
    if (!RSIsEmpty(urls)) {
        NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:10];
        NSUInteger i;
        NSUInteger ct = [urls count];
        NSString *oneURLString;
        for (i = 0; i < ct; i++) {
            oneURLString = [urls objectAtIndex:i];
            if (RSURLIsFeedURL(oneURLString))
                oneURLString = RSURLWithFeedURL(oneURLString);
            [tempArray addObject:oneURLString];
        }
        [d setObject:tempArray forKey:@"sourceURLsArray"];    
    }
    
    return (d);
}


- (BOOL)itemsContainNonDraggableNodes:(NSArray *)items {
    for (RSTreeNode *oneTreeNode in items) {
        if (!oneTreeNode.allowsDragging)
            return YES;
    }
    return NO;
}


- (BOOL)itemsContainAtLeastOneFolder:(NSArray *)items {
    for (RSTreeNode *oneTreeNode in items) {
        if (oneTreeNode.isGroup)
            return YES;
    }
    return NO;    
}


- (BOOL)itemsContainsAtLeastOneChild:(NSArray *)items ofParentTreeNode:(RSTreeNode *)parentTreeNode {
    for (RSTreeNode *oneTreeNode in items) {
        if (oneTreeNode.parent == parentTreeNode)
            return YES;
    }
    return NO;        
}


- (BOOL)items:(NSArray *)items containsItsOwnParent:(RSTreeNode *)parentTreeNode {
    return [items rs_containsObjectIdenticalTo:parentTreeNode];
}


- (BOOL)draggedItemsContainsAncestorsOfItem:(RSTreeNode *)parentTreeNode {
    for (RSTreeNode *oneTreeNode in self.draggedItems) {
        if ([parentTreeNode isDescendedFrom:oneTreeNode])
            return YES;
    }
    return NO;            
}


- (void)retargetLocalDropWithProposedParent:(RSTreeNode *)parentTreeNode proposedChildIndex:(NSInteger)childIndex {
    
    if (childIndex == NSOutlineViewDropOnItemIndex)
        return;

    NSInteger sortedIndex = (NSInteger)[parentTreeNode orderedIndexForPotentialChild:[self.draggedItems objectAtIndex:0]];
    if (sortedIndex != childIndex && sortedIndex != NSNotFound)
        [self.sourceListOutlineView setDropItem:parentTreeNode dropChildIndex:sortedIndex];                
}


- (NSDragOperation)validateLocalDropWithProposedParent:(RSTreeNode *)parentTreeNode proposedChildIndex:(NSInteger)childIndex {
    
    if ([self itemsContainNonDraggableNodes:self.draggedItems])
        return NSDragOperationNone;
    
    if (parentTreeNode == nil)
        return NSDragOperationNone;
    if (!parentTreeNode.isGroup)
        return NSDragOperationNone;
    
    BOOL parentIsFolder = parentTreeNode.isGroup && !parentTreeNode.isSpecialGroup;
    
    if (parentIsFolder && [self itemsContainAtLeastOneFolder:self.draggedItems])
        return NSDragOperationNone; //sub-folders not allowed
    
    if ([self itemsContainsAtLeastOneChild:self.draggedItems ofParentTreeNode:parentTreeNode])
        return NSDragOperationNone; //already have that parent as the parent
    if ([self items:self.draggedItems containsItsOwnParent:parentTreeNode])
        return NSDragOperationNone;
    if ([self draggedItemsContainsAncestorsOfItem:parentTreeNode])
        return NSDragOperationNone;
    
    [self retargetLocalDropWithProposedParent:parentTreeNode proposedChildIndex:childIndex];
    return NSDragOperationMove;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    
    BOOL isLocalDrop = ([info draggingSource] == self.sourceListOutlineView);
    RSTreeNode *treeNode = (RSTreeNode *)item;
    
    if (index == NSOutlineViewDropOnItemIndex) {
        if (!treeNode.isGroup) {
            RSTreeNode *parentNode = treeNode.parent;
            if (parentNode != nil && parentNode.parent != nil) {
                [self.sourceListOutlineView setDropItem:treeNode.parent dropChildIndex:NSOutlineViewDropOnItemIndex];
                return isLocalDrop ? NSDragOperationMove : NSDragOperationCopy;
            }
            return NSDragOperationNone;            
        }
    }
    
    if (isLocalDrop)
        return [self validateLocalDropWithProposedParent:treeNode proposedChildIndex:index];
    
    else {
        NSDictionary *d = [self getInfoFromPasteboard:[info draggingPasteboard]];
        
        NSString *urlString = [d objectForKey:@"sourceRSSURL"];
        if (urlString == nil)
            return NSDragOperationNone;
        urlString = [urlString rs_stringByTrimmingWhitespace];
        if (RSIsEmpty(urlString))
            return NSDragOperationNone;
        if ([urlString rs_contains:@" "])
            return NSDragOperationNone;
        if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"] && ![urlString hasPrefix:@"file://"])
            return NSDragOperationNone;
        
        return NSDragOperationCopy;
    }

    return NSDragOperationNone;
}


- (void)sendFeedsAndFoldersDidReorganizeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:NNWFeedsAndFoldersDidReorganizeNotification object:self userInfo:nil];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    
    if ([self outlineView:outlineView validateDrop:info proposedItem:item proposedChildIndex:index] == NSDragOperationNone)
        return NO;
    BOOL isLocalDrop = ([info draggingSource] == self.sourceListOutlineView);
    RSTreeNode *treeNode = (RSTreeNode *)item;

    if (isLocalDrop) {
        [treeNode moveChildren:self.draggedItems];
        [self reloadDataPreservingSelection];
        [self sendFeedsAndFoldersDidReorganizeNotification];
        [rs_app_delegate.dataController performSelectorOnMainThread:@selector(makeAllAccountsDirty) withObject:nil waitUntilDone:NO];
        return YES;
    }

    else {
        
        NSDictionary *d = [self getInfoFromPasteboard:[info draggingPasteboard]];
        NSString *urlString = [d objectForKey:@"sourceRSSURL"];
        NSString *name = [d objectForKey:@"sourceName"];
        //NSArray *urls = [d objectForKey:@"sourceURLsArray"];

        NNWSubscribeRequest *subscribeRequest = [[NNWSubscribeRequest alloc] init];
        subscribeRequest.feedURL = [NSURL URLWithString:urlString];
        subscribeRequest.backgroundWindow = [self.sourceListOutlineView window];
        subscribeRequest.title = name;
        subscribeRequest.account = [RSDataAccount localAccount];
        if ([treeNode.representedObject isKindOfClass:[RSFolder class]])
            subscribeRequest.parentFolder = treeNode.representedObject;
        [nnw_app_delegate addFeedWithSubscribeRequest:subscribeRequest];
        [self sendFeedsAndFoldersDidReorganizeNotification];
        return YES;
    }

    return NO;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pb {
    
    /*TODO: figure out why this isn't working, then add the richer set of types that older versions of
     NetNewsWire exported.*/
    
    if ([self itemsContainNonDraggableNodes:items])
        return NO;
    self.draggedItems = items;    
    
    NSMutableArray *urls = [NSMutableArray array];
    
    for (RSTreeNode *oneTreeNode in items) {
        if ([oneTreeNode.representedObject respondsToSelector:@selector(URL)])
            [urls rs_safeAddObject:((RSFeed *)(oneTreeNode.representedObject)).URL];
    }
    
    if (RSIsEmpty(urls))
        return NO;
    
    [pb declareTypes:[NSArray arrayWithObjects:NSPasteboardTypeString, nil] owner:self];
    [pb setString:[[urls objectAtIndex:0] absoluteString] forType:NSPasteboardTypeString];
    return YES;
}


#pragma mark Notifications

- (void)faviconDidDownload:(NSNotification *)note {
    [self.sourceListOutlineView setNeedsDisplay:YES];
}


- (void)updateDisplayForRowsThatRepresentObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject {
    NSArray *treeNodes = [self.sourceListTreeBuilder treeNodesForRepresentedObject:aRepresentedObject];
    if (RSIsEmpty(treeNodes))
        return;
    for (RSTreeNode *oneTreeNode in treeNodes) {
        NSInteger oneRow = [self.sourceListOutlineView rowForItem:oneTreeNode];
        if (oneRow < 0)
            continue;
        NSRect oneRowRect = [self.sourceListOutlineView rectOfRow:oneRow];
        [self.sourceListOutlineView setNeedsDisplayInRect:oneRowRect];
    }
}


- (void)feedDataDidChange:(NSNotification *)note {
    [self updateDisplayForRowsThatRepresentObject:[note object]];
}


- (void)feedUnreadCountDidChange:(NSNotification *)note {
    [self updateDisplayForRowsThatRepresentObject:[note object]];
}


- (void)boundsDidChange:(NSNotification *)note {
    [self.sourceListOutlineView setNeedsDisplay:YES];
    [[self.sourceListOutlineView enclosingScrollView] setNeedsDisplay:YES];
}


#pragma mark NNWSubscriber Notifications

- (void)subscribeDidFail:(NNWSubscriber *)subscriber {
    NSLog(@"subscribeDidFail"); //TODO
}


- (void)subscribeDidSucceed:(NSNotification *)note {
    [self reloadDataPreservingSelection];
}


- (void)folderAdded:(NSNotification *)note {
    [self reloadDataPreservingSelection];    
}


- (void)importDidSucceed:(NSNotification *)note {
    [self reloadDataPreservingSelection];
}


#pragma mark Split View Delegate

static const CGFloat kDividerSnapPosition = 240.0f;
static const CGFloat kDividerSnapRegion = 32.0f; //on each of both sides, so the whole region is double

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedPosition > kDividerSnapPosition - kDividerSnapRegion && proposedPosition < kDividerSnapPosition + kDividerSnapRegion)
        return kDividerSnapPosition;
    return proposedPosition;
}


- (BOOL)splitView:(NSSplitView *)aSplitView shouldAdjustSizeOfSubview:(NSView *)view {
    return view == [[aSplitView subviews] objectAtIndex:1];
}


- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    NSView *subview0 = [[self.splitView subviews] objectAtIndex:0];
    [subview0 setNeedsDisplay:YES];
    [self.sourceListOutlineView setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark Actions

- (RSTreeNode *)selectedTreeNodeIfOnlyOne {
    if (RSIsEmpty(self.selectedOutlineItems))
        return nil;
    if ([self.selectedOutlineItems count] > 1)
        return nil;
    return [self.selectedOutlineItems anyObject];
}


- (id<RSTreeNodeRepresentedObject>)selectedRepresentedObjectIfOnlyOne {
    RSTreeNode *treeNode = [self selectedTreeNodeIfOnlyOne];
    if (treeNode == nil)
        return nil;
    return treeNode.representedObject;
}


- (RSFeed *)selectedFeedIfOnlyOne {
    id<RSTreeNodeRepresentedObject> representedObject = [self selectedRepresentedObjectIfOnlyOne];
    if (representedObject == nil || ![representedObject isKindOfClass:[RSFeed class]])
        return nil;
    return (RSFeed *)representedObject;
}


- (void)openURLAccordingToPreferences:(NSURL *)aURL {
    if (aURL != nil)
        [NSApp sendAction:@selector(openExternalURL:) to:nil from:aURL];
}


- (void)openHomePageWithRepresentedObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject {
    if (![aRepresentedObject respondsToSelector:@selector(homePageURL)])
        return;
    [self openURLAccordingToPreferences:((RSFeed *)aRepresentedObject).homePageURL];
}


- (void)openHomePage:(id)sender {
    [self openHomePageWithRepresentedObject:[self selectedRepresentedObjectIfOnlyOne]];
}


- (void)copyFeedHomePageURLWithRepresentedObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject {
    if (![aRepresentedObject respondsToSelector:@selector(homePageURL)])
        return;
    RSCopyURLStringToPasteboard([((RSFeed *)aRepresentedObject).homePageURL absoluteString], nil);
}


- (void)copyFeedHomePageURL:(id)sender {
    [self copyFeedHomePageURLWithRepresentedObject:[self selectedRepresentedObjectIfOnlyOne]];
}


- (void)copyFeedURLWithRepresentedObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject {
    if (![aRepresentedObject respondsToSelector:@selector(URL)])
        return;
    RSCopyURLStringToPasteboard([((RSFeed *)aRepresentedObject).URL absoluteString], nil);
}


- (void)copyFeedURL:(id)sender {
    [self copyFeedURLWithRepresentedObject:[self selectedRepresentedObjectIfOnlyOne]];
}


- (void)openWebPageForSelectedTreeNodes:(NSArray *)someTreeNodes {
    for (RSTreeNode *oneTreeNode in someTreeNodes) {
        if (![oneTreeNode.representedObject respondsToSelector:@selector(associatedURL)])
            continue;
        NSURL *URL = oneTreeNode.representedObject.associatedURL;
        if (URL != nil) {
            [self tryToPerform:@selector(openURLInBrowserAccordingToPreferences:) with:URL];
            break; //Open just one. Could get weird with 100 (or whatever) web pages.
        }
    }
}

- (BOOL)validateOpenHomePage:(id)sender {
    RSFeed *feed = [self selectedFeedIfOnlyOne];
    return feed != nil && feed.homePageURL != nil;
}


- (BOOL)validateCopyFeedURL:(id)sender {
    RSFeed *feed = [self selectedFeedIfOnlyOne];
    return feed != nil && feed.URL != nil;
}


- (BOOL)validateCopyFeedHomePageURL:(id)sender {
    RSFeed *feed = [self selectedFeedIfOnlyOne];
    return feed != nil && feed.homePageURL != nil;    
}


- (BOOL)validateDelete:(id)sender {
    if (RSIsEmpty(self.selectedOutlineItems))
        return NO;
    for (RSTreeNode *oneTreeNode in self.selectedOutlineItems) {
        if ([oneTreeNode.representedObject respondsToSelector:@selector(canBeDeleted)] && [oneTreeNode.representedObject canBeDeleted])
            return YES;
    }
    return NO;
}


- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
    if ([anItem action] == @selector(delete:))
        return [self validateDelete:anItem];
    if ([anItem action] == @selector(openHomePage:))
        return [self validateOpenHomePage:anItem];
    if ([anItem action] == @selector(copyFeedURL:))
        return [self validateCopyFeedURL:anItem];
    if ([anItem action] == @selector(copyFeedHomePageURL:))
        return [self validateCopyFeedHomePageURL:anItem];
    return NO;
}


#pragma mark Deleting

- (BOOL)representedObjectCanBeDeleted:(id<RSTreeNodeRepresentedObject>)aRepresentedObject {
    return [aRepresentedObject respondsToSelector:@selector(canBeDeleted)] && [aRepresentedObject canBeDeleted];
}


- (BOOL)treeNodeCanBeDeleted:(RSTreeNode *)aTreeNode {
    return [self representedObjectCanBeDeleted:aTreeNode.representedObject];
}


#define NNW_UNSUBSCRIBE NSLocalizedString(@"Delete", @"Sheet title")
#define NNW_DONT_DELETE NSLocalizedString(@"Don’t Delete", @"Button")
#define NNW_CONFIRM_DELETE_FEED_OR_FOLDER NSLocalizedString(@"Are you sure you want to delete %@? This operation cannot be undone.", @"Delete sheet message")
#define NNW_CONFIRM_DELETE_FEED_OR_FOLDER_NO_NAME NSLocalizedString(@"Are you sure you want to delete this item? This operation cannot be undone.", @"Delete sheet message")
#define NNW_CONFIRM_DELETE_MULTIPLE_FEED_OR_FOLDER NSLocalizedString(@"Are you sure you want to delete these items? This operation cannot be undone.", @"Delete sheet message")

- (BOOL)anyItemInSelectionIsFolderWithChildren {
    for (RSTreeNode *oneTree in self.selectedOutlineItems) {
        if (oneTree.isGroup && !oneTree.isSpecialGroup && oneTree.hasChildren)
            return YES;
    }
    return NO;    
}


- (NSMutableSet *)setOfFeedsInSelectedOutlineItems {
    NSMutableSet *feeds = [NSMutableSet set];
    for (RSTreeNode *oneTreeNode in self.selectedOutlineItems) {
        NSArray *feedsForTreeNode = [self.sourceListTreeBuilder feedsForTreeNode:oneTreeNode];
        if (!RSIsEmpty(feedsForTreeNode))
            [feeds addObjectsFromArray:feedsForTreeNode];
    }
    return feeds;
}


- (void)deleteSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
    if (returnCode != NSAlertDefaultReturn)
        return;
    
    NSMutableSet *deletedFeeds = [self setOfFeedsInSelectedOutlineItems];
    for (RSTreeNode *oneTreeNode in self.selectedOutlineItems)
        [oneTreeNode detach];
    
    [self.sourceListTreeBuilder invalidateAllCaches];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSTreeDidDeleteItemsNotification object:self userInfo:[NSDictionary dictionaryWithObject:self.selectedOutlineItems forKey:@"nodes"]]; //updates feedsDictionary in RSDataAccount
    
    /*Feeds may be in multiple places -- remove those feeds from the feeds-to-delete list.*/
    NSMutableSet *feedsToDelete = [NSMutableSet set];
    for (RSFeed *oneFeed in deletedFeeds) {
        if (![oneFeed.account isSubscribedToFeedWithURL:oneFeed.URL])
            [feedsToDelete addObject:oneFeed];
    }
    
    /*Mark for deletion all the articles in the feed.*/
    NSManagedObjectContext *moc = rs_app_delegate.mainThreadManagedObjectContext;
    for (RSFeed *oneFeed in feedsToDelete)
        [RSDataArticle markAsDeletedAllArticlesForFeedURL:oneFeed.URL accountID:oneFeed.account.identifier moc:moc];

    [rs_app_delegate saveManagedObjectContext:moc];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSDataDidDeleteArticlesNotification object:self userInfo:nil];
    
    [self reloadDataAndSelectNone];
}


- (void)runDeleteConfirmSheet {
    
    BOOL isOneItem = [self.selectedOutlineItems count] < 2;
    BOOL isFolderWithChildren = [self anyItemInSelectionIsFolderWithChildren];
    NSString *message = nil;
    
    if (isFolderWithChildren)
        isOneItem = NO;
    
    if (isOneItem) {
        NSString *name = ((RSTreeNode *)[self.selectedOutlineItems anyObject]).representedObject.nameForDisplay;
        if (!RSStringIsEmpty(name))
            message = [NSString stringWithFormat:NNW_CONFIRM_DELETE_FEED_OR_FOLDER, name];
        else
            message = NNW_CONFIRM_DELETE_FEED_OR_FOLDER_NO_NAME;
    }
    else {
        message = NNW_CONFIRM_DELETE_MULTIPLE_FEED_OR_FOLDER;
    }

    NSBeginAlertSheet(NNW_UNSUBSCRIBE, NNW_UNSUBSCRIBE, NNW_DONT_DELETE, nil, [NSApp mainWindow], self, @selector(deleteSheetDidEnd:returnCode:contextInfo:), nil, nil, message);
}


- (void)delete:(id)sender {
    if (![self validateDelete:sender]) //Could be coming from toolbar, and might not be validated
        return;
    [self runDeleteConfirmSheet];
}


#pragma mark -
#pragma mark Contextual Menu

- (void)addAction:(SEL)anAction title:(NSString *)aTitle toMenu:(NSMenu *)aMenu {
    NNWSourceListValidatedUserInterfaceItem *item = [[NNWSourceListValidatedUserInterfaceItem alloc] init];
    item.action = anAction;
    if ([self validateUserInterfaceItem:item])
        [aMenu addItemWithTitle:aTitle action:anAction keyEquivalent:@""];
}


- (NSMenu *)contextualMenuForFeed:(RSFeed *)feed {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Folder Contextual Menu"];
    
    [self addAction:@selector(openHomePage:) title:NSLocalizedString(@"Open Home Page", @"Feed Command") toMenu:menu];
    if ([menu numberOfItems] > 0)
        [menu addItem:[NSMenuItem separatorItem]];
    
    [self addAction:@selector(copyFeedURL:) title:NSLocalizedString(@"Copy Feed URL", @"Feed Command") toMenu:menu];
    [self addAction:@selector(copyFeedHomePageURL:) title:NSLocalizedString(@"Copy Home Page URL", @"Feed Command") toMenu:menu];
    
    [menu rs_addSeparatorItemIfLastItemIsNotSeparator];
    
    [self addAction:@selector(delete:) title:NSLocalizedString(@"Delete", @"Feed Command") toMenu:menu];
    
    return menu;                                                
}


- (NSMenu *)contextualMenuForRow:(NSInteger)row {
    RSTreeNode *treeNode = [self.sourceListOutlineView itemAtRow:row];
    if (treeNode == nil)
        return nil;
    id<RSTreeNodeRepresentedObject> representedObject = treeNode.representedObject;
    if ([representedObject isKindOfClass:[RSFeed class]])
        return [self contextualMenuForFeed:representedObject];
    return nil;
}


#pragma mark -
#pragma mark Events

static const unichar kNNWKeypadEnterKey = 3;

- (void)keyDown:(NSEvent *)event {
    
    NSString *s = [event characters];
    if (RSStringIsEmpty(s)) {
        [super keyDown:event];
        return;
    }
            
    unichar ch = [s characterAtIndex:0];
    BOOL shiftKeyDown = (([event modifierFlags] & NSShiftKeyMask) != 0);
    BOOL optionKeyDown = (([event modifierFlags] & NSAlternateKeyMask) != 0);
    BOOL commandKeyDown = (([event modifierFlags] & NSCommandKeyMask) != 0);
    BOOL controlKeyDown = (([event modifierFlags] & NSControlKeyMask) != 0);
    BOOL anyModifierKeyDown = shiftKeyDown || optionKeyDown || commandKeyDown || controlKeyDown;
    
    switch (ch) {
            
        case kNNWKeypadEnterKey:
        case '\n':
        case '\r':
            if (!anyModifierKeyDown) {
                [self tryToPerform:@selector(openWebPageForSelectedTreeNodes:) with:self.selectedOutlineItems];
                return;
            }
            break;

        case NSRightArrowFunctionKey:
            if (!anyModifierKeyDown) {
                [self tryToPerform:@selector(moveFocusToArticleListAndSelectTopRowIfNeeded:) with:nil];
                return;
            }
            break;
            
        default:
            break;
    }
    
    [super keyDown:event];
}


@end

