/*
	RSDiskFileDownloadItemView.h
	NetNewsWire

	Created by Brent Simmons on 12/14/04.
	Copyright 2004 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


extern NSString *RSDiskFileDownloadItemDidChangeDownloadingStatusNotification;


@class RSDiskFileDownloadRequest;
@class RSCloseButton;


@interface RSDiskFileDownloadItemView : NSView {

	@private
		NSProgressIndicator *progressIndicator;
		NSTextField *filenameTextField;
		NSTextField *subtextTextField;
		RSCloseButton *cancelOrRevealButton;
		RSDiskFileDownloadRequest *request;
		BOOL downloading;
		NSImage *fileIcon;
		BOOL mouseInsideCancelOrRevealButton;
		BOOL _inProgress;
		long long _lastBytesDownloaded;
	}


- (RSDiskFileDownloadRequest *)request;
- (void)setRequest:(RSDiskFileDownloadRequest *)r;

- (void)tile;

- (BOOL)isDownloading;

- (void)updateTextFields;

- (NSMenu *)contextualMenu;

- (void)updateAll;


@end
