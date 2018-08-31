//
//  NNWMainWindowController.m
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "NNWMainWindowController.h"
#import "NNWAppDelegate.h"
#import "NNWArticleListDelegate.h"
#import "NNWRightPaneContainerView.h"
#import "NNWSourceListDelegate.h"
#import "NNWSourceListTreeBuilder.h"
#import "RSArticleListController.h"
#import "RSDataArticle.h"
#import "RSDataController.h"
#import "RSDownloadConstants.h"
#import "RSPluginManager.h"
#import "RSPluginObjects.h"
#import "RSPluginProtocols.h"



#define NNW_MARK_READ NSLocalizedString(@"Mark As Read", @"Menu command")
#define NNW_MARK_UNREAD NSLocalizedString(@"Mark As Unread", @"Menu command")


@interface NNWMainWindowController ()

@property (nonatomic, assign) NSUInteger unreadCount;
@property (nonatomic, strong) NSString *mouseOverURL;
@property (nonatomic, strong) NSString *selectedURL;
@property (nonatomic, strong) NSString *statusBarURL;
@property (nonatomic, strong) id<RSSharableItem> presentedSharableItem;
@property (nonatomic, strong, readwrite) NSString *toggleReadMenuItemTitle;
@property (nonatomic, strong) NSUndoManager *undoManager;

- (void)updateWindowTitle;
- (BOOL)validateSharingPluginCommand:(id<RSPluginCommand>)aPluginCommand withSharableItem:(id<RSSharableItem>)aSharableItem;

@end


@implementation NNWMainWindowController

@synthesize articleListDelegate;
@synthesize articleListScrollView;
@synthesize dataController;
@synthesize mouseOverURL;
@synthesize pluginManager;
@synthesize presentedSharableItem;
@synthesize selectedURL;
@synthesize sourceListDelegate;
@synthesize sourceListTreeBuilder;
@synthesize sourceListView;
@synthesize statusBarURL;
@synthesize toggleReadMenuItemTitle;
@synthesize unreadCount;
@synthesize rightPaneContainerView;
@synthesize currentWebView;
@synthesize undoManager;

#pragma mark Init

- (id)init {
    self = [self initWithWindowNibName:@"MainWindow"];
    if (self == nil)
        return nil;
    toggleReadMenuItemTitle = NNW_MARK_READ;
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"currentWebView"];
    [self.articleListDelegate removeObserver:self forKeyPath:@"currentWebView"];
}


#pragma mark NSWindowController

- (void)windowDidLoad {
    [[self window] setAllowsConcurrentViewDrawing:YES];
#ifdef LITE
    [[self window] setTitle:@"NetNewsWire Lite"];
#endif
    
    self.undoManager = [[NSUndoManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedURLDidChange:) name:NNWSelectedURLDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mouseOverURLDidChange:) name:NNWMouseOverURLDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentedSharableItemDidChange:) name:NNWPresentedSharableItemDidChangeNotification object:nil];
    
    [self.articleListDelegate addObserver:self forKeyPath:@"currentWebView" options:0 context:nil];
    self.currentWebView = articleListDelegate.currentWebView;
    [self addObserver:self forKeyPath:@"currentWebView" options:0 context:nil];
    
    ((NNWMainWindow *)[self window]).keyDownFilter = self;

    /*The source list delegate and article list delegate are responders and they get inserted in the chain.*/
    [self.sourceListDelegate setNextResponder:[[self.sourceListView enclosingScrollView] nextResponder]];
    [[self.sourceListView enclosingScrollView] setNextResponder:self.sourceListDelegate];
    [self.articleListDelegate setNextResponder:[self.articleListScrollView nextResponder]];
    [self.articleListScrollView setNextResponder:self.articleListDelegate];
    
    [self addObserver:self forKeyPath:@"unreadCount" options:0 context:nil];
    self.unreadCount = 0;
    [nnw_app_delegate addObserver:self forKeyPath:@"unreadCount" options:0 context:nil];
    
    [self updateWindowTitle];
}


- (void)updateWindowTitle {
#ifdef LITE
    NSString *baseTitle = @"NetNewsWire Lite - %d unread";
    NSString *baseTitleNoUnread = @"NetNewsWire Lite";
#else
    NSString *baseTitle = @"NetNewsWire - %d unread";
    NSString *baseTitleNoUnread = @"NetNewsWire";
#endif
    if (self.unreadCount < 1)
        [[self window] setTitle:baseTitleNoUnread];
    else
        [[self window] setTitle:[NSString stringWithFormat:baseTitle, self.unreadCount]];
}


#pragma mark NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:NNWMainWindowDidResizeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self window] forKey:NNWWindowKey]];
}



#pragma mark Notifications

- (void)updateStatusBar {
    if (!RSStringIsEmpty(self.mouseOverURL)) {
        self.statusBarURL = self.mouseOverURL;
        return;
    }
    if (self.articleListDelegate.currentWebViewIsDetailView)
        self.statusBarURL = (self.selectedURL == nil ? @"" : self.selectedURL);
    else
        self.statusBarURL = @"";
    
}
- (void)selectedURLDidChange:(NSNotification *)note {
    NSView *viewForURL = [[note userInfo] objectForKey:@"view"];
    if (![viewForURL isDescendantOf:[[self window] contentView]])
        return;
    NSString *urlString = [[note userInfo] objectForKey:RSURLKey];
    self.selectedURL = urlString ? urlString : @"";
    [self updateStatusBar];
//    if (RSStringIsEmpty(self.mouseOverURL))
//        self.statusBarURL = self.selectedURL;
}


- (void)mouseOverURLDidChange:(NSNotification *)note {
    NSView *viewForURL = [[note userInfo] objectForKey:@"view"];
    if (![viewForURL isDescendantOf:[[self window] contentView]])
        return;
    NSString *urlString = [[note userInfo] objectForKey:RSURLKey];
    self.mouseOverURL = urlString ? urlString : @"";
    [self updateStatusBar];
//    if (!RSStringIsEmpty(self.mouseOverURL))
//        self.statusBarURL = self.mouseOverURL;
//    else
//        self.statusBarURL = self.selectedURL;
}


- (void)presentedSharableItemDidChange:(NSNotification *)note {
    self.presentedSharableItem = [[note userInfo] objectForKey:NNWSharableItemKey];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"unreadCount"]) {
        if (object == self)
            [self updateWindowTitle];
        else            
            self.unreadCount = nnw_app_delegate.unreadCount;
    }
    if ([keyPath isEqualToString:@"currentWebView"] && object == self.articleListDelegate) {
        if (self.articleListDelegate.currentWebView != self.currentWebView)
            self.currentWebView = self.articleListDelegate.currentWebView;
    }
    else if ([keyPath isEqualToString:@"currentWebView"] && object == self)
        [self updateStatusBar];
}


#pragma mark -
#pragma mark Actions

#pragma mark Sharing Plugins

static const char *kNNWSharableItemKey = "sharableItem"; //using associated objects: these keys are added to the menu item
static const char *kNNWPluginCommandKey = "pluginCommand";

- (id<RSPluginCommand>)pluginCommandForUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    
    /*First check for associated-object. (Menu items should have these.)
     
     If the item can have a representedObject, then it should be the plugin command.
     (True in the case of menu items.) But not all items have representedObject, so we should
     have made its tag the index into the sharing commands array.
     
     Each command also has a unique identifier, which we use in the case of toolbar items.*/
    
    id<RSPluginCommand>pluginCommand = [self.pluginManager associatedPluginCommandForMenuItem:anItem];
    if (pluginCommand != nil)
        return pluginCommand;
    
    if ([(id)anItem respondsToSelector:@selector(representedObject)])
        pluginCommand = (id<RSPluginCommand>)[(NSMenuItem *)anItem representedObject];
    
    if ([(id)anItem respondsToSelector:@selector(itemIdentifier)])
        pluginCommand = [self.pluginManager pluginCommandWithCommandID:((NSToolbarItem *)(anItem)).itemIdentifier];
    
    if (pluginCommand == nil) {
        NSInteger itemTag = [anItem tag];
        pluginCommand = [self.pluginManager.sharingCommands rs_safeObjectAtIndex:(NSUInteger)itemTag];
    }
    return pluginCommand;
}


- (void)performSharingPluginCommand:(id<RSPluginCommand>)aPluginCommand withSharableItem:(id<RSSharableItem>)sharableItem {
    NSMutableArray *sharableItems = [NSMutableArray array];
    [sharableItems rs_safeAddObject:sharableItem];
    NSError *error = nil;
    [self.pluginManager runPluginCommand:aPluginCommand withItems:sharableItems sendingViewController:nil sendingView:nil sendingControl:nil barButtonItem:nil event:[NSApp currentEvent] error:&error];
    
}


- (void)performSharingPluginCommandWithSender:(id)sender withSharableItem:(id<RSSharableItem>)sharableItem {
    id<RSPluginCommand> pluginCommand = [self pluginCommandForUserInterfaceItem:sender];
    if (pluginCommand == nil)
        return;
    [self performSharingPluginCommand:pluginCommand withSharableItem:sharableItem];
}


- (void)performSharingPluginCommandWithSender:(id)sender {
    [self performSharingPluginCommandWithSender:(id)sender withSharableItem:self.presentedSharableItem];
}


- (void)performSharingPluginCommandWithAssociatedObject:(id)sender {
    id<RSPluginCommand> pluginCommand = [[RSPluginManager sharedManager] associatedPluginCommandForMenuItem:sender];
    id<RSSharableItem> sharableItem = [[RSPluginManager sharedManager] associatedObjectForMenuItem:sender];
    if (pluginCommand == nil || sharableItem == nil)
        return;
    [self performSharingPluginCommand:pluginCommand withSharableItem:sharableItem];
}


- (void)addPluginCommandsInPlugin:(id<RSPlugin>)aPlugin toMenu:(NSMenu *)menu withSharableItem:(id<RSSharableItem>)sharableItem {
    
    NSUInteger numberOfCommandsAdded = 0;
    
    for (id<RSPluginCommand> oneCommand in aPlugin.allCommands) {
        if ([oneCommand isKindOfClass:NSClassFromString(@"NNWSharingCommandOpenInBrowser")])
            continue;
        if ([self validateSharingPluginCommand:oneCommand withSharableItem:sharableItem]) {
            numberOfCommandsAdded++;
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:oneCommand.title action:@selector(performSharingPluginCommandWithAssociatedObject:) keyEquivalent:@""];
            [menu addItem:menuItem];
            if ([oneCommand respondsToSelector:@selector(image)])
                [menuItem setImage:oneCommand.image];
            [[RSPluginManager sharedManager] associateMenuItem:menuItem withObject:sharableItem];
            [[RSPluginManager sharedManager] associateMenuItem:menuItem withPluginCommand:oneCommand];
//            objc_setAssociatedObject(menuItem, (void *)kNNWSharableItemKey, sharableItem, OBJC_ASSOCIATION_RETAIN);
//            objc_setAssociatedObject(menuItem, (void *)kNNWPluginCommandKey, oneCommand, OBJC_ASSOCIATION_RETAIN);
        }
    }

    if (numberOfCommandsAdded > 1)
        [menu rs_addSeparatorItem];
}


- (void)addCommandsInPlugins:(NSArray *)somePlugins toMenu:(NSMenu *)menu withSharableItem:(id<RSSharableItem>)sharableItem {
    for (id<RSPlugin> onePlugin in somePlugins)
        [self addPluginCommandsInPlugin:onePlugin toMenu:menu withSharableItem:sharableItem];    
}


//- (void)addSoloPlugins:(NSArray *)somePlugins toMenu:(NSMenu *)menu withSharableItem:(id<RSSharableItem>)sharableItem {
//    for (id<RSPlugin> onePlugin in somePlugins)
//        [self addPluginCommandsInPlugin:onePlugin toMenu:menu withSharableItem:sharableItem];
//}
//
//
//- (void)addGroupedPlugins:(NSArray *)somePlugins toMenu:(NSMenu *)menu withSharableItem:(id<RSSharableItem>)sharableItem {
//    for (id<RSPlugin> onePlugin in somePlugins)
//        [self addPluginCommandsInPlugin:onePlugin toMenu:menu withSharableItem:sharableItem];
//}


- (void)addSharingPluginCommandsToMenu:(NSMenu *)menu withSharableItem:(id<RSSharableItem>)sharableItem {
    
    [self addCommandsInPlugins:[[RSPluginManager sharedManager] pluginsWithSoloCommandsOfType:RSPluginCommandTypeSharing] toMenu:menu withSharableItem:sharableItem];
    [menu rs_addSeparatorItemIfLastItemIsNotSeparator];
    [self addCommandsInPlugins:[[RSPluginManager sharedManager] pluginsWithGroupedCommandsOfType:RSPluginCommandTypeSharing] toMenu:menu withSharableItem:sharableItem];
    [menu rs_addSeparatorItemIfLastItemIsNotSeparator];

    [self addCommandsInPlugins:[[RSPluginManager sharedManager] pluginsWithSoloCommandsOfType:RSPluginCommandTypeOpenInViewer] toMenu:menu withSharableItem:sharableItem];
    [menu rs_addSeparatorItemIfLastItemIsNotSeparator];
    [self addCommandsInPlugins:[[RSPluginManager sharedManager] pluginsWithGroupedCommandsOfType:RSPluginCommandTypeOpenInViewer] toMenu:menu withSharableItem:sharableItem];
    [menu rs_addSeparatorItemIfLastItemIsNotSeparator];
}

                                                                   
#pragma mark Mark All As Read

- (BOOL)validateMarkAllAsRead {
    RSArticleListController *articleListController = self.dataController.currentListController;
    if (articleListController == nil)
        return NO;
    return articleListController.hasAnyUnreadItems;
}


- (void)markAllInArrayAsUnread:(NSArray *)someArticles {
    [self.undoManager beginUndoGrouping];
    [self.undoManager registerUndoWithTarget:self selector:@selector(markAllInArrayAsRead:) object:someArticles];
    [self.undoManager setActionName:NSLocalizedString(@"Mark All as Read", @"Undo action title")];
    NSMutableArray *changedArticles = [NSMutableArray array];
    for (RSDataArticle *oneArticle in someArticles) {
        if ([oneArticle.read boolValue] != NO) {
            oneArticle.read = [NSNumber numberWithBool:NO];
            [changedArticles addObject:oneArticle];
        }
    }
//        [oneArticle markAsRead:NO];
    [self.undoManager endUndoGrouping];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSMultipleArticlesDidChangeReadStatusNotification object:self userInfo:[NSDictionary dictionaryWithObject:changedArticles forKey:@"articles"]];
}


- (void)markAllInArrayAsRead:(NSArray *)someArticles {
    [self.undoManager beginUndoGrouping];
    [self.undoManager registerUndoWithTarget:self selector:@selector(markAllInArrayAsUnread:) object:someArticles];
    [self.undoManager setActionName:NSLocalizedString(@"Mark All as Read", @"Undo action title")];
    NSMutableArray *changedArticles = [NSMutableArray array];
    for (RSDataArticle *oneArticle in someArticles) {
        if ([oneArticle.read boolValue] == NO) {
            oneArticle.read = [NSNumber numberWithBool:YES];
            [changedArticles addObject:oneArticle];
        }
    }
//        [oneArticle markAsRead:YES];
    [self.undoManager endUndoGrouping];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSMultipleArticlesDidChangeReadStatusNotification object:self userInfo:[NSDictionary dictionaryWithObject:changedArticles forKey:@"articles"]];
}


- (void)markAllAsRead:(id)sender {
    NSArray *articles = self.dataController.currentListController.articles;
    NSMutableArray *articlesThatShouldChangeReadStatus = [NSMutableArray array];
    for (RSDataArticle *oneArticle in articles) {
        if (![oneArticle.read boolValue])
            [articlesThatShouldChangeReadStatus addObject:oneArticle];
    }
    if (RSIsEmpty(articlesThatShouldChangeReadStatus))
        return;
    [self markAllInArrayAsRead:articlesThatShouldChangeReadStatus];
}


#pragma mark Mark Read/Unread

- (void)updateToggleReadMenuItemTitle {
    NSArray *selectedArticles = self.dataController.currentArticles;
    if (RSIsEmpty(selectedArticles)) {
        self.toggleReadMenuItemTitle = NNW_MARK_READ;
        return;
    }
    RSDataArticle *firstArticle = [selectedArticles objectAtIndex:0];
    if ([firstArticle.read boolValue] == NO)
        self.toggleReadMenuItemTitle = NNW_MARK_READ;
    else
        self.toggleReadMenuItemTitle = NNW_MARK_UNREAD;
}


- (BOOL)validateToggleRead {
    NSArray *selectedArticles = self.dataController.currentArticles;
    [self updateToggleReadMenuItemTitle];
    return !RSIsEmpty(selectedArticles);
}


- (void)toggleRead:(id)sender {
    NSArray *selectedArticles = self.dataController.currentArticles;
    if (RSIsEmpty(selectedArticles))
        return;
    RSDataArticle *firstArticle = [selectedArticles objectAtIndex:0];
    BOOL markAsRead = ([firstArticle.read boolValue] == NO); //if first is unread, we'll mark selected as read
    for (RSDataArticle *oneArticle in selectedArticles)
        [oneArticle markAsRead:markAsRead];
}


#pragma mark Next Unread


- (RSDataArticle *)selectedArticle {
    NSArray *selectedArticles = self.dataController.currentArticles;
    if (RSIsEmpty(selectedArticles))
        return nil;
    return [selectedArticles objectAtIndex:0];
}


- (BOOL)validateNextUnread {
    if (self.unreadCount < 1)
        return NO;
    if (self.unreadCount > 1)
        return YES;
    /*Special case: there's just one unread item, and it's selected.*/
    RSDataArticle *selectedArticle = [self selectedArticle];
    if (selectedArticle != nil && [selectedArticle.read boolValue] == NO)
        return NO;
    return YES;
}


- (RSDataArticle *)firstUnreadArticleInArray:(NSArray *)someArticles {
    for (RSDataArticle *oneArticle in someArticles) {
        if ([oneArticle.read boolValue] == NO)
            return oneArticle;
    }
    return nil;
}


- (RSDataArticle *)firstUnreadArticleAfterIndex:(NSUInteger)anIndex inArray:(NSArray *)someArticles {
    NSUInteger i = 0;
    NSUInteger numberOfArticles = [someArticles count];
    for (i = anIndex + 1; i < numberOfArticles; i++) {
        RSDataArticle *oneArticle = [someArticles objectAtIndex:i];
        if ([oneArticle.read boolValue] == NO)
            return oneArticle;
    }
    return nil;
}


- (RSDataArticle *)unreadArticleAfterArticle:(RSDataArticle *)anArticle inArray:(NSArray *)someArticles {
    if (RSIsEmpty(someArticles))
        return nil;
    NSUInteger indexOfArticle = NSNotFound;
    if (anArticle != nil)
        indexOfArticle = [someArticles indexOfObjectIdenticalTo:anArticle];
    if (indexOfArticle == NSNotFound)
        return [self firstUnreadArticleInArray:someArticles];
    return [self firstUnreadArticleAfterIndex:indexOfArticle inArray:someArticles];
}


- (void)nextUnread:(id)sender {
    
    RSDataArticle *selectedArticle = [self selectedArticle];
    NSArray *articles = self.dataController.currentListController.articles;

    RSDataArticle *nextUnreadArticleInSameList = [self unreadArticleAfterArticle:selectedArticle inArray:articles];
    if (nextUnreadArticleInSameList != nil) {
        [self.articleListDelegate navigateToArticleInCurrentList:nextUnreadArticleInSameList];
        [[self window] makeFirstResponder:self.articleListScrollView];
        return;
    }
        
    /*Next unread is in another feed, or above the current location in this list. Try another feed next.*/
    
    /*First need to make sure all unread counts are absolutely correct.*/
    
    [self.dataController updateAllUnreadCountsOnMainThread];
    RSTreeNode *nextTreeNodeWithUnreadItems = [self.sourceListTreeBuilder treeNodeWithCountForDisplayAfter:self.sourceListDelegate.currentTreeNode];
    if (nextTreeNodeWithUnreadItems == nil)
        nextTreeNodeWithUnreadItems = [[NNWSourceListTreeBuilder sharedTreeBuilder] firstTreeNodeWithCountForDisplay]; /*may wrap around to current feed*/
    
    [self.sourceListDelegate selectTreeNode:nextTreeNodeWithUnreadItems];
    [self.articleListDelegate navigateToFirstUnreadArticle];
    [[self window] makeFirstResponder:self.articleListScrollView];
}



#pragma mark Focus - Navigation

- (void)moveFocusToArticleListAndSelectTopRowIfNeeded:(id)sender {
    [self.articleListScrollView selectTopRowIfNoneSelected];    
    [[self window] makeFirstResponder:[self.articleListScrollView documentView]];
}


- (void)moveFocusToSourceList:(id)sender {
    [[self window] makeFirstResponder:self.sourceListView];
}


#pragma mark NSValidatedUserInterfaceItem

- (BOOL)validateSharingPluginCommand:(id<RSPluginCommand>)aPluginCommand withSharableItem:(id<RSSharableItem>)aSharableItem {
    NSMutableArray *sharableItems = [NSMutableArray array];
    [sharableItems rs_safeAddObject:aSharableItem];
    return [self.pluginManager validateCommand:aPluginCommand withArray:sharableItems];
}


- (BOOL)validateSharingPluginCommandWithUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {    
    id<RSPluginCommand> pluginCommand = [self pluginCommandForUserInterfaceItem:anItem];
    if (pluginCommand == nil)
        return NO;
    return [self validateSharingPluginCommand:pluginCommand withSharableItem:self.presentedSharableItem];
}


- (BOOL)validateZoomToActualSize:(id)sender {
    return self.currentWebView != nil && [self.currentWebView canMakeTextStandardSize];
}


- (BOOL)validateZoomIn:(id)sender {
    return self.currentWebView != nil && [self.currentWebView canMakeTextLarger];
}


- (BOOL)validateZoomOut:(id)sender {
    return self.currentWebView != nil && [self.currentWebView canMakeTextSmaller];
}


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    if ([anItem action] == @selector(performSharingPluginCommandWithSender:))
        return [self validateSharingPluginCommandWithUserInterfaceItem:anItem];
    if ([anItem action] == @selector(markAllAsRead:))
        return [self validateMarkAllAsRead];
    if ([anItem action] == @selector(toggleRead:))
        return [self validateToggleRead];
    if ([anItem action] == @selector(nextUnread:))
        return [self validateNextUnread];
    if ([anItem action] == @selector(zoomToActualSize:))
        return [self validateZoomToActualSize:anItem];
    if ([anItem action] == @selector(zoomIn:))
        return [self validateZoomIn:anItem];
    if ([anItem action] == @selector(zoomOut:))
        return [self validateZoomOut:anItem];
    return YES;
}


#pragma mark Deleting Feeds and Folders

- (void)deleteSelectedFeedsAndFolders:(id)sender {
    /*Got here from toolbar*/
    [self.sourceListDelegate performSelector:@selector(delete:) withObject:sender];
}


#pragma mark WebView

- (void)zoomIn:(id)sender {
    [self.currentWebView makeTextLarger:sender];
}


- (void)zoomOut:(id)sender {
    [self.currentWebView makeTextSmaller:sender];
}


- (void)zoomToActualSize:(id)sender {
    [self.currentWebView makeTextStandardSize:sender];
}


#pragma mark Open in Browser

/*Sometimes we need to call this special-case plugin outside the normal plugin contexts.*/

- (void)openInBrowserAccordingToPreferences:(id<RSSharableItem>)sharableItem {
    id<RSPluginCommand> openInBrowserCommand = [self.pluginManager pluginCommandOfClass:NSClassFromString(@"NNWSharingCommandOpenInBrowser")];
    NSAssert(openInBrowserCommand != nil, @"openInBrowserCommand must not be nil");
    if ([self validateSharingPluginCommand:openInBrowserCommand withSharableItem:sharableItem])
        [self performSharingPluginCommand:openInBrowserCommand withSharableItem:sharableItem];
}


- (void)openURLInBrowserAccordingToPreferences:(NSURL *)aURL {
    [self openInBrowserAccordingToPreferences:[RSSharableItem sharableItemWithURL:aURL]];
}


- (void)openURLInDefaultBrowser:(NSURL *)aURL {
    [self openInBrowserAccordingToPreferences:[RSSharableItem sharableItemWithURL:aURL]];    
}


- (void)openExternalURL:(NSURL *)aURL {
    if (aURL == nil)
        return;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"openLinksInBrowser"]) {
        id<RSSharableItem> sharableItem = [RSSharableItem sharableItemWithURL:aURL];
        [NSApp sendAction:@selector(openInBrowserAccordingToPreferences:) to:nil from:sharableItem];
    }
    else
        [self.articleListDelegate openURLInInternalBrowser:aURL];
}


#pragma mark Key Down Filter

- (BOOL)didHandleKeyDown:(NSEvent *)event {

    NSString *s = [event characters];
    if (RSStringIsEmpty(s))
        return NO;    
    unichar ch = [s characterAtIndex:0];
    BOOL shiftKeyDown = (([event modifierFlags] & NSShiftKeyMask) != 0);
    BOOL optionKeyDown = (([event modifierFlags] & NSAlternateKeyMask) != 0);
    BOOL commandKeyDown = (([event modifierFlags] & NSCommandKeyMask) != 0);
    BOOL controlKeyDown = (([event modifierFlags] & NSControlKeyMask) != 0);
    BOOL anyModifierKeyDown = shiftKeyDown || optionKeyDown || commandKeyDown || controlKeyDown;
    
    if ([[self window] firstResponder] == [self window] && (ch == NSRightArrowFunctionKey || ch == '\t') && !anyModifierKeyDown) {
        [[self window] makeFirstResponder:self.sourceListView];
        return YES;
    }
    
    if (ch == ' ' || ch == NSLeftArrowFunctionKey || ch == NSRightArrowFunctionKey || ch == '[' || ch == ']' || ch == 'l' || ch == 'L' || ch == '\'')
        return [(id<NNWKeyDownFilter>)(self.articleListDelegate) didHandleKeyDown:event];
    
    return NO;
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    if (self.undoManager == nil)
        self.undoManager = [[NSUndoManager alloc] init];
    return self.undoManager;
}


@end



//@interface NNWUndoManager : NSUndoManager
//@end
//
//@implementation NNWUndoManager
//
//- (NSUInteger)levelsOfUndo {
//    return 5; //arbitrary: afraid of things getting impossible to undo
//}
//
//
//@end


#pragma mark -


@interface NNWMainWindow ()

//@property (nonatomic, retain, readwrite) NSUndoManager *undoManager;

@end


@implementation NNWMainWindow

@synthesize keyDownFilter;
//@synthesize undoManager;

#pragma mark Dealloc



#pragma mark Events

- (WebView *)currentWebView:(NSView *)currentView {
    if (![currentView isKindOfClass:[NSView class]])
        return nil;
    NSView *nomad = currentView;
    while (nomad != nil) {
        if ([nomad isKindOfClass:[WebView class]])
            return (WebView *)nomad;
        nomad = [nomad superview];
    }
    return nil;
}


- (BOOL)caretIsInWebViewTextArea:(NSView *)currentView {
    WebView *webview = [self currentWebView:currentView];
    if (!webview)
        return NO;
    DOMRange *domRange = [webview selectedDOMRange];
    if (!domRange)
        return NO;
    DOMNode *nomad = [domRange startContainer];
    while (nomad != nil) {
        if ([nomad respondsToSelector:@selector(isContentEditable)] && [(DOMHTMLElement *)nomad isContentEditable])
            return YES;
        nomad = [nomad parentNode];
    }
    return NO;
}


- (void)sendEvent:(NSEvent *)event {
    
    /*Capture certain keystrokes here that can't be handled the normal way.
     For instance, the space bar scrolls the current webview or goes
     to next unread.*/
    
    if ([event type] != NSKeyDown) {
        [super sendEvent:event];
        return;
    }

    /*Don't send the key to the filter if in an editable text field or text view --
     including in a webview.*/
    
    BOOL shouldCallFilter = YES;
    BOOL shouldCallSuper = YES;
    
    NSResponder *firstResponder = [self firstResponder];
    if (firstResponder != nil && [firstResponder isKindOfClass:[NSView class]]) {
        if ([firstResponder isKindOfClass:[NSTextView class]] && [(NSTextView *)firstResponder isEditable])
            shouldCallFilter = NO;
        if (shouldCallFilter && [self caretIsInWebViewTextArea:(NSView *)firstResponder])
            shouldCallFilter = NO;
        if (shouldCallFilter && [[firstResponder className] isEqualToString:@"NSViewAWT"]) /*Java*/
            shouldCallFilter = NO;
    }

    if (shouldCallFilter && self.keyDownFilter != nil && [self.keyDownFilter didHandleKeyDown:event])
        shouldCallSuper = NO;
    
    if (shouldCallSuper)
        [super sendEvent:event];
}


#pragma mark Close

- (BOOL)validatePerformClose:(id)sender {
    BOOL temporaryPushedViewIsShowing = ((NNWMainWindowController *)(self.windowController)).rightPaneContainerView.hasPushedView;
    if (temporaryPushedViewIsShowing && [sender respondsToSelector:@selector(setTitle:)])
        [sender setTitle:NSLocalizedString(@"Close Web Page", @"File menu item title")];
    else
        [sender setTitle:NSLocalizedString(@"Close Window", @"File menu item title")];
    return YES;
}


- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    if ([anItem action] == @selector(performClose:))
        return [self validatePerformClose:anItem];
    return [super validateUserInterfaceItem:anItem];
}


#pragma mark First Responder

- (BOOL)makeFirstResponder:(NSResponder *)aResponder {
    BOOL success = [super makeFirstResponder:aResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSMainResponderDidChangeNotification object:self userInfo:nil];
    return success;
}


#pragma mark Actions

- (void)performClose:(id)sender {
    BOOL temporaryPushedViewIsShowing = ((NNWMainWindowController *)(self.windowController)).rightPaneContainerView.hasPushedView;
    if (temporaryPushedViewIsShowing)
        [((NNWMainWindowController *)(self.windowController)).rightPaneContainerView popView];
    else
        [super performClose:sender];
}


//#pragma mark Undo
//
//- (NSUndoManager *)undoManager {
//    if (undoManager == nil)
//        self.undoManager = [[[NNWUndoManager alloc] init] autorelease];
//    return undoManager;
//}




@end

