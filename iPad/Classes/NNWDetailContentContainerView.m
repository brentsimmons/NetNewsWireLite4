//
//  NNWDetailContentContainerView.m
//  nnwipad
//
//  Created by Brent Simmons on 2/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWDetailContentContainerView.h"
#import "NNWAppDelegate.h"


@implementation NNWDetailContentContainerView

@synthesize toolbar;
@synthesize contentView;


#pragma mark Dealloc

- (void)dealloc {
	[toolbar release];
	[contentView release];
	[super dealloc];
}


#pragma mark Content View

- (void)setContentView:(UIView *)aContentView {
	if (contentView == aContentView)
		return;
	[contentView removeFromSuperview];
	[contentView autorelease];
	contentView = [aContentView retain];
	[self addSubview:contentView];
	[self setNeedsLayout];
	//TODO: animate swapping in/out the contentView
}


#pragma mark Layout

- (void)layoutSubviews {
	CGRect r = self.bounds;
	CGRect rToolbar = self.toolbar.frame;
	rToolbar.origin.x = 0;
	rToolbar.origin.y = 0;
	self.toolbar.frame = CGRectIntegral(rToolbar);
	CGRect rContentView = r;
	rContentView.origin.x = 0;
	rContentView.origin.y = CGRectGetMaxY(rToolbar);
	rContentView.size.height = CGRectGetHeight(r) - rContentView.origin.y;
	self.contentView.frame = rContentView;
}


@end
