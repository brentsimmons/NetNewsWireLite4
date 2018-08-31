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

@property (nonatomic, retain) IBOutlet NSWindow *window;

@property (nonatomic, retain) IBOutlet NSView *refreshButtonContainerView;
@property (nonatomic, retain) IBOutlet NSButton *refreshButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *articleThemePopupButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *actionPopupButton;
@property (nonatomic, retain) IBOutlet NSSegmentedControl *addRemoveSegmentedControl;
@property (nonatomic, retain) IBOutlet NSPopUpButton *sharePopupButton;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *refreshProgressIndicator;

@end

