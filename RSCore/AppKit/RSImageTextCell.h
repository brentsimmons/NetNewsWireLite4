/*
	RSImageTextCell.h
	RancheroAppKit
	
	Created by Brent Simmons on Sat Mar 15 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
	
	Descended from Apple's ImageAndTextCell sample code.
*/


#import <Cocoa/Cocoa.h>


@interface RSImageTextCell : NSTextFieldCell {

	@protected
		NSImage *image;
		NSInteger padding;
		NSInteger _verticalTextOffset;
		NSInteger fontFudge;
		BOOL geneva9;
		CGFloat faviconFudge;
		BOOL _selected;
		BOOL _drawMouseOverHighlight;
	}

- (void) setImage: (NSImage *) anImage;
- (NSImage *) image;
- (void) setPadding: (NSInteger) i;
- (void) setVerticalTextOffset: (NSInteger) i;
- (void) drawWithFrame:(NSRect) cellFrame inView: (NSView *) controlView;
- (NSSize) cellSize;
- (void)setFaviconFudge:(CGFloat)f;
- (BOOL)isSelected;
- (void)setIsSelected:(BOOL)flag;
- (void)setDrawMouseOverHighlight:(BOOL)flag;


@end
