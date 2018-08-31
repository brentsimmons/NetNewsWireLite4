/*
	RSImageTextCell.h
	RancheroAppKit
	
	Created by Brent Simmons on Sat Mar 15 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
	
	Descended from Apple's ImageAndTextCell sample code.
*/


#import "RSImageTextCell.h"
#import "RSAppKitCategories.h"


@implementation RSImageTextCell


- (void)dealloc {
	[image release];	
	image = nil;	
	[super dealloc];
	}


- (id)copyWithZone:(NSZone *)zone {
	RSImageTextCell *cell = (RSImageTextCell *)[super copyWithZone: zone];	
	cell->image = [image retain];	
	return cell;
	}


- (void)setImage:(NSImage *)anImage {
	[image autorelease];
	image = [anImage retain];
	}


- (NSImage *)image {
	return image;
	}


- (void)setDrawMouseOverHighlight:(BOOL)flag {
	_drawMouseOverHighlight = flag;
	}
	
	
- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {

	if (!image)
		return NSZeroRect;

	NSRect imageFrame;
	imageFrame.size = [image size];		
	imageFrame.origin = cellFrame.origin;
	imageFrame.origin.x += 3;
	imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2) + 1;
	return imageFrame;
	}


- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {	
	NSRect textFrame, imageFrame;	
	NSDivideRect(aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);	
	[super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
	}


- (void)setPadding:(NSInteger)i {
	padding = i;
	}
	

- (void)setVerticalTextOffset:(NSInteger)i {
	_verticalTextOffset = i;
	}
	
	
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	NSRect textFrame, imageFrame;
	NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
	[super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
	}


NSString *RSImageTextCellGeneva = @"Geneva Regular";

- (NSInteger)fontFudge {
	return fontFudge;
	}


- (void)setFontFudge:(NSInteger)n {
	fontFudge = n;
	}


- (void)setFont:(NSFont *)f {
	[super setFont:f];
	if (([f pointSize] == 9) && ([[f displayName] isEqualToString:RSImageTextCellGeneva])) {
		[self setFontFudge:1];
		geneva9 = YES;
		}
	else {
		[self setFontFudge:0];
		geneva9 = NO;
		}
	}
	

- (void)setFaviconFudge:(CGFloat)f {
	faviconFudge = f;
	}
	
	
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

	if (image) {
 
		NSSize imageSize;
		NSRect imageFrame;
		NSInteger pad = padding;
	   
		if (pad < 0 || pad > 20)
			pad = 3;
		imageSize = [image size];
		NSDivideRect(cellFrame, &imageFrame, &cellFrame, pad + imageSize.width, NSMinXEdge);
		
		if ([self drawsBackground] && !_drawMouseOverHighlight) {		
			[[self backgroundColor] set];			
			NSRectFill(imageFrame);
			}
		
		imageFrame.origin.x += 3;		
		imageFrame.size = imageSize;		
			
		if ([controlView isFlipped])
			imageFrame.origin.y += (ceil ((cellFrame.size.height + imageFrame.size.height) / 2) - 1);
		else
			imageFrame.origin.y += (ceil ((cellFrame.size.height - imageFrame.size.height) / 2) + 1);
	
		imageFrame.origin.y += faviconFudge;
		[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
		}
	else {
		cellFrame.origin.x += 3;
		cellFrame.size.width -= 3;
		}
	NSInteger adjustedOffset = _verticalTextOffset + fontFudge;
	cellFrame.origin.y += adjustedOffset;
	cellFrame.size.height -= adjustedOffset;
	
	if ([self isSelected]) {
		NSAttributedString *val = [[[self objectValue] retain] autorelease];
		if ([val isKindOfClass:[NSAttributedString class]]) {
			NSMutableAttributedString *attString = [[val mutableCopy] autorelease];
			[attString removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [attString length])];
			if ([controlView rs_isOrIsDescendedFromFirstResponder])
				[attString addAttribute:NSForegroundColorAttributeName value:[NSColor rs_grayWithFloat:0.4] range:NSMakeRange(0, [attString length])];
			else
				[attString addAttribute:NSForegroundColorAttributeName value:[NSColor rs_grayWithFloat:0.75] range:NSMakeRange(0, [attString length])];
			if ([controlView isFlipped])
				cellFrame.origin.y++;
			else
				cellFrame.origin.y--;
			[self setObjectValue:attString];
			[super drawWithFrame:cellFrame inView:controlView];
			if ([controlView isFlipped])
				cellFrame.origin.y--;
			else
				cellFrame.origin.y++;
			[self setObjectValue:val];
			}		
		}
		
	[super drawWithFrame:cellFrame inView:controlView];
	}



- (NSSize)cellSize {
	NSSize cellSize = [super cellSize];	
	cellSize.width += (image ? [image size].width : 0) + 13;	
	return cellSize;
	}


- (BOOL)isSelected {
	return _selected;
	}
	
	
- (void)setIsSelected:(BOOL)flag {
	_selected = flag;
	}


@end
