/*
	RSBrowserAddressCell.h
	NetNewsWire

	Created by Brent Simmons on Sun Nov 23 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


@interface RSBrowserAddressCell : NSTextFieldCell {

	NSImage *_image;
	BOOL pageLoadInProgress;
	double estimatedProgress;
	}


- (void)setPageLoadInProgress:(BOOL)fl;
- (void)setEstimatedProgress:(double)ep;

- (void) setImage: (NSImage *) image;
- (NSImage *) image;

- (void) editWithFrame: (NSRect) aRect inView: (NSView *) controlView
	editor: (NSText *) textObj delegate: (id) anObject
	event: (NSEvent *) theEvent;
- (void) selectWithFrame: (NSRect) aRect inView: (NSView *) controlView
	editor: (NSText *) textObj delegate: (id) anObject
	start: (NSInteger) selStart length: (NSInteger) selLength;	
	
- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView *) controlView;


@end
