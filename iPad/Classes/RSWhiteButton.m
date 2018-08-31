//
//  RSWhiteButton.m
//  nnwipad
//
//  Created by Brent Simmons on 2/14/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSWhiteButton.h"


void RSSetupWhiteButton(UIButton *button) {
	static UIImage *upImage = nil;
	static UIImage *downImage = nil;
	if (upImage == nil)
		upImage = [[[UIImage imageNamed:@"WhiteButton_Up.png"] stretchableImageWithLeftCapWidth:30 topCapHeight:10] retain];
	if (downImage == nil)
		downImage = [[[UIImage imageNamed:@"WhiteButton_Down.png"] stretchableImageWithLeftCapWidth:30 topCapHeight:10] retain];
	[button setBackgroundImage:upImage forState:UIControlStateNormal];
	[button setBackgroundImage:downImage forState:UIControlStateHighlighted];
	[button setBackgroundImage:downImage forState:UIControlStateSelected];
	[button setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateHighlighted];
	[button setTitleColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateSelected];
	[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateSelected];
	button.adjustsImageWhenHighlighted = NO;
	button.showsTouchWhenHighlighted = NO;
	button.titleEdgeInsets = UIEdgeInsetsMake(-1, 0, 1, 0);
	button.reversesTitleShadowWhenHighlighted = NO;
	button.titleLabel.shadowOffset = CGSizeMake(0, 1);
	button.opaque = NO;
	button.backgroundColor = [UIColor clearColor];
	button.clearsContextBeforeDrawing = NO;
	button.contentMode = UIViewContentModeCenter;
}