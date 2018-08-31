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

@property (nonatomic, strong) IBOutlet NNWSourceListDelegate *sourceListDelegate;
@property (nonatomic, strong) IBOutlet NNWArticleListDelegate *articleListDelegate;
@property (nonatomic, strong) IBOutlet NSOutlineView *sourceListView;
@property (nonatomic, strong) IBOutlet NNWArticleListScrollView *articleListScrollView;
@property (nonatomic, strong) IBOutlet NNWRightPaneContainerView *rightPaneContainerView;

@property (nonatomic, strong) RSPluginManager *pluginManager;
@property (nonatomic, strong, readonly) NSString *toggleReadMenuItemTitle;
@property (nonatomic, strong) NNWSourceListTreeBuilder *sourceListTreeBuilder;
@property (nonatomic, strong) RSDataController *dataController;

@property (nonatomic, strong) WebView *currentWebView; //detail view or browser view

- (void)openURLInDefaultBrowser:(NSURL *)aURL;
- (void)addSharingPluginCommandsToMenu:(NSMenu *)menu withSharableItem:(id<RSSharableItem>)sharableItem;

@end



@interface NNWMainWindow : NSWindow {
@private
    id<NNWKeyDownFilter> keyDownFilter;
//    NSUndoManager *undoManager;
}


@property (nonatomic, strong) id<NNWKeyDownFilter> keyDownFilter;
//@property (nonatomic, retain, readonly) NSUndoManager *undoManager;

@end

