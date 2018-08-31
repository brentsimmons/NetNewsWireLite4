//
//  RSContainerViewController.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/9/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*A view controller that exists just as a place for swapping in and out other view controllers.
 When you change the childViewController, the childViewController's view appears
 on top of this container's view, resized the same. (See RSContainerView.)*/

@class RSContainerView;

@interface RSContainerViewController : NSViewController {
@private
	NSViewController *childViewController;
}


@property (nonatomic, retain) NSViewController *childViewController;
@property (nonatomic, retain, readonly) RSContainerView *containerView;

//- (void)setChildViewController:(NSViewController *)aViewController animated:(BOOL)animated; //TODO


@end
