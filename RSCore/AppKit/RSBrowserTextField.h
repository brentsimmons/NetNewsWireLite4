/*
	RSBrowserTextField.h
	RancheroAppKit

	Created by Brent Simmons on Sun Nov 23 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


@interface RSBrowserTextField : NSTextField {

	NSImage *_image;
	NSProgressIndicator *_progressIndicator;
	BOOL _flInProgress;
	NSString *_title;
	NSString *_urlString;
	BOOL _flDisplayTitle;
	}


- (void) setImage: (NSImage *) image;
- (void) setInProgress: (BOOL) fl;
- (void)setEstimatedProgress:(double)ep;
- (void) setTitle: (NSString *) s;
- (void) setURLString: (NSString *) s;
- (void) setDisplayTitle: (BOOL) fl;


@end
