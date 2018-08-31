/*
	RSDiskFileDownloadsWindowController.m
	NetNewsWire

	Created by Brent Simmons on 12/14/04.
	Copyright 2004 Ranchero Software. All rights reserved.
*/


#import "RSDiskFileDownloadsWindowController.h"
#import "RSDiskFileDownloadRequest.h"
#import "RSDiskFileDownloadController.h"
#import "RSDiskFileDownloadView.h"


@interface RSDiskFileDownloadsWindowController (Private)
- (void)setupDownloadView;
- (void)updateUI;
@end


@implementation RSDiskFileDownloadsWindowController


#pragma mark Init

- (id)init {	
	return [super initWithWindowNibName:@"FileDownloads"];
	}


#pragma mark Notifications

- (void)handleRequestDidInitialize:(NSNotification *)note {
	[downloadsView addViewForRequest:[note object]];
	[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
	}
	

- (void)handleGenericFileDownloadStatusChange:(NSNotification *)note {
	[self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
	}
	
	
- (void)registerForNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRequestDidInitialize:) name:RSDiskFileDownloadRequestDidInitializeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFileDownloadStatusChange:) name:RSDiskFileDownloadStatusDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFileDownloadStatusChange:) name:RSDiskFileDownloadDidGetRemovedNotification object:nil];
	}
	

#pragma mark Setup

- (void)setupDownloadView {
	[downloadsView addViewsForRequests:[[RSDiskFileDownloadController sharedController] downloadRequests]];
	}
	

- (void)windowDidLoad {
	[[self window] setFrameAutosaveName:@"NNWDownloadsWindow"];
	[self registerForNotifications];
	[self setupDownloadView];
	[self updateUI];
	[gearButton setPullDownMenuDelegate:self];
	[gearButton setRefusesFirstResponder:YES];
	[[statusTextField cell] setBackgroundStyle:NSBackgroundStyleRaised]; 
	}
	

#pragma mark Actions

- (IBAction)clearDownloads:(id)sender {
	[[RSDiskFileDownloadController sharedController] clearClearableDownloads];
	[self updateUI];
	}
	

#pragma mark Gear menu

- (NSMenu *)menuForPopupButton:(NSButton *)button {
	return [downloadsView menuForPopupButton:button];
	}
	
	
#pragma mark UI

- (void)updateClearButton {
	NSInteger ctCanBeDeleted = [[RSDiskFileDownloadController sharedController] numberOfDeletableRequests];
	[clearButton setEnabled:(ctCanBeDeleted > 0)];
	}


- (void)updateStatusTextField {
	NSInteger numDownloads = [[RSDiskFileDownloadController sharedController] numberOfRequests];
	if (numDownloads == 1)
		[statusTextField setStringValue:NNW_1_DOWNLOAD];
	else
		[statusTextField setStringValue:[NSString stringWithFormat:NNW_I_DOWNLOADS, (long)numDownloads]];
	}
	

- (void)updateUI {
	[self updateClearButton];
	[self updateStatusTextField];
	}
	
	
@end
