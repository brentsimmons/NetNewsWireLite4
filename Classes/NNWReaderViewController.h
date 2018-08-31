//
//  NNWReaderViewController.h
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWMainWindowController.h"


@class NNWArticleListDelegate;
@class NNWReaderRightPaneContainerView;
@class NNWSourceListDelegate;
@class RSDataArticle;
@class RSTreeNode;


@interface NNWReaderViewController : NSViewController <NNWKeyDownFilter, NSUserInterfaceValidations> {
@private
	NNWReaderRightPaneContainerView *rightPaneContainerView;
	NSSplitView *splitView;
	NNWSourceListDelegate *sourceListDelegate;
	NNWArticleListDelegate *readerContentViewController;
	RSTreeNode *currentTreeNode;
	NSOutlineView *sourceListView;
}


@property (nonatomic, retain) IBOutlet NNWReaderRightPaneContainerView *rightPaneContainerView;
@property (nonatomic, retain) IBOutlet NSSplitView *splitView;
@property (nonatomic, retain) IBOutlet NNWSourceListDelegate *sourceListDelegate;
@property (nonatomic, retain) IBOutlet NSOutlineView *sourceListView;

@property (nonatomic, retain) NNWArticleListDelegate *readerContentViewController;

@property (nonatomic, retain) RSTreeNode *currentTreeNode; //more than one may be selected: this is the top one

- (void)navigateToArticleInCurrentList:(RSDataArticle *)anArticle;
- (void)navigateToFirstUnreadArticle;
- (void)navigateToTreeNode:(RSTreeNode *)aTreeNode;

@end


CGImageRef NNWImageForFeedOrFolder(id feedOrFolder);
