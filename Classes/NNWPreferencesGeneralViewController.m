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

@property (nonatomic, strong, readwrite) NSToolbarItem *toolbarItem;
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
    NNWInstapaperCredentialsEditor *instapaperCredentialsEditor = [[NNWInstapaperCredentialsEditor alloc] init];
    [instapaperCredentialsEditor editInstapaperCredentials];
}


#pragma mark SLFullContentViewControllerPlugin

- (NSString *)windowTitle {
    return [self.toolbarItem label];
}


@end
