//
//  NNWSourceListDelegate.h
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWSubscriber.h"


/*Gets inserted into responder chain -- is an NSResponder.*/

extern NSString *RSSourceListSelectionDidChangeNotification;

@class NNWSourceListTreeBuilder;
@class RSTreeNode;


@interface NNWSourceListDelegate : NSResponder <NSUserInterfaceValidations> {
@private
    NNWSourceListTreeBuilder *sourceListTreeBuilder;
    CGFloat configuredRowHeight;
    NSOutlineView *sourceListOutlineView;
    NSSet *selectedOutlineItems;
    NSArray *draggedItems;
    NSSplitView *splitView;
    RSTreeNode *itemBeingEdited;
}


@property (nonatomic, strong) IBOutlet NSOutlineView *sourceListOutlineView;
@property (nonatomic, strong) NSSet *selectedOutlineItems;
@property (nonatomic, strong, readonly) RSTreeNode *currentTreeNode;
@property (nonatomic, strong) IBOutlet NSSplitView *splitView;

- (void)selectTreeNode:(RSTreeNode *)aTreeNode;
- (void)selectRow:(NSUInteger)aRow;

@end

CGImageRef NNWFaviconForFeed(NSURL *feedHomePageURL, NSURL *feedFaviconURL, BOOL useDefaultIfNotFound);

