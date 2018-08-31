//
//  NNWToolbar.m
//  nnw
//
//  Created by Brent Simmons on 12/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWToolbar.h"
#import "NNWCloseButton.h"


@implementation NNWToolbar

@synthesize toolbarItems;
@synthesize closeButton;


#pragma mark Dealloc

- (void)dealloc {
	[toolbarItems release];
	[closeButton release];
	[super dealloc];
}


#pragma mark AwakeFromNib

- (void)awakeFromNib {
	[self.closeButton setRealImage:[NSImage imageNamed:@"tab_close"]];
	[self.closeButton setAlternateImage:[NSImage imageNamed:@"tab_closePressed"]];
	[self.closeButton setMouseOverImage:[NSImage imageNamed:@"tab_closeMouseover"]];
	[self.closeButton setImagePosition:NSImageOnly];
	[self.closeButton setAutoresizingMask:NSViewMaxXMargin];
	[self.closeButton setButtonType:NSMomentaryPushInButton];
	[self.closeButton setBezelStyle:NSThickSquareBezelStyle];
	[self.closeButton setToolTip:NSLocalizedString(@"Close web page. You can also use cmd-W or the left arrow key to close the web page.", @"Tooltip for close button on web page")];
	[[self.closeButton cell] setControlSize:NSSmallControlSize];
	[[self.closeButton cell] setGradientType:NSGradientNone];
	[[self.closeButton cell] setShowsStateBy:NSNoCellMask];
	[[self.closeButton cell] setHighlightsBy:NSContentsCellMask];
	[self.closeButton setBordered:NO];
	
	for (NSView *oneSubview in [self subviews]) {
		if ([oneSubview isKindOfClass:[NSProgressIndicator class]])
			[(NSProgressIndicator *)oneSubview setUsesThreadedAnimation:YES];
	}
}

#pragma mark Layout

static const CGFloat spaceBetweenItems = 20.0f;

- (NSView *)firstItemWithPriority:(NNWToolbarItemVisibilityPriority)priority {
	for (NSView *oneView in self.toolbarItems) {
		if ([oneView respondsToSelector:@selector(visibilityPriority)] && [(id<NNWToolbarItem>)oneView visibilityPriority] == priority)
			return oneView;
	}
	return nil;
}


- (NSView *)findItemToRemove:(NSMutableArray *)items {
	NSView *itemToRemove = [self firstItemWithPriority:NNWToolbarItemVisibilityPriorityLow];
	if (itemToRemove != nil)
		return itemToRemove;
	itemToRemove = [self firstItemWithPriority:NNWToolbarItemVisibilityPriorityMedium];
	if (itemToRemove != nil)
		return itemToRemove;
	return [items objectAtIndex:0];
}


- (void)removeOneItem:(NSMutableArray *)items {
	/*Remove one item, paying attention to visibility priority.*/
	NSView *itemToRemove = [self findItemToRemove:items];
	[items removeObject:itemToRemove];
}


- (BOOL)willFitItems:(NSArray *)items width:(CGFloat)width {
	CGFloat totalWidthOfItems = spaceBetweenItems;
	for (NSView *oneView in items) {
		totalWidthOfItems = totalWidthOfItems + [oneView bounds].size.width;
		totalWidthOfItems = totalWidthOfItems + spaceBetweenItems;
		if (totalWidthOfItems > width)
			return NO;
	}
	return totalWidthOfItems <= width;
}


- (NSArray *)itemsThatWillFit {
	CGFloat width = [self bounds].size.width;
	NSMutableArray *itemsThatWillFit = [[self.toolbarItems mutableCopy] autorelease];
	while (true) {
		if ([self willFitItems:itemsThatWillFit width:width])
			return itemsThatWillFit;
		[self removeOneItem:itemsThatWillFit];
		if ([itemsThatWillFit count] < 1)
			return nil;
	}
	return nil;
}



- (void)hideAllItems {
	for (NSView *oneView in self.toolbarItems)
		[oneView setHidden:YES];
}


- (void)unhideItemsInArray:(NSArray *)items {
	for (NSView *oneView in items)
		[oneView setHidden:NO];
}


#pragma mark Accessors

- (void)setToolbarItems:(NSArray *)someToolbarItems {
	if (toolbarItems != nil) {
		for (NSView *oneView in toolbarItems)
			[oneView removeFromSuperview];
	}
	toolbarItems = [someToolbarItems retain];
	for (NSView *oneView in toolbarItems)
		[self addSubview:oneView];
	[self resizeSubviewsWithOldSize:NSZeroSize];
	[self setNeedsDisplay:YES];
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {

	RSCGRectFillWithWhite([self bounds]);
	
	NSRect rBounds = NSIntegralRect([self bounds]);
	NSRect rBox = rBounds;
	rBox.size.height = rBox.size.height - 1.0f;
	rBox.origin.y = rBox.origin.y + 1.0f;
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	static NSColor *frameColor = nil;
	if (frameColor == nil)
		frameColor = [[NSColor colorWithCalibratedRed:145.0f/255.0f green:145.0f/255.0f blue:145.0f/255.0f alpha:1.0f] retain];
	
	/*Gradient fill*/
	
	static NSGradient *headerGradient = nil;
	if (headerGradient == nil) {
		NSColor *startingColor = [frameColor highlightWithLevel:0.6f];
		NSColor *endingColor = [frameColor highlightWithLevel:0.9f];
		headerGradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	}
	[headerGradient drawInRect:rBox angle:-89.0f];
	
	static NSGradient *highlightGradient = nil;
	if (highlightGradient == nil) {
		NSColor *startingColor = [NSColor colorWithDeviceWhite:1.0f alpha:0.5f];
		NSColor *endingColor = [NSColor colorWithDeviceWhite:1.0f alpha:0.105f];
		highlightGradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	}
	[highlightGradient drawInRect:rBox relativeCenterPosition:NSMakePoint(0.0f, -1.0f)];
	
	CGContextRestoreGState(context);
		
	/*Borders*/
	
	static CGColorRef blackShadowColor = nil;
	if (blackShadowColor == nil)
		blackShadowColor = CGColorCreateGenericGray(0.0f, 0.09f);
	CGContextSaveGState(context);
	NSBezierPath *bottomPath = [NSBezierPath bezierPath];
	[bottomPath setLineWidth:1.0f];
	[bottomPath moveToPoint:NSMakePoint(0.0f, NSMaxY(rBox) - 0.5f)];
	[bottomPath lineToPoint:NSMakePoint(NSMaxX(rBox) - 0.0f, NSMaxY(rBox) - 0.5f)];
	[[frameColor highlightWithLevel:0.2] set];
	[bottomPath stroke];
	CGContextRestoreGState(context);

	CGContextSaveGState(context);
	NSBezierPath *topPath = [NSBezierPath bezierPath];
	[topPath setLineWidth:1.0f];
		[topPath moveToPoint:NSMakePoint(0.0f, NSMinY(rBox) - 0.5f)];
		[topPath lineToPoint:NSMakePoint(NSMaxX(rBox), NSMinY(rBox) - 0.5f)];
	
	[[frameColor highlightWithLevel:0.8] set];
	[[NSColor colorWithDeviceWhite:1.0 alpha:0.75f] set];
	[topPath stroke];
}


@end
