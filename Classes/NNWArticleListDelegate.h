//
//  NNWReaderContentViewController.h
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWArticleListScrollView.h"
#import "NNWArticleListView.h"
#import "NNWBrowserViewController.h"


/*Gets inserted into responder chain -- is an NSResponder.*/


@class NNWArticleDetailPaneView;
@class NNWArticleListScrollView;
@class NNWBrowserViewController;
@class NNWRightPaneContainerView;
@class NNWSourceListDelegate;
@class RSArticleListController;
@class RSDataArticle;
@class RSMacWebView;


@interface NNWArticleListDelegate : NSResponder <NNWArticleListDelegate, NNWBrowserViewControllerDelegate, NNWArticleContextualMenuDelegate> {
@private
    NNWArticleDetailPaneView *articleDetailPaneView;
    NNWArticleListScrollView *articleListScrollView;
    NNWBrowserViewController *browserViewController;
    NNWRightPaneContainerView *rightPaneContainerView;
    NNWSourceListDelegate *sourceListDelegate;
    NSArray *articles;
    NSArray *feeds;
    NSArray *selectedArticles;
    NSString *listControllerKey;
    NSViewController *detailTemporaryViewController;
    RSArticleListController *articleListController;
    RSMacWebView *webView;
    BOOL sortAscending;
    WebView *currentWebView;
    RSDataArticle *contextualMenuArticle;
}


@property (nonatomic, strong) IBOutlet NNWArticleDetailPaneView *articleDetailPaneView;
@property (nonatomic, strong) IBOutlet NNWArticleListScrollView *articleListScrollView;
@property (nonatomic, strong) IBOutlet NNWRightPaneContainerView *rightPaneContainerView;
@property (nonatomic, strong) IBOutlet NNWSourceListDelegate *sourceListDelegate;

@property (nonatomic, strong) NSArray *articles; //generated here, after feeds are set
@property (nonatomic, strong) NSArray *feeds; //set (usually) based on source list selection

@property (nonatomic, strong) NSArray *selectedArticles; //set based on article list selection, updates HTML in detail pane view
@property (nonatomic, strong) WebView *currentWebView; //detail view or browser view
@property (nonatomic, assign, readonly) BOOL currentWebViewIsDetailView;

- (void)navigateToArticleInCurrentList:(RSDataArticle *)anArticle;
- (void)navigateToFirstUnreadArticle;

- (void)makeArticleListFirstResponder;
- (void)makeDetailViewFirstResponder;

- (void)openURLInInternalBrowser:(NSURL *)aURL;

- (void)selectArticle:(RSDataArticle *)anArticle;

@end
