//
//  nnw_AppDelegate.h
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright NewsGator Technologies, Inc. 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSAppDelegateProtocols.h"
#import "RSPluginProtocols.h"


@class NNWAddFeedWithURLWindowController;
@class NNWAddFolderWindowController;
@class NNWDockIconController;
@class NNWMainWindowController;
@class NNWRefreshController;
@class NNWSourceListTreeBuilder;
@class NNWStyleSheetController;
@class NNWSubscribeRequest;
@class RSContainerWithTableWindowController;
@class RSDataController;
@class RSFaviconController;
@class RSLocalAccountFeedMetadataCache;
@class RSOperationController;

@interface NNWAppDelegate : NSObject <RSAppDelegate, NSApplicationDelegate> {
@private
	NSMenu *articleMenu;
	NSMenu *shareMenu;
	NSUInteger unreadCount;
	NNWRefreshController *refreshController;
	RSDataController *dataController;
	NNWMainWindowController *mainWindowController;
	BOOL isFirstRun;
	RSOperationController *mainOperationController;
	BOOL online;
	RSPluginManager *pluginManager;
	NNWSourceListTreeBuilder *sourceListTreeBuilder;
	BOOL refreshInProgress;
	NNWStyleSheetController *styleSheetController;
	RSFaviconController *faviconController;
	RSLocalAccountFeedMetadataCache *localAccountFeedMetadataCache;
	RSContainerWithTableWindowController *addFeedsWindowController;
	NNWDockIconController *dockIconController;
	NSString *userAgent;
	NNWAddFeedWithURLWindowController *addFeedWindowController;
	NNWAddFolderWindowController *addFolderWindowController;
	id<RSSharableItem> presentedSharableItem;
	NSString *applicationNameForWebviewUserAgent;
	NSString *pathToCacheFolder;
	NSString *pathToDataFolder;
	BOOL runningModalSheet;
	NSTimer *periodicRefreshTimer;
	NSDate *lastRefreshDate;
	NSArray *sharingPluginsWithSoloCommands;
	NSArray *sharingPluginsWithGroupedCommands;
	NSArray *orderedSharingPluginCommands;
	BOOL appIsShuttingDown;
}


@property (nonatomic, retain) IBOutlet NSMenu *articleMenu;
@property (nonatomic, retain) IBOutlet NSMenu *shareMenu;
@property (nonatomic, retain) IBOutlet NSMenuItem *toggleReadMenuItem;

@property (nonatomic, assign, readonly) NSUInteger unreadCount;
@property (nonatomic, retain, readonly) NNWRefreshController *refreshController;
@property (nonatomic, retain, readonly) RSDataController *dataController;

@property (nonatomic, retain, readonly) NSArray *sharingPluginsWithSoloCommands;
@property (nonatomic, retain, readonly) NSArray *sharingPluginsWithGroupedCommands;
@property (nonatomic, retain, readonly) NSArray *orderedSharingPluginCommands;

@property (nonatomic, assign) BOOL runningModalSheet;

@property (nonatomic, assign, readonly) BOOL appIsShuttingDown;

/*RSAppDelegateProtocols*/

@property (nonatomic, retain, readonly) NSString *pathToCacheFolder;
@property (nonatomic, retain, readonly) NSString *pathToDataFolder;

- (void)addFeedWithSubscribeRequest:(NNWSubscribeRequest *)aSubscribeRequest;
- (void)showAlertSheetWithTitle:(NSString *)title andMessage:(NSString *)message;

- (void)addSharingCommandsToMenu:(NSMenu *)aMenu includeGroupTitles:(BOOL)includeGroupTitles includeKeyboardShortcuts:(BOOL)includeKeyboardShortcuts; //for toolbar share menu

- (void)handleSubscribeToFeedRequest:(NSString *)feedURLString;

@end
