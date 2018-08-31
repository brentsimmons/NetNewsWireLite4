//
//  RSPluginLoader.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSPluginLoader.h"
#import "RSPluginController.h"


@interface RSPluginLoader ()

@property (nonatomic, retain) NSMutableDictionary *pluginControllers;
@property (nonatomic, assign) id<RSPluginLoaderDelegate> delegate;

@end


@implementation RSPluginLoader

@synthesize pluginControllers;
@synthesize delegate;


#pragma mark Init

- (id)initWithDelegate:(id<RSPluginLoaderDelegate>)aDelegate {
	self = [super init];
	if (self == nil)
		return nil;
	delegate = aDelegate;
	pluginControllers = [[NSMutableDictionary dictionary] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[pluginControllers release];
	[super dealloc];
}


#pragma mark Plugin Controllers

- (void)registerPluginController:(RSPluginController *)aPluginController {
	[self.pluginControllers setObject:aPluginController forKey:[NSNumber numberWithInteger:aPluginController.pluginType]];
}


- (RSPluginController *)pluginControllerForType:(NSInteger)pluginType {
	return [self.pluginControllers objectForKey:[NSNumber numberWithInteger:pluginType]];
}


#pragma mark Registering

- (void)registerPluginClass:(Class)pluginClass ofType:(NSInteger)pluginType {
	RSPluginController *aPluginController = [self pluginControllerForType:pluginType];
	if (aPluginController != nil)
		[aPluginController registerPluginClass:pluginClass];
}


#pragma mark Startup

- (void)registerAndLoadPlugins {
}


@end
