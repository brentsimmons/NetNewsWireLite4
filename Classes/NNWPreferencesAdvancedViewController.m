//
//  NNWPreferencesAdvancedViewController.m
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWPreferencesAdvancedViewController.h"


@interface NNWPreferencesAdvancedViewController ()

@property (nonatomic, retain, readwrite) NSToolbarItem *toolbarItem;
@end


@implementation NNWPreferencesAdvancedViewController

@synthesize toolbarItem;

#pragma mark Init

- (id)init {
	self = [self initWithNibName:@"PreferencesAdvanced" bundle:nil];
	if (self == nil)
		return nil;
	toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"PreferencesAdvanced"];
	[toolbarItem setLabel:NSLocalizedStringFromTable(@"Advanced", @"PreferencesAdvanced", @"Toolbar item name")];
	[toolbarItem setImage:[NSImage imageNamed:NSImageNameAdvanced]];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[toolbarItem release];
	[super dealloc];
}


#pragma mark NSViewController

- (void)loadView {
	[super loadView];
}


#pragma mark Actions

#pragma mark SLFullContentViewControllerPlugin

- (NSString *)windowTitle {
	return [self.toolbarItem label];
}



@end
