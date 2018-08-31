//
//  NNWFeedsTableBackgroundView.m
//  nnwipad
//
//  Created by Brent Simmons on 2/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWFeedsTableBackgroundView.h"


@implementation NNWFeedsTableBackgroundView

- (void)drawRect:(CGRect)rect {
	static UIColor *backgroundColor = nil;
	if (backgroundColor == nil)
		backgroundColor = [[UIColor colorWithWhite:0.99 alpha:1.0] retain];
	[backgroundColor set];
	UIRectFill(rect);
	[[UIImage imageNamed:@"LastFeedShadow.png"] drawAtPoint:self.bounds.origin];
}


@end
