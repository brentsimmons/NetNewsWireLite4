/*
 RSSolidColorView.h
 NetNewsWire
 
 Created by Brent Simmons on 12/17/04.
 Copyright 2004 Ranchero Software. All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@interface RSSolidColorView : NSView {
@private
	NSColor *backgroundColor;
}

@property (nonatomic, retain) NSColor *backgroundColor;


@end
