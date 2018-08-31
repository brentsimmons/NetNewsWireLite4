//
//  RSPluginsLoader.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum {
	RSPluginTypeSharing,
	RSPluginTypeFeed
}; /*App-specific plugin types should have numbers above 1000.*/


@protocol RSPluginLoaderDelegate

@required
- (NSArray *)pluginControllersToRegister;

@optional


@end


@interface RSPluginLoader : NSObject {
@private
	NSMutableDictionary *pluginControllers;
	id<RSPluginLoaderDelegate> delegate;
}


- (id)initWithDelegate:(id<RSPluginLoaderDelegate>)aDelegate;
- (void)registerAndLoadPlugins;


@end
