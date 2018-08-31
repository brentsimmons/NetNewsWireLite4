//
//  RSLevelIndicatorCell.m
//  NetNewsWire
//
//  Created by Brent Simmons on 5/10/07.
//  Copyright 2007 Ranchero Software. All rights reserved.
//

#import "RSLevelIndicatorCell.h"


@implementation RSLevelIndicatorCell


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSInteger midPoint = (NSInteger)NSMidY(cellFrame);
	cellFrame.size.height = 10;
	cellFrame.origin.y = (NSInteger)(midPoint - ((NSInteger)cellFrame.size.height / 2));
	[super drawWithFrame:cellFrame inView:controlView];
	}


@end
