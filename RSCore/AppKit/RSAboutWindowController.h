/*
	RSAboutWindowController.h
	NetNewsWire

	Created by Brent Simmons on Fri Aug 08 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

//TODO: figure out how to move the xib file into RSCore *and* make it so it doesn't need localization.

@interface RSAboutWindowController : NSWindowController {

	@private
		IBOutlet WebView *_webView;
		IBOutlet NSTextField *_appNameTextField;
		IBOutlet NSTextField *_appVersionTextField;
		IBOutlet NSTextField *_urlTextField;
		BOOL _flWindowDidLoad;
	}


- (void)loadHTMLPage;
			

@end
