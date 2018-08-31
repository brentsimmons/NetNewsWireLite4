//
//  RSContainerWindowController.h
//  nnw
//
//  Created by Brent Simmons on 12/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "SLViewControllerProtocols.h"


/*Preferences-style window, with a toolbar. Each toolbar item corresponds to a different view.
 The toolbar items and views each correspond to a plugin, which supplies the view.
 When a toolbar item is clicked, the corresponding view is swapped in.*/

@interface RSContainerWindowController : NSWindowController <NSToolbarDelegate> {
@private
	NSArray *plugins;
	NSMutableArray *toolbarItems;
	NSToolbar *toolbar;
}


- (id)initWithPlugins:(NSArray *)somePlugins windowNibName:(NSString *)windowNibName;
- (id)initWithPlugins:(NSArray *)somePlugins; //Uses nib named ContainerWindow

/*For subclasses*/

@property (nonatomic, retain) NSArray *plugins;
@property (nonatomic, retain) NSMutableArray *toolbarItems;

- (void)switchToPlugin:(id<SLSelectableViewControllerPlugin>)aPlugin;


@end
