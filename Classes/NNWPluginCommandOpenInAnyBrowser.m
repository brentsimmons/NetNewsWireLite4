//
//  NNWPluginCommandOpenInBrowser.m
//  nnw
//
//  Created by Brent Simmons on 1/4/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWPluginCommandOpenInAnyBrowser.h"


@interface NNWPluginCommandOpenInAnyBrowser ()

@property (nonatomic, retain) NSString *appName;
@property (nonatomic, retain) NSString *appPath;
@property (nonatomic, retain) NSString *bundleID;
@end


@implementation NNWPluginCommandOpenInAnyBrowser

@synthesize appName;
@synthesize appPath;
@synthesize bundleID;


#pragma mark Init

- (id)initWithAppName:(NSString *)anAppName bundleID:(NSString *)aBundleID path:(NSString *)aPath {
	self = [super init];
	if (self == nil)
		return nil;
	if ([anAppName hasSuffix:@".app"])
		anAppName = [anAppName stringByDeletingPathExtension];
	appName = [anAppName retain];
	bundleID = [aBundleID retain];
	appPath = [aPath retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[appIcon release];
	[appName release];
	[appPath release];
	[bundleID release];
	[super dealloc];
}


#pragma mark App Icon

- (NSImage *)appIcon {
	if (appIcon != nil)
		return appIcon;
	appIcon = [[[NSWorkspace sharedWorkspace] iconForFile:self.appPath] retain];
	return appIcon;
}


#pragma mark Sending

- (BOOL)sendSharableItem:(id<RSSharableItem>)sharableItem {
	NSURL *url = sharableItem.permalink; //for articles in feeds, most people expect the permalink, so use that if available
	if (url == nil)
		url = sharableItem.URL;
	return [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:self.bundleID options:0 additionalEventParamDescriptor:nil launchIdentifiers:NULL];
}


#pragma mark RSPluginCommand

- (NSString *)commandID {
	return [NSString stringWithFormat:@"com.ranchero.NetNewsWire.plugin.sharing.OpenInAnyBrowser.%@", self.appName];
}


- (NSString *)title {
	return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Open in %@", @"NNWPluginCommandOpenInBrowser", @"Command"), self.appName];
}


- (NSString *)shortTitle {
	return self.appName;
}


- (NSImage *)image {
	return self.appIcon;
}


- (NSArray *)commandTypes {
	return [NSArray arrayWithObject:[NSNumber numberWithInteger:RSPluginCommandTypeOpenInViewer]];
}


- (BOOL)validateCommandWithArray:(NSArray *)items {
	
	if (items == nil || [items count] != 1)
		return NO;
	id<RSSharableItem> aSharableItem = [items objectAtIndex:0];
	return aSharableItem.URL != nil || aSharableItem.permalink != nil;
}


- (BOOL)performCommandWithArray:(NSArray *)items userInterfaceContext:(id<RSUserInterfaceContext>)userInterfaceContext pluginHelper:(id<RSPluginHelper>)aPluginHelper error:(NSError **)error {
	
	id<RSSharableItem> sharableItem = [items objectAtIndex:0];
	
	if (![self sendSharableItem:sharableItem])
		return NO;
	
	NSString *serviceIdentifier = self.appName;
	if (serviceIdentifier == nil)
		serviceIdentifier = self.bundleID;	
	[aPluginHelper noteUserDidShareItem:sharableItem viaServiceIdentifier:serviceIdentifier];
	
	return YES;
}

@end
