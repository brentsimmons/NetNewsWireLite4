//
//  NNWMainWindowStatusBarView.m
//  nnw
//
//  Created by Brent Simmons on 11/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWMainWindowStatusBarView.h"


@interface NNWMainWindowStatusBarView ()

@property (nonatomic, assign) CGFloat sourceListWidth;
@end


@implementation NNWMainWindowStatusBarView

#pragma mark Dealloc

- (void)dealloc {
	self.statusBarTextField = nil;
	[super dealloc];
}

#pragma mark AwakeFromNib

- (void)awakeFromNib {
//	[[self.statusBarTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceListDidResize:) name:NNWSourceListDidResizeNotification object:nil];
}


#pragma mark Layout

static const CGFloat minimumStatusTextLeftMargin = 203.0f;
static const CGFloat statusTextRightMargin = 172.0f;

- (void)layoutStatusText {
	
//	//[super resizeSubviewsWithOldSize:oldSize];
//	
//	/*The left edge of the status text field is pinned to the right edge of the source list.*/
//	CGRect rStatusBar = [self.statusBarTextField frame];
//	rStatusBar.origin.x = MAX(self.sourceListWidth, minimumStatusTextLeftMargin);
//	rStatusBar.size.width = [self bounds].size.width - (rStatusBar.origin.x + statusTextRightMargin);
//	if (rStatusBar.size.width < 1.0f)
//		rStatusBar.size.width = 0.0f;
//	[self.statusBarTextField setFrame:rStatusBar];
}


#pragma mark Notifications

- (void)sourceListDidResize:(NSNotification *)note {
//	NSView *callingView = [[note userInfo] objectForKey:NNWViewKey];
//	if (![callingView isDescendantOf:[[self window] contentView]])
//		return;
//	self.sourceListWidth = [[[note userInfo] objectForKey:NNWWidthKey] floatValue];
//	[self layoutStatusText];
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return NO;
}


@end
