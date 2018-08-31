//
//  RSPluginManager.h
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSPluginProtocols.h"


@interface RSPluginManager : NSObject <RSPluginManager> {
@private
	NSMutableArray *plugins;
	NSMutableArray *pluginClasses;
	NSMutableArray *commands;
	NSMutableArray *sharingCommands;
	NSMutableArray *appObserverPlugins;
	NSMutableArray *adManagerPlugins;
	id<RSPluginHelper> pluginHelper;
}


+ (RSPluginManager *)sharedManager;

@property (nonatomic, retain, readonly) NSArray *sharingCommands;
@property (nonatomic, retain, readonly) NSMutableArray *appObserverPlugins;
@property (nonatomic, retain, readonly) NSMutableArray *adManagerPlugins;
@property (nonatomic, retain, readonly) NSArray *sharingPlugins; //all plugins with at least one sharing command

- (void)registerPluginOfClass:(Class)pluginClass;
- (void)registerPlugins:(NSArray *)somePluginClasses;
- (void)registerPluginsWithClassNames:(NSArray *)somePluginClassNames;

- (void)loadPluginsFromPluginsFolders;
- (void)loadUserPlugins;

- (NSArray *)commandsOfType:(NSInteger)commandType;

- (BOOL)validateCommand:(id<RSPluginCommand>)pluginCommand withArray:(NSArray *)items;
- (NSArray *)validCommandsOfType:(NSInteger)commandType forArray:(NSArray *)items;

- (BOOL)runPluginCommand:(id<RSPluginCommand>)pluginCommand withItems:(NSArray *)items sendingViewController:(id)sendingViewController sendingView:(id)sendingView sendingControl:(id)sendingControl barButtonItem:(id)barButtonItem event:(id)event error:(NSError **)error;

- (void)makePlugins:(NSArray *)somePlugins performSelector:(SEL)aSelector withObject:(id)anObject;
- (void)makePlugins:(NSArray *)somePlugins performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

- (id<RSPluginCommand>)pluginCommandOfClass:(Class)aClass; //sometimes we need to find a special-case plugin
- (id<RSPluginCommand>)pluginCommandWithCommandID:(NSString *)aCommandID;

- (NSArray *)sharingCommandsInPlugin:(id<RSPlugin>)aPlugin;

- (void)associateMenuItem:(NSMenuItem *)aMenuItem withPluginCommand:(id<RSPluginCommand>)aPluginCommand;
- (id<RSPluginCommand>)associatedPluginCommandForMenuItem:(NSMenuItem *)aMenuItem;
- (void)associateMenuItem:(NSMenuItem *)aMenuItem withObject:(id)anObject; //often an RSSharableItem
- (id<RSSharableItem>)associatedObjectForMenuItem:(NSMenuItem *)aMenuItem;

- (NSArray *)pluginsWithGroupedCommandsOfType:(NSUInteger)aPluginCommandType;
- (NSArray *)pluginsWithSoloCommandsOfType:(NSUInteger)aPluginCommandType;

- (void)addPluginCommandsOfType:(NSUInteger)aPluginCommandType toMenu:(NSMenu *)aMenu associatedObject:(id)anAssociatedObject indentGroupedItems:(BOOL)indentGroupedItems;

- (NSArray *)orderedPluginCommandsOfType:(NSUInteger)aPluginCommandType; //solo, then grouped

- (NSArray *)soloPluginCommandsOfType:(NSUInteger)aPluginCommandType;
- (NSArray *)pluginsWithGroupedCommandsOfType:(NSUInteger)aPluginCommandType;

@end
