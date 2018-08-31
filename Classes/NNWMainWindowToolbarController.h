//
//  NNWMainWindowToolbarController.h
//  nnw
//
//  Created by Brent Simmons on 12/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWMainWindowToolbarController : NSObject <NSToolbarDelegate> {
@private
    NSButton *refreshButton;
    NSMenuItem *shareMenuRepresentation;
    NSMutableArray *pluginCommandIDs;
    NSMutableArray *pluginCommands;
    NSPopUpButton *actionPopupButton;
    NSPopUpButton *articleThemePopupButton;
    NSPopUpButton *sharePopupButton;
    NSProgressIndicator *refreshProgressIndicator;
    NSSegmentedControl *addRemoveSegmentedControl;
    NSToolbar *toolbar;
    NSView *refreshButtonContainerView;
    NSWindow *window;
}

@property (nonatomic, strong) IBOutlet NSWindow *window;

@property (nonatomic, strong) IBOutlet NSView *refreshButtonContainerView;
@property (nonatomic, strong) IBOutlet NSButton *refreshButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *articleThemePopupButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *actionPopupButton;
@property (nonatomic, strong) IBOutlet NSSegmentedControl *addRemoveSegmentedControl;
@property (nonatomic, strong) IBOutlet NSPopUpButton *sharePopupButton;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *refreshProgressIndicator;

@end

