//
//  NNWDockIconController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWDockIconController.h"
#import "NNWAppDelegate.h"


@interface NNWDockIconController ()

@property (nonatomic, assign) BOOL showingAlternateIcon;

- (void)updateDockIcon;
@end


@implementation NNWDockIconController

@synthesize showingAlternateIcon;

#pragma mark Class Methods

+ (NNWDockIconController *)sharedController {
	static id gMyInstance = nil;
	if (gMyInstance == nil)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	[nnw_app_delegate addObserver:self forKeyPath:@"unreadCount" options:NSKeyValueObservingOptionInitial context:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[nnw_app_delegate removeObserver:self forKeyPath:@"unreadCount"];
	[super dealloc];}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"unreadCount"])
		[self updateDockIcon];
}


#pragma mark Drawing

static NSImageView *gDockTileImageView = nil;

- (void)ensureDockTileImageView {
	if (!gDockTileImageView) {
		gDockTileImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 256, 256)];
		[[NSApp dockTile] setContentView:gDockTileImageView];
	}
}


- (void)updateDockTileWithAlternateIcon {
	[self ensureDockTileImageView];
	[gDockTileImageView setImage:[NSImage imageNamed:@"appIconNoRays"]];
	self.showingAlternateIcon = YES;
	[[NSApp dockTile] display];
}


- (void)updateDockTileWithStandardIcon {
	[self ensureDockTileImageView];
	[gDockTileImageView setImage:[NSImage imageNamed:@"appIcon"]];
	self.showingAlternateIcon = NO;
	[[NSApp dockTile] display];	
}


- (void)updateDockBadgeWithUnreadCount:(NSUInteger)unread {
	static NSUInteger lastUnread = NSNotFound;
	if (unread == 0 && self.showingAlternateIcon)
		[self updateDockTileWithStandardIcon];
	else if (unread > 0 && !self.showingAlternateIcon)
		[self updateDockTileWithAlternateIcon];
//	if (lastUnread == 0 && unread != 0)
//		[self updateDockTileWithAlternateIcon];
//	if (lastUnread != 0 && unread == 0)
//		[self updateDockTileWithStandardIcon];
	if (lastUnread == unread)
		return;
	lastUnread = unread;
	@try { /*This appears to have been implicated in some crashes.*/
		NSDockTile *dockTile = [NSApp dockTile];
		if (dockTile) {
			[dockTile setBadgeLabel:(unread > 0) ? [NSString stringWithFormat:@"%ld", (unsigned long)unread] : @""];
			[[NSApp dockTile] display];	
		}
	}
	@catch(id obj) {
	}
	return;
}


- (void)updateDockIcon {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateDockIcon:) withObject:nil waitUntilDone:NO];
		return;
	}
	[self updateDockBadgeWithUnreadCount:nnw_app_delegate.unreadCount];
}


@end
