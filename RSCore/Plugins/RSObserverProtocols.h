//
//  NGObserverProtocols.h
//  padlynx
//
//  Created by Brent Simmons on 10/6/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif
#import "RSPluginProtocols.h"


/*App observers get many of the same messages that the app delegate gets.
 Also: you can have more than one observer.*/

@protocol RSAppObserver <RSPlugin, NSObject>

@optional

#if TARGET_OS_IPHONE

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions; //note void return
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillResignActive:(UIApplication *)application;

#else //Mac

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationDidResignActive:(NSNotification *)notification;

#endif

/*Common to both platforms.*/

- (void)userDidViewItem:(id<RSSharableItem>)sharableItem; //think page-view, usually, but check the properties

/*These two are for movies and audio. When these are called, userDidViewItem is not called, so you don't note the same event twice.*/

- (void)userDidBeginViewingTimeBasedMediaItem:(id<RSSharableItem>)sharableItem;
- (void)userDidEndViewingTimeBasedMediaItem:(id<RSSharableItem>)sharableItem;

/*serviceIdentifier will be something like @"com.twitter" or @"email". There's no set list, because sharing plugins
 may connect to anything. Also, because sharing plugins specify the serviceIdentifier, it may be nil, or weird somehow.
 Also, since we rely on sharing plugins to notify the app, which then notifies the observers, it's possible that
 observers won't get notified because a sharing plugin doesn't notify the app.*/

- (void)userDidShareItem:(id<RSSharableItem>)sharableItem serviceIdentifier:(NSString *)serviceIdentifier;


#if TARGET_OS_IPHONE

/*This happens on startup and on returning to the home screen after navigating elsewhere.*/

- (void)userDidViewHomeScreen;

#endif


@end
