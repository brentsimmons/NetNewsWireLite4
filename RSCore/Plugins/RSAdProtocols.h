//
//  NGAdProtocols.h
//  padlynx
//
//  Created by Brent Simmons on 10/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//


/*This API is for iOS and TapLynx: there's no Mac version.*/

#import <UIKit/UIKit.h>
#import "NGPluginProtocols.h"
#import "TLViewControllerProtocols.h"


/*TapLynx has space for ads -- at this writing (Oct. 28, 2010), just on the article pages, though that
 may change in the future.
 
 Your NGAdManager plugin gets called when we have a new page. Params are tab, sharableItem
 (representing the article), and size. The size will be constant, even if the device is
 rotated.
 
 Your view controller should assume it's being displayed. It will be released when it's
 no longer on-screen.
 
 Your ad plugin will also get called right before releasing a view controller, in case
 you want to have a pool instead of creating a new one each time.
 
 You can have multiple ad plugins. If one plugin returns nil for adViewControllerForTab,
 then the app will ask the next one in the list. They're checked in the order they appear in the
 Plugins_Ads array in the config file.
 
 The ad manager gets called at startup, so that it can start doing whatever setup it may require.
 
 For doing analytics instead of ads, NGObserverProtocols.h.
 */


@protocol NGAdManager <NGPlugin>

@required

/*The view controller's view will display an ad. TLTab comes from TLViewControllerProtocols.h.*/

- (UIViewController *)adViewControllerForTab:(id<TLTab>)aTab sharableItem:(id<NGSharableItem>)aSharableItem size:(CGSize)aSize;

@optional

- (void)adViewControllerWillBeReleased:(UIViewController *)anAdViewController; //Keep it around, if you have a pool.

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions; //In case there's setup to do.


@end
