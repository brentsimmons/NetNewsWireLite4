/*
	RSKeyboardShortcutsWindowController.h
	RancheroAppKit

	Created by Brent Simmons on Wed Jul 23 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/

#import <Cocoa/Cocoa.h>


@class WebView;


@interface RSKeyboardShortcutsWindowController : NSWindowController {

	@private
		IBOutlet WebView *_webView;
		NSString *rs_filename;
	}


- (id)initWithFilename: (NSString *)filename;


@end
