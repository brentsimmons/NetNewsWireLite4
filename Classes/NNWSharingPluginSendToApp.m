//
//  NNWSendToAppPlugin.m
//  nnw
//
//  Created by Brent Simmons on 1/3/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSharingPluginSendToApp.h"
#import "NNWPluginCommandSendToApp.h"


@interface NNWSharingPluginSendToApp ()

@property (nonatomic, retain, readwrite) NSArray *allCommands;
@property (nonatomic, retain) id<RSPluginHelper> pluginHelper;

- (NSArray *)buildCommands;

@end


@implementation NNWSharingPluginSendToApp

@synthesize allCommands;
@synthesize pluginHelper;


#pragma mark Dealloc

- (void)dealloc {
	[pluginHelper release];
	[allCommands release];
	[super dealloc];
}


#pragma mark RSPlugin

- (BOOL)commandsShouldBeGrouped {
	return YES;
}


- (NSString *)titleForGroup {
	return NSLocalizedStringFromTable(@"Send to App", @"NNWSharingPluginSendToApp", @"Commands group title");
}


- (BOOL)shouldRegister:(id<RSPluginManager>)pluginManager {
	self.pluginHelper = pluginManager.pluginHelper;
	self.allCommands = [self buildCommands];
	return YES;
}


#pragma mark Commands

- (BOOL)equalAppNames:(NSString *)appName1 appName2:(NSString *)appName2 {
	
	/*Beware of .app suffix. Also be case-insensitive -- forgive people's typing.*/
	
	NSString *lowerAppName1 = [appName1 lowercaseString];
	NSString *lowerAppName2 = [appName2 lowercaseString];
	
	if ([lowerAppName1 hasSuffix:@".app"])
		lowerAppName1 = [lowerAppName1 stringByDeletingPathExtension];
	if ([lowerAppName2 hasSuffix:@".app"])
		lowerAppName2 = [lowerAppName2 stringByDeletingPathExtension];
	
	return [lowerAppName1 isEqualToString:lowerAppName2];
}


- (BOOL)commandForAppAlreadyExists:(NSString *)appName inArray:(NSArray *)anArray {
	
	/*Beware of duplicate commands. The openURL-app finder, for instance, may find apps
	 that already exist in the configured list. It's also possible that a user
	 has configured an app that already appears in the builtin list (especially
	 if we update that list to add an app.)*/
	
	NSArray *existingAppNames = [anArray valueForKeyPath:@"sendToAppSpecifier.appName"];
	for (NSString *oneAppName in existingAppNames) {
		if ([self equalAppNames:appName appName2:oneAppName])
			return YES;
	}
	return NO;
}


- (void)addCommandsFromPlistFileAtPath:(NSString *)plistFilePath toArray:(NSMutableArray *)anArray {
	
	if (plistFilePath == nil)
		return;
	NSDictionary *sendToAppsDictionary = [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
	if (sendToAppsDictionary == nil)
		return;

	for (NSString *oneKey in [sendToAppsDictionary allKeys]) {
		NNWSendToAppSpecifier *oneSendToAppSpecifier = [[[NNWSendToAppSpecifier alloc] initWithAppName:oneKey configInfo:[sendToAppsDictionary objectForKey:oneKey]] autorelease];
		if (oneSendToAppSpecifier.appExistsOnDisk && ![self commandForAppAlreadyExists:oneKey inArray:anArray])
			[anArray addObject:[[[NNWPluginCommandSendToApp alloc] initWithAppSpecifier:oneSendToAppSpecifier] autorelease]];
	}	
}


- (NSArray *)buildCommands {
	
	NSMutableArray *commands = [NSMutableArray array];
	
	/*User-configured apps have priority.*/
	
	NSString *userSendToAppsPlistPath = [[self.pluginHelper pathToDataFolder] stringByAppendingPathComponent:@"SendToApps.plist"];
	[self addCommandsFromPlistFileAtPath:userSendToAppsPlistPath toArray:commands];
		
	NSString *builtinSendToAppsPlistPath = [[NSBundle mainBundle] pathForResource:@"SendToApps" ofType:@"plist"];
	[self addCommandsFromPlistFileAtPath:builtinSendToAppsPlistPath toArray:commands];

	NSSortDescriptor *sortByAppNameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sendToAppSpecifier.appName" ascending:YES selector:@selector(localizedStandardCompare:)];
	[commands sortUsingDescriptors:[NSArray arrayWithObject:sortByAppNameDescriptor]];
	
	return commands;
}


@end
