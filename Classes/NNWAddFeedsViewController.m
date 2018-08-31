//
//  NNWAddFeedsViewController.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedsViewController.h"
#import "NNWAddFeedWithURLViewController.h"
#import "NNWAddFeedsContainerView.h"


@interface NNWAddFeedsViewController ()

@property (nonatomic, retain) NSViewController *addFeedWithURLViewController;
@end


@implementation NNWAddFeedsViewController

#pragma mark Init

- (id)init {
	return [self initWithNibName:@"AddFeeds" bundle:nil];
}


#pragma mark NSViewController

- (void)loadView {
	[super loadView];
	self.addFeedWithURLViewController = [[[NNWAddFeedWithURLViewController alloc] init] autorelease];
	[self.addFeedsContainerView addSubview:[self.addFeedWithURLViewController view]];
	[self.addFeedsContainerView resizeSubviewsWithOldSize:NSZeroSize];
}


@end
