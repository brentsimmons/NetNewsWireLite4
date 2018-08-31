//
//  NNWArticleDetailPaneView.m
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleDetailPaneView.h"


@interface NNWArticleDetailPaneView ()

@property (nonatomic, retain, readonly) NSImageView *screenshotViewForAnimation;
@end


@implementation NNWArticleDetailPaneView

@synthesize detailContentView;
@synthesize detailTemporaryView;
@synthesize screenshotViewForAnimation;


#pragma mark Dealloc

- (void)dealloc {
	[detailContentView release];
	[detailTemporaryView release];
	[screenshotViewForAnimation release];
	[super dealloc];
}


#pragma mark Detail Content View

/*HTML view (or could be something else, conceivably, like a video view.*/

static const CGFloat initialFadeInAnimationDuration = 1.2f;
static const CGFloat animationDuration = 0.25f;
static const CGFloat delayBeforeRemovingTemporaryView = 0.26f;

- (void)fadeInInitialContentView:(NSView *)aDetailContentView {
	detailContentView = [aDetailContentView retain];
	[self addSubview:detailContentView];
	[detailContentView setAlphaValue:0.0f];
	[detailContentView setFrame:[self bounds]];
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:initialFadeInAnimationDuration];
	[[detailContentView animator] setAlphaValue:1.0f];
	[NSAnimationContext endGrouping];	
}


- (NSImageView *)screenshotViewForAnimation {
	if (screenshotViewForAnimation == nil)
		screenshotViewForAnimation = [[NSImageView alloc] initWithFrame:[self bounds]];
	return screenshotViewForAnimation;
}


- (NSImage *)screenshotOfView:(NSView *)aView {

	[aView lockFocus];
	NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:[self bounds]] autorelease];	
	[aView unlockFocus];
	
	NSImage *screenshot = [[[NSImage alloc] initWithSize:[self bounds].size] autorelease];
	[screenshot lockFocus];
	[bitmap draw];
	[screenshot unlockFocus];
	
	return screenshot;
}


- (void)animateScreenshotViewToZeroAlpha {

	[self.screenshotViewForAnimation setFrame:[self bounds]];
	[self.screenshotViewForAnimation setHidden:NO];
	[self.screenshotViewForAnimation setAlphaValue:1.0f];

	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:animationDuration];
	[[self.screenshotViewForAnimation animator] setAlphaValue:0.0f];
	[self performSelector:@selector(hideScreenshotView) withObject:nil afterDelay:delayBeforeRemovingTemporaryView];
	[NSAnimationContext endGrouping];	
}


- (void)animateOutDetailTemporaryView {

	[self.screenshotViewForAnimation setImage:[self screenshotOfView:self.detailTemporaryView]];
	[self.detailTemporaryView removeFromSuperview];
	[detailTemporaryView autorelease];
	detailTemporaryView = nil;
	[self.screenshotViewForAnimation removeFromSuperview];
	[self addSubview:self.screenshotViewForAnimation positioned:NSWindowAbove relativeTo:self.detailContentView];
	[self animateScreenshotViewToZeroAlpha];
}


- (void)setDetailContentView:(NSView *)aDetailContentView {
	
	if (aDetailContentView != nil && detailContentView == nil && detailTemporaryView == nil) {
		[self fadeInInitialContentView:aDetailContentView];
		return;
	}
	
	if (detailContentView != aDetailContentView) {
		[detailContentView removeFromSuperview];
		[detailContentView autorelease];
		detailContentView = [aDetailContentView retain];
	}
	
	if (detailContentView != nil) {
		if (![detailContentView isDescendantOf:self])
			[self addSubview:detailContentView];
		if ([detailContentView isHidden])
			[detailContentView setHidden:NO];
		if ([detailContentView alphaValue] < 0.99f)
			[detailContentView setAlphaValue:1.0f];
		if (!NSEqualRects([self bounds], [detailContentView frame]))
			[detailContentView setFrame:[self bounds]];
	}
	 	
	if (detailTemporaryView != nil)
		[self animateOutDetailTemporaryView];
}


- (void)setDetailTemporaryView:(NSView *)aDetailTemporaryView {
	if (detailTemporaryView == aDetailTemporaryView)
		return;
	[detailTemporaryView removeFromSuperview];
	[detailTemporaryView release];
	
	detailTemporaryView = [aDetailTemporaryView retain];
	
	if (![self.screenshotViewForAnimation isDescendantOf:self])
		[self addSubview:self.screenshotViewForAnimation];
	[self.screenshotViewForAnimation setImage:[self screenshotOfView:self.detailContentView]];
	
	[self.detailContentView setHidden:YES];
	
	if ([detailTemporaryView isDescendantOf:self])
		[detailTemporaryView removeFromSuperview];
	[self addSubview:detailTemporaryView positioned:NSWindowBelow relativeTo:self.screenshotViewForAnimation];
	[detailTemporaryView setFrame:[self bounds]];

	[self animateScreenshotViewToZeroAlpha];
}


- (void)hideView:(NSView *)aView {
	[aView setHidden:YES];
}


- (void)hideScreenshotView {
	[self.screenshotViewForAnimation setHidden:YES];
	[self.screenshotViewForAnimation setImage:nil];
}


- (void)setNeedsDisplay {
	[self setNeedsDisplay:YES];
}


#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	[self.detailContentView setFrame:[self bounds]];
	[self.detailTemporaryView setFrame:[self bounds]];
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)r {
	RSCGRectFillWithWhite(r);
	
	NSImage *dishImage = [NSImage imageNamed:@"Dish"];
	NSSize dishImageSize = [dishImage size];
	NSRect rBounds = [self bounds];
	if (dishImageSize.width > rBounds.size.width || dishImageSize.height > rBounds.size.height)
		return;
	NSRect rDish = rBounds;
	rDish.size = dishImageSize;
	rDish.origin.x = NSMidX(rBounds) - (dishImageSize.width / 2);
	rDish.origin.y = NSMidY(rBounds) - (dishImageSize.height / 2);
	rDish = NSIntegralRect(rDish);

	if (CGRectIntersectsRect(r, rDish))
		[dishImage drawInRect:rDish fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.3f respectFlipped:YES hints:nil]; 

}

@end
