//
//  NNWSourceListView.m
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSourceListView.h"
#import "RSAppKitCategories.h"


//TODO: see if NSSystemColorsDidChangeNotification sends note when selectedTextBackgroundColor changes.
//If so, we create the highlightGradient once and store it until the color changes.

@interface NSObject (NNWSourceListContextualMenu)

- (NSMenu *)contextualMenuForRow:(NSInteger)aRow;
@end


@implementation NNWSourceListView

- (void)drawHighlightForRow:(NSInteger)row {

	NSRect rect = NSIntegralRect([self rectOfRow:row]);

	NSColor *baseColor = [NSColor selectedTextBackgroundColor];
	NSColor *darkGradientColor = baseColor;
	NSColor *lightGradientColor = [baseColor highlightWithLevel:0.4f];
	
	NSGradient *highlightGradient = [[[NSGradient alloc] initWithStartingColor:darkGradientColor endingColor:lightGradientColor] autorelease];
	[highlightGradient drawInRect:rect angle:-90.0f];
}


//- (void)drawFolderBackgroundForRow:(NSInteger)row {
//	NSRect rect = NSIntegralRect([self rectOfRow:row]);
//
//	static NSColor *backgroundColor = nil;
//	if (backgroundColor == nil)
//		backgroundColor = [[[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.8f] retain];
//	[backgroundColor set];
//	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
//
//	
////	NSColor *baseColor = [NSColor colorWithDeviceWhite:0.82 alpha:1.0];
////	NSColor *darkGradientColor = baseColor;
////	NSColor *lightGradientColor = [NSColor colorWithDeviceWhite:0.85 alpha:1.0];
////	
////	NSGradient *highlightGradient = [[[NSGradient alloc] initWithStartingColor:darkGradientColor endingColor:lightGradientColor] autorelease];
////	[highlightGradient drawInRect:rect angle:-90.0f];	
//}


- (void)highlightSelectionInClipRect:(NSRect)clipRect {

	if (![self rs_isOrIsDescendedFromFirstResponder]) {
		[super highlightSelectionInClipRect:clipRect];
		return;
	}
	NSRange rangeOfRows = [self rowsInRect:clipRect];
	if (rangeOfRows.length < 1)
		return;
	NSUInteger row = 0;
	[[self backgroundColor] set];
	NSRectFillUsingOperation(clipRect, NSCompositeSourceOver);
	for (row = rangeOfRows.location; row <= rangeOfRows.location + rangeOfRows.length ; row++) {
		if ([self isRowSelected:(NSInteger)row])
			[self drawHighlightForRow:(NSInteger)row];
//		else if ([self isExpandable:[self itemAtRow:(NSInteger)row]])
//			[self drawFolderBackgroundForRow:(NSInteger)row];
	}
}


- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row {
	NSRect outlineCellFrame = [super frameOfOutlineCellAtRow:row];
	if (NSEqualRects(NSZeroRect, outlineCellFrame))
		return outlineCellFrame;
	outlineCellFrame.origin.x = outlineCellFrame.origin.x - 2.0f;//20.0f;
	return outlineCellFrame;
}


- (void)setFramex:(NSRect)frameRect {
	NSRect rScrollView = [[self enclosingScrollView] frame];
	if (frameRect.size.width > rScrollView.size.width) {
		[self setNeedsDisplay:YES];
		frameRect.size.width = rScrollView.size.width;
	}
	[super setFrame:frameRect];
}


- (void)viewDidEndLiveResize {
	[self setNeedsDisplay:YES];
}


#pragma mark Drag and Drop

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	if (isLocal)
		return NSDragOperationMove;
	return NSDragOperationCopy;
}


//#pragma mark -
//#pragma mark Text Delegate
//
//- (id<NNWSourceListViewTextDelegate>)sourceListTextDelegate {
//	return (id<NNWSourceListViewTextDelegate>)[self delegate];
//}
//
//
//- (BOOL)textShouldBeginEditing:(NSText *)textObject {
//	if ([[self sourceListTextDelegate] respondsToSelector:@selector(textShouldBeginEditing:)])
//		return [[self sourceListTextDelegate] textShouldBeginEditing:textObject];
//	return YES;
//}
//
//
//- (BOOL)textShouldEndEditing:(NSText *)textObject {
//	if ([[self sourceListTextDelegate] respondsToSelector:@selector(textShouldEndEditing:)])
//		return [[self sourceListTextDelegate] textShouldEndEditing:textObject];
//	return YES;
//}
//
//
//- (void)textDidBeginEditing:(NSNotification *)notification {
//	if ([[self sourceListTextDelegate] respondsToSelector:@selector(textDidBeginEditing:)])
//		[[self sourceListTextDelegate] textDidBeginEditing:notification];
//}
//
//
//- (void)textDidEndEditing:(NSNotification *)notification {
//	if ([[self sourceListTextDelegate] respondsToSelector:@selector(textDidEndEditing:)])
//		[[self sourceListTextDelegate] textDidEndEditing:notification];
//}
//
//
//- (void)textDidChange:(NSNotification *)notification {
//	if ([[self sourceListTextDelegate] respondsToSelector:@selector(textDidChange:)])
//		[[self sourceListTextDelegate] textDidChange:notification];
//}


#pragma mark -
#pragma mark Events

- (void)collapseAll {	
	NSInteger ct = [self numberOfRows];
	NSInteger i;	
	for (i = ct - 1; i >= 0; i--) {
		id item = [self itemAtRow:i];
		[self collapseItem: item collapseChildren:YES];		
	}	
}


- (void)expandAll {	
	NSInteger i;	
	for (i = 0; i < [self numberOfRows]; i++) {		
		id item = [self itemAtRow:i];		
		[self expandItem:item expandChildren:YES];		
	}	
}


- (void)collapseItemOrCollapseItemToParent {
	
	NSInteger ix = [self selectedRow];
	NSInteger origLevel = [self levelForRow:ix];
	id selectedItem = [self itemAtRow:ix];
	id nomad = nil;
	
	if (([self isExpandable:selectedItem]) && ([self isItemExpanded:selectedItem])) {
		[self collapseItem:selectedItem];
		return;
	}
	
	while (true) {
		
		NSInteger currentLevel;
		ix--;
		currentLevel = [self levelForRow:ix];
		if (currentLevel >= origLevel)
			continue;
		if (currentLevel < origLevel - 1)
			break;			
		nomad = [self itemAtRow:ix];
		if ([self isExpandable:nomad]) {
			[self collapseItem:nomad];
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)[self rowForItem:nomad]] byExtendingSelection:NO];
			return;			
		}
		break;
	}
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
	
	switch(ch) {
			
		case ';':
			if (!anyModifierKeyDown) {				
				[self collapseAll];
				return;
			}
			break;
			
		case '\'':			
			if (!anyModifierKeyDown) {				
				[self expandAll];
				return;
			}
			break;
			
		case '.':			
			if (!anyModifierKeyDown) {				
				[self expandItem:[self itemAtRow:[self selectedRow]]];			
				return;
			}
			break;
			
		case ',':
			if (!anyModifierKeyDown) {				
				[self collapseItemOrCollapseItemToParent];
				return;
			}
			break;
			
		case NSLeftArrowFunctionKey:
			if (optionKeyDown && commandKeyDown && !shiftKeyDown && !controlKeyDown) {
				[self collapseAll];
				return;
			}
			if (commandKeyDown && !optionKeyDown && !shiftKeyDown && !controlKeyDown) {
				[self collapseItemOrCollapseItemToParent];
				return;
			}
			break;
			
		case NSRightArrowFunctionKey:
			if (!anyModifierKeyDown) {
				[self tryToPerform:@selector(moveFocusToArticleListAndSelectTopRowIfNeeded:) with:nil];
				return;
			}
			if (optionKeyDown && commandKeyDown && !shiftKeyDown && !controlKeyDown) {
				[self expandAll];
				return;
			}
			if (commandKeyDown && !optionKeyDown && !shiftKeyDown && !controlKeyDown) {
				[self expandItem:[self itemAtRow:[self selectedRow]]];
				return;
			}
			break;
			
	}
	
	[super keyDown:event];	
}


- (NSMenu *)menuForEvent:(NSEvent *)event {
	NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:mousePoint]; 
	
	if (row >= 0 && [[self delegate] respondsToSelector:@selector(contextualMenuForRow:)]) {
		[self rs_goToRow:row];		
		return [(id)[self delegate] contextualMenuForRow:row];
	}
	
	return nil; 	
}


@end
