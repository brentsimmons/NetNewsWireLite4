//
//  NNWListHeaderView.m
//  nnw
//
//  Created by Brent Simmons on 11/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWListHeaderView.h"


@implementation NNWListHeaderView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (BOOL)isOpaque {
	return YES;
}


- (BOOL)isFlipped {
	return YES;
}


- (NSString *)title {
	return @"Feeds";
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect rBounds = [self bounds];
	NSColor *baseColor = [NSColor greenColor];
	baseColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
	//	baseColor = [NSColor colorWithDeviceRed:217.0f/255.0f green:221.0f/255.0f blue:227.0f/255.0f alpha:1.0f];
	//	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
	//	baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
	//	baseColor = [NSColor colorWithDeviceWhite:168.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor colorWithDeviceWhite:150.0f/255.0f alpha:1.0f];
//	baseColor = [NSColor selectedTextBackgroundColor];
	//	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
//	baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
	//	baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
//		baseColor = [NSColor colorWithDeviceRed:225.0f/255.0f green:225.0f/255.0f blue:226.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor colorWithDeviceWhite:150.0f/255.0f alpha:1.0f];
	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[baseColor shadowWithLevel:0.1f] endingColor:[baseColor highlightWithLevel:0.25f]] autorelease];
	[gradient drawInRect:rBounds angle:-90.0f];

	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0f];
	NSRect r = rBounds;
	[p moveToPoint:r.origin];
	[p lineToPoint:NSMakePoint(NSMaxX(r), NSMinY(r))];
	[[NSColor colorWithDeviceWhite:1.0f alpha:0.99f] set];
	//[p stroke];
	
	
	NSBezierPath *p2 = [NSBezierPath bezierPath];
	[p2 setLineWidth:1.0f];
	r.origin.y = NSMaxY(r);
	[p2 moveToPoint:r.origin];
	[p2 lineToPoint:NSMakePoint(NSMaxX(r), r.origin.y)];
	[[NSColor colorWithDeviceWhite:0.0f alpha:0.2f] set];
	[p2 stroke];

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	NSColor *fontColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
	//fontColor = [baseColor shadowWithLevel:0.7f];
	fontColor = [fontColor shadowWithLevel:0.1f];
	fontColor = [NSColor colorWithDeviceWhite:0.0f alpha:0.45f];
	//fontColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
//	fontColor = [fontColor shadowWithLevel:0.1f];
//	fontColor = [NSColor grayColor];
	//fontColor = [[NSColor colorForControlTint:[NSColor currentControlTint]] shadowWithLevel:0.15f];
//	fontColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
	//fontColor = [[NSColor selectedTextBackgroundColor] highlightWithLevel:0.95f];
	//fontColor = [NSColor whiteColor];
	[attributes setObject:fontColor forKey:NSForegroundColorAttributeName];
	//[attributes setObject:[NSColor colorWithDeviceWhite:0.0f alpha:0.8f] forKey:NSForegroundColorAttributeName];
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0f alpha:0.6f]];
	[shadow setShadowBlurRadius:1.0f];
	[attributes setObject:shadow forKey:NSShadowAttributeName];
	
	[attributes setObject:[NSFont boldSystemFontOfSize:12.0f] forKey:NSFontAttributeName];
	NSAttributedString *titleString = [[[NSAttributedString alloc] initWithString:self.title attributes:attributes] autorelease];
	[titleString drawAtPoint:NSMakePoint(10.0f, 1.0f)];
}

@end
