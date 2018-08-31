//
//  RSContainerWithTableWindowController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSContainerWithTableWindowController.h"
#import "NNWAddFeedsGroupRowView.h"
#import "NNWAddFeedsRowView.h"
#import "SLViewControllerProtocols.h"


@implementation RSContainerWithTableWindowController

@synthesize containerView;
@synthesize pluginTableView;


#pragma mark Init

- (id)initWithPlugins:(NSArray *)somePlugins {
	return [self initWithPlugins:somePlugins windowNibName:@"AddFeedsContainerWindow"];
}


#pragma mark Dealloc

- (void)dealloc {
	[self.pluginTableView removeObserver:self forKeyPath:@"selectedRowIndexes"];
	[pluginTableView release];
	[containerView release];
	[super dealloc];
}


#pragma mark NSViewController

- (void)windowDidLoad {
	NSMutableArray *pluginsCopy = [[self.plugins mutableCopy] autorelease];
	self.plugins = pluginsCopy;
	[self.pluginTableView reloadData];
	[self.pluginTableView addObserver:self forKeyPath:@"selectedRowIndexes" options:0 context:nil];
	[self.pluginTableView selectTopRow];
}


#pragma mark View Controller Switching

- (void)resizeWindowToFitView:(NSView *)aView {
	NSRect viewRect = [aView frame];
	NSRect windowRect = [self.window frame];
	NSRect tableViewRect = [self.pluginTableView frame];
	CGFloat updatedWidthOfWindow = tableViewRect.size.width + viewRect.size.width;
	windowRect.size.width = updatedWidthOfWindow;
	[self.window setFrame:windowRect display:YES animate:YES];
	[[self.window contentView] resizeSubviewsWithOldSize:NSZeroSize];
	[self.containerView resizeSubviewsWithOldSize:NSZeroSize];
}


- (NSView *)currentView {
	NSArray *subviews = [self.containerView subviews];
	if (RSIsEmpty(subviews))
		return nil;
	return [subviews objectAtIndex:0];
}


- (void)switchToPlugin:(id<SLSelectableViewControllerPlugin>)aPlugin {
	NSView *currentView = [self currentView];
	if (aPlugin.view == currentView)
		return;
	[self.window setTitle:aPlugin.windowTitle];
		[self resizeWindowToFitView:aPlugin.view];
	if (currentView != nil)
		[[self.containerView animator] replaceSubview:currentView with:aPlugin.view];
	else
		[self.containerView addSubview:aPlugin.view];
	[aPlugin.view setNextResponder:(NSResponder *)aPlugin];
	[(NSResponder *)aPlugin setNextResponder:self.containerView];
	[[self.window contentView] resizeSubviewsWithOldSize:NSZeroSize];
	[self.containerView resizeSubviewsWithOldSize:NSZeroSize];
}


- (void)switchToPluginWithSelectedRowIndexes:(NSIndexSet *)selectedRowIndexes {
	NSUInteger firstIndex = [selectedRowIndexes firstIndex];
	if (firstIndex != NSNotFound)
		[self switchToPlugin:[self.plugins objectAtIndex:firstIndex]];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"selectedRowIndexes"] && object == self.pluginTableView)
		[self switchToPluginWithSelectedRowIndexes:self.pluginTableView.selectedRowIndexes];
}


#pragma mark Article List Scroll View Data Source

- (NSView *)listView:(id)listView viewForRow:(NSUInteger)row {
	
	id<SLSelectableViewControllerPlugin> plugin = [self.plugins objectAtIndex:row];
	
	NSString *reuseIdentifier = nil;
	Class viewClass = nil;
	
	BOOL isGroupItem = [plugin respondsToSelector:@selector(isGroupItem)] && [plugin isGroupItem];
	if (isGroupItem) {
		reuseIdentifier = @"AddFeedsGroupCell";
		viewClass = [NNWAddFeedsGroupRowView class];
	}
	else {
		reuseIdentifier = @"AddFeedsCell";
		viewClass = [NNWAddFeedsRowView class];
	}

	NSView *aView = [listView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (aView == nil)
		aView = [[[viewClass alloc] init] autorelease];
	
	[aView setFrame:NSMakeRect(0.0f, 0.0f, 300.0f, [self listView:listView heightForRow:row])];
	((NNWAddFeedsRowView *)(aView)).title = plugin.windowTitle;
	((NNWAddFeedsRowView *)(aView)).image = [plugin.toolbarItem image];
	((NNWAddFeedsRowView *)(aView)).reuseIdentifier = reuseIdentifier;
	return aView;	
}


- (CGFloat)listView:(id)listView heightForRow:(NSUInteger)row {
	id<SLSelectableViewControllerPlugin> plugin = [self.plugins objectAtIndex:row];
	if ([plugin respondsToSelector:@selector(isGroupItem)] && [plugin isGroupItem])
		return 24.0f;
//	if (row > 1)
//		return 24.0f;
	return 64.0f;
}


- (NSUInteger)numberOfRowsInListView:(id)listView {
	return [self.plugins count];
}


- (BOOL)listView:(id)listView shouldSelectRow:(NSUInteger)row {
	id<SLSelectableViewControllerPlugin> plugin = [self.plugins objectAtIndex:row];
	if ([plugin respondsToSelector:@selector(isGroupItem)] && plugin.isGroupItem)
		return NO;
	return YES;
}

#pragma mark Toolbar

/*Superclass has a toolbar instead of a tableview, so these over-rides are necessary.*/

- (void)toolbarItemClicked:(id)sender {
}


- (void)setupToolbar {
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	return nil;
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return nil;
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return nil;
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return nil;
}


#pragma mark Actions

- (void)cancel:(id)sender {
	[[self window] close];
}

@end

@implementation RSContainerWithTableContentView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSView *tableViewScrollView = [self rs_firstSubviewOfClass:[NSScrollView class]];
	NSAssert(tableViewScrollView != nil, @"Table view must not be nil.");
	NSView *containerView = [self rs_firstSubviewOfClass:[RSContainerWithTableContainerView class]];
	NSAssert(containerView != nil, @"Container view must not be nil.");
	NSRect rTable = [tableViewScrollView frame];
	NSRect rContainer = [containerView frame];
	rTable.origin.x = 0;
	rTable.origin.y = 0;
	rTable.size.height = [self bounds].size.height + 1;
	[tableViewScrollView setFrame:rTable];
	rContainer.origin.x = NSMaxX(rTable);
	rContainer.origin.y = 0;
	rContainer.size.height = rTable.size.height - 1;
	[containerView setFrame:rContainer];
}

@end

							 

@implementation RSContainerWithTableContainerView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSRect rBounds = [self bounds];
	for (NSView *oneSubview in [self subviews]) {
		NSRect r = [oneSubview frame];
		r = CGRectIntegral(CGRectCenteredInRect(r, rBounds));
		[oneSubview setFrame:r];
	}
}


- (void)drawRect:(NSRect)dirtyRect {
	NSRect r = NSMakeRect(0, 0, 1, NSHeight([self bounds]));
	if (NSIntersectsRect(dirtyRect, r)) {
		[[NSColor grayColor] set];
		NSRectFillUsingOperation(r, NSCompositeSourceOver);
	}
}

@end

@implementation RSContainerTableView

- (BOOL)acceptsFirstResponder {
	return NO;
}


@end
