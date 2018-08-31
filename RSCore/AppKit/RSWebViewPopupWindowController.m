/*
	RSWebViewPopupWindowController.m
	NetNewsWire

	Created by Brent Simmons on 3/11/06.
	Copyright 2006 Ranchero Software. All rights reserved.
*/


#import "RSWebViewPopupWindowController.h"
#import "WebView+Extras.h"


@implementation RSWebViewPopupWindowController


- (id)init {
	return [super initWithWindowNibName:@"WebViewPopup"];
	}


- (void)windowDidLoad {
	[self setWindowFrameAutosaveName:[self windowNibName]];//@"BrowserPopup"];
	}	


- (void)openURLString:(NSString *)urlString {
	[self openURLString:urlString showWindow:YES];
	}
	
	
- (void)openURLString:(NSString *)urlString showWindow:(BOOL)showWindow {
	[self window];
	if (showWindow)
		[self showWindow:self];
	[_webview loadURLString:urlString];
	}
	

- (void)setReleaseOnClose:(BOOL)flag {
	_releaseOnClose = flag;
	}


- (WebView *)webview {
	return _webview;
	}
	
	
- (BOOL)windowShouldClose:(id)sender {
	if (_releaseOnClose)
		//[self performSelectorOnMainThread:@selector(autorelease) withObject:nil waitUntilDone:NO];
	return YES;
	}
	
	
@end
