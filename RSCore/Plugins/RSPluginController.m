//
//  RSPluginsController.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSPluginController.h"
#import "RSPluginProtocols.h"
#import "RSPluginCommand.h"
#import "RSFoundationExtras.h"


static NSInteger gNextCommandTag = 0; //global across all plugins: each command has its own tag

@implementation RSPluginController

@synthesize pluginInstances;
@synthesize classesRegistered;
@synthesize commands;
@synthesize pluginType;
@synthesize pluginHelper;


#pragma mark Init

- (id)initWithPluginType:(NSInteger)aPluginType pluginHelper:(id<RSPluginHelper>)aPluginHelper {
	self = [super init];
	if (self == nil)
		return nil;
	pluginHelper = aPluginHelper;
	pluginType = aPluginType;
	pluginInstances = [[NSMutableArray array] retain];
	classesRegistered = [[NSMutableArray array] retain];
	commands = [[NSMutableDictionary dictionary] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[pluginInstances release];
	[classesRegistered release];
	[commands release];
	[super dealloc];
}


//#pragma mark Registering with Plugins Loader
//
//- (void)registerWithPluginsLoader:(RSPluginLoader *)pluginsLoader {
//	[pluginsLoader registerPluginsController:self forType:self.pluginType];
//}


#pragma mark Registering Plugins

- (void)addCommandsFromPlugin:(id<RSPlugin>)pluginObject {
	if (![(id)pluginObject respondsToSelector:@selector(allCommands)])
		return;
	for (id<RSPluginCommand> onePluginCommand in pluginObject.allCommands) {
		RSPluginCommand *command = [[[RSPluginCommand alloc] initWithRSPluginCommand:onePluginCommand tag:gNextCommandTag pluginType:self.pluginType] autorelease];
		[self.commands rs_safeSetObject:command forKey:[NSNumber numberWithInteger:gNextCommandTag]];
		gNextCommandTag++;
	}
}


- (void)registerPluginClass:(Class)aPluginClass {
	if ([self.classesRegistered containsObject:aPluginClass])
		return;
	id<RSPlugin> pluginObject = [[[aPluginClass alloc] init] autorelease];
	if (pluginObject == nil)
		return;
	if ([(id)pluginObject respondsToSelector:@selector(shouldRegister:)])
		if (![pluginObject shouldRegister:self])
			return;
	if ([(id)pluginObject respondsToSelector:@selector(willRegister)])
		[pluginObject willRegister];
	[self.pluginInstances addObject:pluginObject];
	[self addCommandsFromPlugin:pluginObject];
	if ([(id)pluginObject respondsToSelector:@selector(didRegister)])
		[pluginObject didRegister];
}


#pragma mark Commands

- (NSArray *)validatedCommandsForArrayOfItems:(NSArray *)items {
	NSMutableArray *validatedCommands = [NSMutableArray array];
	for (RSPluginCommand *oneCommand in self.commands) {
		if ([oneCommand validateCommandWithArray:items])
			[validatedCommands addObject:oneCommand];
	}
	return validatedCommands;
}



@end
