/*
	NNWStyleDocument.h
	NetNewsWire

	Created by Brent Simmons on 1/30/05.
	Copyright 2005 Ranchero Software. All rights reserved.
*/

#import <Cocoa/Cocoa.h>


@interface NNWStyleDocument : NSDocument {
@private
	BOOL isInstalled;
	BOOL styleWithSameNameIsInstalled;
	NSButton *authorWebsiteButton;
	NSString *authorName;
	NSString *authorWebsiteURL;
	NSString *filePath;
	NSString *message;
	NSString *title;
	NSWindow *mainWindow;
}


@property (nonatomic, retain) IBOutlet NSButton *authorWebsiteButton;
@property (nonatomic, retain) IBOutlet NSWindow *mainWindow;


@end
