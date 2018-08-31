//
//  NNWSourceListPointerWindow.h
//  nnw
//
//  Created by Brent Simmons on 1/2/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*It's a child window with an arrow that points to the thing just
 added to the source list.
 
 The init method takes the point in the window coordinates where
 the thing was just added. The arrow points there.
 
 This could be generalized into a general popover-like thing.
 And it probably will be. This is just a first cut at it.
 
 After creating the window, set the message to display,
 then call NSWindow addChildWindow.*/


@interface NNWSourceListPointerWindow : NSWindow {
@private
	NSPoint pointInWindow;
	NSWindow *parentWindow;
	NSTextField *messageTextField;
}


- (id)initWithPoint:(NSPoint)aPoint inWindow:(NSWindow *)aWindow;

@property (nonatomic, retain) NSString *message;


@end
