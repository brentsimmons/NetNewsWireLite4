//
//  SLViewControllerProtocols.h
//  nnw
//
//  Created by Brent Simmons on 12/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol SLViewControllerPlugin <NSObject>

/*The plugin should be a subclass of NSViewController.*/

@required
- (NSView *)view;

@end


@protocol SLFullContentViewControllerPlugin <SLViewControllerPlugin>

@required
@property (readonly) NSString *windowTitle; //Might get observed via KVO

@end


@protocol SLSelectableViewControllerPlugin <SLFullContentViewControllerPlugin>

@required
@property (readonly) NSToolbarItem *toolbarItem;

/*Note: ideally you could create the toolbarItem in your xib file, and this would work fine --
 but there's a timing issue with loading nibs. Instead, create the toolbarItem in code.
 Don't forget to give the toolbarItem an image and an identifier.
 
 Tip: windowTitle can just be [toolbarItem label].*/

@optional
@property (readonly) BOOL isGroupItem; //Might become a separator, for instance

@end
