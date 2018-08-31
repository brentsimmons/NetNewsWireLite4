/*
	RSDiskFileDownloadsWindowController.h
	NetNewsWire

	Created by Brent Simmons on 12/14/04.
	Copyright 2004 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


@class RSDiskFileDownloadView;
@class RSPopupButton;


@interface RSDiskFileDownloadsWindowController : NSWindowController {
	
	@private
		IBOutlet RSDiskFileDownloadView *downloadsView;
		IBOutlet NSButton *clearButton;
		IBOutlet NSTextField *statusTextField;
		IBOutlet RSPopupButton *gearButton;
	}


- (IBAction)clearDownloads:(id)sender;


@end
