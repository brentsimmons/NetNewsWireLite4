//
//  NNWSourceListPointerWindow.m
//  nnw
//
//  Created by Brent Simmons on 1/2/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSourceListPointerWindow.h"


@interface NNWSourceListPointerBackgroundView : NSView
@end

@interface NNWSourceListPointerWindow ()

@property (nonatomic, retain) NSWindow *parentWindow;
@property (nonatomic, assign) NSPoint pointInWindow;
@property (nonatomic, retain) NSTextField *messageTextField;
@end


@implementation NNWSourceListPointerWindow

@synthesize messageTextField;
@synthesize parentWindow;
@synthesize pointInWindow;


#pragma mark Init

- (id)initWithPoint:(NSPoint)aPoint inWindow:(NSWindow *)aWindow {
	
	NSRect initialContentRect = NSIntegralRect(NSMakeRect(aPoint.x, aPoint.y, 320.0f, 48.0f));
	self = [super initWithContentRect:initialContentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	if (self == nil)
		return nil;
	
	pointInWindow = aPoint;
	parentWindow = [aWindow retain];
	
	NNWSourceListPointerBackgroundView *backgroundView = [[[NNWSourceListPointerBackgroundView alloc] initWithFrame:initialContentRect] autorelease];
	[self setContentView:backgroundView];
	
	messageTextField = [[NSTextField alloc] initWithFrame:NSInsetRect(initialContentRect, 8.0f, 8.0f)];
	static NSColor *messageColor = nil;
	if (messageColor == nil)
		messageColor = [[NSColor colorWithDeviceRed:157.0f/255.0f green:194.0f/255.0f blue:235.0f/255.0f alpha:1.0f] retain];
	[messageTextField setTextColor:[NSColor whiteColor]];
	[messageTextField setEditable:NO];
	[messageTextField setAlignment:NSLeftTextAlignment];
	[messageTextField setFont:[NSFont userFontOfSize:14.0f]];
	[messageTextField setBezeled:NO];
	[messageTextField setBordered:NO];
	[messageTextField setDrawsBackground:NO];
	[backgroundView addSubview:messageTextField];
	self.message = @"The new feed was added here."; //TODO
	
	[self setExcludedFromWindowsMenu:YES];
	[self setOpaque:NO];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setMovableByWindowBackground:YES];
	[self setHasShadow:NO];
	
	NSRect windowFrame = initialContentRect;
	windowFrame.origin = [aWindow convertBaseToScreen:aPoint];
	[self setFrame:windowFrame display:NO];
	[[self contentView] resizeSubviewsWithOldSize:NSZeroSize];
	
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[messageTextField release];
	[parentWindow release];
	[super dealloc];
}


#pragma mark Message

- (NSString *)message {
	return [self.messageTextField stringValue];
}


- (void)setMessage:(NSString *)aMessage {
	[self.messageTextField setStringValue:aMessage];
}


#pragma mark Geometry

static const CGFloat leftMargin = 2.0f;
static const CGFloat rightMargin = 2.0f;
static const CGFloat topMargin = 2.0f;
static const CGFloat bottomMargin = 4.0f;
static const CGFloat cornerRadius = 2.0f;

//- (NSRect)contentRectForFrameRect:(NSRect)frameRect {
//	NSRect rBorder = [self bounds];
//	rBorder.origin.x = rBorder.origin.x + leftMargin;
//	rBorder.size.width = rBorder.size.width - (leftMargin + rightMargin);
//	rBorder.origin.y = rBorder.origin.y + bottomMargin;
//	rBorder.size.height = rBorder.size.height - (bottomMargin + topMargin);
//}
//
//
//+ (NSRect)frameRectForContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle {
//    return NSInsetRect(contentRect, -kWindowBorderWidth, -kWindowBorderWidth);
//}

@end


@implementation NNWSourceListPointerBackgroundView

- (BOOL)isOpaque {
	return NO;
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSTextField *textField = (NSTextField *)[self rs_firstSubviewOfClass:[NSTextField class]];
	NSRect rBounds = [self bounds];
	NSRect rTextField = NSInsetRect(rBounds, 8.0f, 8.0f);
	rTextField.size.height = 22.0f;
	rTextField = CGRectCenteredInRect(rTextField, rBounds);
	[textField setFrame:rTextField];
}


- (void)drawRect:(NSRect)r {
	
	
	NSRect rBorder = [self bounds];
	rBorder.origin.x = rBorder.origin.x + leftMargin;
	rBorder.size.width = rBorder.size.width - (leftMargin + rightMargin);
	rBorder.origin.y = rBorder.origin.y + bottomMargin;
	rBorder.size.height = rBorder.size.height - (bottomMargin + topMargin);
	rBorder = NSIntegralRect(rBorder);
	rBorder.origin.x = rBorder.origin.x + 0.5f;
	rBorder.origin.y = rBorder.origin.y + 0.5f;
	
	NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:rBorder xRadius:cornerRadius yRadius:cornerRadius];
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

	/*Shadow*/
	
	CGContextSaveGState(context);
	static CGColorRef shadowColor = nil;
	if (shadowColor == nil)
		shadowColor = CGColorCreateGenericGray(0.0f, 0.6f);
	CGContextSetShadow(context, CGSizeMake(0.0f, -1.0f), 2.0f);
	[[NSColor whiteColor] set];
	[borderPath stroke];
	CGContextRestoreGState(context);

	/*Fill*/
	
	CGContextSaveGState(context);
	static NSColor *backgroundColor = nil;
	if (backgroundColor == nil)
		backgroundColor = [[NSColor colorWithDeviceWhite:0.3 alpha:0.66] retain];
	[backgroundColor set];
	[borderPath addClip];
	NSRectFillUsingOperation(r, NSCompositeSourceOver);
	CGContextRestoreGState(context);

	/*Inner border*/
	
	[[NSColor whiteColor] set];
	[[NSColor colorWithDeviceWhite:1.0f alpha:0.5f] set];
	NSRect rInnerBorder = NSInsetRect(rBorder, 1.0f, 1.0f);
	NSBezierPath *innerBorderPath = [NSBezierPath bezierPathWithRoundedRect:rInnerBorder xRadius:cornerRadius yRadius:cornerRadius];
	[innerBorderPath setLineWidth:1.0f];
	[innerBorderPath stroke];
	
	/*Outer border*/
	
	[[NSColor colorWithDeviceWhite:0.3f alpha:1.0f] set];
	[borderPath setLineWidth:1.0f];
	[borderPath stroke];
}


@end

