//
//  BCCenteredActivityTitleView.m
//  bobcat
//
//  Created by Brent Simmons on 3/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "BCCenteredActivityTitleView.h"


@implementation BCCenteredActivityTitleView

@synthesize offsetX = _offsetX;

#pragma mark Init

- (id)initWithFrame:(CGRect)r {
	if (![super initWithFrame:r])
		return nil;
	_activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	_activityIndicator.hidesWhenStopped = YES;
	[_activityIndicator sizeToFit];
	[self addSubview:_activityIndicator];
	return self;
}


#pragma mark Activity

- (void)startActivity {
	if ([_activityIndicator isAnimating])
		return;
	[_activityIndicator startAnimating];
	_activityIndicator.alpha = 1.0;
}


- (void)stopActivity {
	[_activityIndicator stopAnimating];
}


#pragma mark UIView

- (BOOL)autoresizesSubviews {
	return NO;
}


- (void)layoutSubviews {
	CGRect rActivity = [_activityIndicator frame];
	CGRect rParent = [self superview].bounds;
	CGRect r = self.frame;
	rActivity.origin.x = (((rParent.size.width / 2) - (rActivity.size.width / 2)) - r.origin.x) + _offsetX;
	rActivity.origin.y = ((rParent.size.height / 2) - (rActivity.size.height / 2)) - r.origin.y;
	_activityIndicator.frame = CGRectIntegral(rActivity);
}


@end
