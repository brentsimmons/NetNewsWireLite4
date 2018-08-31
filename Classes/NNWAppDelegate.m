//
//  nnw_AppDelegate.m
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright NewsGator Technologies, Inc. 2010 . All rights reserved.
//

#import "NNWAppDelegate.h"
#import "NNWAddFeedWithURLWindowController.h"
#import "NNWAddFolderWindowController.h"
#import "NNWDockIconController.h"
#import "NNWExportOPMLController.h"
#import "NNWImportOPMLController.h"
#import "NNWMainWindowController.h"
#import "NNWRefreshController.h"
#import "NNWSourceListDelegate.h"
#import "NNWSourceListTreeBuilder.h"
#import "NNWStyleSheetController.h"
#import "RSContainerWindowController.h"
#import "RSContainerWithTableWindowController.h"
#import "RSCrashReportWindowController.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSDataController.h"
#import "RSDateManager.h"
#import "RSDownloadConstants.h"
#import "RSDownloadOperation.h"
#import "RSFaviconController.h"
#import "RSFeed.h"
#import "RSFileUtilities.h"
#import "RSLocalAccountFeedMetadataCache.h"
#import "RSLocalImageURLProtocol.h"
#import "RSLocalStyleSheetProtocol.h"
#import "RSOperationController.h"
#import "RSPluginManager.h"
#import "RSPluginProtocols.h"


@interface NNWAppDelegate ()

@property (nonatomic, assign) BOOL isFirstRun;
@property (nonatomic, assign) BOOL online;
@property (nonatomic, assign) BOOL refreshInProgress;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;
@property (nonatomic, retain) NNWAddFeedWithURLWindowController *addFeedWindowController;
@property (nonatomic, retain) NNWAddFolderWindowController *addFolderWindowController;
@property (nonatomic, retain) NNWDockIconController *dockIconController;
@property (nonatomic, retain) NNWMainWindowController *mainWindowController;
@property (nonatomic, retain) NNWSourceListTreeBuilder *sourceListTreeBuilder;
@property (nonatomic, retain) NNWStyleSheetController *styleSheetController;
@property (nonatomic, retain) NSDate *lastRefreshDate;
@property (nonatomic, retain) NSTimer *periodicRefreshTimer;
@property (nonatomic, retain) RSContainerWithTableWindowController *addFeedsWindowController;
@property (nonatomic, retain) RSFaviconController *faviconController;
@property (nonatomic, retain) RSLocalAccountFeedMetadataCache *localAccountFeedMetadataCache;
@property (nonatomic, retain) RSOperationController *mainOperationController;
@property (nonatomic, retain) id<RSSharableItem> presentedSharableItem;
@property (nonatomic, retain, readwrite) NNWRefreshController *refreshController;
@property (nonatomic, retain, readwrite) NSArray *sharingPluginsWithGroupedCommands;
@property (nonatomic, retain, readwrite) NSArray *sharingPluginsWithSoloCommands;
@property (nonatomic, retain, readwrite) NSString *applicationNameForWebviewUserAgent;
@property (nonatomic, retain, readwrite) NSString *pathToCacheFolder;
@property (nonatomic, retain, readwrite) NSString *pathToDataFolder;
@property (nonatomic, retain, readwrite) NSString *pathToTemporaryCacheFolder;
@property (nonatomic, retain, readwrite) NSString *userAgent;
@property (nonatomic, retain, readwrite) RSDataController *dataController;
@property (nonatomic, retain, readwrite) RSPluginManager *pluginManager;
@property (nonatomic, assign, readwrite) BOOL appIsShuttingDown;

- (void)setupDataController;
- (void)loadPlugins;
- (void)addDefaultFeedsIfNeeded;
- (void)updateMenuWithPlugins;
- (void)addFeedWithURLString:(NSString *)urlString;
- (void)showReaderWindow:(id)sender;
- (void)runDefaultAggregatorSheetIfNeeded;
- (NSArray *)pluginsWithGroupedCommandsInArray:(NSArray *)somePlugins;
- (NSArray *)pluginsWithSoloCommandsInArray:(NSArray *)somePlugins;
	
@end


@implementation NNWAppDelegate

@synthesize addFeedWindowController;
@synthesize addFeedsWindowController;
@synthesize addFolderWindowController;
@synthesize appIsShuttingDown;
@synthesize applicationNameForWebviewUserAgent;
@synthesize articleMenu;
@synthesize dataController;
@synthesize dockIconController;
@synthesize faviconController;
@synthesize isFirstRun;
@synthesize lastRefreshDate;
@synthesize localAccountFeedMetadataCache;
@synthesize mainOperationController;
@synthesize mainWindowController;
@synthesize online;
@synthesize pathToCacheFolder;
@synthesize pathToDataFolder;
@synthesize pathToTemporaryCacheFolder;
@synthesize periodicRefreshTimer;
@synthesize pluginManager;
@synthesize presentedSharableItem;
@synthesize refreshController;
@synthesize refreshInProgress;
@synthesize runningModalSheet;
@synthesize shareMenu;
@synthesize sharingPluginsWithGroupedCommands;
@synthesize sharingPluginsWithSoloCommands;
@synthesize sourceListTreeBuilder;
@synthesize styleSheetController;
@synthesize toggleReadMenuItem;
@synthesize unreadCount;
@synthesize userAgent;

#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;

	NSString *baseCacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *cacheFolder = [baseCacheDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CacheFolderName"]];
	RSSureFolder(cacheFolder);
	pathToCacheFolder = [cacheFolder retain];
	
	NSString *baseAppSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *appSupportFolder = [baseAppSupportDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DataFolderName"]];
	RSSureFolder(appSupportFolder);
	pathToDataFolder = [appSupportFolder retain];

	(void)[RSDateManager sharedManager];
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[periodicRefreshTimer rs_invalidateIfValid];
	[periodicRefreshTimer release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.mainWindowController removeObserver:self forKeyPath:@"toggleReadMenuItemTitle"];
	[articleMenu release];
	[refreshController release];
	[dataController release];
	[mainWindowController release];
	[mainOperationController release];
	[pluginManager release];
	[sourceListTreeBuilder release];
	[styleSheetController release];
	[faviconController release];
	[localAccountFeedMetadataCache release];
	[addFeedsWindowController release];
	[dockIconController release];
	[userAgent release];
	[addFeedWindowController release];
	[addFolderWindowController release];
	[presentedSharableItem release];
	[applicationNameForWebviewUserAgent release];
	[pathToTemporaryCacheFolder release];
	[pathToCacheFolder release];
	[pathToDataFolder release];
	[lastRefreshDate release];
	[sharingPluginsWithSoloCommands release];
	[sharingPluginsWithGroupedCommands release];
	[super dealloc];
}


#pragma mark Awake From Nib

static NSString *NNWFirstRunDateKey = @"FirstRunDate";

- (void)awakeFromNib {
	
//#if BETA
//	NSDate *expirationDate = [NSDate dateWithString:@"2011-03-01 00:00:00 -0800"];
//	if ([expirationDate earlierDate:[NSDate date]] == expirationDate) {
//		[RSTimeBomb runTimeBombSheet];
//		return;
//	}
//#endif
		
	if ([[NSUserDefaults standardUserDefaults] objectForKey:NNWFirstRunDateKey] == nil) {
		self.isFirstRun = YES;
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NNWFirstRunDateKey];
	}
	
	self.unreadCount = 0;
	self.online = YES; //assume at first
	self.mainOperationController = [RSOperationController sharedController];
	self.mainOperationController.tracksOperations = NO;
	[self.mainOperationController.operationQueue setMaxConcurrentOperationCount:15];
	
	self.userAgent = [[NSString stringWithFormat:@"NetNewsWire/%@ (Mac OS X; http://netnewswireapp.com/mac/; gzip-happy)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] retain];		
	[RSDownloadOperation setDefaultUserAgent:self.userAgent];
	self.applicationNameForWebviewUserAgent = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"didSetWebKitPrefs"]) {
		[[WebPreferences standardPreferences] setStandardFontFamily:@"Georgia"];
		[[WebPreferences standardPreferences] setMinimumFontSize:9];
		[[WebPreferences standardPreferences] setFixedFontFamily:@"Menlo"];
		[[WebPreferences standardPreferences] setDefaultFixedFontSize:13];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didSetWebKitPrefs"];
	}
	[self setupDataController];
	[RSDataArticle deleteArticlesMarkedForDeletion:self.mainThreadManagedObjectContext];
	[self loadPlugins];
	self.styleSheetController = [NNWStyleSheetController sharedController];
	self.faviconController = [RSFaviconController sharedController];
	self.localAccountFeedMetadataCache = [RSLocalAccountFeedMetadataCache sharedCache];
	self.dockIconController = [NNWDockIconController sharedController];
	[NSURLProtocol registerClass:[RSFaviconURLProtocol class]];
	[RSFaviconURLProtocol mapScheme:@"rsfavicon" toImageFolderCache:[RSFaviconController sharedController].imageFolderCache];
	[NSURLProtocol registerClass:[RSLocalStyleSheetProtocol class]];
	
	self.sourceListTreeBuilder = [[[NNWSourceListTreeBuilder alloc] initWithDataController:self.dataController] autorelease];
	[self addDefaultFeedsIfNeeded];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetConnectionIsDown:) name:RSErrorNotConnectedToInternetNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetConnectionIsUp:) name:RSConnectedToInternetNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSessionDidBegin:) name:RSRefreshSessionDidBeginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSessionDidEnd:) name:RSRefreshSessionDidEndNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsAndFoldersDidReorganize:) name:NNWFeedsAndFoldersDidReorganizeNotification object:nil];
	if ([RSDiskSpaceChecker isDiskSpaceLow]) {
		[RSDiskSpaceChecker runDiskSpaceLowSheet];
		return;
	}
	
	self.refreshController = [[[NNWRefreshController alloc] init] autorelease];	
	[self performSelectorOnMainThread:@selector(refreshAll:) withObject:nil waitUntilDone:NO];

	self.mainWindowController = [[[NNWMainWindowController alloc] init] autorelease];
	[self.mainWindowController addObserver:self forKeyPath:@"toggleReadMenuItemTitle" options:0 context:nil];
	self.mainWindowController.pluginManager = self.pluginManager;
	self.mainWindowController.dataController = self.dataController;
	self.mainWindowController.sourceListTreeBuilder = self.sourceListTreeBuilder;
	
	[self.mainWindowController showWindow:self];
	
	[self runDefaultAggregatorSheetIfNeeded];
	
	self.periodicRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(doPeriodicRefreshIfNeeded:) userInfo:nil repeats:YES];
	
	if (!self.runningModalSheet)
		RSCheckForCrash();
}


#pragma mark Startup

- (void)setupDataController {
	self.dataController = [[[RSDataController alloc] initWithModelResourceName:RSCoreDataModelResourceName storeFileName:RSCoreDataStoreFileName] autorelease];
	[self.dataController addObserver:self forKeyPath:@"unreadCount" options:0 context:nil];
	self.unreadCount = self.dataController.unreadCount;
}


- (void)loadPlugins {
	
	self.pluginManager = [RSPluginManager sharedManager];
	
	NSArray *builtInSharingPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_Sharing"];
	[self.pluginManager registerPluginsWithClassNames:builtInSharingPluginClassNames];

	NSArray *builtInArticleViewerPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_OpenInViewer"];
	[self.pluginManager registerPluginsWithClassNames:builtInArticleViewerPluginClassNames];

	[self.pluginManager loadUserPlugins];

	NSArray *sharingPlugins = self.pluginManager.sharingPlugins;
	self.sharingPluginsWithGroupedCommands = [self pluginsWithGroupedCommandsInArray:sharingPlugins];
	self.sharingPluginsWithSoloCommands = [self pluginsWithSoloCommandsInArray:sharingPlugins];
	
	[self.pluginManager addPluginCommandsOfType:RSPluginCommandTypeOpenInViewer toMenu:self.articleMenu associatedObject:nil indentGroupedItems:NO];
	[self.pluginManager addPluginCommandsOfType:RSPluginCommandTypeSharing toMenu:self.shareMenu associatedObject:nil indentGroupedItems:NO];

	/*Open in Browser command needs cmd-B*/
	for (NSMenuItem *oneMenuItem in [self.articleMenu itemArray]) {
		id<RSPluginCommand> onePluginCommand = [self.pluginManager associatedPluginCommandForMenuItem:oneMenuItem];
		if (onePluginCommand == nil || ![onePluginCommand isKindOfClass:NSClassFromString(@"NNWSharingCommandOpenInBrowser")])
			continue;
		[oneMenuItem setKeyEquivalent:@"b"];
		[oneMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
	}
	
	/*Some items in share menu need shortcuts*/
	for (NSMenuItem *oneMenuItem in [self.shareMenu itemArray]) {
		id<RSPluginCommand> onePluginCommand = [self.pluginManager associatedPluginCommandForMenuItem:oneMenuItem];
		if (onePluginCommand == nil)
			continue;
		if ([[onePluginCommand commandID] isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendViaEmail"]) {
			[oneMenuItem setKeyEquivalent:@"l"];
			[oneMenuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask]; 
		}
		if ([[onePluginCommand commandID] isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendToApp.MarsEdit"]) {
			[oneMenuItem setKeyEquivalent:@"p"];
			[oneMenuItem setKeyEquivalentModifierMask:NSShiftKeyMask | NSCommandKeyMask]; 
		}
		if ([[onePluginCommand commandID] isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendToApp.Twitter"]) {
			[oneMenuItem setKeyEquivalent:@"t"];
			[oneMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask]; 
		}
		if ([[onePluginCommand commandID] isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendToInstapaper"]) {
			[oneMenuItem setKeyEquivalent:@"p"];
			[oneMenuItem setKeyEquivalentModifierMask:NSControlKeyMask]; 
		}
	}
	
//	[self updateMenuWithPlugins];
}

			 
#pragma mark First Run / Default Feeds

static NSString *NNWDidAddDefaultFeedsKey = @"didAddDefaultFeeds";

- (void)addOneDefaultFeed:(NSDictionary *)feedDictionary {
	RSFeed *feed = [RSFeed feedWithURL:[NSURL URLWithString:[feedDictionary objectForKey:@"rss"]] account:[RSDataAccount localAccount]];
	feed.homePageURL = [NSURL URLWithString:[feedDictionary objectForKey:@"home"]];
	feed.userSpecifiedName = [feedDictionary objectForKey:@"name"];
	NSString *faviconURLString = [feedDictionary objectForKey:@"favicon"];
	if (!RSStringIsEmpty(faviconURLString))
		feed.faviconURL = [NSURL URLWithString:faviconURLString];
	[[RSDataAccount localAccount] addFeed:feed];
}


- (void)addDefaultFeeds {
	NSArray *defaultFeeds = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultFeeds" ofType:@"plist"]];
	if (RSIsEmpty(defaultFeeds))
		return;
	for (NSDictionary *oneFeedDictionary in defaultFeeds)
		[self addOneDefaultFeed:oneFeedDictionary];
	[RSDataAccount localAccount].needsToBeSavedOnDisk = YES;
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NNWDidAddDefaultFeedsKey];
}


- (void)addDefaultFeedsIfNeeded {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:NNWDidAddDefaultFeedsKey])
		return;
	if (!self.isFirstRun)
		return;
//	id obj = [[NSUserDefaults standardUserDefaults] objectForKey:NNWFirstRunDateKey];
//	if (obj != nil)
//		return;
//	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NNWFirstRunDateKey];
	[self addDefaultFeeds];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"unreadCount"])
		self.unreadCount = self.dataController.unreadCount;
	else if ([keyPath isEqualToString:@"toggleReadMenuItemTitle"])
		[self.toggleReadMenuItem setTitle:self.mainWindowController.toggleReadMenuItemTitle];
}


#pragma mark Menus

- (BOOL)sharingCommandShouldAppearInShareMenu:(id<RSPluginCommand>)aPluginCommand {
	
	/*Special-case sharing commands should not appear in Share menu. They appear elsewhere.*/
	
	NSArray *classNamesOfSpecialCasePlugins = [NSArray arrayWithObjects:@"NNWSharingCommandOpenInBrowser", nil];
	return ![classNamesOfSpecialCasePlugins containsObject:[(id)aPluginCommand className]];
}


- (NSArray *)pluginsWithGroupedCommandsInArray:(NSArray *)somePlugins {
	NSMutableArray *pluginsWithGroupedCommands = [NSMutableArray array];
	for (id<RSPlugin> onePlugin in somePlugins) {
		if ([onePlugin respondsToSelector:@selector(commandsShouldBeGrouped)] && onePlugin.commandsShouldBeGrouped)
			[pluginsWithGroupedCommands addObject:onePlugin];
	}
	return pluginsWithGroupedCommands;
}


- (NSArray *)pluginsWithSoloCommandsInArray:(NSArray *)somePlugins {
	NSMutableArray *pluginsWithSoloCommands = [NSMutableArray array];
	for (id<RSPlugin> onePlugin in somePlugins) {
		if (![onePlugin respondsToSelector:@selector(commandsShouldBeGrouped)] || !onePlugin.commandsShouldBeGrouped)
			[pluginsWithSoloCommands addObject:onePlugin];
	}
	return pluginsWithSoloCommands;
}


- (NSMenuItem *)addSharingCommand:(id<RSPluginCommand>)pluginCommand toMenu:(NSMenu *)aMenu keyEquivalent:(NSString *)keyEquivalent indentationLevel:(NSInteger)indentationLevel includeKeyboardShortcuts:(BOOL)includeKeyboardShortcuts {
	if (keyEquivalent == nil)
		keyEquivalent = @"";

	
	NSString *title = pluginCommand.title;
	if (indentationLevel > 0 && [pluginCommand respondsToSelector:@selector(shortTitle)]) {
		title = pluginCommand.shortTitle;
		if (RSStringIsEmpty(title))
			title = pluginCommand.title;
	}
		
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:title action:@selector(performSharingPluginCommandWithSender:) keyEquivalent:keyEquivalent] autorelease];
	[menuItem setRepresentedObject:pluginCommand];
	if ([pluginCommand respondsToSelector:@selector(image)])
		[menuItem setImage:pluginCommand.image];
	//[menuItem setIndentationLevel:indentationLevel];
	[aMenu addItem:menuItem];

	if (includeKeyboardShortcuts) {
		/*Special case keyboard shortcuts for stuff from 3.x.*/
		if ([pluginCommand.commandID isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendToApp.MarsEdit"]) {
			[menuItem setKeyEquivalent:@"p"];
			[menuItem setKeyEquivalentModifierMask:NSShiftKeyMask | NSCommandKeyMask];
		}
		if ([pluginCommand.commandID isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendToApp.Twitterrific"]) {
			[menuItem setKeyEquivalent:@"t"];
			[menuItem setKeyEquivalentModifierMask:NSControlKeyMask];
		}
		if ([pluginCommand.commandID isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendToApp.Twitter"]) {
			[menuItem setKeyEquivalent:@"t"];
			[menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		}
		if ([pluginCommand.commandID isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendToInstapaper"]) {
			[menuItem setKeyEquivalent:@"p"];
			[menuItem setKeyEquivalentModifierMask:NSControlKeyMask];
		}
		if ([pluginCommand.commandID isEqualToString:@"com.ranchero.NetNewsWire.plugin.sharing.SendViaEmail"]) {
			[menuItem setKeyEquivalent:@"l"];
			[menuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
		}
	}
	
	return menuItem;
}


- (void)addPluginsWithSoloCommands:(NSArray *)somePlugins toMenu:(NSMenu *)aMenu includeKeyboardShortcuts:(BOOL)includeKeyboardShortcuts {
	for (id<RSPlugin> onePlugin in somePlugins) {
		for (id<RSPluginCommand> onePluginCommand in [self.pluginManager sharingCommandsInPlugin:onePlugin]) {
			if ([self sharingCommandShouldAppearInShareMenu:onePluginCommand])
				(void)[self addSharingCommand:onePluginCommand toMenu:aMenu keyEquivalent:nil indentationLevel:0 includeKeyboardShortcuts:includeKeyboardShortcuts];
		}
	}
}


- (void)addPluginsWithGroupedCommands:(NSArray *)somePlugins toMenu:(NSMenu *)aMenu includeGroupTitles:(BOOL)includeGroupTitles includeKeyboardShortcuts:(BOOL)includeKeyboardShortcuts {
	
	for (id<RSPlugin> onePlugin in somePlugins) {
		
		NSString *groupTitle = nil;
		BOOL hasGroupTitle = NO;
		if ([onePlugin respondsToSelector:@selector(titleForGroup)])
			groupTitle = onePlugin.titleForGroup;
		if (!RSStringIsEmpty(groupTitle))
			hasGroupTitle = YES;
		NSInteger indentationLevel = 0;
		
		if ([aMenu numberOfItems] > 0)
			[aMenu addItem:[NSMenuItem separatorItem]];
		if (hasGroupTitle && includeGroupTitles) {
			[aMenu addItemWithTitle:groupTitle action:nil keyEquivalent:@""];
			indentationLevel = 1;
		}
		
		for (id<RSPluginCommand> onePluginCommand in [self.pluginManager sharingCommandsInPlugin:onePlugin]) {
			if ([self sharingCommandShouldAppearInShareMenu:onePluginCommand])
				(void)[self addSharingCommand:onePluginCommand toMenu:aMenu keyEquivalent:nil indentationLevel:indentationLevel includeKeyboardShortcuts:includeKeyboardShortcuts];
		}
	}	
}


- (void)addSharingCommandsInPlugins:(NSArray *)somePlugins toArray:(NSMutableArray *)anArray {
	for (id<RSPlugin> onePlugin in somePlugins) {
		for (id<RSPluginCommand> onePluginCommand in [self.pluginManager sharingCommandsInPlugin:onePlugin]) {
			if ([self sharingCommandShouldAppearInShareMenu:onePluginCommand])
				[anArray addObject:onePluginCommand];
		}
	}	
}


- (void)addSharingCommandsToMenu:(NSMenu *)aMenu includeGroupTitles:(BOOL)includeGroupTitles includeKeyboardShortcuts:(BOOL)includeKeyboardShortcuts {
	NSArray *sharingPlugins = self.pluginManager.sharingPlugins;
	if (RSIsEmpty(sharingPlugins))
		return;
	[self addPluginsWithSoloCommands:self.sharingPluginsWithSoloCommands toMenu:aMenu includeKeyboardShortcuts:includeKeyboardShortcuts];
	[self addPluginsWithGroupedCommands:self.sharingPluginsWithGroupedCommands toMenu:aMenu includeGroupTitles:includeGroupTitles includeKeyboardShortcuts:includeKeyboardShortcuts];
}


- (void)addCommandsToShareMenu {
	[self addSharingCommandsToMenu:self.shareMenu includeGroupTitles:NO includeKeyboardShortcuts:YES];
}


- (NSArray *)orderedSharingPluginCommands {
	/*All sharing commands that should appear in Share menu. Ungrouped, as a flat list.*/
	if (orderedSharingPluginCommands != nil)
		return orderedSharingPluginCommands;
	NSMutableArray *tempArray = [NSMutableArray array];
	[self addSharingCommandsInPlugins:self.sharingPluginsWithSoloCommands toArray:tempArray];
	[self addSharingCommandsInPlugins:self.sharingPluginsWithGroupedCommands toArray:tempArray];
	orderedSharingPluginCommands = [tempArray retain];
	return orderedSharingPluginCommands;
}


- (void)updateMenuWithPlugins {
	
	/*Open in Browser is special-case sharing plugin. It goes in the Article menu.*/
	
	id<RSPluginCommand> openInBrowserCommand = [self.pluginManager pluginCommandOfClass:NSClassFromString(@"NNWSharingCommandOpenInBrowser")];
	NSMenuItem *openInBrowserMenuItem = [[[NSMenuItem alloc] initWithTitle:openInBrowserCommand.title action:@selector(performSharingPluginCommandWithSender:) keyEquivalent:@"b"] autorelease];
	[openInBrowserMenuItem setRepresentedObject:openInBrowserCommand];
	[self.articleMenu addItem:openInBrowserMenuItem];
	
	[self addCommandsToShareMenu];
}


#pragma mark Connection Status

- (void)handleNetConnectionIsDown:(NSNotification *)note {
	self.online = NO;
}


- (void)handleNetConnectionIsUp:(NSNotification *)note {
	self.online = YES;
}


#pragma mark Refresh Status

- (void)refreshSessionDidBegin:(NSNotification *)note {
	self.refreshInProgress = YES;
}


- (void)refreshSessionDidEnd:(NSNotification *)note {
	self.refreshInProgress = NO;
	self.lastRefreshDate = [NSDate date];
}


#pragma mark Notifications

- (void)feedsAndFoldersDidReorganize:(NSNotification *)note {
	[self.dataController markAllUnreadCountsAsInvalid];
}


#pragma mark Periodic Refresh Timer

- (void)doPeriodicRefreshIfNeeded:(NSTimer *)aTimer {
	if (self.refreshInProgress || self.lastRefreshDate == nil)
		return;
	NSInteger refreshInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"refreshFeedsInterval"];
	if (refreshInterval < 10)
		return;
	NSTimeInterval secondsBetweenRefreshes = refreshInterval * 60;
	NSDate *dateOfNextRefresh = [self.lastRefreshDate dateByAddingTimeInterval:secondsBetweenRefreshes];
	if ([dateOfNextRefresh earlierDate:[NSDate date]] == dateOfNextRefresh)
		[self performSelectorOnMainThread:@selector(refreshAll:) withObject:nil waitUntilDone:NO];
}


#pragma mark Core Data - RSAppDelegate

- (void)addCoreDataBackgroundOperation:(NSOperation *)coreDataBackgroundOperation {
	[self.dataController addCoreDataBackgroundOperation:coreDataBackgroundOperation];
}


- (NSManagedObjectContext *)mainThreadManagedObjectContext {
	return self.dataController.mainThreadManagedObjectContext;
}


- (NSManagedObjectContext *)temporaryManagedObjectContext {
	return [self.dataController temporaryManagedObjectContext];
}


- (void)saveManagedObjectContext:(NSManagedObjectContext *)moc {
	[self.dataController saveManagedObjectContext:moc];
}


#pragma mark Observer Plugins - RSAppDelegate

- (void)makeAppObserversPerformSelector:(SEL)aSelector withObject:(id)anObject {
	[self.pluginManager makePlugins:self.pluginManager.appObserverPlugins performSelector:aSelector withObject:anObject];
}


- (void)makeAppObserversPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
	[self.pluginManager makePlugins:self.pluginManager.appObserverPlugins performSelector:aSelector withObject:object1 withObject:object2];
}


#pragma mark Sheets

- (void)runModalSheet:(NSWindow *)aSheet {
	self.runningModalSheet = YES;
	[NSApp beginSheet:aSheet modalForWindow:[self.mainWindowController window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:aSheet];
	[NSApp endSheet:aSheet];
	[aSheet orderOut:self];	
	self.runningModalSheet = NO;
}



- (void)showAlertSheetWithTitle:(NSString *)title andMessage:(NSString *)message {	
	NSBeginAlertSheet(title, NNW_OK, nil, nil, self.mainWindowController.window, self, nil, nil, nil, message);
}


#pragma mark URLs

static BOOL RSSystemShouldAlwaysHandleURLScheme(NSString *aURLScheme) {
	if (RSIsEmpty(aURLScheme))
		return NO;
	NSString *lowerURLScheme = [aURLScheme lowercaseString];
	if ([lowerURLScheme isEqualToString:@"http"] || [lowerURLScheme isEqualToString:@"https"] || [lowerURLScheme isEqualToString:@"file"] || [lowerURLScheme isEqualToString:@"about"] || [lowerURLScheme isEqualToString:@"applewebdata"] || [lowerURLScheme isEqualToString:@"javascript"])
		return NO;		
	return YES;	
}


static BOOL RSSystemShouldAlwaysHandleHost(NSString *host) {
	return host != nil && ([host caseInsensitiveCompare:@"phobos.apple.com"] == NSOrderedSame || [host caseInsensitiveCompare:@"itunes.apple.com"] == NSOrderedSame);
}


- (BOOL)systemShouldOpenURLString:(NSString *)aURLString {
	NSURL *aURL = [NSURL URLWithString:aURLString];
	if (aURL == nil)
		return NO;
	if (RSSystemShouldAlwaysHandleURLScheme([aURL scheme]))
		return YES;
	if (RSSystemShouldAlwaysHandleHost([aURL host]))
		return YES;
	return NO;
}


#pragma mark -
#pragma mark NSApplicationDelegate

//- (void)applicationDidBecomeActive:(NSNotification *)notification {
////	/*If URL on pasteboard, popup subscribe dialog.*/
////	NSString *urlString = RSURLStringOnClipboard(YES);
////	static NSString *previousURLString = nil;
////	if (previousURLString != nil && [previousURLString isEqualToString:urlString])
////		return;
////	if (!RSStringIsEmpty(urlString)) {
////		if ([self.dataController anyAccountIsSubscribedToFeedWithURL:[NSURL URLWithString:urlString]])
////			return;
////		[self addFeedWithURLString:urlString];
////		[previousURLString autorelease];
////		previousURLString = [urlString copy];
////	}
//}
//
//
//- (void)applicationDidFinishLaunching:(NSNotification *)notification {
////	/*If URL on pasteboard, popup subscribe dialog.*/
////	NSString *urlString = RSURLStringOnClipboard(YES);
////	if (!RSStringIsEmpty(urlString))
////		[self addFeedWithURLString:urlString];
//}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)app hasVisibleWindows:(BOOL)fl {	
	[self showReaderWindow:nil];
	return NO;
}


- (void)applicationWillResignActive:(NSNotification *)notification {
	[self saveManagedObjectContext:self.mainThreadManagedObjectContext];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	self.appIsShuttingDown = YES;
	[RSOperationController cancelAllOperations];
	[self.dataController cancelCoreDataBackgroundOperations];
	[self.dataController waitUntilCoreDataBackgroundOperationsAreFinished];
	[self.dataController saveAllAccounts];
	[self saveManagedObjectContext:self.mainThreadManagedObjectContext];
}
//
//
//- (void)applicationDidChangeScreenParameters:(NSNotification *)notification {
//	NSLog(@"applicationDidChangeScreenParameters: %@", notification);
//}



#pragma mark -
#pragma mark Add Feed with URL Sheet

- (void)addFeedWithURLString:(NSString *)urlString { //urlString may be nil
	if (self.runningModalSheet)
		return;
	self.addFeedWindowController = [[[NNWAddFeedWithURLWindowController alloc] initWithURLString:urlString] autorelease];
	[self runModalSheet:[self.addFeedWindowController window]];	
}


- (void)addFeedWithSubscribeRequest:(NNWSubscribeRequest *)aSubscribeRequest {
	if (self.runningModalSheet)
		return;
	self.addFeedWindowController = [[[NNWAddFeedWithURLWindowController alloc] initWithSubscribeRequest:aSubscribeRequest] autorelease];
	[self runModalSheet:[self.addFeedWindowController window]];		
}


#pragma mark -
#pragma mark Apple event - Subscribe to Feed

- (void)handleSubscribeToFeedRequest:(NSString *)feedURLString {
	[self showReaderWindow:nil];

	if ([self.dataController anyAccountIsSubscribedToFeedWithURL:[NSURL URLWithString:feedURLString]]) {
		; //TODO: reveal feed in source list
	}
	else
		[self addFeedWithURLString:feedURLString];
}


- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)reply {
	
	NSString *rawURLString = [[event descriptorForKeyword:keyDirectObject] stringValue];
	NSString *lowerRawURLString = [rawURLString lowercaseString];
	NSString *urlString = [[rawURLString copy] autorelease];
	
	if ([lowerRawURLString isEqualToString:@"feed:"])
		return;
	if ([rawURLString length] < 8)
		return;
	if ([lowerRawURLString hasPrefix:@"http"]) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:rawURLString]];
		return;
	}
	if ([lowerRawURLString hasPrefix:@"feed:"])
		urlString = [rawURLString substringFromIndex:5];
	if ([urlString hasPrefix:@"//"])
		urlString = [urlString substringFromIndex:2];
	if (![urlString rs_contains:@"//"])
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	
	[self performSelectorOnMainThread:@selector(handleSubscribeToFeedRequest:) withObject:urlString waitUntilDone:NO];
}


#pragma mark -
#pragma mark Default Aggregator

#define NNW_DEFAULT_AGGREGATOR_TITLE NSLocalizedString(@"Set NetNewsWire Lite as default feed reader?", @"Default aggregator title")
#define NNW_DEFAULT_AGGREGATOR_MESSAGE NSLocalizedString(@"When you click on a feed in your browser, it will send it to NetNewsWire so you can add it if you want to.", @"Default aggregator message")
#define NNW_DEFAULT_AGGREGATOR_BUTTON_OK NSLocalizedString(@"Set as Default", @"Default aggregator OK button")
#define NNW_DEFAULT_AGGREGATOR_BUTTON_DONT_SET NSLocalizedString(@"Don’t Set", @"Default aggregator Cancel button")

- (void)makeDefaultAggregator {
	LSSetDefaultHandlerForURLScheme(CFSTR("feed"), (CFStringRef)[[NSBundle mainBundle] bundleIdentifier]);
}


static NSString *NNWSuppressDefaultAggregatorPromptKey = @"suppressDefaultAggregatorPrompt";

- (void)defaultAggregatorAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	self.runningModalSheet = NO;
	[[NSUserDefaults standardUserDefaults] setBool:(BOOL)[[alert suppressionButton] integerValue] forKey:NNWSuppressDefaultAggregatorPromptKey];
	if (returnCode == NSAlertFirstButtonReturn)
		[self makeDefaultAggregator];
}


- (void)runDefaultAggregatorSheet {
	if (self.runningModalSheet || [[NSUserDefaults standardUserDefaults] boolForKey:NNWSuppressDefaultAggregatorPromptKey])
		return;
	self.runningModalSheet = YES;
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:NNW_DEFAULT_AGGREGATOR_TITLE];
	[alert setInformativeText:NNW_DEFAULT_AGGREGATOR_MESSAGE];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setShowsSuppressionButton:YES];
	[alert addButtonWithTitle:NNW_DEFAULT_AGGREGATOR_BUTTON_OK];
	[alert addButtonWithTitle:NNW_DEFAULT_AGGREGATOR_BUTTON_DONT_SET];
	[alert beginSheetModalForWindow:[self.mainWindowController window] modalDelegate:self didEndSelector:@selector(defaultAggregatorAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
	 

static BOOL anyVersionOfNetNewsWireIsDefaultAggregator(void) {
    CFURLRef appURL;
	LSGetApplicationForURL((__bridge CFURLRef)[NSURL URLWithString: @"feed:"], kLSRolesAll, nil, &appURL);
    NSURL *appURLARC = (__bridge_transfer NSURL *)appURL;
    if (appURLARC == nil)
		return NO;
    BOOL isDefault = [[appURLARC absoluteString] rs_caseInsensitiveContains:@"netnewswire"];

	return isDefault;
}


- (void)runDefaultAggregatorSheetIfNeeded {
	if (self.isFirstRun || anyVersionOfNetNewsWireIsDefaultAggregator())
		return;
	[self runDefaultAggregatorSheet];
}


#pragma mark Errors

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo {
	;
}


#pragma mark -
#pragma mark First Responder Actions

#pragma mark File Menu

- (void)addFeed:(id)sender {
	[self addFeedWithURLString:RSURLStringOnClipboard(YES)];

	
	//	if (self.addFeedsWindowController == nil) {
//		NSArray *builtInAddFeedsPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_AddFeeds"];
//		if (RSIsEmpty(builtInAddFeedsPluginClassNames)) {
//			NSLog(@"No add-feeds plugins. Can't load add-feeds window.");
//			return;
//		}
//		NSMutableArray *addFeedsPlugins = [NSMutableArray array];
//		for (NSString *onePluginClassName in builtInAddFeedsPluginClassNames)
//			[addFeedsPlugins addObject:[[[NSClassFromString(onePluginClassName) alloc] init] autorelease]];
//		self.addFeedsWindowController = [[RSContainerWithTableWindowController alloc] initWithPlugins:addFeedsPlugins windowNibName:@"AddFeedsContainerWindow"];
//	}
//	
//	[self.addFeedsWindowController showWindow:self];
}


- (void)addFolder:(id)sender {
	self.addFolderWindowController = [[[NNWAddFolderWindowController alloc] init] autorelease];
	[self runModalSheet:[self.addFolderWindowController window]];
}


- (void)refreshAll:(id)sender {
	[self.refreshController refreshAllInAccounts:[NSArray arrayWithObject:self.dataController.localAccount]];
}


- (void)chooseOPMLSheetDidEnd:(id)sender {
	NSArray *outlineItems = ((NNWImportOPMLController *)sender).outlineItems;
	if (RSIsEmpty(outlineItems))
		return;
	[[RSDataAccount localAccount] importOPMLOutlineItems:outlineItems];
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWOPMLImportDidSucceedNotification object:self userInfo:nil];
	[self refreshAll:self];
	
}


- (void)importFeeds:(id)sender {
	static NNWImportOPMLController *importOPMLController = nil;
	if (importOPMLController == nil)
		importOPMLController = [[NNWImportOPMLController alloc] init];
	importOPMLController.backgroundWindow = [self.mainWindowController window];
	[importOPMLController runChooseOPMLFileSheet:self callbackSelector:@selector(chooseOPMLSheetDidEnd:)];
}


- (void)exportFeeds:(id)sender {
	static NNWExportOPMLController *exportOPMLController = nil;
	if (exportOPMLController == nil)
		exportOPMLController = [[NNWExportOPMLController alloc] init];
	exportOPMLController.backgroundWindow = [self.mainWindowController window];
	[exportOPMLController exportOPML:[RSDataAccount localAccount]];
}


#pragma mark NetNewsWire Menu

- (void)openPreferencesWindow:(id)sender {
	
	static RSContainerWindowController *preferencesWindowController = nil;
	
	if (preferencesWindowController == nil) {
		NSArray *builtInPreferencesPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_Preferences"];
		if (RSIsEmpty(builtInPreferencesPluginClassNames)) {
			NSLog(@"No preferences plugins. Can't load preferences window.");
			return;
		}
		NSMutableArray *preferencesPlugins = [NSMutableArray array];
		for (NSString *onePluginClassName in builtInPreferencesPluginClassNames)
			[preferencesPlugins addObject:[[[NSClassFromString(onePluginClassName) alloc] init] autorelease]];
		preferencesWindowController = [[RSContainerWindowController alloc] initWithPlugins:preferencesPlugins];
	}
	
	[preferencesWindowController showWindow:self];
}


#pragma mark Go Menu

- (void)gotoAllUnread:(id)sender {
	[self showReaderWindow:self];
	[self.mainWindowController.sourceListDelegate selectRow:0];
	[[self.mainWindowController window] makeFirstResponder:self.mainWindowController.sourceListDelegate.sourceListOutlineView];
}


- (void)gotoToday:(id)sender {
	[self showReaderWindow:self];
	[self.mainWindowController.sourceListDelegate selectRow:1];
	[[self.mainWindowController window] makeFirstResponder:self.mainWindowController.sourceListDelegate.sourceListOutlineView];
}


#pragma mark Window Menu

- (void)showReaderWindow:(id)sender {
	[[self.mainWindowController window] makeKeyAndOrderFront:sender];
}


#pragma mark Help Menu

- (void)openAssociatedURL:(id)sender {
	NSParameterAssert([sender respondsToSelector:@selector(urlString)]);
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender valueForKey:@"urlString"]]];
}


#pragma mark Menu Validation

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(refreshAll:))
		return !self.refreshInProgress;
	return YES;
}


@end
