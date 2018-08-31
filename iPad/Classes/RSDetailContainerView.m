//
//  RSDetailContainerView.m
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDetailContainerView.h"


@interface RSDetailContainerView ()

@property (nonatomic, retain) UIView *previousContentView;

@end


@implementation RSDetailContainerView

@synthesize contentView;
@synthesize previousContentView;

#pragma mark Dealloc

- (void)dealloc {
	[contentView release];
	[super dealloc];
}


#pragma mark Content View

- (void)viewSwapAnimationDidComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	[self.previousContentView removeFromSuperview];
	self.previousContentView.alpha = 1.0f; //it may get used again
	self.previousContentView = nil;
}


- (void)setContentView:(UIView *)aContentView {
	if (contentView == aContentView)
		return;
	if (contentView != nil) {
		self.previousContentView = contentView;
		[contentView autorelease];
	}
	contentView = [aContentView retain];
	contentView.frame = self.bounds;
	if (self.previousContentView == nil)
		[self addSubview:contentView];
	else {
		[self insertSubview:contentView belowSubview:self.previousContentView];
		contentView.alpha = 1.0f;
		if ([self.previousContentView respondsToSelector:@selector(makeWebviewTransparent)])
			[self.previousContentView performSelector:@selector(makeWebviewTransparent)];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.2f];
		[UIView setAnimationDelegate:self]; 
		[UIView setAnimationDidStopSelector:@selector(viewSwapAnimationDidComplete:finished:context:)];
		self.previousContentView.alpha = 0.0f;
		[UIView commitAnimations];		
	}
	[self setNeedsLayout];
}



@end
