//
//  NNWMainWindowToolbarController.m
//  nnw
//
//  Created by Brent Simmons on 12/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NNWMainWindowToolbarController.h"
#import "NNWAppDelegate.h"
#import "NNWStyleSheetController.h"
#import "RSPluginManager.h"


//static NSString *NNWToolbarItemAction = @"NNWToolbarItemAction";
static NSString *NNWToolbarItemAddRemove = @"NNWToolbarItemAddRemove";
static NSString *NNWToolbarItemArticleTheme = @"NNWToolbarItemArticleTheme";
static NSString *NNWToolbarItemMarkAllAsRead = @"NNWToolbarItemMarkAllAsRead";
static NSString *NNWToolbarItemNewFolder = @"NNWToolbarItemNewFolder";
static NSString *NNWToolbarItemNextUnread = @"NNWToolbarItemNextUnread";
static NSString *NNWToolbarItemRefresh = @"NNWToolbarToolbarItemRefresh";
static NSString *NNWToolbarItemShare = @"NNWToolbarItemShare";


@interface NNWArticleThemeToolbarItem : NSToolbarItem {
@private
    NSMenuItem *menuItem;
}

@property (nonatomic, strong) NSMenuItem *menuItem;
@end


@interface NNWMainWindowToolbarController ()


@property (nonatomic, strong) NSMutableArray *pluginCommandIDs;
@property (nonatomic, strong) NSMutableArray *pluginCommands;
@property (nonatomic, strong) NSToolbar *toolbar;
@property (nonatomic, strong) NSMenuItem *shareMenuRepresentation;

- (void)setupToolbar;

@end


@implementation NNWMainWindowToolbarController


@synthesize actionPopupButton;
@synthesize addRemoveSegmentedControl;
@synthesize articleThemePopupButton;
@synthesize pluginCommandIDs;
@synthesize pluginCommands;
@synthesize refreshButton;
@synthesize refreshButtonContainerView;
@synthesize refreshProgressIndicator;
@synthesize sharePopupButton;
@synthesize toolbar;
@synthesize window;
@synthesize shareMenuRepresentation;

#pragma mark Dealloc



#pragma mark AwakeFromNib

- (void)awakeFromNib {
    [self setupToolbar];
}


#pragma mark Toolbar

- (void)setupToolbar {
    
    self.toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainWindowToolbar"];
    [self.toolbar setDelegate:self];
    [self.toolbar setAllowsUserCustomization:YES];
    [self.toolbar setAutosavesConfiguration:YES];
    [self.toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    
    [nnw_app_delegate addSharingCommandsToMenu:[self.sharePopupButton menu] includeGroupTitles:NO includeKeyboardShortcuts:NO];
    
    self.shareMenuRepresentation = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Share", @"Share menu") action:nil keyEquivalent:@""];
    NSMenu *shareSubmenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Share", @"Share menu")];
    [nnw_app_delegate addSharingCommandsToMenu:shareSubmenu includeGroupTitles:NO includeKeyboardShortcuts:NO];
    [self.shareMenuRepresentation setSubmenu:shareSubmenu];
    [self.shareMenuRepresentation setState:NSOffState];
    
    [self.refreshProgressIndicator setUsesThreadedAnimation:YES];    
    [self.window setToolbar:self.toolbar];
}


- (void)addPluginCommands:(NSArray *)somePluginCommands toArray:(NSMutableArray *)anArray {
    for (id<RSPluginCommand> onePluginCommand in somePluginCommands) {
        if ([onePluginCommand respondsToSelector:@selector(image)] && [onePluginCommand respondsToSelector:@selector(title)])
            [anArray addObject:onePluginCommand];
    }    
}


- (NSMutableArray *)pluginCommands {
    
    if (pluginCommands != nil)
        return pluginCommands;
    
    NSMutableArray *tempArray = [NSMutableArray array];
    NSArray *sharingPluginCommands = [[RSPluginManager sharedManager] orderedPluginCommandsOfType:RSPluginCommandTypeSharing];
    [self addPluginCommands:sharingPluginCommands toArray:tempArray];
    
    NSArray *openInViewerPluginCommands = [[RSPluginManager sharedManager]  orderedPluginCommandsOfType:RSPluginCommandTypeOpenInViewer];
    [self addPluginCommands:openInViewerPluginCommands toArray:tempArray];
    
    pluginCommands = tempArray;
    return pluginCommands;
}


- (NSMutableArray *)pluginCommandIDs {
    
    if (pluginCommandIDs != nil)
        return pluginCommandIDs;
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for (id<RSPluginCommand> onePluginCommand in self.pluginCommands) {
        if ([onePluginCommand respondsToSelector:@selector(commandID)] && !RSStringIsEmpty(onePluginCommand.commandID))
            [tempArray addObject:onePluginCommand.commandID];
    }
    
    pluginCommandIDs = tempArray;
    return pluginCommandIDs;
}


- (NSToolbarItem *)toolbarItemForPluginCommand:(id<RSPluginCommand>)aPluginCommand {
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:aPluginCommand.commandID];
    [toolbarItem setImage:aPluginCommand.image];
    [toolbarItem setLabel:aPluginCommand.title];
    [toolbarItem setPaletteLabel:aPluginCommand.title];
    if ([aPluginCommand respondsToSelector:@selector(tooltip)])
        [toolbarItem setToolTip:aPluginCommand.tooltip];
    [toolbarItem setAction:@selector(performSharingPluginCommandWithSender:)];
    return toolbarItem;
}


- (NSToolbarItem *)pluginItemWithItemIdentifier:(NSString *)itemIdentifier {
    
    if (RSStringIsEmpty(itemIdentifier))
        return nil;
    
    for (id<RSPluginCommand> onePluginCommand in self.pluginCommands) {
        if ([onePluginCommand.commandID isEqualToString:itemIdentifier])
            return [self toolbarItemForPluginCommand:onePluginCommand];
    }

    return nil;
}


- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {

    if ([itemIdentifier isEqualToString:NNWToolbarItemRefresh]) {
        NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemRefresh];
        [toolbarItem setView:self.refreshButtonContainerView];
        [self.refreshButton setAction:@selector(refreshAll:)];
        [toolbarItem setLabel:NSLocalizedString(@"Refresh", @"Command")];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:NSLocalizedString(@"Refresh all feeds", @"Refresh tooltip")];
        return toolbarItem;
    }
    
    if ([itemIdentifier isEqualToString:NNWToolbarItemArticleTheme]) {
        NNWArticleThemeToolbarItem *toolbarItem = [[NNWArticleThemeToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemArticleTheme];
        [toolbarItem setView:self.articleThemePopupButton];
        [toolbarItem setLabel:NSLocalizedString(@"Article Style", @"Command")];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:NSLocalizedString(@"Choose a style for the articles", @"Article style tooltip")];
        return toolbarItem;
    }

//    if ([itemIdentifier isEqualToString:NNWToolbarItemAction]) {
//        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemAction] autorelease];
//        [toolbarItem setView:self.actionPopupButton];
//        [toolbarItem setLabel:NSLocalizedString(@"Action", @"Command")];
//        [toolbarItem setPaletteLabel:[toolbarItem label]];
//        [toolbarItem setToolTip:NSLocalizedString(@"Perform tasks with the selected item", @"Action menu tooltip")];
//        return toolbarItem;
//    }

    if ([itemIdentifier isEqualToString:NNWToolbarItemAddRemove]) {
        NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemAddRemove];
        [toolbarItem setView:self.addRemoveSegmentedControl];
        [toolbarItem setLabel:NSLocalizedString(@"Add/Remove", @"Command")];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:NSLocalizedString(@"Add and remove feeds", @"Add/Remove feeds tooltip")];
        [self.addRemoveSegmentedControl setAction:@selector(addRemoveSegmentedControlClicked:)];
        [self.addRemoveSegmentedControl setTarget:self];
        return toolbarItem;
    }

    if ([itemIdentifier isEqualToString:NNWToolbarItemShare]) {
        NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemShare];
        [toolbarItem setView:self.sharePopupButton];
        [toolbarItem setLabel:NSLocalizedString(@"Share", @"Command")];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:NSLocalizedString(@"Share the selected article on the web", @"Share tooltip")];
        [toolbarItem setMenuFormRepresentation:self.shareMenuRepresentation];
        return toolbarItem;
    }

    if ([itemIdentifier isEqualToString:NNWToolbarItemNextUnread]) {
        NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemNextUnread];
        [toolbarItem setImage:[NSImage imageNamed:@"toolbar_main_nextUnread"]];
        [toolbarItem setAction:@selector(nextUnread:)];
        [toolbarItem setLabel:NSLocalizedString(@"Next Unread", @"Command")];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:NSLocalizedString(@"Go to the next unread article", @"Next unread tooltip")];
        return toolbarItem;
    }
    
    if ([itemIdentifier isEqualToString:NNWToolbarItemMarkAllAsRead]) {
        NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemMarkAllAsRead];
        [toolbarItem setImage:[NSImage imageNamed:@"toolbar_main_markAllAsRead"]];
        [toolbarItem setLabel:NSLocalizedString(@"Mark All as Read", @"Command")];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:NSLocalizedString(@"Mark all articles in the list as read", @"Mark All as Read tooltip")];
        [toolbarItem setAction:@selector(markAllAsRead:)];
        return toolbarItem;
    }

    if ([itemIdentifier isEqualToString:NNWToolbarItemNewFolder]) {
        NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:NNWToolbarItemNewFolder];
        [toolbarItem setImage:[NSImage imageNamed:@"toolbar_main_newFolder"]];
        [toolbarItem setLabel:NSLocalizedString(@"New Folder", @"Command")];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:NSLocalizedString(@"Add a new folder to your feeds list", @"New folder tooltip")];
        [toolbarItem setAction:@selector(addFolder:)];
        return toolbarItem;
    }
    
    return [self pluginItemWithItemIdentifier:itemIdentifier];
//    return nil;
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:NSToolbarSpaceItemIdentifier, NNWToolbarItemAddRemove, NNWToolbarItemRefresh, NSToolbarFlexibleSpaceItemIdentifier, NNWToolbarItemMarkAllAsRead, NNWToolbarItemNextUnread, NSToolbarSpaceItemIdentifier, NNWToolbarItemShare, NSToolbarFlexibleSpaceItemIdentifier, NNWToolbarItemArticleTheme, nil];
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    NSMutableArray *allowedItemIdentifiers = [NSMutableArray array];
    NSArray *builtinItemIdentifiers = [NSArray arrayWithObjects:NNWToolbarItemAddRemove, NNWToolbarItemNewFolder, NNWToolbarItemRefresh, /*NNWToolbarItemAction,*/ NNWToolbarItemMarkAllAsRead, NNWToolbarItemNextUnread, NNWToolbarItemShare, NNWToolbarItemArticleTheme, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
    [allowedItemIdentifiers addObjectsFromArray:builtinItemIdentifiers];
    [allowedItemIdentifiers addObjectsFromArray:self.pluginCommandIDs];
    return allowedItemIdentifiers;
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return nil;
}


#pragma mark Actions

static const NSInteger kSegmentedControlAddFeed = 0;
static const NSInteger kSegmentedControlAddFolder = 1;

- (void)addRemoveSegmentedControlClicked:(id)sender {
    NSInteger indexOfClickedButton = [(NSSegmentedControl *)sender selectedSegment];
    if (indexOfClickedButton == kSegmentedControlAddFeed)
        [NSApp sendAction:@selector(addFeed:) to:nil from:sender];
    else if (indexOfClickedButton == kSegmentedControlAddFolder)
        [NSApp sendAction:@selector(deleteSelectedFeedsAndFolders:) to:nil from:sender];
}
         
         

@end


@implementation NNWArticleThemeToolbarItem

@synthesize menuItem;

#pragma mark Dealloc



#pragma mark Menu

- (void)switchToStyleSheet:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[sender representedObject] forKey:NNWStyleSheetDefaultsNameKey];
}


- (void)addStylesToMenu:(NSMenu *)aMenu {
    
    NSString *selectedStyleSheetName = [[NSUserDefaults standardUserDefaults] objectForKey:NNWStyleSheetDefaultsNameKey];
    
    for (NSString *oneStyleSheetName in [NNWStyleSheetController sharedController].styleSheetNames) {
        NSMenuItem *oneStyleSheetItem = [[NSMenuItem alloc] initWithTitle:oneStyleSheetName action:@selector(switchToStyleSheet:) keyEquivalent:@""];
        [oneStyleSheetItem setTarget:self];
        [oneStyleSheetItem setRepresentedObject:oneStyleSheetName];
        
        if ([oneStyleSheetName isEqualToString:selectedStyleSheetName])
            [oneStyleSheetItem setState:NSOnState];
        else
            [oneStyleSheetItem setState:NSOffState];
        [aMenu addItem:oneStyleSheetItem];
    }
}


- (NSMenuItem *)menuFormRepresentation {
    
    if (!self.menuItem)
        self.menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Article Style", @"Command") action:nil keyEquivalent:@""];

    NSMenu *submenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Article Style", @"Command")];
    
    [self addStylesToMenu:submenu];
    [self.menuItem setSubmenu:submenu];
    [self.menuItem setState:NSOffState];
    return self.menuItem;
}


@end
