//
//  NNWSharingPluginOpenInOtherBrowser.m
//  nnw
//
//  Created by Brent Simmons on 1/4/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSharingPluginOpenInAnyBrowser.h"
#import "NNWPluginCommandOpenInAnyBrowser.h"


@interface NNWSharingPluginOpenInAnyBrowser ()

@property (nonatomic, retain, readwrite) NSArray *allCommands;

- (NSArray *)buildCommands;

@end


@implementation NNWSharingPluginOpenInAnyBrowser

@synthesize allCommands;


#pragma mark Dealloc

- (void)dealloc {
	[allCommands release];
	[super dealloc];
}


#pragma mark RSPlugin

- (BOOL)commandsShouldBeGrouped {
	return YES;
}


- (NSString *)titleForGroup {
	return NSLocalizedStringFromTable(@"Open in", @"NNWSharingPluginOpenInAnyBrowser", @"Commands group title");
}


- (BOOL)shouldRegister:(id<RSPluginManager>)pluginManager {
	self.allCommands = [self buildCommands];
	return YES;
}


- (BOOL)appBundleIDIsBrowser:(NSString *)appBundleID {

	/*Need to filter out some:
	 0 : <CFString 0x102931740 [0x7fff7090cee0]>{contents = "org.mozilla.firefox"}
	 1 : <CFString 0x102931590 [0x7fff7090cee0]>{contents = "com.apple.safari"}
	 2 : <CFString 0x1029315e0 [0x7fff7090cee0]>{contents = "com.picodev.Versions"}
	 3 : <CFString 0x102931640 [0x7fff7090cee0]>{contents = "com.vmware.proxyApp.564d284980c3489b-b72895e75961a2f9.1713129647"}
	 4 : <CFString 0x102931770 [0x7fff7090cee0]>{contents = "com.google.Chrome"}
	 5 : <CFString 0x102931810 [0x7fff7090cee0]>{contents = "com.operasoftware.Opera"}
	 6 : <CFString 0x1029316e0 [0x7fff7090cee0]>{contents = "com.vmware.proxyApp.564d284980c3489b-b72895e75961a2f9.1924399171"}
	 7 : <CFString 0x102931840 [0x7fff7090cee0]>{contents = "com.omnigroup.OmniWeb5"}
	 8 : <CFString 0x102931610 [0x7fff7090cee0]>{contents = "com.apple.mobilesafari"}
	 
	 Instead of filtering-out, we'll go with a known-good list of bundle IDs. Better to not support enough than
	 to have weird things in there that do weird things. We can add more when they come up, which isn't often.
	 */

	if ([appBundleID rs_caseInsensitiveContains:@"proxyApp"])
		return NO;
	
	static NSArray *knownBrowserBundleIDs = nil;
	if (knownBrowserBundleIDs == nil)
		knownBrowserBundleIDs = [[NSArray arrayWithObjects:@"org.mozilla.firefox", @"com.apple.safari", @"com.google.Chrome", @"com.operasoftware.Opera", @"com.omnigroup.OmniWeb5", @"org.mozilla.camino", nil] retain];
	if ([knownBrowserBundleIDs containsObject:appBundleID])
		return YES;
	
	for (NSString *oneBrowserBundleID in knownBrowserBundleIDs) {
		if ([oneBrowserBundleID caseInsensitiveCompare:appBundleID] == NSOrderedSame)
			return YES;
	}
	
	if ([appBundleID rs_caseInsensitiveContains:@"google"] && [appBundleID rs_caseInsensitiveContains:@"chrome"])
		return YES;
	if ([appBundleID rs_caseInsensitiveContains:@"omnigroup"] && [appBundleID rs_caseInsensitiveContains:@"omniweb"])
		return YES;
	
	return NO;

}
- (void)addCommandsForOpenURLApps:(NSArray *)openURLApps toArray:(NSMutableArray *)anArray {
	
	
	for (NSString *oneAppBundleID in openURLApps) {
		if (![self appBundleIDIsBrowser:oneAppBundleID])
			continue;
		
		NSString *oneAppPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:oneAppBundleID];
		if (oneAppPath == nil)
			continue;
		NSString *oneAppName = [[NSFileManager defaultManager] displayNameAtPath:oneAppPath];
		NNWPluginCommandOpenInAnyBrowser *onePluginCommand = [[[NNWPluginCommandOpenInAnyBrowser alloc] initWithAppName:oneAppName bundleID:oneAppBundleID path:oneAppPath] autorelease];
		[anArray addObject:onePluginCommand];
	}
}


- (NSArray *)buildCommands {
	
	NSMutableArray *commands = [NSMutableArray array];
	
	NSArray *openURLApps = (NSArray *)[NSMakeCollectable(LSCopyAllHandlersForURLScheme(CFSTR("http"))) autorelease];
	[self addCommandsForOpenURLApps:openURLApps toArray:commands];
	
	NSSortDescriptor *sortByAppNameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"appName" ascending:YES selector:@selector(localizedStandardCompare:)];
	[commands sortUsingDescriptors:[NSArray arrayWithObject:sortByAppNameDescriptor]];
	
	return commands;
}


@end
