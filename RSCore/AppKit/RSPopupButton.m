/*
 RSPopupButton.m
 RancheroAppKit
 
 Created by Brent Simmons on Mon Feb 02 2004.
 Copyright (c) 2004 Ranchero Software. All rights reserved.
 */


#import "RSPopupButton.h"

@interface NSObject (RSPopupButtonMenuDelegate)
- (NSMenu *)menuForPopupButton:(RSPopupButton *)button;
@end


@implementation RSPopupButton

@synthesize pullDownMenu = _pullDownMenu, pullDownMenuDelegate = _pullDownMenuDelegate;

- (void)dealloc {
	self.pullDownMenu = nil;
	[super dealloc];
}


- (BOOL)isFlipped {
	return YES;
}


- (void)getMenuFromPullDownMenuDelegate {
	if (_pullDownMenuDelegate && [_pullDownMenuDelegate respondsToSelector:@selector(menuForPopupButton:)])
		self.pullDownMenu = [_pullDownMenuDelegate menuForPopupButton:self];
}


- (void)mouseDown:(NSEvent *)event {
	
	[self getMenuFromPullDownMenuDelegate];
	if (!self.pullDownMenu)
		return;
	
	NSPoint p = [self bounds].origin;
	CGFloat h = [self bounds].size.height;
	
	p.y += h + 3;
	p.x += 3;
	p = [self convertPoint:p toView:nil];
	
	[self highlight:YES];
	
	NSEvent *newEvent = [NSEvent mouseEventWithType:[event type] location:p modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
	[NSMenu popUpContextMenu:self.pullDownMenu withEvent:newEvent forView:self];
	[self mouseUp:newEvent];
}


- (void)mouseUp:(NSEvent *)event {
	[self highlight:NO];
	[super mouseUp:event];
}


@end
