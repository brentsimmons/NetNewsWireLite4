//
//  NNWPreferencesGeneralViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWPreferencesGeneralViewController.h"
#import "NNWInstapaperCredentialsEditor.h"


@interface NNWPreferencesGeneralViewController ()

@property (nonatomic, retain, readwrite) NSToolbarItem *toolbarItem;
@end


@implementation NNWPreferencesGeneralViewController

@synthesize allowPluginsButton;
@synthesize allowPluginsButtonCell;
@synthesize openLinksButtonCell;
@synthesize toolbarItem;


#pragma mark Init

- (id)init {
	self = [self initWithNibName:@"PreferencesGeneral" bundle:nil];
	if (self == nil)
		return nil;
	toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"PreferencesGeneral"];
	[toolbarItem setLabel:NSLocalizedStringFromTable(@"General", @"PreferencesGeneral", @"Toolbar item name")];
	[toolbarItem setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[openLinksButtonCell release];
	[allowPluginsButtonCell release];
	[allowPluginsButton release];
	[toolbarItem release];
	[super dealloc];
}


#pragma mark NSViewController

- (void)loadView {
	[super loadView];
	[self.openLinksButtonCell setBackgroundColor:[NSColor windowBackgroundColor]];
	[self.allowPluginsButtonCell setBackgroundColor:[NSColor windowBackgroundColor]];
	[self.allowPluginsButton setIntValue:(int)[[WebPreferences standardPreferences] arePlugInsEnabled]];
}


#pragma mark Actions

- (void)pluginsCheckboxClicked:(id)sender {
	[[WebPreferences standardPreferences] setPlugInsEnabled:(BOOL)[sender intValue]];
}


- (void)editInstapaperAccount:(id)sender {
	NNWInstapaperCredentialsEditor *instapaperCredentialsEditor = [[[NNWInstapaperCredentialsEditor alloc] init] autorelease];
	[instapaperCredentialsEditor editInstapaperCredentials];
}


#pragma mark SLFullContentViewControllerPlugin

- (NSString *)windowTitle {
	return [self.toolbarItem label];
}


@end
