/*
 RSSolidColorView.m
 NetNewsWire
 
 Created by Brent Simmons on 12/17/04.
 Copyright 2004 Ranchero Software. All rights reserved.
 */


#import "RSSolidColorView.h"


@implementation RSSolidColorView


- (NSColor *)backgroundColor {
	if (!backgroundColor)
		self.backgroundColor = [NSColor colorWithCalibratedRed:0.607843137255 green:0.788235294118 blue:1.0 alpha:1.0];
	return backgroundColor;
}


- (void)setBackgroundColor:(NSColor *)color {
	if ([color isEqual:backgroundColor])
		return;
	[backgroundColor autorelease];
	backgroundColor = [color retain];
	[self setNeedsDisplay:YES];
}


- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {
	[self.backgroundColor set];
	NSRectFillUsingOperation(r, NSCompositeSourceOver);
}


@end
