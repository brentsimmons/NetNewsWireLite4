//
//  NNWArticleListScrollView.m
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleListScrollView.h"


@interface NSObject (NNWArticleListContextualMenus)

- (NSMenu *)contextualMenuForRow:(NSUInteger)row;
@end


@interface NNWArticleListScrollView ()

@property (nonatomic, retain) NSMutableArray *enqueuedViews;
@property (nonatomic, retain) NSMutableArray *visibleViews;
@property (nonatomic, retain) NSMutableDictionary *rowToViewMap;
@property (nonatomic, assign) NSUInteger numberOfRows;
@property (nonatomic, retain, readwrite) NSIndexSet *selectedRowIndexes;
@property (nonatomic, assign) NSUInteger indexOfFirstVisibleRow;

- (void)addViewsForVisibleRows;
- (NSUInteger)rowForView:(NSView *)aView;
- (NSUInteger)rowAtPoint:(NSPoint)point;
- (void)selectRow:(NSUInteger)aRow scrollToVisibleIfNeeded:(BOOL)scrollToVisibleIfNeeded;

@end


@implementation NNWArticleListScrollView

@synthesize delegate;
@synthesize enqueuedViews;
@synthesize heightOfAllRows;
@synthesize indexOfFirstVisibleRow;
@synthesize numberOfRows;
@synthesize rowToViewMap;
@synthesize selected;
@synthesize selectedRowIndexes;
@synthesize visibleViews;


#pragma mark Init

- (void)commonInit {
	enqueuedViews = [[NSMutableArray array] retain];
	visibleViews = [[NSMutableArray array] retain];
	selectedRowIndexes = [[NSIndexSet indexSet] retain];
	rowToViewMap = [[NSMutableDictionary dictionary] retain];
}


- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self == nil)
		return nil;
	[self commonInit];
	return self;
}


- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	[self commonInit];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"selectedRowIndexes"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	delegate = nil;
	[selectedRowIndexes release];
	[enqueuedViews release];
	[visibleViews release];
	[rowToViewMap release];
	if (cachedViewYOrigins != NULL) {
		free(cachedViewYOrigins);
		cachedViewYOrigins = NULL;
	}
	[super dealloc];
}


#pragma mark AwakeFromNib

- (void)awakeFromNib {
	[[self contentView] setPostsBoundsChangedNotifications:YES];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewBoundsDidChange:) name:NSViewFrameDidChangeNotification object:[self contentView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[self contentView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewBoundsDidChange:) name:NNWMainWindowDidResizeNotification object:nil];
	[self addObserver:self forKeyPath:@"selectedRowIndexes" options:0 context:nil];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"selectedRowIndexes"]) {
		if ([self.delegate respondsToSelector:@selector(listViewSelectionDidChange:)])
			[self.delegate listViewSelectionDidChange:self];
	}
}

#pragma mark Notifications

- (void)contentViewBoundsDidChange:(NSNotification *)note {
//	NSLog(@"contentViewBoundsDidChange");
	[self addViewsForVisibleRows];
	[self tile];
}


#pragma mark Selection State

- (BOOL)rowIsSelected:(NSUInteger)aRow {
	NSUInteger anIndex = [self.selectedRowIndexes firstIndex];
	while (anIndex != NSNotFound) {
		if (anIndex == aRow)
			return YES;
		anIndex = [self.selectedRowIndexes indexGreaterThanIndex:anIndex];
	}
	return NO;
}


- (void)updateSelectionStateOfVisibleViews {
	for (NSView<NNWArticleListRowView> *oneView in self.visibleViews) {
		NSUInteger rowForView = [self rowForView:oneView];
		oneView.selected = [self rowIsSelected:rowForView];
	}
}


- (void)selectTopRow {
	NSUInteger proposedRowIndex = 0;
	while (true) {
		if ([self.delegate listView:self shouldSelectRow:proposedRowIndex]) {
			[self selectRow:proposedRowIndex scrollToVisibleIfNeeded:YES];
			return;
		}
		proposedRowIndex++;
		if (proposedRowIndex >= self.numberOfRows)
			break;
	}
}


- (void)selectLastRow {
	NSUInteger proposedRowIndex = self.numberOfRows - 1;
	while (true) {
		if ([self.delegate listView:self shouldSelectRow:proposedRowIndex]) {
			[self selectRow:proposedRowIndex scrollToVisibleIfNeeded:YES];
			return;
		}
		if (proposedRowIndex < 1)
			break;
		proposedRowIndex--;
	}	
}


- (BOOL)selectRow:(NSUInteger)aRow {
	if (aRow == NSNotFound || aRow >= self.numberOfRows)
		return NO;
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:aRow];
	[self updateSelectionStateOfVisibleViews];
	return YES;
}


- (void)selectRow:(NSUInteger)aRow scrollToVisibleIfNeeded:(BOOL)scrollToVisibleIfNeeded {
	if ([self selectRow:aRow]) {
		if (scrollToVisibleIfNeeded) {
			[self scrollRowToVisible:aRow];
			if (aRow < 2)
				[[self documentView] scrollPoint:NSZeroPoint];
		}
	}
}


- (void)selectNextRow {
	NSUInteger selectedRowIndex = [self.selectedRowIndexes firstIndex];
	if (selectedRowIndex == NSNotFound)
		return;
	NSUInteger proposedRowIndex = selectedRowIndex;
	while (true) {
		proposedRowIndex++;
		if (proposedRowIndex >= self.numberOfRows)
			return;
		if ([self.delegate listView:self shouldSelectRow:proposedRowIndex]) {
			[self selectRow:proposedRowIndex scrollToVisibleIfNeeded:YES];
			return;
		}
	}
}


- (void)selectPreviousRow {
	NSUInteger selectedRowIndex = [self.selectedRowIndexes firstIndex];
	if (selectedRowIndex == NSNotFound) 
		return;
	NSUInteger proposedRowIndex = selectedRowIndex;
	while (true) {
		proposedRowIndex--;
		if ([self.delegate listView:self shouldSelectRow:proposedRowIndex]) {
			[self selectRow:proposedRowIndex scrollToVisibleIfNeeded:YES];
			return;
		}
		if (proposedRowIndex == 0)
			return;
	}
}


- (void)selectPreviousRowOrLastRow {
	/*For up-arrow with no selection, select last row.*/
	NSUInteger selectedRowIndex = [self.selectedRowIndexes firstIndex];
	if (selectedRowIndex == NSNotFound) {
		[self selectLastRow];
		return;
	}
	[self selectPreviousRow];	
}


- (void)selectNextRowOrTopRow {
	/*For down-arrow with no selection, select top row.*/
	NSUInteger selectedRowIndex = [self.selectedRowIndexes firstIndex];
	if (selectedRowIndex == NSNotFound) {
		[self selectTopRow];
		return;
	}
	[self selectNextRow];	
}


- (void)selectTopRowIfNoneSelected {
	NSUInteger selectedRowIndex = [self.selectedRowIndexes firstIndex];
	if (selectedRowIndex == NSNotFound) {
		[self selectTopRow];
		return;
	}
}


#pragma mark Events


- (void)swipeWithEvent:(NSEvent *)event {
	
	if ([event deltaY] > 0.0f) {
		[self selectPreviousRow];
		return;
	}

	if ([event deltaY] < 0.0f) {
		[self selectNextRow];
		return;
	}
	
	if ([event deltaX] < 0.0f) {
		if ([[self delegate] respondsToSelector:@selector(listViewUserDidSwipeRight:)]) {
			[[self delegate] listViewUserDidSwipeRight:self];
			return;
		}
	}

	[super swipeWithEvent:event];
}


- (void)keyDown:(NSEvent *)event {

	NSString *s = [event characters];
	if (RSStringIsEmpty(s)) {
		[super keyDown:event];
		return;
	}
	
	unichar ch = [s characterAtIndex:0];
	BOOL shiftKeyDown = (([event modifierFlags] & NSShiftKeyMask) != 0);
	BOOL optionKeyDown = (([event modifierFlags] & NSAlternateKeyMask) != 0);
	BOOL commandKeyDown = (([event modifierFlags] & NSCommandKeyMask) != 0);
	BOOL controlKeyDown = (([event modifierFlags] & NSControlKeyMask) != 0);
	BOOL anyModifierKeyDown = shiftKeyDown || optionKeyDown || commandKeyDown || controlKeyDown;
	
	if (optionKeyDown && !commandKeyDown && !controlKeyDown && !shiftKeyDown) {
		
		switch (ch) {
				
			case NSUpArrowFunctionKey:
				[self selectTopRow];
				[[self window] makeFirstResponder:self];
				[NSCursor setHiddenUntilMouseMoves:YES];				
				return;

			case NSDownArrowFunctionKey:
				[self selectLastRow];
				[[self window] makeFirstResponder:self];
				[NSCursor setHiddenUntilMouseMoves:YES];				
				return;
				
			default:
				break;
		}
	}
	
	
	if (anyModifierKeyDown) {
		[super keyDown:event];
		return;
	}
	
	switch (ch) {
			
		case NSUpArrowFunctionKey:
			[self selectPreviousRowOrLastRow];
			[[self window] makeFirstResponder:self];
			[NSCursor setHiddenUntilMouseMoves:YES];
			return;
			
		case NSDownArrowFunctionKey:
			[self selectNextRowOrTopRow];
			[[self window] makeFirstResponder:self];
			[NSCursor setHiddenUntilMouseMoves:YES];
			return;
			
		case NSHomeFunctionKey:
			[self scrollRowToVisible:0];
			[[self window] makeFirstResponder:self];
			[NSCursor setHiddenUntilMouseMoves:YES];
			return;
			
		case NSEndFunctionKey:
			[self scrollRowToVisible:self.numberOfRows - 1];
			[[self window] makeFirstResponder:self];
			[NSCursor setHiddenUntilMouseMoves:YES];
			return;
	}
	
	[super keyDown:event];
}


- (BOOL)canBecomeKeyView {
	return YES;
}


- (BOOL)acceptsFirstResponder {
	return YES;
}


- (void)mouseUp:(NSEvent *)theEvent {
	NSPoint mousePoint = [theEvent locationInWindow];
	mousePoint = [[self documentView] convertPoint:mousePoint fromView:nil];
	NSUInteger selectedRow = [self rowAtPoint:mousePoint];
	if (selectedRow == NSNotFound)
		return;
	if ([self.delegate respondsToSelector:@selector(listView:shouldSelectRow:)] && ![self.delegate listView:self shouldSelectRow:selectedRow])
		 return;
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:selectedRow];
	[self updateSelectionStateOfVisibleViews];
	if ([theEvent clickCount] == 2) {
		if ([self.delegate respondsToSelector:@selector(listView:rowWasDoubleClicked:)])
			[self.delegate listView:self rowWasDoubleClicked:selectedRow];
	}
}


- (void)mouseUpInArticleListView:(id)sender {
//	[self.selectedRowIndexes removeAllIndexes];
//	[self.selectedRowIndexes addIndex:[self rowForView:sender]];
//	[self updateSelectionStateOfVisibleViews];
}


#pragma mark Contextual Menus

- (NSMenu *)menuForEvent:(NSEvent *)event {
	
	NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	NSUInteger row = [self rowAtPoint:mousePoint]; 
	
	if (row == NSNotFound || ![[self delegate] listView:self shouldSelectRow:row] || ![[self delegate] respondsToSelector:@selector(contextualMenuForRow:)])
		return nil;
	
	[self selectRow:(NSUInteger)row];
	return [(id)[self delegate] contextualMenuForRow:row];
}


#pragma mark Layout

- (void)calculateYOrigins {
	if (cachedViewYOrigins != NULL) {
		free(cachedViewYOrigins);
		cachedViewYOrigins = NULL;
	}
	if (self.numberOfRows < 1)
		return;
	cachedViewYOrigins = (CGFloat *)malloc(sizeof(CGFloat) * self.numberOfRows);
	CGFloat currentYOrigin = 0.0f;
	NSUInteger row = 0;
	for (row = 0; row < self.numberOfRows; row++) {
		cachedViewYOrigins[row] = currentYOrigin;
		currentYOrigin = currentYOrigin + [self.delegate listView:self heightForRow:row];
	}
}


- (void)calculateHeightOfAllRows {
	/*calculateYOrigins should have been called first.*/
	if (self.numberOfRows < 1) {
		self.heightOfAllRows = 0.0f;
		return;
	}
	CGFloat originOfLastRow = cachedViewYOrigins[self.numberOfRows - 1];
	CGFloat heightOfLastRow = [self.delegate listView:self heightForRow:(self.numberOfRows - 1)];
	self.heightOfAllRows = originOfLastRow + heightOfLastRow;	
}


- (NSRect)contentViewRect {
	NSSize contentViewSize = [[self class] contentSizeForFrameSize:[self frame].size hasHorizontalScroller:NO hasVerticalScroller:([self frame].size.height < self.heightOfAllRows) borderType:[self borderType]];
	return NSMakeRect(0.0f, 0.0f, contentViewSize.width, contentViewSize.height);
}


- (NSSize)contentSize {
	return [self contentViewRect].size;
}


- (NSRect)rectOfRow:(NSUInteger)row {
	if (cachedViewYOrigins == nil)
		return NSZeroRect;
	NSSize contentSize = [self contentSize];
	NSRect rectOfRow = NSZeroRect;
	rectOfRow.size.width = contentSize.width;
	rectOfRow.size.height = [self.delegate listView:self heightForRow:row];
	rectOfRow.origin.y = cachedViewYOrigins[row];
	rectOfRow.origin.x = 0.0f;
	return rectOfRow;
}


- (void)scrollRowToVisible:(NSUInteger)row {
	NSRect rRow = [self rectOfRow:row];
	[[self documentView] scrollRectToVisible:rRow];
}


- (BOOL)rectIsCompletelyVisible:(NSRect)aRect {
	return NSContainsRect([self documentVisibleRect], aRect);
}


- (BOOL)scrollRowToMiddleIfNotVisible:(NSUInteger)row {
	
	NSRect rRow = [self rectOfRow:row];
	if ([self rectIsCompletelyVisible:rRow])
		return YES;
	
	NSRect rVisible = [self documentVisibleRect];
	CGFloat rowMidY = CGRectGetMidY(rRow);
	NSPoint scrollPoint = NSMakePoint(0.0f, 0.0f);
	scrollPoint.y = rowMidY - (rVisible.size.height / 2.0f);
	
	scrollPoint.y = floor(scrollPoint.y);
	scrollPoint.y = scrollPoint.y + 24.0f; //just to raise it a little
	if (scrollPoint.y < 0.0f)
		scrollPoint.y = 0.0f;
	
	NSRect rDocumentView = [[self documentView] frame];
	CGFloat maxScrollPointY = rDocumentView.size.height - rVisible.size.height;
	if (scrollPoint.y > maxScrollPointY)
		scrollPoint.y = maxScrollPointY;
	
	//[[self documentView] scrollPoint:scrollPoint];
	
//	rDocumentView.size.height = self.frame.size.height;
//	rDocumentView.size.width = [self contentSize].width;
//	rDocumentView.size.width = [self bounds].size.width;
//	[[self documentView] setFrame:rDocumentView];
//	NSRect rContentView = [[self contentView] frame];
	NSRect rbContentView = [[self contentView] bounds];
	NSClipView *clipView = [self contentView];
	
	NSRect updatedClipViewBounds = NSMakeRect(scrollPoint.x, scrollPoint.y, rbContentView.size.width, rbContentView.size.height);
//	NSDictionary *clipViewAnimation = [NSDictionary dictionaryWithObjectsAndKeys:clipView, NSViewAnimationTargetKey, [NSValue valueWithRect:updatedClipViewBounds], NSViewAnimationEndFrameKey, nil];
//	NSArray *animations = [NSArray arrayWithObject:clipViewAnimation];
//	NSViewAnimation *viewAnimation = [[[NSViewAnimation alloc] initWithViewAnimations:animations] autorelease];
//	[viewAnimation setAnimationBlockingMode:NSAnimationBlocking];
//    [viewAnimation setDuration:2.5];
//	
//    [viewAnimation startAnimation];
	
//	NSLog(@"a: %@", [clipView animations]);
//	NSLog(@"ap: %@", [[clipView animator] animations]);
//	NSAnimation *animation = [[[NSAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseOut] autorelease];
//	[animation setAnimationBlockingMode:NSAnimationBlocking];
//	[clipView setAnimations:[NSDictionary dictionaryWithObject:animation forKey:@"bounds"]];
	//[clipView setWantsLayer:YES];
	[[clipView animator] setBounds:updatedClipViewBounds];
	
//	[NSAnimationContext beginGrouping];
//	[[NSAnimationContext currentContext] setDuration:0.3f];
//	[[clipView animator] setBounds:NSMakeRect(scrollPoint.x, scrollPoint.y, rbContentView.size.width, rbContentView.size.height)];
//	[NSAnimationContext endGrouping];	
	
	return NO;
}


- (NSUInteger)rowAtPoint:(NSPoint)point {
	NSUInteger oneRow = 0;
	for (oneRow = 0; oneRow < self.numberOfRows; oneRow++) {
		NSRect oneRowRect = [self rectOfRow:oneRow];
		if (NSPointInRect(point, oneRowRect))
			return oneRow;
	}
	return NSNotFound;
}


- (void)updateDocumentFrame {
	//NSLog(@"updateDocumentFrame");
	CGFloat documentHeight = self.heightOfAllRows;
	if (documentHeight < self.frame.size.height)
		documentHeight = self.frame.size.height;
	NSRect rDocumentView = NSZeroRect;
	rDocumentView.size.height = documentHeight;
	rDocumentView.size.width = [self contentSize].width;
//	rDocumentView.size.width = [self bounds].size.width;
	[[self documentView] setFrame:rDocumentView];
}


- (void)updateContentFrame {
	//[[self contentView] setFrame:[self contentViewRect]];
}


- (NSUInteger)rowForView:(NSView *)aView {
	for (NSNumber *oneKey in self.rowToViewMap) {
		NSView *oneView = [self.rowToViewMap objectForKey:oneKey];
		if (oneView == aView)
			return [oneKey unsignedIntegerValue];
	}
	return NSNotFound;
}


- (void)tile {
//	NSLog(@"tile");
	[super tile];
	//NSUInteger currentRow = self.indexOfFirstVisibleRow;
	for (NSView *oneView in self.visibleViews) {
		NSUInteger rowForView = [self rowForView:oneView];
		[oneView setFrame:[self rectOfRow:rowForView]];
		//currentRow++;
	}
	[self updateDocumentFrame];
	[self updateContentFrame];
	[self setNeedsDisplay:YES];
	if ([self verticalScroller] != nil)
		[[self verticalScroller] setNeedsDisplay:YES];
}


- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize {
	[super resizeWithOldSuperviewSize:oldBoundsSize];
	//NSLog(@"resizeWithOldSuperviewSize");
	[self addViewsForVisibleRows];
	[self tile];
}


#pragma mark Data

- (void)enqueueOneView:(NSView *)aView {
	[aView setHidden:YES];
	[self.enqueuedViews addObject:aView];
	[self.visibleViews removeObjectIdenticalTo:aView];
	[aView removeFromSuperview];
}


- (void)enqueueVisibleViews {
	for (NSView *oneView in self.visibleViews)
		[self enqueueOneView:oneView];
}


- (NSView<NNWArticleListRowView> *)mappedViewForRow:(NSUInteger)row {
	return [self.rowToViewMap objectForKey:[NSNumber numberWithUnsignedInteger:row]];
}


- (void)addView:(NSView *)aView toMapForRow:(NSUInteger)row {
	[self.rowToViewMap setObject:aView forKey:[NSNumber numberWithUnsignedInteger:row]];
}


- (void)removeMappedViewsNotInRange:(NSRange)rangeOfVisibleRows {
	NSMutableArray *keysToRemove = [NSMutableArray array];
	for (NSNumber *oneKey in self.rowToViewMap) {
		NSUInteger oneRow = [oneKey unsignedIntegerValue];
		if (oneRow < rangeOfVisibleRows.location)
			[keysToRemove addObject:oneKey];
		else if (oneRow > rangeOfVisibleRows.location + rangeOfVisibleRows.length)
			[keysToRemove addObject:oneKey];
	}
	if (RSIsEmpty(keysToRemove))
		return;
	for (NSNumber *oneKey in keysToRemove)
		[self enqueueOneView:[self.rowToViewMap objectForKey:oneKey]];
	[self.rowToViewMap removeObjectsForKeys:keysToRemove];
}


- (NSRange)rangeOfVisibleRows {
	NSRect documentVisibleRect = [[self contentView] documentVisibleRect];
	NSRange range = NSMakeRange(NSNotFound, 0);
	for (NSUInteger row = 0; row < self.numberOfRows; row++) {
		BOOL rowIsInRect = NSIntersectsRect([self rectOfRow:row], documentVisibleRect);
		if (range.location == NSNotFound && rowIsInRect)
			range = NSMakeRange(row, 1);
		else if (range.location != NSNotFound && rowIsInRect)
			range.length = range.length + 1;
		else if (range.location != NSNotFound && !rowIsInRect)
			break;
	}
	return range;
}


- (void)addViewsForVisibleRows {
	NSRange rangeOfVisibleRows = [self rangeOfVisibleRows];
	NSUInteger row = 0;
	self.indexOfFirstVisibleRow = rangeOfVisibleRows.location;
	for (row = rangeOfVisibleRows.location; row < rangeOfVisibleRows.location + rangeOfVisibleRows.length; row++) {
		NSView *oneVisibleView = [self mappedViewForRow:row];
		if (oneVisibleView == nil) {
			oneVisibleView = [self.delegate listView:self viewForRow:row];
			[self addView:oneVisibleView toMapForRow:row];
			[oneVisibleView setNeedsDisplay:YES];
		}
		if (![oneVisibleView isDescendantOf:[self documentView]]) {
			[[self documentView] addSubview:oneVisibleView];
			[oneVisibleView setNeedsDisplay:YES];
		}
		if ([oneVisibleView isHidden]) {
			[oneVisibleView setHidden:NO];
			[oneVisibleView setNeedsDisplay:YES];
		}
		if ([self.visibleViews indexOfObjectIdenticalTo:oneVisibleView] == NSNotFound) {
			[self.visibleViews addObject:oneVisibleView];
			[oneVisibleView setNeedsDisplay:YES];		
		}
		BOOL rowIsSelected = [self rowIsSelected:row];
		if (rowIsSelected != ((id<NNWArticleListRowView>)oneVisibleView).selected)
			((id<NNWArticleListRowView>)oneVisibleView).selected = rowIsSelected;
	}
	[self removeMappedViewsNotInRange:rangeOfVisibleRows];
}


- (void)reloadDataWithoutResettingSelectedRowIndexes {
	self.rowToViewMap = [NSMutableDictionary dictionary];
	[self.enqueuedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	self.enqueuedViews = [NSMutableArray array];
	[self.visibleViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	self.visibleViews = [NSMutableArray array];
	self.numberOfRows = [self.delegate numberOfRowsInListView:self];
	[self calculateYOrigins];
	[self calculateHeightOfAllRows];
	[self updateDocumentFrame];
	[self addViewsForVisibleRows];
	
	/*Make document view size of scrollview so that it scrolls to top.*/
	NSRect rDocumentView = NSZeroRect;
	rDocumentView.size.height = self.frame.size.height;
	rDocumentView.size.width = [self contentSize].width;
	rDocumentView.size.width = [self bounds].size.width;
	[[self documentView] setFrame:rDocumentView];
	
	[self tile];
}


- (void)reloadData {
	self.selectedRowIndexes = [NSIndexSet indexSet];
	[self reloadDataWithoutResettingSelectedRowIndexes];
}


- (NSView<NNWArticleListRowView> *)dequeueReusableCellWithIdentifier:(NSString *)identifier {
	NSUInteger i = 0;
	for (i = 0; i < [self.enqueuedViews count]; i++) {
		NSView<NNWArticleListRowView> *oneView = [self.enqueuedViews objectAtIndex:i];
		if ([identifier isEqualToString:[oneView reuseIdentifier]]) {
			[[[oneView retain] autorelease] prepareForReuse];
			[self.enqueuedViews removeObjectAtIndex:i];
			return oneView;
		}
	}
	return nil;
}


#pragma mark Items

- (id)itemAtRow:(NSUInteger)row {
	if ([self.delegate respondsToSelector:@selector(itemInListView:atRow:)])
		return [self.delegate itemInListView:self atRow:row];
	return nil;
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}

- (void)drawRect:(NSRect)r {
//	RSCGRectFillWithWhite(r);
	static NSColor *backgroundColor = nil;
	if (backgroundColor == nil)
		backgroundColor = [[[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.4f] retain];
//		backgroundColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"notepaper"]] retain];
//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, 0)];
//	[backgroundColor set];
	[backgroundColor set];
	[[NSColor blackColor] set];
	NSRectFillUsingOperation(r, NSCompositeSourceOver);
}


@end

