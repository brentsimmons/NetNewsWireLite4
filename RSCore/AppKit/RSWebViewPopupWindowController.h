/*
	RSWebViewPopupWindowController.h
	NetNewsWire

	Created by Brent Simmons on 3/11/06.
	Copyright 2006 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface RSWebViewPopupWindowController : NSWindowController {

	@private
		IBOutlet WebView *_webview;
		BOOL _releaseOnClose;
	}


- (void)openURLString:(NSString *)urlString;
- (void)openURLString:(NSString *)urlString showWindow:(BOOL)showWindow;

- (void)setReleaseOnClose:(BOOL)flag;

- (WebView *)webview;


@end
