//
//  RSContainerWindowController.m
//  nnw
//
//  Created by Brent Simmons on 12/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSContainerWindowController.h"
#import "SLViewControllerProtocols.h"


@interface RSContainerWindowController ()

@property (nonatomic, retain) NSToolbar *toolbar;

- (void)switchToPlugin:(id<SLSelectableViewControllerPlugin>)aPlugin;
- (void)setupToolbar;

@end


@implementation RSContainerWindowController

@synthesize plugins;
@synthesize toolbar;
@synthesize toolbarItems;


#pragma mark Init

- (id)initWithPlugins:(NSArray *)somePlugins windowNibName:(NSString *)windowNibName {
	self = [super initWithWindowNibName:windowNibName];
	if (self == nil)
		return nil;
	NSParameterAssert(somePlugins != nil && [somePlugins count] > 0);
	plugins = [somePlugins retain];
	return self;	
}


- (id)initWithPlugins:(NSArray *)somePlugins {
	return [self initWithPlugins:somePlugins windowNibName:@"ContainerWindow"];
}


#pragma mark Dealloc

- (void)dealloc {
	[plugins release];
	[toolbarItems release];
	[toolbar release];
	[super dealloc];
}


#pragma mark NSWindowController

- (void)windowDidLoad {
	[self setupToolbar];
	[self switchToPlugin:[self.plugins objectAtIndex:0]];
}


#pragma mark View Controller Switching

- (void)resizeWindowToFitView:(NSView *)aView {
	NSRect viewRect = [aView frame];
	NSRect windowRect = [self.window frame];
	NSRect contentViewRect = [[self.window contentView] frame];
	CGFloat deltaHeight = contentViewRect.size.height - viewRect.size.height;
	CGFloat heightForWindow = windowRect.size.height - deltaHeight;
	CGFloat yForWindow = windowRect.origin.y + deltaHeight;
	windowRect.size.height = heightForWindow;
	windowRect.origin.y = yForWindow;
	viewRect.origin.y = 0;
	viewRect.origin.x = 0;
	[aView setFrame:viewRect];
	windowRect.size.width = viewRect.size.width;
	if (!NSEqualRects([self.window frame], windowRect))
		[self.window setFrame:windowRect display:YES animate:YES];
	viewRect.origin.y = 0;
	viewRect.origin.x = 0;
	[aView setFrame:viewRect];
}


- (NSView *)currentView {
	NSArray *subviewsOfContentView = [self.window.contentView subviews];
	if (RSIsEmpty(subviewsOfContentView))
		return nil;
	return [subviewsOfContentView objectAtIndex:0];
}


- (void)switchToPlugin:(id<SLSelectableViewControllerPlugin>)aPlugin {
	NSView *currentView = [self currentView];
	[aPlugin.view setNextResponder:(NSResponder *)aPlugin];
	[(NSResponder *)aPlugin setNextResponder:[self.window contentView]];
	if (aPlugin.view == currentView) {
		[[self window] makeFirstResponder:aPlugin.view];
		return;		
	}
	[self.window setTitle:aPlugin.windowTitle];
	[self resizeWindowToFitView:aPlugin.view];
	if (currentView != nil)
		[[self.window.contentView animator] replaceSubview:currentView with:aPlugin.view];
	else
		[self.window.contentView addSubview:aPlugin.view];
	[aPlugin.view setNextResponder:(NSResponder *)aPlugin];
	[(NSResponder *)aPlugin setNextResponder:[self.window contentView]];
	[[self window] makeFirstResponder:aPlugin.view];
}


#pragma mark Toolbar

- (void)toolbarItemClicked:(id)sender {
	
	/*Sender should be the toolbarItem. Find plugin with that toolbarItem, then we know what plugin to switch to.*/
	
	id<SLSelectableViewControllerPlugin> pluginToSwitchTo = nil;
	
	for (id<SLSelectableViewControllerPlugin> onePlugin in self.plugins) {
		NSAssert(onePlugin.toolbarItem != nil, @"onePlugin.toolbarItem is nil");
		if (onePlugin.toolbarItem == sender) {
			pluginToSwitchTo = onePlugin;
			break;
		}
	}
	
	NSAssert(pluginToSwitchTo != nil, @"Found a toolbar item without a plugin.");
	[self switchToPlugin:pluginToSwitchTo];
}


- (void)setupToolbar {
	NSMutableArray *pluginToolbarItems = [NSMutableArray array];
	for (id<SLSelectableViewControllerPlugin> onePlugin in self.plugins) {
		[onePlugin.toolbarItem setAction:@selector(toolbarItemClicked:)];
		[onePlugin.toolbarItem setTarget:nil];
		NSAssert(onePlugin.toolbarItem != nil, @"onePlugin.toolbarItem is nil");
		[pluginToolbarItems addObject:onePlugin.toolbarItem];
	}
	self.toolbarItems = pluginToolbarItems;

	self.toolbar = [[[NSToolbar alloc] initWithIdentifier:@"PreferencesToolbar"] autorelease];
	[self.toolbar setDelegate:self];
	[self.toolbar setAllowsUserCustomization:NO];
	[self.toolbar setAutosavesConfiguration:NO];
	[self.toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[self.toolbar setSelectedItemIdentifier:[[self.toolbarItems objectAtIndex:0] itemIdentifier]];
	[self.window setToolbar:self.toolbar];
	[self.window setShowsToolbarButton:NO];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	for (NSToolbarItem *oneToolbarItem in self.toolbarItems) {
		if ([[oneToolbarItem itemIdentifier] isEqualToString:itemIdentifier])
			return oneToolbarItem;
	}
	return nil;
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [self.toolbarItems valueForKey:@"itemIdentifier"];
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [self.toolbarItems valueForKey:@"itemIdentifier"];
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [self.toolbarItems valueForKey:@"itemIdentifier"];
}


@end

