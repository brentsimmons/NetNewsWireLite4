//
//  NNWVerticalScroller.m
//  nnw
//
//  Created by Brent Simmons on 11/27/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWVerticalScroller.h"



@implementation NNWVerticalScroller

static CGFloat kKnobRadius = 5.0f;

- (void)drawKnob {
	
	
//	[[NSColor blueColor] set];
//	//NSRectFill(r);
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);

	CGContextSetBlendMode(context, kCGBlendModeNormal);
	NSRect r = [self rectForPart:NSScrollerKnob];
	r.origin.y = r.origin.y - 1.0f;
	r.size.height = r.size.height + 2.0f;
	r.origin.x = r.origin.x + 1.0f;
	r.size.width = r.size.width - 2.0f;
	r = NSIntegralRect(r);
	r.origin.x = r.origin.x + 0.5;
	r.origin.y = r.origin.y + 0.5;
	r.size.height = r.size.height - 1.0f;
	r.size.width = r.size.width - 1.0f;
	
	//	strokeColor = [[[NSColor colorWithDeviceRed:132.0f/255.0f green:142.0f/255.0f blue:166.0f/255.0f alpha:1.0f] shadowWithLevel:0.2f] retain];

	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:r xRadius:kKnobRadius yRadius:kKnobRadius];
	[path addClip];

	static NSColor *baseColor = nil;
	if (baseColor == nil)
		baseColor = [[[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.4f] retain];

	static NSColor *strokeColor = nil;
	if (strokeColor == nil)
	//strokeColor = [[NSColor colorWithDeviceWhite:0.85 alpha:1.0] retain];
		strokeColor = [[baseColor shadowWithLevel:0.0f] retain];
	
	static NSColor *color1 = nil;
	static NSColor *color2 = nil;
	static NSColor *color3 = nil;
	static NSColor *color4 = nil;
//	if (color1 == nil)
//				  // color1 = [[NSColor colorWithDeviceRed:181.0f/255.0f green:190.0f/255.0f blue:204.0f/255.0f alpha:1.0f] retain];
//		   color1 = [[NSColor colorWithDeviceRed:0.88f green:0.89f blue:0.9f alpha:1.0f] retain];
//	if (color2 == nil)
//		color2 = [[NSColor colorWithDeviceRed:0.90f green:0.91f blue:0.92f alpha:1.0f] retain];
//	if (color3 == nil)
//		color3 = [[NSColor colorWithDeviceRed:0.94f green:0.94f blue:0.94f alpha:1.0f] retain];
//	if (color4 == nil)
//		color4 = [[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] retain];

	if (color1 == nil)
		// color1 = [[NSColor colorWithDeviceRed:181.0f/255.0f green:190.0f/255.0f blue:204.0f/255.0f alpha:1.0f] retain];
		color1 = [[baseColor highlightWithLevel:0.2f] retain];
	if (color2 == nil)
		color2 = [[baseColor highlightWithLevel:0.4f] retain];
	if (color3 == nil)
		color3 = [[baseColor highlightWithLevel:0.5f] retain];
	if (color4 == nil)
		color4 = [[baseColor highlightWithLevel:0.7f] retain];

	static NSGradient *knobGradient = nil;
	if (knobGradient == nil)
		//knobGradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor orangeColor], 0.0f, [NSColor greenColor], 0.5f, [NSColor blackColor], 1.0f, nil];
		knobGradient = [[NSGradient alloc] initWithColorsAndLocations:color1, 0.0f, color2, 0.45f, color3, 0.45f, color4, 1.0f, nil];
		//knobGradient = [[NSGradient alloc] initWithStartingColor:color1 endingColor:color2];
//	[[NSColor blackColor] set];
//	NSRectFill(r);
	CGContextSetAlpha(context, 1.0f);
	[knobGradient drawInRect:r angle:180.0f];
//	[[strokeColor highlightWithLevel:0.4f] set];
//	NSRectFill(r);

	CGContextSetAlpha(context, 1.0f);
//	static NSColor *backgroundTextureColor = nil;
//	if (backgroundTextureColor == nil)
//		backgroundTextureColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"bluepattern"]] retain];
//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, NSMaxY([self bounds]))];
//	[backgroundTextureColor set];
//	NSRectFillUsingOperation(r, NSCompositeSourceOver);

//	CGContextSetAlpha(context, 0.7f);
//	[knobGradient drawInRect:r angle:0.0f];
	
//	NSImage *knobImage = [NSImage imageNamed:@"knob"];
//	[knobImage drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.6f];
	CGContextRestoreGState(context);
	
	[strokeColor set];
	[path setLineWidth:1.0f];
	[path stroke];
//	[p moveToPoint:NSMakePoint(NSMidX(r), NSMinY(r))];
//	[p lineToPoint:NSMakePoint(NSMidX(r), NSMaxY(r))];
//	[p setLineCapStyle:NSRoundLineCapStyle];
//	[[NSColor lightGrayColor] set];
//	[p stroke];
}


//- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag {
//	[super drawKnobSlotInRect:slotRect highlight:flag];
//	
//	NSBezierPath *p = [NSBezierPath bezierPath];
//	[p setLineWidth:1.0f];
//	[p moveToPoint:NSMakePoint(NSMaxX(slotRect) + 1.0f, NSMinY(slotRect))];
//	[p lineToPoint:NSMakePoint(NSMaxX(slotRect) + 1.0f, NSMaxY(slotRect))];
//
//	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//	CGContextSaveGState(context);
//
//	[[NSColor colorWithDeviceWhite:0.3 alpha:1.0f] set];
//	static CGColorRef shadowColor = nil;
//	if (shadowColor == nil)
//		shadowColor = CGColorCreateGenericGray(0.0f, 0.7f);	
//	CGContextSetShadowWithColor(context, CGSizeMake(-2.0f, 0.0f), 5.0f, shadowColor);
//
//	[p stroke];
//
//	CGContextRestoreGState(context);
//
//	
////	NSRect r = [self rectForPart:NSScrollerKnob];
////	NSRectFill([self bounds]);
////	NSImage *backgroundImage = [NSImage imageNamed:@"scrollerBackground"];
////	[backgroundImage drawInRect:slotRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
////	NSColor *aColor = self.backgroundColor;
////	if (aColor == nil)
////		aColor = [NSColor whiteColor];
////	[aColor set];
////	NSRectFill([self bounds]);
//	
//}


//- (NSScrollArrowPosition)arrowsPosition {
//	return NSScrollerArrowsNone;
//}

//- (void)drawArrow:(NSScrollerArrow)arrow highlight:(BOOL)highlight {
//	if (arrow == NSScrollerIncrementArrow && highlight)
//		[[NSColor cyanColor] set];
//	else if (arrow == NSScrollerIncrementArrow && !highlight)
//		[[NSColor blackColor] set];
//	else if (arrow == NSScrollerDecrementArrow && highlight)
//		[[NSColor magentaColor] set];
//	else if (arrow == NSScrollerDecrementArrow && !highlight)
//		[[NSColor greenColor] set];
//	NSRectFill([self bounds]);
//}

- (BOOL)isOpaque {
	return YES;
}


//- (NSColor *)backgroundColor {
//	NSColor *backgroundColor = nil;
//	NSView *nomad = [self superview];
//	while ((nomad != nil)) {
//		if ([nomad respondsToSelector:@selector(backgroundColor)]) {
//			backgroundColor = [nomad backgroundColor];
//			if (backgroundColor != nil)
//				return backgroundColor;
//		}
//		nomad = [nomad superview];
//	}
//	return nil;
//}
//

//- (void)drawRectx:(NSRect)r {
//	[[NSColor whiteColor] set];
//	NSRectFillUsingOperation(r, NSCompositeSourceOver);
////	[super drawRect:r];
//	[self drawKnob];
////	NSColor *backgroundColor = [self backgroundColor];
////	if (backgroundColor == nil)
////		backgroundColor = [NSColor redColor];
////	NSColor *aColor = self.backgroundColor;
////	if (aColor == nil)
////		aColor = [NSColor whiteColor];
////	[aColor set];
////	NSRectFill([self bounds]);
////	[[NSColor whiteColor] set];
////	NSRectFill(r);
////	[self drawKnobSlotInRect:[self bounds] highlight:NO];
////	[self drawKnob];
//}

@end
