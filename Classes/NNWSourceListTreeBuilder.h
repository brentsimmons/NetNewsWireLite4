//
//  NNWSourceListTreeBuilder.h
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSTreeNode.h"
#import "RSRefreshProtocols.h"


@class RSDataController;
@class RSTree;

@interface NNWSourceListTreeBuilder : NSObject {
@private
	RSTree *tree;
	RSDataController *dataController;
	RSTreeNode *localAccountNode;
}


+ (NNWSourceListTreeBuilder *)sharedTreeBuilder; //init has to be called first
- (id)initWithDataController:(RSDataController *)aDataController;

@property (nonatomic, retain) RSTree *tree;

- (void)rebuildTree;

- (NSArray *)treeNodesForRepresentedObject:(id<RSTreeNodeRepresentedObject>)aRepresentedObject; //entire tree

- (RSTreeNode *)treeNodeWithCountForDisplayAfter:(RSTreeNode *)aTreeNode;
- (RSTreeNode *)firstTreeNodeWithCountForDisplay;

- (void)invalidateAllCaches;

- (RSTreeNode *)treeNodeForAccount:(id<RSAccount>)anAccount; //finds existing
- (RSTreeNode *)treeNodeForFolderName:(NSString *)folderName inAccount:(id<RSAccount>)anAccount; //finds existing

- (NSArray *)feedsForTreeNode:(RSTreeNode *)aTreeNode; //RSFeed array. If folder, all descendants; else just the feed for the node.
@end
