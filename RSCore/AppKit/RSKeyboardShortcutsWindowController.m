/*
	RSKeyboardShortcutsWindowController.m
	RancheroAppKit

	Created by Brent Simmons on Wed Jul 23 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import <WebKit/WebKit.h>
#import "RSKeyboardShortcutsWindowController.h"
//#import "Definitions.h"
//#import "NetNewsWire.h"


@interface RSKeyboardShortcutsWindowController ()
- (void) setFilename: (NSString *) filename;
@end


static BOOL gFlWindowLoaded = NO;


@implementation RSKeyboardShortcutsWindowController


- (id)initWithFilename:(NSString *)filename {
	self = [super initWithWindowNibName:@"KeyboardShortcutsWindow"];
	if (self)
		[self setFilename:filename];
	return self;
	}


- (void) dealloc {
	[rs_filename release];
	[super dealloc];
	}
	

- (void) setFilename: (NSString *) filename {
	[rs_filename autorelease];
	rs_filename = [filename retain];
	}
	
	
- (void) loadHTMLPage {
	
	NSString *filePathString = [[NSBundle mainBundle]
		pathForResource: rs_filename ofType: @"html"];	
	NSURL *fileURL = [NSURL fileURLWithPath: filePathString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL: fileURL];
	
	[[_webView mainFrame] loadRequest: urlRequest];	
	}
	
	
- (void) windowDidLoad {
	
	gFlWindowLoaded = YES;
	
	[_webView setUIDelegate: [NSApp delegate]];
	[_webView setResourceLoadDelegate: [NSApp delegate]];
	//[_webView setCustomUserAgent:NNWUserAgent];
	
	[self loadHTMLPage];
	
	[_webView setPolicyDelegate: [NSApp delegate]];
	}
	

- (void) showWindow: (id) sender {
			
	[super showWindow: sender];
	if (gFlWindowLoaded)
		[self loadHTMLPage];
	}
	
	
@end
