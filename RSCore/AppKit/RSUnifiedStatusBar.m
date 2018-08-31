//
//  NNWStatusBar.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSUnifiedStatusBar.h"
#import "RSAppKitCategories.h"


@implementation RSUnifiedStatusBar

@synthesize hasGrabberOnRight;


- (void)setHasGrabberOnRight:(BOOL)shouldHaveGrabber {
	if (shouldHaveGrabber != hasGrabberOnRight) {
		hasGrabberOnRight = shouldHaveGrabber;
		[self setNeedsDisplay:YES];
	}
}


- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}


static NSColor *statusBarPatternPhaseColor(void) {
	static NSColor *patternColor = nil;
	if (!patternColor) {
		NSRect rBounds = NSMakeRect(0, 0, 400, 23);
		NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(rBounds.size.width, rBounds.size.height)];
		[image lockFocus];
		NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:RSGray(0.79) endingColor:RSGray(0.92)] autorelease];
		[gradient drawInRect:rBounds angle:90.0];
		[NSGraphicsContext saveGraphicsState];
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];;
		NSBezierPath *p = [NSBezierPath bezierPath];
		[p setLineWidth:1.0];
		[p moveToPoint:NSMakePoint(rBounds.origin.x, NSMaxY(rBounds) - 1)];
		[p lineToPoint:NSMakePoint(NSMaxX(rBounds), NSMaxY(rBounds) - 1)];
		[RSGray(0.45) set];
		[p stroke];
		[p removeAllPoints];
		[p moveToPoint:NSMakePoint(rBounds.origin.x, NSMaxY(rBounds) - 2)];
		[p lineToPoint:NSMakePoint(NSMaxX(rBounds), NSMaxY(rBounds) - 2)];
		[RSGray(0.93) set];
		[p stroke];
		[NSGraphicsContext restoreGraphicsState];
		[image unlockFocus];
		patternColor = [[NSColor colorWithPatternImage:image] retain];
		[image release];
	}
	return patternColor;
}


static const NSUInteger kGrabberWidth = 18;

- (void)drawRect:(NSRect)dirtyRect {
	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, 0)];
	[statusBarPatternPhaseColor() set];
	NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
	if (!self.hasGrabberOnRight)
		return;
	NSRect rGrabber = NSMakeRect(NSMaxX([self bounds]) - kGrabberWidth, 0, kGrabberWidth, [self bounds].size.height);
	if (NSIntersectsRect(rGrabber, dirtyRect)) {
		[NSGraphicsContext saveGraphicsState];
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		
		[self rs_setShadowWithBlurRadius:1.0 color:RSGray(0.9) offset:NSMakeSize(1, 0)];
		static NSBezierPath *p = nil;
		if (!p) {
			p = [[NSBezierPath bezierPath] retain];
			[p setLineWidth:1.0];
		}
		NSInteger offsetRight = 6;
		NSInteger distanceBetween = 3;
		NSRect rBounds = rGrabber;
		NSInteger bottomY = (NSInteger)NSMidY(rBounds) - 5;
		NSInteger topY = (NSInteger)NSMidY(rBounds) + 4;
		
		[p removeAllPoints];
		[p moveToPoint:NSMakePoint(NSMaxX(rBounds) - offsetRight, bottomY)];
		[p lineToPoint:NSMakePoint(NSMaxX(rBounds) - offsetRight, topY)];
		[p moveToPoint:NSMakePoint(NSMaxX(rBounds) - (offsetRight + distanceBetween), bottomY)];
		[p lineToPoint:NSMakePoint(NSMaxX(rBounds) - (offsetRight + distanceBetween), topY)];
		[p moveToPoint:NSMakePoint(NSMaxX(rBounds) - (offsetRight + (distanceBetween * 2)), bottomY)];
		[p lineToPoint:NSMakePoint(NSMaxX(rBounds) - (offsetRight + (distanceBetween * 2)), topY)];
		[RSGray(0.25) set];
		[p stroke];
		[NSGraphicsContext restoreGraphicsState];
	}		
}


@end
