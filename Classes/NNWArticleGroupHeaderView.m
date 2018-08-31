//
//  NNWArticleGroupHeaderView.m
//  nnw
//
//  Created by Brent Simmons on 12/27/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleGroupHeaderView.h"


@implementation NNWArticleGroupHeaderView

@synthesize groupItem;
@synthesize reuseIdentifier;
@synthesize selected;
@synthesize title;
@synthesize isFirst;

#pragma mark Dealloc

- (void)dealloc {
}


#pragma mark Reuse

- (void)prepareForReuse {
	self.title = nil;
	self.groupItem = nil;
	self.selected = NO;
	self.isFirst = NO;
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {
	
	RSCGRectFillWithWhite(r);
	
//	static NSColor *backgroundColor = nil;
//	if (backgroundColor == nil)
//		backgroundColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"notepaper"]] retain];
//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, 0)];
//	[backgroundColor set];
//	NSRectFillUsingOperation(r, NSCompositeSourceOver);

	NSRect rBounds = NSIntegralRect([self bounds]);
	NSRect rBox = rBounds;
	rBox.size.height = rBox.size.height - 1.0f;
	rBox.origin.y = rBox.origin.y + 1.0f;
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//	CGContextSaveGState(context);
//	CGContextSetAlpha(context, 0.5f);
	static NSColor *frameColor = nil;
	if (frameColor == nil)
		frameColor = [[NSColor colorWithCalibratedRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] retain];
	
	/*Gradient fill*/
	
	static NSGradient *headerGradient = nil;
	if (headerGradient == nil) {
//		NSColor *startingColor = [NSColor colorWithDeviceWhite:218.0f/255.0f alpha:1.0f];
//		NSColor *endingColor = [NSColor colorWithDeviceWhite:240.0f/255.0f alpha:1.0f];
//		NSColor *startingColor = [frameColor highlightWithLevel:0.7f];
//		NSColor *endingColor = [frameColor highlightWithLevel:0.9f];
		
		NSColor *startingColor = [frameColor highlightWithLevel:0.80f];
		NSColor *endingColor = [frameColor highlightWithLevel:0.95f];
		
//		NSColor *startingColor = [frameColor highlightWithLevel:0.95f];
//		NSColor *endingColor = [frameColor highlightWithLevel:0.99f];
		headerGradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	}
	[headerGradient drawInRect:rBox angle:-89.0f];
	
//	NSImage *tabImage = [NSImage imageNamed:@"TabImageTranslucent"];
//	[tabImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.1f];
	
	static NSGradient *highlightGradient = nil;
	if (highlightGradient == nil) {
//		NSColor *startingColor = [NSColor colorWithDeviceWhite:1.0f alpha:0.2f];
//		NSColor *endingColor = [NSColor colorWithDeviceWhite:1.0f alpha:0.0f];
		NSColor *startingColor = [NSColor colorWithDeviceWhite:1.0f alpha:0.105f];
		NSColor *endingColor = [NSColor colorWithDeviceWhite:1.0f alpha:0.4f];
		highlightGradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	}
	[highlightGradient drawInRect:rBox relativeCenterPosition:NSMakePoint(0.0f, -1.0f)];

	CGContextRestoreGState(context);

	
//	NSRect rTopWhiteLine = CGRectIntegral(rBox);
//	rTopWhiteLine.origin.y += 1.0f;
//	rTopWhiteLine.size.height = 1.0f;
//	RSCGRectFillWithWhite(rTopWhiteLine);	
//	static CGColorRef topInnerShadowColor = nil;
//	if (topInnerShadowColor == nil)
//		topInnerShadowColor = CGColorCreateGenericGray(1.0f, 0.3f);
//	RSCGRectFillWithColor(rTopWhiteLine, topInnerShadowColor);
		
	/*Borders*/

	static CGColorRef blackShadowColor = nil;
	if (blackShadowColor == nil)
		blackShadowColor = CGColorCreateGenericGray(0.0f, 0.02f);
	CGContextSaveGState(context);
	NSBezierPath *bottomPath = [NSBezierPath bezierPath];
	[bottomPath setLineWidth:1.0f];
	[bottomPath moveToPoint:NSMakePoint(0.0f, NSMaxY(rBox) - 0.5f)];
	[bottomPath lineToPoint:NSMakePoint(NSMaxX(rBox) - 0.0f, NSMaxY(rBox) - 0.5f)];
	[[frameColor highlightWithLevel:0.7] set];
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 1.0f, blackShadowColor);
	 [bottomPath stroke];
	CGContextRestoreGState(context);

	CGContextSaveGState(context);
	NSBezierPath *topPath = [NSBezierPath bezierPath];
	[topPath setLineWidth:1.0f];
	if (self.isFirst) {
		[topPath moveToPoint:NSMakePoint(0.0f, NSMinY(rBox) - 0.5f)];
		[topPath lineToPoint:NSMakePoint(NSMaxX(rBox), NSMinY(rBox) - 0.5f)];
	}
	else {
		[topPath moveToPoint:NSMakePoint(0.0f, NSMinY(rBox) + 0.5f)];
		[topPath lineToPoint:NSMakePoint(NSMaxX(rBox), NSMinY(rBox) + 0.5f)];
	}

	[[frameColor highlightWithLevel:0.8] set];
	static CGColorRef whiteShadowColor = nil;
	if (whiteShadowColor == nil)
		whiteShadowColor = CGColorCreateGenericGray(1.0f, 0.95f);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, -1.0f), 1.0f, whiteShadowColor);
	[topPath stroke];
	//CGContextRestoreGState(context);

	/*Title*/
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSFont boldSystemFontOfSize:13.0f] forKey:NSFontAttributeName];

	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
	[shadow setShadowBlurRadius:1.0f];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0f alpha:1.0f]];
	[attributes setObject:shadow forKey:NSShadowAttributeName];

	static NSColor *dateColor = nil;
	if (dateColor == nil)
		//dateColor = [[[NSColor colorWithDeviceRed:157.0f/255.0f green:194.0f/255.0f blue:235.0f/255.0f alpha:1.0f] shadowWithLevel:0.15f] retain];
	dateColor = [[[NSColor colorWithDeviceRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f] shadowWithLevel:0.30f] retain];
	//dateColor = [[NSColor colorWithDeviceRed:116.0f/255.0f green:173.0f/255.0f blue:235.0f/255.0f alpha:1.0f] retain];
	//dateColor = [RSRGBColor(49, 137, 235) retain];
	[attributes setObject:dateColor forKey:NSForegroundColorAttributeName];

	//	[attributes setObject:[NSNumber numberWithFloat:5.0f] forKey:NSKernAttributeName];
	[attributes setObject:[NSNumber numberWithFloat:2.0f] forKey:NSKernAttributeName];
	
	NSAttributedString *titleString = [[[NSAttributedString alloc] initWithString:[self.title uppercaseString] attributes:attributes] autorelease];
	
	NSSize sizeOfString = [titleString size];
	NSRect rTitle = rBox;
	rTitle.size = sizeOfString;
	rTitle = CGRectCenteredInRect(rTitle, rBox);
	rTitle.origin.y = rTitle.origin.y - 1.0f;
	rTitle = CGRectIntegral(rTitle);
//	rTitle.origin.x = 38.0f;//[self bounds].size.width - (rTitle.size.width + 8.0f);
//	rTitle.size.width = [self bounds].size.width - rTitle.origin.x;
	[titleString drawInRect:rTitle];
	
}


@end
