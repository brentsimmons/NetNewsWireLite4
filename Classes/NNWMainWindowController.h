//
//  NNWMainWindowController.h
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


@protocol NNWKeyDownFilter <NSObject>

- (BOOL)didHandleKeyDown:(NSEvent *)anEvent;

@end


@class NNWArticleListDelegate;
@class NNWArticleListScrollView;
@class NNWRightPaneContainerView;
@class NNWSourceListDelegate;
@class NNWSourceListTreeBuilder;
@class RSDataController;
@class RSPluginManager;


@interface NNWMainWindowController : NSWindowController <NSUserInterfaceValidations, NNWKeyDownFilter> {
@private
	NNWArticleListDelegate *articleListDelegate;
	NNWRightPaneContainerView *rightPaneContainerView;
	NNWSourceListDelegate *sourceListDelegate;
	NSString *mouseOverURL;
	NSString *selectedURL;
	NSString *statusBarURL;
	NSString *toggleReadMenuItemTitle;
	NSUInteger unreadCount;
	RSDataController *dataController;
	RSPluginManager *pluginManager;
	id<RSSharableItem> presentedSharableItem;
	WebView *currentWebView;
	NSUndoManager *undoManager;
}

@property (nonatomic, retain) IBOutlet NNWSourceListDelegate *sourceListDelegate;
@property (nonatomic, retain) IBOutlet NNWArticleListDelegate *articleListDelegate;
@property (nonatomic, retain) IBOutlet NSOutlineView *sourceListView;
@property (nonatomic, retain) IBOutlet NNWArticleListScrollView *articleListScrollView;
@property (nonatomic, retain) IBOutlet NNWRightPaneContainerView *rightPaneContainerView;

@property (nonatomic, retain) RSPluginManager *pluginManager;
@property (nonatomic, retain, readonly) NSString *toggleReadMenuItemTitle;
@property (nonatomic, retain) NNWSourceListTreeBuilder *sourceListTreeBuilder;
@property (nonatomic, retain) RSDataController *dataController;

@property (nonatomic, retain) WebView *currentWebView; //detail view or browser view

- (void)openURLInDefaultBrowser:(NSURL *)aURL;
- (void)addSharingPluginCommandsToMenu:(NSMenu *)menu withSharableItem:(id<RSSharableItem>)sharableItem;

@end



@interface NNWMainWindow : NSWindow {
@private
	id<NNWKeyDownFilter> keyDownFilter;
//	NSUndoManager *undoManager;
}


@property (nonatomic, retain) id<NNWKeyDownFilter> keyDownFilter;
//@property (nonatomic, retain, readonly) NSUndoManager *undoManager;

@end

