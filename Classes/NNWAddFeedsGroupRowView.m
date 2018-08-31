//
//  NNWAddFeedsGroupRowView.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedsGroupRowView.h"


@implementation NNWAddFeedsGroupRowView


- (BOOL)isFlipped {
	return YES;
}

- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)dirtyRect {
	
	NSRect rBounds = [self bounds];
	NSColor *backgroundColor = [NSColor lightGrayColor];
	[backgroundColor set];
	NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
	
	NSColor *darkGradientColor = [NSColor colorWithDeviceWhite:216.0f/255.0f alpha:1.0f];
	NSColor *lightGradientColor = [NSColor colorWithDeviceWhite:237.0f/255.0f alpha:1.0f];
	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:darkGradientColor endingColor:lightGradientColor] autorelease];
	[gradient drawInRect:rBounds angle:-90.0f];
	
	if (RSStringIsEmpty(self.title))
		return;
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSColor colorWithDeviceWhite:0.05f alpha:0.95f] forKey:NSForegroundColorAttributeName];
	[attributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	[attributes setObject:[NSFont boldSystemFontOfSize:12.0f] forKey:NSFontAttributeName];
	
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	
	CGContextRef context = NULL;
	context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	static CGColorRef shadowColor = nil;
	if (shadowColor == nil)
		shadowColor = CGColorCreateGenericGray(1.0f, 0.5f);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, -1.0f), 1.0f, shadowColor);		
	NSAttributedString *titleString = [[[NSAttributedString alloc] initWithString:self.title attributes:attributes] autorelease];
	NSRect rTitle = NSInsetRect([self bounds], 2.0f, 2.0f);
	rTitle.origin.y = rTitle.origin.y + 1.0f;
	rTitle = NSIntegralRect(rTitle);
	[titleString drawInRect:rTitle];
	CGContextRestoreGState(context);
	
	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0f];
	[p moveToPoint:NSMakePoint(0, NSMaxY([self bounds]) - 0.5f)];
	[p lineToPoint:NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]) - 0.5f)];
	[p moveToPoint:NSMakePoint(0, 0.5f)];
	[p lineToPoint:NSMakePoint(NSMaxX([self bounds]), 0.5f)];
	[NSColor colorWithDeviceWhite:105.0f/255.0f alpha:1.0f];
	[p stroke];
	
	NSBezierPath *p2 = [NSBezierPath bezierPath];
	[p2 setLineWidth:1.0f];
	[p2 moveToPoint:NSMakePoint(0, 1.5f)];
	[p2 lineToPoint:NSMakePoint(NSMaxX([self bounds]), 1.5f)];
	[[NSColor colorWithDeviceWhite:1.0f alpha:0.95f] set];
	[p2 stroke];
	
}


@end
