//
//  NNWAddFeedsListView.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedsListView.h"


@implementation NNWAddFeedsListView

- (void)drawRect:(NSRect)r {

	static NSColor *backgroundColor = nil;
	if (backgroundColor == nil)
		backgroundColor = [[NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f] retain];
	[backgroundColor set];
	NSRectFillUsingOperation(r, NSCompositeSourceOver);
}


@end
