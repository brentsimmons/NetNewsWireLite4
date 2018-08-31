//
//  NNWDetailToolbar.m
//  nnw
//
//  Created by Brent Simmons on 11/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWDetailToolbar.h"


@implementation NNWDetailToolbar

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)dirtyRect {

	NSRect rBounds = [self bounds];
	NSColor *baseColor = [NSColor orangeColor];
	//	baseColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
	//	baseColor = [NSColor colorWithDeviceRed:217.0f/255.0f green:221.0f/255.0f blue:227.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor colorWithDeviceWhite:168.0f/255.0f alpha:1.0f];
	//	baseColor = [NSColor colorWithDeviceWhite:150.0f/255.0f alpha:0.3f];
	//	baseColor = [NSColor selectedTextBackgroundColor];
	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
	//	baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:225.0f/255.0f green:225.0f/255.0f blue:226.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:188.0f/255.0f green:194.0f/255.0f blue:203.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:164.0f/255.0f green:174.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
	//	baseColor = [NSColor colorWithDeviceWhite:242.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor blueColor];
	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[baseColor shadowWithLevel:0.0f] endingColor:[baseColor highlightWithLevel:0.2f]] autorelease];
	[gradient drawInRect:rBounds angle:-90.0f];

//	static NSColor *backgroundTextureColor = nil;
//	if (backgroundTextureColor == nil)
//		backgroundTextureColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"lightbgraypattern"]] retain];
//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, NSMaxY([self bounds]))];
//	[backgroundTextureColor set];
//	NSRectFillUsingOperation(rBounds, NSCompositeSourceOver);

	
	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0f];
	NSRect r = NSIntegralRect(rBounds);
	r.origin.y = r.origin.y + 0.5f;
	[p moveToPoint:NSMakePoint(NSMinX(r), NSMinY(r) + 1)];
	[p lineToPoint:NSMakePoint(NSMaxX(r), NSMinY(r) + 1)];
	[[NSColor colorWithDeviceWhite:1.0f alpha:0.3f] set];
//	[[NSColor greenColor] set];
	[p stroke];
	
	
	NSBezierPath *p2 = [NSBezierPath bezierPath];
	[p2 setLineWidth:1.0f];
//	r.origin.y = NSMaxY(r);
	[p2 moveToPoint:NSMakePoint(NSMinX(r), NSMinY(r))];
	[p2 lineToPoint:NSMakePoint(NSMaxX(r), NSMinY(r))];
	[[NSColor colorWithDeviceWhite:0.0f alpha:0.3f] set];
//	[[NSColor orangeColor] set];
	[p2 stroke];

	NSBezierPath *p3 = [NSBezierPath bezierPath];
	[p3 setLineWidth:1.0f];
	//	r.origin.y = NSMaxY(r);
	[p3 moveToPoint:NSMakePoint(NSMinX(r) + 0.5f, NSMinY(r) + 1)];
	[p3 lineToPoint:NSMakePoint(NSMinX(r) + 0.5f, NSMaxY(r))];
	[[NSColor colorWithDeviceWhite:1.0f alpha:0.4f] set];
	//	[[NSColor orangeColor] set];
	[p3 stroke];
}


@end
