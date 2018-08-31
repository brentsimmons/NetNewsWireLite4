//
//  RSPluginsController.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


@interface RSPluginController : NSObject <RSPluginManager> {
@private
	NSMutableArray *pluginInstances;
	NSMutableArray *classesRegistered;
	NSMutableDictionary *commands;
	NSInteger pluginType;
	id<RSPluginHelper> pluginHelper;
}


- (id)initWithPluginType:(NSInteger)aPluginType pluginHelper:(id<RSPluginHelper>)aPluginHelper;

//- (void)registerWithPluginsLoader; //necessary

@property (nonatomic, retain) NSMutableArray *pluginInstances;
@property (nonatomic, retain) NSMutableArray *classesRegistered;
@property (nonatomic, retain) NSMutableDictionary *commands;
@property (nonatomic, assign) NSInteger pluginType;
@property (nonatomic, retain, readonly) id<RSPluginHelper> pluginHelper;

- (void)registerPluginClass:(Class)aPluginClass;

- (NSArray *)validatedCommandsForArrayOfItems:(NSArray *)items; //contextual menus, for example


@end
