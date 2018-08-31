//
//  NNWArticleListDocumentView.m
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleListDocumentView.h"
#import "NNWArticleListScrollView.h"
#import "RSSolidColorView.h"


@implementation NNWArticleListDocumentView


- (BOOL)canBecomeKeyView {
	return YES;
}


- (BOOL)acceptsFirstResponder {
	return YES;
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {
	//RSCGRectFillWithWhite(r);
	static NSColor *backgroundColor = nil;
	if (backgroundColor == nil)
//		backgroundColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"notepaper"]] retain];
//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, 0)];
						   
						   
		backgroundColor = [[[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.4f] retain];
	[backgroundColor set];
	NSRectFillUsingOperation(r, NSCompositeSourceOver);
	
	NNWArticleListScrollView *articleListScrollView = (NNWArticleListScrollView *)[self enclosingScrollView];
	CGFloat heightOfRows = articleListScrollView.heightOfAllRows;
	if (heightOfRows < 1.0f)
		return;
	NSRect rBackground = NSMakeRect(-1, heightOfRows, [self bounds].size.width + 2.0f, [self bounds].size.height - heightOfRows);
	if (NSIntersectsRect(r, rBackground)) {
		rBackground.size.height = 1;
		[[backgroundColor shadowWithLevel:0.2f] set];
		static CGColorRef shadowColor = nil;
		if (shadowColor == nil)
			shadowColor = CGColorCreateGenericGray(0.0f, 0.7f);
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSetShadow(context, CGSizeMake(0.0f, -1.0f), 2.0f);
		NSRectFillUsingOperation(rBackground, NSCompositeSourceOver);
	}		
}


@end
