//
//  NNWReaderContentViewController.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleListDelegate.h"
#import "NNWArticleDetailPaneView.h"
#import "NNWArticleGroupHeaderView.h"
#import "NNWArticleListView.h"
#import "NNWArticleTheme.h"
#import "NNWBrowserViewController.h"
#import "NNWHTMLBuilderArticle.h"
#import "NNWMainWindowController.h"
#import "NNWRightPaneContainerView.h"
#import "NNWSourceListDelegate.h"
#import "NNWStyleSheetController.h"
#import "RSArticleListController.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSDataController.h"
#import "RSDateManager.h"
#import "RSDownloadConstants.h"
#import "RSFeed.h"
#import "RSFolder.h"
#import "RSGlobalFeed.h"
#import "RSMacWebView.h"
#import "RSPluginObjects.h"
#import "RSRefreshController.h"
#import "WebView+Extras.h"



@interface NNWArticleListGroupItem : NSObject {
@private
    NSString *title;
}

@property (nonatomic, strong) NSString *title;

@end


@implementation NNWArticleListGroupItem

@synthesize title;

#pragma mark Dealloc


@end


@interface NNWArticleListDelegate ()

@property (nonatomic, assign) BOOL sortAscending;
@property (nonatomic, strong) NNWBrowserViewController *browserViewController;
@property (nonatomic, strong) NSString *listControllerKey;
@property (nonatomic, strong) NSViewController *detailTemporaryViewController;
@property (nonatomic, strong) RSArticleListController *articleListController;
@property (nonatomic, strong) RSDataArticle *contextualMenuArticle;
@property (nonatomic, strong) RSMacWebView *webView;
@property (nonatomic, strong, readonly) RSDataArticle *selectedArticle;

- (void)updateDetailView;
- (NNWMainWindowController *)mainWindowController;
- (void)openExternalURLForArticle:(RSDataArticle *)anArticle;

@end


#pragma mark -

@implementation NNWArticleListDelegate

@synthesize articleDetailPaneView;
@synthesize articleListController;
@synthesize articleListScrollView;
@synthesize articles;
@synthesize browserViewController;
@synthesize contextualMenuArticle;
@synthesize currentWebView;
@synthesize detailTemporaryViewController;
@synthesize feeds;
@synthesize listControllerKey;
@synthesize rightPaneContainerView;
@synthesize selectedArticles;
@synthesize sortAscending;
@synthesize sourceListDelegate;
@synthesize webView;

#pragma mark Dealloc

- (void)dealloc {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.styleSheetName"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.sortArticlesOldestAtTop"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.articleListScrollView removeObserver:self forKeyPath:@"selectedRowIndexes"];
    [self removeObserver:self forKeyPath:@"feeds"];
    [self removeObserver:self forKeyPath:@"articles"];
    [self removeObserver:self forKeyPath:@"selectedArticles"];
}


#pragma mark AwakeFromNib

- (void)awakeFromNib {
    self.sortAscending = [[NSUserDefaults standardUserDefaults] boolForKey:@"sortArticlesOldestAtTop"];
    self.articleListController = [[RSArticleListController alloc] init];
    self.listControllerKey = [NSString rs_uuidString];
    [rs_app_delegate.dataController setListController:self.articleListController forKey:self.listControllerKey];
    [self.sourceListDelegate addObserver:self forKeyPath:@"selectedOutlineItems" options:0 context:nil];

    [self addObserver:self forKeyPath:@"feeds" options:0 context:nil];
    [self addObserver:self forKeyPath:@"articles" options:0 context:nil];
    [self.articleListScrollView addObserver:self forKeyPath:@"selectedRowIndexes" options:0 context:nil];
    [self addObserver:self forKeyPath:@"selectedArticles" options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.styleSheetName" options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sortArticlesOldestAtTop" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(overlayViewWasPopped:) name:RSOverlayViewWasPoppedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSessionDidEnd:) name:RSRefreshSessionDidEndNotification object:nil];
    
    [self updateDetailView];
}


#pragma mark NNWArticleListDelegate

- (id)objectForRow:(NSUInteger)row {
    return [self.articles rs_safeObjectAtIndex:row];
}


- (NSView *)listView:(id)listView groupViewForRow:(NSUInteger)row {
    id objectForRow = [self objectForRow:row];
    NNWArticleGroupHeaderView *aView = (NNWArticleGroupHeaderView *)[listView dequeueReusableCellWithIdentifier:@"ArticleGroupHeader"];
    NSRect groupRowFrame = NSMakeRect(0.0f, 0.0f, 300.0f, [self listView:listView heightForRow:row]);
    if (aView == nil)
        aView = [[NNWArticleGroupHeaderView alloc] initWithFrame:groupRowFrame];
    aView.title = ((NNWArticleListGroupItem *)[self.articles objectAtIndex:row]).title;
    aView.reuseIdentifier = @"ArticleGroupHeader";
    aView.groupItem = objectForRow;
    aView.isFirst = (row == 0);
    return aView;
}


- (BOOL)rowIsAlternate:(NSUInteger)row {
    NSInteger indexAfterLastGroupItem = 0;
    while (true) {
        indexAfterLastGroupItem++;
        row = row - 1;
        id objectForRow = [self objectForRow:row];
        if ([objectForRow isKindOfClass:[NNWArticleListGroupItem class]])
            break;
        if (row < 1)
            break;
    }
    return indexAfterLastGroupItem % 2 == 0;
}


- (BOOL)showingMultipleFeeds {
    if (self.feeds == nil)
        return NO;
    if ([self.feeds count] > 1)
        return YES;
    if ([[self.feeds objectAtIndex:0] isKindOfClass:[RSFolder class]])
        return YES;
    if ([[self.feeds objectAtIndex:0] isKindOfClass:[RSGlobalFeed class]])
        return YES;
    return NO;
}


- (NSView *)listView:(id)listView viewForRow:(NSUInteger)row {
    id objectForRow = [self objectForRow:row];
    if ([objectForRow isKindOfClass:[NNWArticleListGroupItem class]])
        return [self listView:listView groupViewForRow:row];
    NNWArticleListView *aView = (NNWArticleListView *)[listView dequeueReusableCellWithIdentifier:@"ArticleCell"];
    if (aView == nil)
        aView = [[NNWArticleListView alloc] init];
    [aView setFrame:NSMakeRect(0.0f, 0.0f, 300.0f, [self listView:listView heightForRow:row])];
    aView.title = ((RSDataArticle *)[self.articles objectAtIndex:row]).plainTextTitle;
    aView.reuseIdentifier = @"ArticleCell";
    aView.article = [self.articles objectAtIndex:row];
    aView.showFeedName = self.showingMultipleFeeds;
    aView.contextualMenuDelegate = self;
    return aView;
}


- (CGFloat)listView:(id)listView heightForRow:(NSUInteger)row {
    id objectForRow = [self objectForRow:row];
    if ([objectForRow isKindOfClass:[NNWArticleListGroupItem class]])
        return 24.0f;//72.0f;
    //return 34.0f;//72.0f;
    //return 92.0f;
//    return 108.0f;
    //return 94.0f;
    return [NNWArticleListView heightForArticleWithThumbnail];
}


- (NSUInteger)numberOfRowsInListView:(id)listView {
    if (RSIsEmpty(self.articles))
        return 0;
    return [self.articles count];
}


- (BOOL)listView:(id)listView shouldSelectRow:(NSUInteger)row {
    return [[self objectForRow:row] isKindOfClass:[RSDataArticle class]];
}


- (void)listView:(id)listView rowWasDoubleClicked:(NSUInteger)row {
    id objectForRow = [self objectForRow:row];
    if ([objectForRow isKindOfClass:[RSDataArticle class]])
        [self openExternalURLForArticle:(RSDataArticle *)objectForRow];
}


- (void)listViewUserDidSwipeRight:(id)listView {
    if ([self selectedArticle] != nil)
        [self openExternalURLForArticle:[self selectedArticle]];
}


#pragma mark Articles


- (NSArray *)groupedArticles:(NSArray *)someArticles {
    
    /*Already sorted chronologically.*/
    
    NSMutableArray *groupedArray = [NSMutableArray arrayWithCapacity:[someArticles count] + 20];
    [[RSDateManager sharedManager] recalculateDates];
    
    NSInteger lastGroup = NSNotFound;
    NSInteger lastYear = NSNotFound;
    NSInteger lastMonth = NSNotFound;
    
    for (RSDataArticle *oneArticle in someArticles) {
        
        NSDate *oneDate = oneArticle.dateForDisplay;
        RSDateGroup oneGroup = [[RSDateManager sharedManager] groupForDate:oneDate];
        NSInteger year = 0, month = 0;
        
        if (oneGroup == RSDateGroupPast) {
            [[RSDateManager sharedManager] year:&year andMonth:&month forDate:oneDate];
            if (year != lastYear || month != lastMonth) {
                NNWArticleListGroupItem *yearMonthGroupItem = [[NNWArticleListGroupItem alloc] init];
                static NSDateFormatter *monthYearDateFormatter = nil;
                if (monthYearDateFormatter == nil) {
                    monthYearDateFormatter = [[NSDateFormatter alloc] init];
                    [monthYearDateFormatter setDateFormat:@"MMMM yyyy"];
                }
                yearMonthGroupItem.title = [monthYearDateFormatter stringFromDate:oneDate];
                lastYear = year;
                lastMonth = month;
                [groupedArray addObject:yearMonthGroupItem];
            }
            [groupedArray addObject:oneArticle];
            continue;
        }
        
        if (oneGroup == lastGroup) {
            [groupedArray addObject:oneArticle];
            continue;
        }
        
        NSString *groupTitle = NSLocalizedString(@"Future", @"Date group in list view");
        
        if (oneGroup == RSDateGroupToday)
            groupTitle = NSLocalizedString(@"Today", @"Date group in list view");
        else if (oneGroup == RSDateGroupYesterday)
            groupTitle = NSLocalizedString(@"Yesterday", @"Date group in list view");
        
        NNWArticleListGroupItem *groupItem = [[NNWArticleListGroupItem alloc] init];
        groupItem.title = groupTitle;
        [groupedArray addObject:groupItem];
        [groupedArray addObject:oneArticle];
        
        lastGroup = oneGroup;
    }
    
    return groupedArray;
}


- (void)updateArticles {
    ((RSDataController *)(rs_app_delegate.dataController)).currentListController = self.articleListController;
    self.articleListController.sortAscending = self.sortAscending;
    self.articleListController.feedsAndFolders = self.feeds;
    [self.articleListController updateArticles:nil];
    self.articles = [self groupedArticles:self.articleListController.articles];
}


static BOOL arraysHaveEqualContents(NSArray *array1, NSArray *array2) {
    if (array1 == nil && array2 == nil)
        return YES;
    if (array1 == nil && array2 != nil)
        return NO;
    if (array1 != nil && array2 == nil)
        return NO;
    if ([array1 count] != [array2 count])
        return NO;
    for (id oneItem in array2) {
        if (![array1 rs_containsObjectIdenticalTo:oneItem])
            return NO;
    }
    return YES;
}


- (void)updateSelectedArticles {
    NSIndexSet *selectedRowIndexes = self.articleListScrollView.selectedRowIndexes;
    NSMutableArray *updatedSelectedArticles = [NSMutableArray array];
    NSUInteger oneIndex = [selectedRowIndexes firstIndex];
    while (oneIndex != NSNotFound) {
        [updatedSelectedArticles addObject:[self.articles objectAtIndex:oneIndex]];
        oneIndex = [selectedRowIndexes indexGreaterThanIndex:oneIndex];
    }
    
    /*If the two arrays are equal, don't update, because that triggers a notification, which triggers an update to the HTML view.*/
    if (!arraysHaveEqualContents(self.selectedArticles, updatedSelectedArticles))
        self.selectedArticles = updatedSelectedArticles;
}


- (void)notifySharableItemDidChangeTo:(id<RSSharableItem>)aSharableItem {
    [[NSNotificationCenter defaultCenter] postNotificationName:NNWPresentedSharableItemDidChangeNotification object:self userInfo:aSharableItem ? [NSDictionary dictionaryWithObject:aSharableItem forKey:NNWSharableItemKey] : nil];
}


- (RSDataArticle *)selectedArticle {
    if (RSIsEmpty(self.selectedArticles))
        return nil;
    return [self.selectedArticles objectAtIndex:0];
}


- (void)notifySharableItemDidChangeToCurrentArticle {
    RSDataArticle *currentArticle = [self selectedArticle];
    if (currentArticle == nil)
        [self notifySharableItemDidChangeTo:nil];
    else
        [self notifySharableItemDidChangeTo:[RSSharableItem sharableItemWithArticle:currentArticle]];
     }
     
     
- (void)updateSortOrder {
    RSDataArticle *currentArticle = self.selectedArticle;
    self.sortAscending = [[NSUserDefaults standardUserDefaults] boolForKey:@"sortArticlesOldestAtTop"];
    [self updateArticles];
    if (currentArticle == nil)
        return;
    [self navigateToArticleInCurrentList:currentArticle];
}


#pragma mark Navigation

static NSUInteger gRowToSelect = 0;

- (void)selectRowAfterDelay {
    [self.articleListScrollView selectRow:gRowToSelect];
}


- (void)navigateToArticleInCurrentList:(RSDataArticle *)anArticle {
    [self.webView stopLoading:self];
    NSUInteger row = [self.articles indexOfObjectIdenticalTo:anArticle];
    if (row != NSNotFound) {
        //[self.articleListScrollView scrollRowToMiddleIfNotVisible:row];
    if (![self.articleListScrollView scrollRowToMiddleIfNotVisible:row]) {
            gRowToSelect = row;
            [self performSelector:@selector(selectRowAfterDelay) withObject:nil afterDelay:0.31f];
        }
        else
            [self.articleListScrollView selectRow:row];
    }
}


- (void)navigateToFirstUnreadArticle {
    RSDataArticle *firstUnreadArticle = self.articleListController.firstUnreadArticle;
    if (firstUnreadArticle == nil)
        return; //shouldn't happen
    [self navigateToArticleInCurrentList:firstUnreadArticle];
}


- (void)selectArticle:(RSDataArticle *)anArticle {
    if ([self selectedArticle] == anArticle)
        return;
    NSUInteger row = [self.articles indexOfObjectIdenticalTo:anArticle];
    [self.articleListScrollView selectRow:row];
}


#pragma mark Detail View


- (void)loadEmptyArticleInDetailView {
    NNWArticleTheme *articleTheme = [NNWStyleSheetController sharedController].defaultArticleTheme;
    NSString *styleSheetPath = articleTheme.emptyCSSFilePath;
    NSURL *styleSheetURL = [NSURL fileURLWithPath:styleSheetPath];
    NSString *styleSheetURLString = [styleSheetURL absoluteString];
    styleSheetURLString = RSStringReplaceAll(styleSheetURLString, @"file://", @"rsstylesheet://");
    
    NNWHTMLBuilderArticle *htmlBuilderArticle = [[NNWHTMLBuilderArticle alloc] initWithArticle:nil htmlTemplate:articleTheme.htmlTemplate styleSheetPath:styleSheetURLString];
    htmlBuilderArticle.includeHTMLHeader = YES;
    htmlBuilderArticle.includeHTMLFooter = YES;
    [[self.webView mainFrame] loadHTMLString:htmlBuilderArticle.renderedHTML baseURL:nil];    
}


static NSURL *baseURLWithURLString(NSString *aURLString) {
    if (RSStringIsEmpty(aURLString))
        return nil;
    NSURL *baseURL = [NSURL URLWithString:aURLString];
    if (!RSStringIsEmpty([baseURL fragment])) { /*items with a fragment will cause detail view to stick: Apple dev news, for instance*/
        aURLString = [aURLString rs_stringByStrippingSuffix:[baseURL fragment]];
        aURLString = [aURLString rs_stringByStrippingSuffix:@"#"];
        baseURL = [NSURL URLWithString:aURLString];
    }
    return baseURL;
}


- (void)loadHTMLInDetailView {
    
    BOOL emptyDetailView = (RSIsEmpty(self.selectedArticles) || [self.selectedArticles count] != 1);
    if (emptyDetailView) {
        [self loadEmptyArticleInDetailView];
        return;
    }
        
    NNWArticleTheme *articleTheme = [NNWStyleSheetController sharedController].defaultArticleTheme;
    NSString *styleSheetPath = articleTheme.cssFilePath;
    NSURL *styleSheetURL = [NSURL fileURLWithPath:styleSheetPath];
    NSString *styleSheetURLString = [styleSheetURL absoluteString];
    styleSheetURLString = RSStringReplaceAll(styleSheetURLString, @"file://", @"rsstylesheet://");
    
    RSDataArticle *articleToDisplay = [self.selectedArticles objectAtIndex:0]; //TODO: xmlBaseURL should be saved in article
    NSURL *baseURL = nil;
    NSString *baseURLString = articleToDisplay.bestLink;
    if (!RSStringIsEmpty(baseURLString))
        baseURL = baseURLWithURLString(baseURLString);
    if (baseURL == nil) {
        RSDataAccount *account = [rs_app_delegate.dataController accountWithID:articleToDisplay.accountID];
        RSFeed *feed = [account feedWithURL:[NSURL URLWithString:articleToDisplay.feedURL]];
        baseURL = feed.homePageURL;
    }
    if (baseURL == nil) {
        NSString *feedURLString = articleToDisplay.feedURL;
        if (!RSStringIsEmpty(feedURLString))
            baseURL = baseURLWithURLString(feedURLString);
    }
    if (baseURL == nil)
        baseURL = [NSURL URLWithString:@"http://google.com/"]; //total punt
    
    NNWHTMLBuilderArticle *htmlBuilderArticle = [[NNWHTMLBuilderArticle alloc] initWithArticle:articleToDisplay htmlTemplate:articleTheme.htmlTemplate styleSheetPath:styleSheetURLString];
    htmlBuilderArticle.includeHTMLHeader = YES;
    htmlBuilderArticle.includeHTMLFooter = YES;
    [[self.webView mainFrame] loadHTMLString:htmlBuilderArticle.renderedHTML baseURL:baseURL];    
}


- (void)reloadDetailView {    
    /*After article-theme change, for instance.*/
    [self loadHTMLInDetailView];
}



- (NSView *)detailContentViewForSelectedArticles {
    
    BOOL emptyDetailView = (RSIsEmpty(self.selectedArticles) || [self.selectedArticles count] != 1);
    
    if (self.webView == nil) {
        self.webView = [[RSMacWebView alloc] initWithFrame:[self.articleDetailPaneView frame] frameName:nil groupName:nil];
        self.webView.requestFavicons = NO;
        self.webView.canBeDragDestination = YES;
        [self.webView setMaintainsBackForwardList:NO];
        [self.webView setUIDelegate:self];
        [self.webView setFrameLoadDelegate:self];
        [self.webView setPolicyDelegate:self];
        [self.webView setApplicationNameForUserAgent:rs_app_delegate.applicationNameForWebviewUserAgent];
    }

    if (emptyDetailView)
        [self loadEmptyArticleInDetailView];
    else {
        [self loadHTMLInDetailView];
        RSDataArticle *articleToDisplay = [self.selectedArticles objectAtIndex:0];
        [articleToDisplay markAsRead:YES];
    }
    
    [self notifySharableItemDidChangeToCurrentArticle];
    
    return self.webView;
}


- (BOOL)currentWebViewIsDetailView {
    return self.currentWebView == self.webView;
}


- (void)notifyCurrentWebViewDidChange:(WebView *)aWebView {
    self.currentWebView = aWebView;
    [[NSNotificationCenter defaultCenter] postNotificationName:NNWCurrentWebViewDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:aWebView forKey:NNWViewKey]];    
}


- (void)updateDetailView {
    NSView *detailContentView = [self detailContentViewForSelectedArticles];
    self.articleDetailPaneView.detailContentView = detailContentView;
    self.detailTemporaryViewController = nil;
    [self.rightPaneContainerView popAllViews];
    [self.browserViewController detachDelegates];
    self.browserViewController = nil;
    [self notifyCurrentWebViewDidChange:self.webView];
}


- (void)notifySelectedArticlesDidChange {
    ((RSDataController *)(rs_app_delegate.dataController)).currentArticles = self.selectedArticles;
}


- (void)sendURLDidUpdateNotification:(NSString *)urlString notificationName:(NSString *)notificationName {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo rs_safeSetObject:urlString forKey:RSURLKey];
    [userInfo rs_safeSetObject:self.articleDetailPaneView.detailContentView forKey:@"view"];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}
                                                                   
                                                                   
- (void)updateStatusBarURL {
    if (RSIsEmpty(self.selectedArticles) || [self.selectedArticles count] != 1) {
        [self sendURLDidUpdateNotification:nil notificationName:NNWSelectedURLDidUpdateNotification];
        return;
    }
    RSDataArticle *article = [self.selectedArticles objectAtIndex:0];
    [self sendURLDidUpdateNotification:[article bestLink] notificationName:NNWSelectedURLDidUpdateNotification];    
}


#pragma mark Browser

- (void)openURLInInternalBrowser:(NSURL *)aURL {
    
    [self.rightPaneContainerView popAllViews];
        
    self.browserViewController = [[NNWBrowserViewController alloc] init];
    self.browserViewController.delegate = self;
    
    if (aURL != nil && ![[aURL scheme] isEqualToString:@"about"])
        [self.browserViewController performSelector:@selector(setURLStringForBrowserTextField:) withObject:[aURL absoluteString]];
    
    [self.browserViewController performSelector:@selector(openURL:) withObject:aURL afterDelay:0.27f];
    self.detailTemporaryViewController = self.browserViewController;
    [self.rightPaneContainerView pushViewOnTop:[self.browserViewController view]];
    [[self.rightPaneContainerView window] makeFirstResponder:[self.browserViewController webview]];
    
    [self notifyCurrentWebViewDidChange:(WebView *)[self.browserViewController view]];
}


#pragma mark NNWBrowserViewDelegate


- (void)closeBrowserViewController:(NNWBrowserViewController *)aBrowserViewController {
//    [self.rightPaneContainerView popView];
//    self.browserViewController = nil;
//    self.detailTemporaryViewController = nil;
}


- (void)browserViewControllerDidChange:(NNWBrowserViewController *)aBrowserViewController {
    
    if (aBrowserViewController != self.browserViewController || !self.rightPaneContainerView.hasPushedView)
        return;
    
    NSString *URLString = [aBrowserViewController.webview displayURL];
    if (RSStringIsEmpty(URLString) || [URLString rs_caseInsensitiveContains:@"about:blank"]) {
        [self notifySharableItemDidChangeTo:nil];
        return;
    }
        
    NSURL *aURL = nil;
    if (URLString != nil)
        aURL = [NSURL URLWithString:URLString];
    NSString *title = [aBrowserViewController.webview displayTitle];
    RSSharableItem *sharableItem = [RSSharableItem sharableItemWithURL:aURL permalink:nil title:title];
    [self notifySharableItemDidChangeTo:sharableItem];
}


- (BOOL)firstResponderIsWindow {
    return [[self.articleDetailPaneView window] firstResponder] == [self.articleDetailPaneView window];
}


- (void)overlayViewWasPopped:(NSNotification *)note {
    NSView *overlayView = [[note userInfo] objectForKey:NNWViewKey];
    if ([self.browserViewController view] == overlayView) {
        [self.browserViewController detachDelegates];
        self.browserViewController = nil;
    }
    if ([self.detailTemporaryViewController view] == overlayView)
        self.detailTemporaryViewController = nil;
    if (!self.rightPaneContainerView.hasPushedView) {
        [self notifyCurrentWebViewDidChange:self.webView];
        [self notifySharableItemDidChangeToCurrentArticle];
    }
    if ([self firstResponderIsWindow])
        [self makeArticleListFirstResponder];
        
    
}

#pragma mark KVO

static NSArray *arrayOfFeedsWithSetOfTreeNodes(NSSet *aSet) {
    if (aSet == nil)
        return nil;
    if (RSIsEmpty(aSet))
        return nil;
    NSMutableArray *tempArray = [NSMutableArray array];
    for (id oneObject in aSet)
        [tempArray rs_safeAddObject:((RSTreeNode *)oneObject).representedObject];
    return tempArray;
}


- (void)sendFeedsSelectedNotification:(NSArray *)someFeeds {
    if (RSIsEmpty(someFeeds))
        return;
    for (id oneFeed in someFeeds) {
        if ([oneFeed respondsToSelector:@selector(setUnreadCountIsValid:)])
            ((RSFeed *)oneFeed).unreadCountIsValid = NO;
    }
    [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:NNWFeedsSelectedNotification object:self userInfo:[NSDictionary dictionaryWithObject:self.feeds forKey:@"feeds"]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedOutlineItems"]) {
        self.feeds = arrayOfFeedsWithSetOfTreeNodes(self.sourceListDelegate.selectedOutlineItems);
        [self sendFeedsSelectedNotification:self.feeds];
    }
    else if ([keyPath isEqualToString:@"feeds"])
        [self updateArticles];
    else if ([keyPath isEqualToString:@"articles"])
        [self.articleListScrollView reloadData];
    else if ([keyPath isEqualToString:@"selectedRowIndexes"] && object == self.articleListScrollView)
        [self updateSelectedArticles];
    else if ([keyPath isEqualToString:@"selectedArticles"]) {
        [self notifySelectedArticlesDidChange];
        [self updateDetailView];
        [self updateStatusBarURL];
    }
    else if ([keyPath isEqualToString:@"values.styleSheetName"])
        [self reloadDetailView];
    else if ([keyPath isEqualToString:@"values.sortArticlesOldestAtTop"])
        [self updateSortOrder];
}


#pragma mark Notifications

- (void)refreshSessionDidEnd:(NSNotification *)note {
    
    /*Re-fetch articles for the selected feeds/folders. Keep the current article, even
     if doesn't belong in the re-fetched set.*/
    
    if (RSIsEmpty(self.feeds))
        return;
    NSArray *currentArticles = self.selectedArticles;
    self.articleListController.sortAscending = self.sortAscending;
    self.articleListController.feedsAndFolders = self.feeds;
    [self.articleListController updateArticles:currentArticles]; //make sure current selection is included
    NSArray *updatedArticles = [self groupedArticles:self.articleListController.articles];
    
    if (RSIsEmpty(currentArticles)) {
        self.articles = updatedArticles;
        return;
    }
    
    /*Must avoid setter, because KVO triggers some unwanted behavior. Would be nice to make this better.*/
    articles = updatedArticles;
    NSArray *oneSelectedArticle = [currentArticles objectAtIndex:0];
    NSUInteger row = [articles indexOfObjectIdenticalTo:oneSelectedArticle];
    [self.articleListScrollView reloadDataWithoutResettingSelectedRowIndexes];
    [self.articleListScrollView selectRow:row scrollToVisibleIfNeeded:YES];
}


#pragma mark -
#pragma mark WebUIDelegate

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
    NSURL *link = [elementInformation objectForKey:WebElementLinkURLKey];
    [self sendURLDidUpdateNotification:link ? [link absoluteString] : nil notificationName:NNWMouseOverURLDidUpdateNotification];
}


static NSString *urlStringFromElementDictionary(NSDictionary *dict) {
    id url = [dict objectForKey:@"WebElementLinkURL"];
    if (!url)
        return nil;    
    if ([url isKindOfClass:[NSURL class]])
        return [url absoluteString];
    if (![url isKindOfClass:[NSString class]])
        return nil;
    return url;
}


- (void)removeUnwantedWebKitDefaultCommandsFromItems:(NSMutableArray *)defaultMenuItems {
    
    if (RSIsEmpty(defaultMenuItems))
        return;
    
    NSInteger i = 0;
    NSInteger numberOfItems = (NSInteger)[defaultMenuItems count];
    for (i = numberOfItems - 1; i >= 0; i--) {
        NSMenuItem *oneMenuItem = [defaultMenuItems objectAtIndex:(NSUInteger)i];
        if ([oneMenuItem tag] == WebMenuItemTagReload)
            [defaultMenuItems removeObjectAtIndex:(NSUInteger)i];
    }
}


- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    
    /*We only care about links. Everything just use the default.*/
    
    NSMutableArray *filteredItems = [defaultMenuItems mutableCopy];
    [self removeUnwantedWebKitDefaultCommandsFromItems:filteredItems];
    
    NSString *link = urlStringFromElementDictionary(element);
    if (link == nil)
        return filteredItems;
    NSURL *aURL = [NSURL URLWithString:link];
    if (aURL == nil)
        return defaultMenuItems;

    NSMenu *browserContextualMenu = [[NSMenu alloc] initWithTitle:@"Browser Contextual Menu for Links"];
    [[self mainWindowController] addSharingPluginCommandsToMenu:browserContextualMenu withSharableItem:[RSSharableItem sharableItemWithURL:aURL]];
    
    NSArray *items = [[browserContextualMenu itemArray] copy];
    [browserContextualMenu removeAllItems];
    return items;
}


#pragma mark WebFrameLoadDelegate


- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
    //NSLog(@"didStartProvisionalLoadForFrame: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
    //NSLog(@"didReceiveServerRedirectForProvisionalLoadForFrame: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
    //NSLog(@"didCommitLoadForFrame: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"didReceiveIcon: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
    //NSLog(@"didFinishLoadForFrame: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"didFailProvisionalLoadWithError: %@ %@", [sender mainFrameURL], error);
}


- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"didReceiveTitle: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"didFailLoadWithError: %@ %@", [sender mainFrameURL], error);
}


- (void)webView:(WebView *)sender didChangeLocationWithinPageForFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"didChangeLocationWithinPageForFrame: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"willPerformClientRedirectToURL: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender didCancelClientRedirectForFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"didCancelClientRedirectForFrame: %@", [sender mainFrameURL]);
}


- (void)webView:(WebView *)sender willCloseFrame:(WebFrame *)frame {
    if (frame != [self.webView mainFrame])
        return;
//    NSLog(@"willCloseFrame: %@", [sender mainFrameURL]);
}


#pragma mark WebPolicyDelegate

//- (void)openURLInDefaultBrowser:(NSURL *)aURL {
//    id<RSSharableItem> sharableItem = [RSSharableItem sharableItemWithURL:aURL];
//    [NSApp sendAction:@selector(openInBrowserAccordingToPreferences:) to:nil from:sharableItem];
//}


- (void)openExternalURL:(NSURL *)aURL {
    if (aURL == nil)
        return;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"openLinksInBrowser"]) {
        id<RSSharableItem> sharableItem = [RSSharableItem sharableItemWithURL:aURL];
        [NSApp sendAction:@selector(openInBrowserAccordingToPreferences:) to:nil from:sharableItem];
    }
    else
        [self openURLInInternalBrowser:aURL];
}


- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    NSNumber *navTypeNumber = [actionInformation objectForKey:WebActionNavigationTypeKey];
    NSInteger navType = -1;
    
    if (navTypeNumber != nil)
        navType = [navTypeNumber integerValue];
    
    if ([[[[request URL] scheme] lowercaseString] isEqualToString:@"marsedit"]) {
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        return;
    }

    if (navType == WebNavigationTypeLinkClicked) {
        if ([rs_app_delegate systemShouldOpenURLString:[[request URL] absoluteString]]) {
            [[NSWorkspace sharedWorkspace] openURL:[request URL]];
            [listener ignore];
            return;
        }

        [self openExternalURL:[request URL]];
        [listener ignore];
    }    
    else
        [listener use];
}


#pragma mark -

#pragma mark NSSplitView Delegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    return view == [[splitView subviews] objectAtIndex:1];
}


static const CGFloat kMinimumArticleListWidth = 160.0f;

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0)
        return kMinimumArticleListWidth;
    return proposedMinimumPosition;
}


#pragma mark -
#pragma mark Events

- (void)makeArticleListFirstResponder {
    [[[self articleListScrollView] window] makeFirstResponder:[self.articleListScrollView documentView]];    
}


- (void)makeDetailViewFirstResponder {
//    if (self.detailTemporaryViewController != nil)
//        [[[self view] window] makeFirstResponder:self.detailTemporaryViewController];
//    else
//        [[[self view] window] makeFirstResponder:self.webView];
}


- (WebView *)currentWebView {
    if (self.detailTemporaryViewController != nil && self.detailTemporaryViewController == self.browserViewController)
        return self.browserViewController.webview;
    return self.webView;    
}


- (BOOL)webviewCanScroll {
    return [[self currentWebView] canScrollDown];
}


- (void)scrollWebviewDown {
    return [[self currentWebView] scrollDown];
}


- (BOOL)webviewCanScrollUp {
    return [[self currentWebView] canScrollUp];
}


- (void)scrollWebviewUp {
    return [[self currentWebView] scrollUp];    
}


- (void)openExternalURLForArticle:(RSDataArticle *)anArticle {
    NSString *bestLink = anArticle.bestLink;
    if (!RSStringIsEmpty(bestLink))
        [self openExternalURL:[NSURL URLWithString:bestLink]];
}


- (void)openExternalURLForSelectedArticle {
    [self openExternalURLForArticle:self.selectedArticle];
}



- (BOOL)didHandleKeyDown:(NSEvent *)event {
    
    /*Filtered -- before standard event handling.*/
    
    NSString *s = [event characters];
    if (RSStringIsEmpty(s))
        return NO;
    
    unichar ch = [s characterAtIndex: 0];
    BOOL shiftKeyDown = (([event modifierFlags] & NSShiftKeyMask) != 0);
    BOOL optionKeyDown = (([event modifierFlags] & NSAlternateKeyMask) != 0);
    BOOL commandKeyDown = (([event modifierFlags] & NSCommandKeyMask) != 0);
    BOOL controlKeyDown = (([event modifierFlags] & NSControlKeyMask) != 0);
    BOOL anyModifierKeyDown = shiftKeyDown || optionKeyDown || commandKeyDown || controlKeyDown;
    
    if (ch == ' ' && !anyModifierKeyDown) {
        [NSCursor setHiddenUntilMouseMoves:YES];
        if ([self webviewCanScroll]) {
            [self scrollWebviewDown];
            return YES;
        }
        if (self.currentWebViewIsDetailView) {
            [NSApp sendAction:@selector(nextUnread:) to:nil from:self];
            return YES;
        }
        return NO;
    }
    
    else if (ch == ' ' && shiftKeyDown && !optionKeyDown && !commandKeyDown && !controlKeyDown) {
        if ([self webviewCanScrollUp]) {
            [self scrollWebviewUp];
            [NSCursor setHiddenUntilMouseMoves:YES];
            return YES;
        }
    }
    
    else if (ch == NSLeftArrowFunctionKey && !anyModifierKeyDown) {
        if (self.rightPaneContainerView.hasPushedView) {
            [self.rightPaneContainerView popView];
            return YES;
        }
        return NO;
    }
    
    /*Back/forward in external browser view*/
    else if ((ch == NSLeftArrowFunctionKey || ch == '[') && commandKeyDown && !shiftKeyDown && !optionKeyDown && !controlKeyDown) {
        if (self.rightPaneContainerView.topView == [self.browserViewController view]) {
            [self.browserViewController goBack:self];
            return YES;
        }
        return NO;
    }
    else if ((ch == NSRightArrowFunctionKey || ch == ']') && commandKeyDown && !shiftKeyDown && !optionKeyDown && !controlKeyDown) {
        if (self.rightPaneContainerView.topView == [self.browserViewController view]) {
            [self.browserViewController goForward:self];
            return YES;
        }
        return NO;
    }
    
    /*Browser address field*/
    else if ((ch == 'l' || ch == 'L') && commandKeyDown && !shiftKeyDown && !optionKeyDown && !controlKeyDown) {
        if (self.currentWebViewIsDetailView)
            [self openURLInInternalBrowser:nil];
        [self.browserViewController makeAddressFieldFirstResponder];
        return YES;
    }
    
    else if (ch == '\'' && !anyModifierKeyDown) {
        [NSApp sendAction:@selector(nextUnread:) to:nil from:self];
        return YES;
    }
    return NO;
}


- (void)keyDown:(NSEvent *)event {
    
    NSString *s = [event characters];
    if (RSStringIsEmpty(s)) {
        [super keyDown:event];
        return;
    }

    unichar ch = [s characterAtIndex: 0];
    BOOL shiftKeyDown = (([event modifierFlags] & NSShiftKeyMask) != 0);
    BOOL optionKeyDown = (([event modifierFlags] & NSAlternateKeyMask) != 0);
    BOOL commandKeyDown = (([event modifierFlags] & NSCommandKeyMask) != 0);
    BOOL controlKeyDown = (([event modifierFlags] & NSControlKeyMask) != 0);
    BOOL anyModifierKeyDown = shiftKeyDown || optionKeyDown || commandKeyDown || controlKeyDown;

    if (anyModifierKeyDown) {
        [super keyDown:event];
        return;
    }

    switch (ch) {
        
        case NSRightArrowFunctionKey:
        case 3: /*keypad enter key*/
        case '\r':
        case '\n':
        case 'b':
        case 'B':
        case 'v':
        case 'V':
            [self openExternalURLForSelectedArticle];
            return;
        
        case NSLeftArrowFunctionKey:
            [self tryToPerform:@selector(moveFocusToSourceList:) with:nil];
            return;
            
        case 'm':
        case 'M':
            [self tryToPerform:@selector(toggleRead:) with:nil];
            return;
        
        case 'a':
        case 'A':
            [NSApp sendAction:@selector(addFeed:) to:nil from:self];
            return;
            
        default:
            break;
    }
    
    [super keyDown:event];
}


- (BOOL)articleHasLink:(RSDataArticle *)article {
    return article.link != nil || article.permalink != nil;    
}


- (BOOL)articleHasTitle:(RSDataArticle *)article {
    return article.plainTextTitle != nil;    
}


- (BOOL)articleCanMarkAsRead:(RSDataArticle *)article {
    return [article.read boolValue] == NO;
}


- (BOOL)articleCanMarkAsUnread:(RSDataArticle *)article {
    return [article.read boolValue] == YES;
}


- (void)openLinkWithArticle:(RSDataArticle *)article {
    NSString *urlString = article.bestLink;
    if (RSStringIsEmpty(urlString))
        return;
    NSURL *aURL = [NSURL URLWithString:urlString];
    if (aURL != nil)
        [NSApp sendAction:@selector(openExternalURL:) to:nil from:aURL];
}


- (NNWMainWindowController *)mainWindowController {
    return [[[self articleListScrollView] window] windowController];
}


- (void)openURLInDefaultBrowser:(NSURL *)aURL {
    [[self mainWindowController] openURLInDefaultBrowser:aURL];
}


- (void)openInDefaultBrowserWithArticle:(RSDataArticle *)article {
    NSString *URLString = article.bestLink;
    if (RSStringIsEmpty(URLString))
        return;
    NSURL *aURL = [NSURL URLWithString:URLString];
    [self openURLInDefaultBrowser:aURL];
}


- (void)markAsReadWithArticle:(RSDataArticle *)article {
    [article markAsRead:YES];
}


- (void)markAsUnreadWithArticle:(RSDataArticle *)article {
    [article markAsRead:NO];
}


- (void)copyURLWithArticle:(RSDataArticle *)article {
    NSString *URLString = article.permalink;
    if (RSStringIsEmpty(URLString))
        URLString = article.link;
    RSCopyURLStringToPasteboard(URLString, nil);
}


- (void)copyTitleWithArticle:(RSDataArticle *)article {
    RSCopyStringToPasteboard(article.plainTextTitle, nil);
}


#pragma mark Contextual Menus

- (void)openLinkWithContextualMenuArticle:(id)sender {
    [self openLinkWithArticle:self.contextualMenuArticle];
}


- (void)openInDefaultBrowserWithContextualMenuArticle:(id)sender {
    [self openInDefaultBrowserWithArticle:self.contextualMenuArticle];
}


- (void)markAsReadWithContextualMenuArticle:(id)sender {
    [self markAsReadWithArticle:self.contextualMenuArticle];
}


- (void)markAsUnreadWithContextualMenuArticle:(id)sender {
    [self markAsUnreadWithArticle:self.contextualMenuArticle];
}


- (void)copyURLWithContextualMenuArticle:(id)sender {
    [self copyURLWithArticle:self.contextualMenuArticle];
}


- (void)copyTitleWithContextualMenuArticle:(id)sender {
    [self copyTitleWithArticle:self.contextualMenuArticle];
}


- (void)addPluginCommandsToMenu:(NSMenu *)menu withArticle:(RSDataArticle *)article {
    [[self mainWindowController] addSharingPluginCommandsToMenu:menu withSharableItem:[RSSharableItem sharableItemWithArticle:article]];
}


- (NSMenu *)contextualMenuForArticle:(RSDataArticle *)article {
    
    self.contextualMenuArticle = article;
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Article Contextual Menu"];
    
    BOOL articleHasLink = [self articleHasLink:article];
    
    if (articleHasLink)
        [menu addItemWithTitle:NSLocalizedString(@"Open Link", @"Article Command") action:@selector(openLinkWithContextualMenuArticle:) keyEquivalent:@""];
    if (articleHasLink)
        [menu addItemWithTitle:NSLocalizedString(@"Open in Browser", @"Article Command") action:@selector(openInDefaultBrowserWithContextualMenuArticle:) keyEquivalent:@""];
    if ([menu numberOfItems] > 0)
        [menu addItem:[NSMenuItem separatorItem]];
    
    if ([self articleCanMarkAsRead:article])
        [menu addItemWithTitle:NSLocalizedString(@"Mark as Read", @"Article Command") action:@selector(markAsReadWithContextualMenuArticle:) keyEquivalent:@""];
    if ([self articleCanMarkAsUnread:article])
        [menu addItemWithTitle:NSLocalizedString(@"Mark as Unread", @"Article Command") action:@selector(markAsUnreadWithContextualMenuArticle:) keyEquivalent:@""];
        
    [menu rs_addSeparatorItemIfLastItemIsNotSeparator];
    
    if (articleHasLink)
        [menu addItemWithTitle:NSLocalizedString(@"Copy URL", @"Article Command") action:@selector(copyURLWithContextualMenuArticle:) keyEquivalent:@""];
    if ([self articleHasTitle:article])
        [menu addItemWithTitle:NSLocalizedString(@"Copy Title", @"Article Command") action:@selector(copyTitleWithContextualMenuArticle:) keyEquivalent:@""];
    
    [menu rs_addSeparatorItemIfLastItemIsNotSeparator];
    
    [self addPluginCommandsToMenu:menu withArticle:article];
    
    if ([menu rs_lastItemIsSeparatorItem]) {
        NSInteger numberOfMenuItems = [menu numberOfItems];
        [menu removeItemAtIndex:numberOfMenuItems - 1];
    }
    
    return menu;                                                
}


@end
