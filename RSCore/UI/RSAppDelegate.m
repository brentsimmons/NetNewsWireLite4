//
//  RSAppDelegate.m
//  RSCoreTests
//
//  Created by Brent Simmons on 12/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSAppDelegate.h"


@interface RSAppDelegate ()

@property (nonatomic, assign) BOOL isFirstRun;
@property (nonatomic, assign) BOOL online;
@property (nonatomic, retain) RSOperationController *mainOperationController;
@property (nonatomic, retain, readwrite) RSPluginManager *pluginManager;
@property (nonatomic, retain) RSDataController *dataController;

- (void)setupDataController;
- (void)loadPlugins;

@end


@implementation RSAppDelegate


#pragma mark Awake From Nib

- (void)awakeFromNib {
	
	self.online = YES; //assume at first
	self.mainOperationController = [RSOperationController sharedController];
	[self setupDataController];
	[self loadPlugins];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetConnectionIsDown:) name:RSErrorNotConnectedToInternetNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetConnectionIsUp:) name:RSConnectedToInternetNotification object:nil];
}


#pragma mark Startup

- (void)setupDataController {
	self.dataController = [[[RSDataController alloc] initWithModelResourceName:RSCoreDataModelResourceName storeFileName:RSCoreDataStoreFileName] autorelease];	
}


- (void)loadPlugins {
	
	self.pluginManager = [[[RSPluginManager alloc] init] autorelease];
	
	NSArray *builtInSharingPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_Sharing"];
	[self.pluginManager registerPluginsWithClassNames:builtInSharingPluginClassNames];
	
	NSArray *builtInAddFeedsPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_AddFeeds"];
	[self.pluginManager registerPluginsWithClassNames:builtInAddFeedsPluginClassNames];
	
	NSArray *builtInFeedCommandsPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_FeedCommands"];
	[self.pluginManager registerPluginsWithClassNames:builtInFeedCommandsPluginClassNames];
	
	NSArray *builtInObserverClassNamesToRegister = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_Observers"];
	[self.pluginManager registerPluginsWithClassNames:builtInObserverClassNamesToRegister];
	
	[self.pluginManager loadUserPlugins];
}


#pragma mark Connection Status

- (void)handleNetConnectionIsDown:(NSNotification *)note {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(handleNetConnectionIsDown:) withObject:note waitUntilDone:NO];
		return;
	}
	self.online = NO;
}


- (void)handleNetConnectionIsUp:(NSNotification *)note {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(handleNetConnectionIsUp:) withObject:note waitUntilDone:NO];
		return;
	}
	self.online = YES;
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



@end
