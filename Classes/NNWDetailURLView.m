//
//  NNWDetailURLView.m
//  nnw
//
//  Created by Brent Simmons on 11/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWDetailURLView.h"


@implementation NNWDetailURLView

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return NO;
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	NSTextField *textField = (NSTextField *)[self rs_firstSubviewOfClass:[NSTextField class]];
	[[textField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	NSRect rBounds = [self bounds];

	NSColor *baseColor = [NSColor orangeColor];
	baseColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
	//	baseColor = [NSColor colorWithDeviceRed:217.0f/255.0f green:221.0f/255.0f blue:227.0f/255.0f alpha:1.0f];
//	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
//	baseColor = [NSColor colorWithDeviceWhite:168.0f/255.0f alpha:1.0f];
//	//	baseColor = [NSColor colorWithDeviceWhite:150.0f/255.0f alpha:0.3f];
//	baseColor = [NSColor selectedTextBackgroundColor];
//	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
////	//baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
////	baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
//////	baseColor = [NSColor colorWithDeviceRed:225.0f/255.0f green:225.0f/255.0f blue:226.0f/255.0f alpha:1.0f];
//////	baseColor = [NSColor colorWithDeviceRed:188.0f/255.0f green:194.0f/255.0f blue:203.0f/255.0f alpha:1.0f];
//////	baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
//////	baseColor = [NSColor colorWithDeviceRed:164.0f/255.0f green:174.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
//////	baseColor = [NSColor colorWithDeviceRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
////	baseColor = [NSColor colorWithDeviceWhite:242.0f/255.0f alpha:1.0f];
////	baseColor = [NSColor colorWithDeviceWhite:64.0f/255.0f alpha:1.0f];
//	//baseColor = [NSColor blueColor];
//
//	
//	baseColor = [NSColor colorWithDeviceRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
//	
//	baseColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
	
	
	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[baseColor highlightWithLevel:0.0f] endingColor:[baseColor highlightWithLevel:0.6f]] autorelease];
	[gradient drawInRect:rBounds angle:90.0f];

	
	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0f];
	NSRect r = NSIntegralRect(rBounds);
	r.origin.y = r.origin.y - 0.5f;
	[p moveToPoint:NSMakePoint(NSMinX(r), NSMaxY(r) - 1.0f)];
	[p lineToPoint:NSMakePoint(NSMaxX(r), NSMaxY(r) - 1.0f)];
	//[[NSColor colorWithDeviceWhite:1.0f alpha:0.3f] set];
	//[[NSColor greenColor] set];
	//[p stroke];
	
	
	[self rs_setShadowWithBlurRadius:10.0f color:[NSColor colorWithDeviceWhite:0.0f alpha:1.0f] offset:NSMakeSize(0.0f, -1.0f)];
	NSBezierPath *p2 = [NSBezierPath bezierPath];
	[p2 setLineWidth:1.0f];
	//	r.origin.y = NSMaxY(r);
	[p2 moveToPoint:NSMakePoint(NSMinX(r), NSMaxY(r))];
	[p2 lineToPoint:NSMakePoint(NSMaxX(r), NSMaxY(r))];
	[[NSColor colorWithDeviceWhite:0.0f alpha:0.1f] set];
	//[[NSColor orangeColor] set];
	[p2 stroke];
}


@end
