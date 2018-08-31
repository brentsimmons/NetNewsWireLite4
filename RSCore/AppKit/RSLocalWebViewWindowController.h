/*
	RSLocalWebViewWindowController.h
	RancheroAppKit

	Created by Brent Simmons on Tue Aug 03 2004.
	Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


/*For viewing *local* HTML files. Sends external links to default browser.*/


#import <Cocoa/Cocoa.h>


@class WebView;


@interface RSLocalWebViewWindowController : NSWindowController {

	@protected
		IBOutlet WebView *_webView;
		IBOutlet NSWindow *_mainWindow;
		NSString *_filename;
	}


- (id) initWithFilename: (NSString *) f;

@end
