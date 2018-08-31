/*
	RSDiskFileDownloadView.m
	NetNewsWire

	Created by Brent Simmons on 12/14/04.
	Copyright 2004 Ranchero Software. All rights reserved.
*/


#import "RSDiskFileDownloadView.h"
#import "RSDiskFileDownloadItemView.h"
#import "RSDiskFileDownloadRequest.h"
#import "RSDiskFileDownloadsWindowController.h"
#import "RSDiskFileDownloadController.h"


const CGFloat NNWCollapsedFileDownloadItemViewHeight = 40.0;
const CGFloat NNWExpandedFileDownloadItemViewHeight = 56.0;


@interface RSDiskFileDownloadView (Forward)
- (NSInteger)indexOfItemView:(RSDiskFileDownloadItemView *)itemView;
- (void)setItemViews:(NSMutableArray *)anArray;
- (void)tile;
- (NSRect)frameForItemViewAtIndex:(NSInteger)ix;
- (void)removeViewForRequest:(RSDiskFileDownloadRequest *)request;
- (void)scheduleUpdateAll;
- (void)registerForNotifications;
@end


@implementation RSDiskFileDownloadView


#pragma mark Init

- (void)commonInit {
	indexOfSelectedItem = -1;
	[self setItemViews:[NSMutableArray arrayWithCapacity:5]];
	[self registerForNotifications];
	}


- (id)initWithFrame:(NSRect)r {
	self = [super initWithFrame:r];
	if (self)
		[self commonInit];
	return (self);
	}


- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self)
		[self commonInit];
	return (self);
	}
	

#pragma mark Dealloc

- (void)dealloc {
	[itemViews release];
	[super dealloc];
	}
	

#pragma mark Accessors

- (void)setItemViews:(NSMutableArray *)anArray {
	[itemViews autorelease];
	itemViews = [anArray retain];
	}
	

#pragma mark Selected item

- (RSDiskFileDownloadItemView *)selectedItemView {
	if ((indexOfSelectedItem < 0) || (indexOfSelectedItem == NSNotFound))
		return nil;
	return [itemViews rs_safeObjectAtIndex:indexOfSelectedItem];
	}
	

- (NSInteger)indexOfSelectedItem {
	return (indexOfSelectedItem);
	}


- (void)setIndexOfSelectedItem:(NSInteger)ix {
	RSDiskFileDownloadItemView *selectedView = nil;
	indexOfSelectedItem = ix;
	[self setNeedsDisplay:YES];
	[itemViews makeObjectsPerformSelector:@selector(updateTextFields)];
	selectedView = [self selectedItemView];
	if (selectedView != nil)
		[[self window] makeFirstResponder:selectedView];
	}
	

- (BOOL)isItemViewSelected:(RSDiskFileDownloadItemView *)itemView {
	if ((indexOfSelectedItem < 0) || (indexOfSelectedItem == NSNotFound))
		return NO;
	return (indexOfSelectedItem == [self indexOfItemView:itemView]);
	}
	

- (NSRect)rectOfSelectedItemView {
	if ((indexOfSelectedItem < 0) || (indexOfSelectedItem == NSNotFound))
		return (NSZeroRect);
	return [self frameForItemViewAtIndex:indexOfSelectedItem];
	}
	
	
#pragma mark Events

- (void)mouseDownInItemView:(RSDiskFileDownloadItemView *)itemView {
	NSInteger ix = [self indexOfItemView:itemView];
	[self setIndexOfSelectedItem:ix];
	}
	

- (void)mouseDown:(NSEvent *)event {
	[self setIndexOfSelectedItem:-1];
	[super mouseDown:event];
	}
	

- (void)keyDown:(NSEvent *)event {
	
	if ([itemViews count] < 1)
		return;
		
	NSString *s = [event characters];
	if (!RSIsEmpty(s)) {
		unichar ch = [s characterAtIndex: 0];

		switch (ch) {
		
			case NSUpArrowFunctionKey:

				if (indexOfSelectedItem < 0)
					[self setIndexOfSelectedItem:[itemViews count] - 1];
				else if (indexOfSelectedItem > 0)
					[self setIndexOfSelectedItem:indexOfSelectedItem - 1];
				return;

			case NSDownArrowFunctionKey:
				
				if (indexOfSelectedItem < 0) {
					[self setIndexOfSelectedItem:0];
					return;
					}
				if (indexOfSelectedItem >= [itemViews count] - 1)
					return;
				[self setIndexOfSelectedItem:indexOfSelectedItem + 1];
				return;
			}
		}
	[super keyDown:event];
	}
	

#pragma mark Gear menu


- (void)addRemoveAllCommandToMenu:(NSMenu *)menu {

	NSMenuItem *menuItem = (NSMenuItem *)[menu addItemWithTitle:NNW_REMOVE_COMPLETED_DOWNLOADS
		action:@selector(clearDownloads:)
		keyEquivalent:@""];
	
	if ([[RSDiskFileDownloadController sharedController] numberOfDeletableRequests] > 0)
		[menuItem setTarget:[[self window] windowController]];
	else
		[menuItem setAction:nil];
	}


- (NSMenu *)menuForPopupButton:(NSButton *)button {
	
	RSDiskFileDownloadItemView *itemView = [self selectedItemView];
	NSMenu *menu = nil;
	
	if (itemView == nil)
		menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	else
		menu = [itemView contextualMenu];
	
	if ([menu numberOfItems] > 0)
		[menu addItem:[NSMenuItem separatorItem]];
	[self addRemoveAllCommandToMenu:menu];
	
	return (menu);
	}
	
	
#pragma mark Notifications

- (void)registerForNotifications {
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleItemDidChangeDownloadingStatus:) name:RSDiskFileDownloadItemDidChangeDownloadingStatusNotification object:nil];

	/*Window*/
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericWindowDidChangeStatusNotification:) name:NSWindowDidBecomeKeyNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericWindowDidChangeStatusNotification:) name:NSWindowDidResignKeyNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(handleGenericWindowDidChangeStatusNotification:)
		name:NSWindowDidBecomeMainNotification
		object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGenericWindowDidChangeStatusNotification:) name:NSWindowDidResignMainNotification object:[self window]];	

	/*File downloads*/
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileDownloadDidGetRemoved:) name:RSDiskFileDownloadDidGetRemovedNotification object:[self window]];	
	}
	
	
- (void)handleItemDidChangeDownloadingStatus:(NSNotification *)note {
	[self tile];
	[self setNeedsDisplay:YES];
	}
	

- (void)handleGenericWindowDidChangeStatusNotification:(NSNotification *)note {
	[self setNeedsDisplayInRect:[self rectOfSelectedItemView]];
	[[self selectedItemView] updateTextFields];	
	}


- (void)handleFileDownloadDidGetRemoved:(NSNotification *)note {
	[self removeViewForRequest:[note object]];
	[self scheduleUpdateAll];
	}
	
	
#pragma mark Request views

- (NSInteger)indexOfItemView:(RSDiskFileDownloadItemView *)itemView {
	return [itemViews indexOfObjectIdenticalTo:itemView];
	}
	
	
- (void)addViewForRequest:(RSDiskFileDownloadRequest *)request {
	RSDiskFileDownloadItemView *newView = [[[RSDiskFileDownloadItemView alloc] initWithFrame:NSZeroRect] autorelease];
	[newView setRequest:request];
	[itemViews addObject:newView];
	[self addSubview:newView];
	[self tile];
	}
	

- (void)addViewsForRequests:(NSArray *)requests {
	
	NSInteger i;
	NSInteger ct = [requests count];
	
	for (i = 0; i < ct; i++) {
		RSDiskFileDownloadRequest *oneRequest = [requests rs_safeObjectAtIndex:i];
		if (oneRequest != nil)
			[self addViewForRequest:oneRequest];
		}
	}
	
	
- (void)removeViewForRequest:(RSDiskFileDownloadRequest *)request {
	
	NSInteger i;
	NSInteger ct = [itemViews count];
	
	for (i = 0; i < ct; i++) {		
		RSDiskFileDownloadItemView *oneView = [itemViews rs_safeObjectAtIndex:i];
		id oneRequest = [oneView request];
		if (request == oneRequest) {
			[[oneView retain] autorelease];
			[oneView removeFromSuperview];
			[itemViews removeObjectAtIndex:i];
			if (indexOfSelectedItem >= ct - 1)
				indexOfSelectedItem = ct - 2;
			break;
			}		
		}
	
	[self performSelectorOnMainThread:@selector(tile) withObject:nil waitUntilDone:NO];
	}
	
	
#pragma mark Layout

- (BOOL)isFlipped {
	return YES;
	}


- (CGFloat)collapsedRowHeight {
	return (NNWCollapsedFileDownloadItemViewHeight);
	}


- (CGFloat)expandedRowHeight {
	return (NNWExpandedFileDownloadItemViewHeight);
	}
	

- (CGFloat)heightForRow:(NSInteger)row {

	if (row <= [itemViews count]) {
		RSDiskFileDownloadItemView *itemView = [itemViews rs_safeObjectAtIndex:row];
		if ((itemView != nil) && ([itemView isDownloading]))
			return [self expandedRowHeight];
		}
		
	return [self collapsedRowHeight];
	}
	

- (CGFloat)yOriginOfRow:(NSInteger)row {		
	if (row <= 0)
		return (0.0);
	return [self yOriginOfRow:row - 1] + [self heightForRow:row - 1];
	}
	
	
- (NSRect)frameForItemViewAtIndex:(NSInteger)ix {
	
	NSRect r = [self bounds];
	
	r.size.height = [self heightForRow:ix];
	r.size.width = [[self enclosingScrollView] contentSize].width;
	r.origin.x = 0;
	r.origin.y = [self yOriginOfRow:ix];
	
	return r;
	}
	
	
- (void)recalculateFrame {
	
	NSInteger ct = [itemViews count];
	NSRect r = [self frameForItemViewAtIndex:ct - 1];
	CGFloat h = r.origin.y + r.size.height;
	CGFloat hContentView = [[self enclosingScrollView] contentSize].height;
	NSRect rFrame = [self bounds];
	
	if (h < hContentView)
		h = hContentView;
		
	rFrame.size.width = [[self enclosingScrollView] contentSize].width;
	rFrame.size.height = h;
	rFrame.origin.x = 0;
	rFrame.origin.y = 0;
	
	[self setFrame:rFrame];
	}


- (void)tile {
	
	NSInteger i;
	NSInteger ct = [itemViews count];
	
	for (i = 0; i < ct; i++) {
		RSDiskFileDownloadItemView *oneView = [itemViews rs_safeObjectAtIndex:i];
		[oneView setFrame:[self frameForItemViewAtIndex:i]];
		[oneView tile];
		}
	
	[self recalculateFrame];
	}


- (void)updateAllItemViews {
	
	NSInteger i;
	NSInteger ct = [itemViews count];
	for (i = 0; i < ct; i++) {
		RSDiskFileDownloadItemView *oneView = [itemViews rs_safeObjectAtIndex:i];
		[oneView setFrame:[self frameForItemViewAtIndex:i]];
		[oneView tile];
		[oneView updateAll];
		[oneView setNeedsDisplay:YES];
		}
	}
	

- (void)scheduleUpdateAll {
	if (updateAllScheduled)
		return;
	updateAllScheduled = YES;
	[self performSelectorOnMainThread:@selector(updateAll) withObject:nil waitUntilDone:NO];
	}
	
	
- (void)updateAll {
	[self tile];
	[self updateAllItemViews];
	[self setNeedsDisplay:YES];
	updateAllScheduled = NO;
	}
	
	
- (void)resizeSubviewsWithOldSize:(NSSize)s {
	[self tile];
	}
	
	
#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
	}
	
	
- (BOOL)isFirstResponder {
	return (([NSApp isActive]) && ([[self window] isKeyWindow]));
	}


- (void)drawRect:(NSRect)r {
	
	NSInteger i = 0;
	NSInteger ct = 1;
	NSArray *colors = [NSColor controlAlternatingRowBackgroundColors];
	NSColor *evenColor = [colors rs_safeObjectAtIndex:0];
	NSColor *oddColor = [colors rs_safeObjectAtIndex:1];
	CGFloat w = [[self enclosingScrollView] contentSize].width;
	CGFloat boundsHeight = [self bounds].size.height;
	BOOL flDidIntersect = NO;
	
	if (!evenColor)
		evenColor = [NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.966 alpha:1.0];
	if (!oddColor)
		oddColor = [NSColor whiteColor];

	while (true) {
		
		NSRect rStripe;
		NSInteger row = ct - 1;
		CGFloat h = [self heightForRow:row];
		
		rStripe.size.height = h;
		rStripe.size.width = w;
		rStripe.origin.x = 0;
		rStripe.origin.y = i;
		
		if (i > boundsHeight)
			break;
			
		if (NSIntersectsRect (rStripe, r)) {
			flDidIntersect = YES;
			if (row == indexOfSelectedItem) {
				if ([self isFirstResponder])
					[[NSColor alternateSelectedControlColor] set];
				else
					[[NSColor secondarySelectedControlColor] set];
				}
			else {
				if ((ct % 2) == 0)
					[evenColor set];
				else
					[oddColor set];
				}
			NSRectFill (rStripe);
			}
			
		else {
			if (flDidIntersect)
				break;
			}
			
		i += h;
		ct++;
		}
	}


@end
