//
//  SLAppDelegate.h
//  nnwiphone
//
//  Created by Brent Simmons on 1/30/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLPlatform.h"


@class SLDataController;
@class SLOperationController;
@class SLPluginManager;
@class SLAppIconController;


@interface SLAppDelegate : NSObject <SL_APPLICATION_DELEGATE> {
@private
	BOOL appIsShuttingDown;
	BOOL isFirstRun;
	BOOL online;
	BOOL refreshInProgress;
	NSDate *lastRefreshDate;
	NSString *applicationNameForWebviewUserAgent;
	NSString *pathToCacheFolder;
	NSString *pathToDataFolder;
	NSString *userAgent;
	NSTimer *periodicRefreshTimer;
	NSUInteger unreadCount;
	SLAppIconController *appIconController;
	SLDataController *dataController;
	SLOperationController *mainOperationController;
	SLPluginManager *pluginManaer;
}


@property (nonatomic, assign, readonly) BOOL appIsShuttingDown;
@property (nonatomic, assign, readonly) BOOL isFirstRun;
@property (nonatomic, assign, readonly) BOOL online;

@property (nonatomic, assign, readonly) BOOL refreshInProgress;
@property (nonatomic, retain, readonly) NSDate *lastRefreshData;

@property (nonatomic, retain, readonly) NSString *applicationNameForWebviewUserAgent;
@property (nonatomic, retain, readonly) NSString *pathToCacheFolder;
@property (nonatomic, retain, readonly) NSString *pathToDataFolder;
@property (nonatomic, retain, readonly) NSString *userAgent;

@property (nonatomic, retain, readonly) NSTimer *periodicRefreshTimer;
@property (nonatomic, assign, readonly) NSUInteger unreadCount;

@property (nonatomic, retain, readonly) SLAppIconController *appIconController;
@property (nonatomic, retain, readonly) SLDataController *dataController;
@property (nonatomic, retain, readonly) SLOperationController *mainOperationController;
@property (nonatomic, retain, readonly) SLPluginManager *pluginManaer;

@end
