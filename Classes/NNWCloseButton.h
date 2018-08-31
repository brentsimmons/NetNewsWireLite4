/*
 NNWCloseButton.h
 NetNewsWire
 
 Created by Brent Simmons on 8/13/04.
 Copyright 2004 Ranchero Software. All rights reserved.
 */


#import <Cocoa/Cocoa.h>


@interface NNWCloseButton : NSButton {
    
@private
    NSImage *_realImage;
    NSImage *_mouseOverImage;
    NSTrackingRectTag _buttonTrackingRect;
    id __unsafe_unretained mouseOverDelegate;
}


@property (nonatomic, strong) NSImage *realImage;
@property (nonatomic, strong) NSImage *mouseOverImage;
@property (nonatomic, unsafe_unretained) id mouseOverDelegate;

- (void)commonInit;
- (void)discardTrackingRects;
- (void)resetTrackingRects;


@end
