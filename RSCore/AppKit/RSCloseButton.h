/*
 RSCloseButton.h
 NetNewsWire
 
 Created by Brent Simmons on 8/13/04.
 Copyright 2004 Ranchero Software. All rights reserved.
 */


#import <Cocoa/Cocoa.h>


@interface RSCloseButton : NSButton {
	
@private
	NSImage *_realImage;
	NSImage *_mouseOverImage;
	NSTrackingRectTag _buttonTrackingRect;
	id mouseOverDelegate;
}


@property (nonatomic, retain) NSImage *realImage;
@property (nonatomic, retain) NSImage *mouseOverImage;
@property (nonatomic, assign) id mouseOverDelegate;

- (void)commonInit;
- (void)discardTrackingRects;
- (void)resetTrackingRects;


@end
