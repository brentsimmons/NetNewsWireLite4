//
//  NNWAppDelegate+Mac.m
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//


#import "NNWAppDelegate.h"
#import "RSContainerWindowController.h"


/*First responder actions and similar for Mac versions.*/


@implementation NNWAppDelegate (Mac)

//static void openURLStringInBrowser(NSString *URLString) {
//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URLString]];
//}


//#pragma mark NetNewsWire Menu
//
//- (void)openPreferencesWindow:(id)sender {
//	
//	static RSContainerWindowController *preferencesWindowController = nil;
//	
//	if (preferencesWindowController == nil) {
//		NSArray *builtInPreferencesPluginClassNames = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Plugins_Preferences"];
//		if (RSIsEmpty(builtInPreferencesPluginClassNames)) {
//			NSLog(@"No preferences plugins. Can't load preferences window.");
//			return;
//		}
//		NSMutableArray *preferencesPlugins = [NSMutableArray array];
//		for (NSString *onePluginClassName in builtInPreferencesPluginClassNames)
//			[preferencesPlugins addObject:[[[NSClassFromString(onePluginClassName) alloc] init] autorelease]];
//		preferencesWindowController = [[RSContainerWindowController alloc] initWithPlugins:preferencesPlugins];
//	}
//	
//	[preferencesWindowController showWindow:self];
//}




//#pragma mark Window Menu
//
//- (void)showActivityWindow:(id)sender {
//	//TODO: show activity window
//}
//
//
//- (void)showDownloadsWindow:(id)sender {
//	//TODO: show downloads window	
//}


- (void)showMainWindow:(id)sender {
	//TODO: show main window
}


#pragma mark Help Menu

//- (void)openFrequentlyAskedQuestionsInBrowser:(id)sender {
//	openURLStringInBrowser(@"http://netnewswireapp.com/frequently-asked-questions/");
//}
//
//
//- (void)openUserVoiceInBrowser:(id)sender {
//	openURLStringInBrowser(@"http://nnwmac.uservoice.com/");
//}
//
//
//- (void)openGoogleGroupInBrowser:(id)sender {
//	openURLStringInBrowser(@"http://groups.google.com/group/netnewswire-mac");
//}
//
//
//- (void)openNetNewsWireWebsiteInBrowser:(id)sender {
//	openURLStringInBrowser(@"http://netnewswireapp.com/");
//}


//- (void)openPluginsWebsiteInBrowser:(id)sender {
//	//TODO: open plugins website
//}
//
//
//- (void)openStylesWebsiteInBrowser:(id)sender {
//	//TODO: styles website
//}


//- (void)openNetNewsWireForiPadInBrowser:(id)sender {
//	openURLStringInBrowser(@"http://netnewswireapp.com/ipad/");
//}
//
//
//- (void)openNetNewsWireForiPhoneInBrowser:(id)sender {
//	openURLStringInBrowser(@"http://netnewswireapp.com/iphone/");
//}


- (void)openAcknowledgements:(id)sender {
	//TODO: show acknowledgements
}


@end
