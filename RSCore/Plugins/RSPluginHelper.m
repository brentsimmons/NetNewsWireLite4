//
//  RSPluginHelper.m
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSPluginHelper.h"
#import "NNWFeedbackProgressWindowController.h"


@implementation RSPluginHelper


- (void)startIndeterminateFeedbackWithTitle:(NSString *)title image:(NSImage *)image {
	[NNWFeedbackProgressWindowController runWindowWithTitle:title image:image];
}


- (void)stopIndeterminateFeedback {
	[NNWFeedbackProgressWindowController closeWindow];
}


- (void)showSuccessMessageWithTitle:(NSString *)title image:(NSImage *)image {
	[NNWFeedbackProgressWindowController runWindowWithSuccessMessage:title image:image];
}


- (void)noteUserDidShareItem:(id<RSSharableItem>)sharableItem viaServiceIdentifier:(NSString *)serviceIdentifier {
	
}


- (void)openPopupBrowserWindowWithURL:(NSURL *)url {
	
}


- (BOOL)sendSharableItem:(id<RSSharableItem>)sharableItem toAppWithName:(NSString *)appName error:(NSError **)error {
	return NO;
}


- (void)presentError:(NSError *)error {
	/*App delegate must have didPresentSelector.*/
	[NSApp presentError:error modalForWindow:[NSApp mainWindow] delegate:[NSApp delegate] didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];	
}


- (NSString *)pathToCacheFolder {
	return rs_app_delegate.pathToCacheFolder;
}


- (NSString *)pathToDataFolder {
	return rs_app_delegate.pathToDataFolder;
}


- (NSString *)userAgent {
	return rs_app_delegate.userAgent;
}


- (NSString *)applicationNameForWebviewUserAgent {
	return rs_app_delegate.applicationNameForWebviewUserAgent;
}


@end
