/*
	RSFontLabelView.h
	RancheroAppKit

	Created by Brent Simmons on Thu Dec 04 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import <AppKit/AppKit.h>


@interface RSFontLabelView : NSView {

	@private
		NSFont *_chosenFont;
	}


- (void) setChosenFont: (NSFont *) font;


@end
