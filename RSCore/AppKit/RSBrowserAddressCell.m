/*
	RSBrowserAddressCell.m
	NetNewsWire

	Created by Brent Simmons on Sun Nov 23 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import "RSBrowserAddressCell.h"
#import "RSAppKitCategories.h"


static void RSDrawGlassInRectWithColors(NSRect r, NSView *view, NSColor *lightColor, NSColor *darkColor, NSColor *darkestColor);

@implementation RSBrowserAddressCell


- (void) dealloc {
	[_image release];
	[super dealloc];
	}


- (NSFocusRingType)focusRingType {
	return (NSFocusRingTypeNone);
	}
	
	
- (void) setImage: (NSImage *) image {
	[_image autorelease];
	_image = [image retain];
	}


- (NSImage *) image {
	return (_image);
	}


- (void) calculateFrames: (NSRect) r textFrame: (NSRect *) textFrame
	imageFrame: (NSRect *) imageFrame {
	
	CGFloat imageWidth = [_image size].width;
	
	if (imageWidth < 16)
		imageWidth = 16;
		
	NSDivideRect (r, imageFrame, textFrame, imageWidth, NSMinXEdge);
	
	(*imageFrame).origin.x +=3;
	(*imageFrame).origin.y -=3;
		
	*imageFrame = NSIntegralRect(*imageFrame);
	
	*textFrame = NSInsetRect (*textFrame, 5, 2);
	(*textFrame).size.width -= 2.0f;
	*textFrame = NSIntegralRect(*textFrame);
	
	}
	
	
- (void) editWithFrame: (NSRect) aRect inView: (NSView *) controlView
	editor: (NSText *) textObj delegate: (id) anObject
	event: (NSEvent *) theEvent {
	
	NSRect textFrame, imageFrame;
	
	[self calculateFrames: aRect textFrame: &textFrame imageFrame: &imageFrame];
	
	[super editWithFrame: textFrame inView: controlView
		editor: textObj delegate: anObject event: theEvent];
	}


- (void) selectWithFrame: (NSRect) aRect inView: (NSView *) controlView
	editor: (NSText *) textObj delegate: (id) anObject
	start: (NSInteger) selStart length: (NSInteger) selLength {

	NSRect textFrame, imageFrame;

	[self calculateFrames: aRect textFrame: &textFrame imageFrame: &imageFrame];

	[super selectWithFrame: textFrame inView: controlView
		editor: textObj delegate: anObject start: selStart length: selLength];
	}


- (NSRect)currentProgressRect:(NSView *)controlView {
	NSRect r = [controlView bounds];
	r.origin.x++;
	r.size.width--;	
	if (pageLoadInProgress) {
		r.size.width = r.size.width * estimatedProgress;
		return (r);
		}
	return (NSZeroRect);
	}


- (void)drawBorderx:(NSRect)cellFrame controlView:(NSView *)controlView {
	
	NSColor *bgcolor = [NSColor rs_interfaceColor];
	[NSGraphicsContext saveGraphicsState];
	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0];
	NSRect r = NSIntegralRect(cellFrame);
	r.origin.x += 0.5;
	r.size.width -= 1;
	r.origin.y += 0.5;
	r.size.height -= 1.0f;
	//r.size.height -= 2;
	[p rs_appendBezierPathWithRoundedRectangle:r withRadius:1.0];
	[bgcolor set];
	
	RSSetInterfaceColor(0.9);
	
	[NSGraphicsContext saveGraphicsState];
//	static NSShadow *gshadow = nil;
//	if (!gshadow) {
//		gshadow = [[NSShadow alloc] init];
//		[gshadow setShadowBlurRadius:1.0];
//		[gshadow setShadowColor:RSGray(0.0)];
//		[gshadow setShadowOffset:NSMakeSize(0, -1)];
//	}
	//[gshadow set];
	[RSGray(0.97) set];
	[p fill];
	NSRect progressRect = [self currentProgressRect:controlView];
	if (!NSEqualRects(progressRect, NSZeroRect)) {
		[p addClip];
		//RSSetInterfaceColor(0.6);
		progressRect.size.height -= 1;
		//RSDrawGlassInRectWithColors(progressRect, controlView, RSInterfaceColor(0.52), RSInterfaceColor(0.5), RSInterfaceColor(0.48));
	[[NSColor colorWithDeviceWhite:0.85f alpha:1.0f] set];
//		NSRectFill(progressRect);
//		static NSColor *backgroundColor = nil;
//		if (backgroundColor == nil)
//			//backgroundColor = [[NSColor colorWithDeviceWhite:0.0f alpha:1.0f] retain];
//		backgroundColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"bluepattern"]] retain];
//			[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, 0)];
//		[backgroundColor set];

		static NSColor *backgroundColor = nil;
		if (backgroundColor == nil)
//			//		backgroundColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"notepaper"]] retain];
//			//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, 0)];
//			
//			
			backgroundColor = [[[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.6f] retain];
		[backgroundColor set];

		NSRectFillUsingOperation(progressRect, NSCompositeCopy);
//		NSImage *fillImage = [NSImage imageNamed:@"browserAddressFieldProgressFill"];
//		[fillImage setFlipped:YES];
		//[fillImage drawInRect:progressRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.65f];
	}
	[NSGraphicsContext restoreGraphicsState];
//	[[NSColor rs_borderColor] set];
	static NSColor *borderColor = nil;
	if (borderColor == nil)
		borderColor = [[NSColor colorWithDeviceWhite:238.0f/255.0f alpha:1.0f] retain];
	[borderColor set];
	//[p stroke];
	
	[NSGraphicsContext restoreGraphicsState];
}


- (void)setPageLoadInProgress:(BOOL)fl {
	pageLoadInProgress = fl;
	}
	
	
- (void)setEstimatedProgress:(double)ep {
	estimatedProgress = ep;
	}
	

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView *) controlView {

	NSRect imageFrame, textFrame;

	BOOL flShowsFirstResponder = [self showsFirstResponder];
	
	[self calculateFrames: cellFrame textFrame: &textFrame imageFrame: &imageFrame];		

	NSColor *bgcolor = [NSColor rs_interfaceColor];
	[[bgcolor highlightWithLevel:0.15] set];
	[RSGray(0.5) set];
	//NSRectFill(NSInsetRect(cellFrame, 1, 1));


		//[self drawBorder: cellFrame controlView:controlView];
	
	if (_image != nil) {
		[_image compositeToPoint:
			NSMakePoint (imageFrame.origin.x, (imageFrame.origin.y + imageFrame.size.height))
			operation: NSCompositePlusDarker];
		}
	

		
	[self setShowsFirstResponder: NO];
	[super drawWithFrame: textFrame inView: controlView];
	[self setShowsFirstResponder: flShowsFirstResponder];
	}


@end


//static void RSDrawGlassInRectWithColors(NSRect r, NSView *view, NSColor *lightColor, NSColor *darkColor, NSColor *darkestColor) {
//	
//	NSBezierPath *p = [NSBezierPath bezierPath];
//	NSRect rBounds = r;
//	NSRect rTop = rBounds;
//	NSRect rBottom = rBounds;
//	
//	[[NSColor colorWithCalibratedWhite:0.94 alpha:1.0] set];
//	NSRectFill(r);
//	
//	if (view && [view isFlipped]) {
//		rTop.size.height = (NSInteger)((rTop.size.height / 2) + 0.5);
//		rBottom.origin.y = (rTop.origin.y + rTop.size.height) - 0.5;
//		rBottom.size.height = (r.size.height - rTop.size.height) + 0.5;
//		
//		NSGradient *gTop = [[[NSGradient alloc] initWithStartingColor:darkColor endingColor:lightColor] autorelease];
//		[gTop drawInRect:rTop angle:-90.0];
//		NSGradient *gBottom = [[[NSGradient alloc] initWithStartingColor:lightColor endingColor:darkestColor] autorelease];
//		[gBottom drawInRect:rBottom angle:-90.0];
//	}
//	
//	else {
//		rTop.size.height = (NSInteger)((rTop.size.height / 2) + 0.5);
//		rBottom.origin.y = (NSInteger)((rBottom.size.height / 2) + 0.5);
//		rBottom.size.height = rBottom.size.height - rBottom.origin.y;
//		
//		
//		//		/*Light look*/
//		[p rs_drawRect:rBottom withGradientFrom:darkColor to:lightColor];		
//		[p rs_drawRect:rTop withGradientFrom:lightColor to:darkestColor];
//	}
//}
