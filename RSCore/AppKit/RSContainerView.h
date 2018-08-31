//
//  RSContainerView.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/9/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*Manages a single view controller and view pair. The childView is resized to fit exactly the size of this view.*/

@interface RSContainerView : NSView {
@private
	NSViewController *viewController;
	NSViewController *childViewController;
	NSView *childView;
	NSColor *backgroundColor;
}


@property (nonatomic, assign) NSViewController *viewController;
@property (nonatomic, retain) NSViewController *childViewController;

@property (nonatomic, retain) NSColor *backgroundColor;

@end
