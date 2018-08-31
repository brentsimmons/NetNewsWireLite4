/*
	RSDiskFileDownloadView.h
	NetNewsWire

	Created by Brent Simmons on 12/14/04.
	Copyright 2004 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>


@class RSDiskFileDownloadRequest;
@class RSDiskFileDownloadItemView;
@class RSPopupButton;


@interface RSDiskFileDownloadView : NSView {

	@private
		NSMutableArray *itemViews;
		NSInteger indexOfSelectedItem;
		BOOL updateAllScheduled;
	}


- (void)addViewForRequest:(RSDiskFileDownloadRequest *)request;
- (void)addViewsForRequests:(NSArray *)requests;

- (CGFloat)collapsedRowHeight;
- (CGFloat)expandedRowHeight;

- (void)mouseDownInItemView:(RSDiskFileDownloadItemView *)itemView;

- (BOOL)isItemViewSelected:(RSDiskFileDownloadItemView *)itemView;

- (NSMenu *)menuForPopupButton:(NSButton *)button;


@end
