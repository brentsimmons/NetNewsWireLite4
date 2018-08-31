//
//  NNWFeedsContainerView.m
//  nnwipad
//
//  Created by Brent Simmons on 2/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWFeedsContainerView.h"
#import "NNWAppDelegate.h"


@implementation NNWFeedsContainerView

@synthesize toolbar, tableView;

- (void)layoutSubviews {
	CGRect rToolbar = self.bounds;
	rToolbar.size.height = toolbar.frame.size.height;
	rToolbar.size.width = kNNWLeftPaneWidth;
	self.toolbar.frame = CGRectIntegral(rToolbar);
	CGRect rTableView = CGRectZero;//self.bounds;
	rTableView.origin.y = CGRectGetMaxY(rToolbar);
//	rTableView.size.height = self.bounds.size.height - rTableView.origin.y;
	rTableView.size.height = app_delegate.windowHeight - kNNWToolbarHeight;
	rTableView.size.width = kNNWLeftPaneWidth;
	rTableView.origin.x = 0;
	self.tableView.frame = CGRectIntegral(rTableView);
}


@end
