/*
 NNWCloseButton.m
 NetNewsWire
 
 Created by Brent Simmons on 8/13/04.
 Copyright 2004 Ranchero Software. All rights reserved.
 */


#import "NNWCloseButton.h"


@interface NSObject (NNWCloseButtonMouseoverDelegate)
- (void)mouseEnteredCloseButton:(NSButton *)button;
- (void)mouseExitedCloseButton:(NSButton *)button;
@end


@implementation NNWCloseButton

@synthesize realImage = _realImage, mouseOverImage = _mouseOverImage, mouseOverDelegate;

#pragma mark Init

- (void)commonInit {
	[self setPostsFrameChangedNotifications:YES];
	[self setPostsBoundsChangedNotifications:YES];
	_buttonTrackingRect = -1;
	[self performSelectorOnMainThread:@selector(resetTrackingRects) withObject:nil waitUntilDone:NO];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFrameDidChangeNotification:) name:NSViewFrameDidChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFrameDidChangeNotification:) name:NSViewBoundsDidChangeNotification object:self];		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFrameDidChangeNotification:) name:NSWindowDidMoveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericFrameDidChangeNotification:) name:NSWindowDidResizeNotification object:nil];
}


- (id)initWithFrame:(NSRect)r {
	self = [super initWithFrame:r];
	if (self)
		[self commonInit];
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self)
		[self commonInit];
	return self;
}


#pragma mark Dealloc	

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self discardTrackingRects];
	[_realImage release];
	[_mouseOverImage release];
	[super dealloc];
}


#pragma mark First responder

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return NO;
}


#pragma mark Mouse events

- (void)mouseEntered:(NSEvent *)event {
	if (!_mouseOverImage || ![NSApp isActive]) {
		[super mouseEntered:event];
		return;
	}
	[self setImage:_mouseOverImage];
	[self display];
	if (mouseOverDelegate != nil) {
		if ([mouseOverDelegate respondsToSelector:@selector(mouseEnteredCloseButton:)])
			[mouseOverDelegate mouseEnteredCloseButton:self];
	}
}


- (void)mouseExited:(NSEvent *)event {
	if (!_mouseOverImage) {
		[super mouseExited:event];
		return;
	}
	[self setImage:_realImage];
	[self display];
	if (mouseOverDelegate != nil) {
		if ([mouseOverDelegate respondsToSelector:@selector(mouseExitedCloseButton:)])
			[mouseOverDelegate mouseExitedCloseButton:self];
	}
}


#pragma mark Tracking rects

- (void)discardTrackingRects {
	if (_buttonTrackingRect >= 0) {
		[self removeTrackingRect: _buttonTrackingRect];
		_buttonTrackingRect = -1;
	}
}


- (void)resetTrackingRects {
	NSRect r = [self frame];
	r.origin = NSZeroPoint;
	[self discardTrackingRects];
	_buttonTrackingRect = [self addTrackingRect:r owner:self userData:nil assumeInside:NO];
}


#pragma mark Notifications

- (void)handleGenericFrameDidChangeNotification:(NSNotification *)note {
	[self resetTrackingRects];
}


- (void)viewDidMoveToWindow {
	[self resetTrackingRects];
}


#pragma mark RemoveFromSuperview

- (void)removeFromSuperview {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self discardTrackingRects];
	[super removeFromSuperview];
}


@end
