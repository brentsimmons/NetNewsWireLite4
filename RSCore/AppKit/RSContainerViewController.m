//
//  RSContainerViewController.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/9/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSContainerViewController.h"
#import "RSContainerView.h"


@implementation RSContainerViewController

@synthesize childViewController;

- (id)init {
	return [self initWithNibName:nil bundle:nil];
}


- (void)dealloc {
	[childViewController release];
	[super dealloc];
}


- (void)setChildViewController:(NSViewController *)aViewController {
	if (aViewController == self.childViewController)
		return;
	[childViewController autorelease];
	childViewController = [aViewController retain];
	((RSContainerView *)(self.view)).childViewController = aViewController;
}


- (void)loadView {
	RSContainerView *aContainerView = [[[RSContainerView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)] autorelease];
	[aContainerView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[self setView:aContainerView];
	self.containerView.viewController = self;
}


- (RSContainerView *)containerView {
	return (RSContainerView *)[self view];
}


@end
