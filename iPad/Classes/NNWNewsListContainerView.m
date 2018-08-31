//
//  NNWNewsListContainerView.m
//  nnwipad
//
//  Created by Brent Simmons on 2/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWNewsListContainerView.h"
#import "NNWAppDelegate.h"


@implementation NNWNewsListContainerView

@synthesize toolbar, tableView;

- (void)layoutSubviews {
	CGRect rToolbar = self.bounds;
	rToolbar.size.height = toolbar.frame.size.height;
	NSInteger rightPaneWidth = app_delegate.rightPaneWidth;
	rToolbar.size.width = rightPaneWidth;
	self.toolbar.frame = CGRectIntegral(rToolbar);
	CGRect rTableView = self.bounds;
	rTableView.origin.y = CGRectGetMaxY(rToolbar);
	rTableView.size.height = self.bounds.size.height - rTableView.origin.y;
	rTableView.size.width = rightPaneWidth;
	self.tableView.frame = CGRectIntegral(rTableView);
}


@end
