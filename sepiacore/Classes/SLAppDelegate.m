//
//  SLAppDelegate.m
//  nnwiphone
//
//  Created by Brent Simmons on 1/30/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "SLAppDelegate.h"
#import "SLAppIconController.h"
#import "SLDataController.h"
#import "SLOperationController.h"
#import "SLPluginManager.h"


@interface SLAppDelegate ()

@property (nonatomic, assign, readwrite) BOOL appIsShuttingDown;
@property (nonatomic, assign, readwrite) BOOL isFirstRun;
@property (nonatomic, assign, readwrite) BOOL online;

@property (nonatomic, assign, readwrite) BOOL refreshInProgress;
@property (nonatomic, retain, readwrite) NSDate *lastRefreshData;

@property (nonatomic, retain, readwrite) NSString *applicationNameForWebviewUserAgent;
@property (nonatomic, retain, readwrite) NSString *pathToCacheFolder;
@property (nonatomic, retain, readwrite) NSString *pathToDataFolder;
@property (nonatomic, retain, readwrite) NSString *userAgent;

@property (nonatomic, retain, readwrite) NSTimer *periodicRefreshTimer;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;

@property (nonatomic, retain, readwrite) SLAppIconController *appIconController;
@property (nonatomic, retain, readwrite) SLDataController *dataController;
@property (nonatomic, retain, readwrite) SLOperationController *mainOperationController;
@property (nonatomic, retain, readwrite) SLPluginManager *pluginManaer;

@end


@implementation SLAppDelegate

@synthesize appIconController;
@synthesize appIsShuttingDown;
@synthesize applicationNameForWebviewUserAgent;
@synthesize dataController;
@synthesize isFirstRun;
@synthesize lastRefreshDate;
@synthesize mainOperationController;
@synthesize online;
@synthesize pathToCacheFolder;
@synthesize pathToDataFolder;
@synthesize periodicRefreshTimer;
@synthesize pluginManaer;
@synthesize refreshInProgress;
@synthesize unreadCount;
@synthesize userAgent;


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[appIconController release];
	[applicationNameForWebviewUserAgent release];
	[dataController release];
	[lastRefreshDate release];
	[mainOperationController release];
	[pathToCacheFolder release];
	[pathToDataFolder release];
	[periodicRefreshTimer release];
	[pluginManaer release];
	[userAgent release];
	[super dealloc];
}


#pragma mark Startup

- (void)startup {
	
	;
}


#pragma mark AwakeFromNib (Mac)

#if !TARGET_OS_IPHONE

- (void)awakeFromNib {
	[self startup];
}


#endif

#pragma mark applicationDidFinishLaunching (iOS)

#if TARGET_OS_IPHONE

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[self startup];
	return YES;
}

#endif

@end
