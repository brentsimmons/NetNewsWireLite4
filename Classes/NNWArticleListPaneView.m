//
//  NNWArticleListPaneView.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleListPaneView.h"
//#import "NNWArticleListHeaderView.h"


//@interface NNWArticleListPaneView ()
//@property (nonatomic, retain) NNWArticleListHeaderView *articleListHeaderView;
//@end


@implementation NNWArticleListPaneView

//@synthesize articleListHeaderView;

//#pragma mark Dealloc
//
//- (void)dealloc {
//	[articleListHeaderView release];
//	[super dealloc];
//}

#pragma mark Awake from Nib

//- (void)awakeFromNib {
//	self.articleListHeaderView = [[[NNWArticleListHeaderView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, [self bounds].size.width, 22.0f)] autorelease];
//	[self.articleListHeaderView setAutoresizingMask:NSViewWidthSizable];
//	[self addSubview:self.articleListHeaderView];
//}


#pragma mark Layout

//- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
//	NSScrollView *scrollView = (NSScrollView *)[self rs_firstSubviewOfClass:[NSScrollView class]];
//	NSRect rHeader = [self bounds];
//	rHeader.size.height = 17.0f;
//	rHeader.origin.y = NSMaxY([self bounds]) - rHeader.size.height;
//	[self.articleListHeaderView setFrame:rHeader];
//	NSRect rScrollView = [self bounds];
//	rScrollView.size.height = rScrollView.size.height - rHeader.size.height;
//	[scrollView setFrame:rScrollView];
//}


#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {	
	RSCGRectFillWithWhite(r);
}


@end
