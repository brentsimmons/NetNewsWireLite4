//
//  RSAppKitExtras.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSAppKitCategories.h"
#import "RSFoundationExtras.h"


@implementation NSBezierPath (RSCore)

- (void)rs_appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(CGFloat) radius {
    NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
    NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
    
    [self moveToPoint:topMid];
    [self appendBezierPathWithArcFromPoint:topLeft toPoint:aRect.origin radius:radius];
    [self appendBezierPathWithArcFromPoint:aRect.origin toPoint:bottomRight radius:radius];
    [self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight radius:radius];
    [self appendBezierPathWithArcFromPoint:topRight toPoint:topLeft radius:radius];
    [self closePath]; 
} 


- (void)rs_drawRect:(NSRect)rect withGradientFrom:(NSColor*)colorStart to:(NSColor*)colorEnd { 
    NSRect t1, t2, t3; 
    CGFloat r, g, b,a; 
    CGFloat rdiff, gdiff, bdiff, adiff; 
    NSInteger i; 
    CGFloat index = rect.size.height; 
    t1 = rect; 
    
    r = [colorStart redComponent]; 
    g = [colorStart greenComponent]; 
    b = [colorStart blueComponent]; 
    a = [colorStart alphaComponent]; 
    
    rdiff = ([colorEnd redComponent] - r)/index; 
    gdiff = ([colorEnd greenComponent] - g)/index; 
    bdiff = ([colorEnd blueComponent] - b)/index; 
    adiff = ([colorEnd alphaComponent] - a)/index; 
    
    for ( i = 0; i < index; i++ ) 
    { 
        NSDivideRect ( t1, &t2, &t3, 1.0, NSMinYEdge); 
        [[NSColor colorWithDeviceRed:r green:g blue:b alpha:a] set]; 
        NSRectFillUsingOperation(t2, NSCompositeSourceOver); 
        r += rdiff; 
        g += gdiff; 
        b += bdiff; 
        a += adiff; 
        t1 = t3; 
    } 
} 


@end

#pragma mark -

NSString *NSColorInterfaceColor = @"InterfaceColor";

void RSSetInterfaceColor(CGFloat f) {
    [[NSColor rs_interfaceColor:f] set];
}


NSColor *RSInterfaceColor(CGFloat n) {
    return [NSColor rs_interfaceColor:n];
}


NSColor *RSGray(CGFloat grayValue) {
    return [NSColor rs_grayWithFloat:grayValue];
}


NSColor *RSRGBColor(NSUInteger red, NSUInteger green, NSUInteger blue) {
    return [NSColor colorWithCalibratedRed:(red/255.0) green:(green/255.0) blue:(blue/255.0) alpha:1.0];
}

@implementation NSColor (RSCore)

+ (NSColor *)rs_grayWithFloat:(CGFloat)grayValue {
    /*Done this way so it will work in gradients. Or something like that.*/
    return [NSColor colorWithCalibratedRed:grayValue green:grayValue blue:grayValue alpha:1.0];
}


+ (NSColor *)rs_grayBorderColor {
    static NSColor *grayBorderColor = nil;
    if (!grayBorderColor)
        grayBorderColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
    return grayBorderColor;
}


+ (NSColor *)rs_darkGrayBorderColor {
    static NSColor *darkGrayBorderColor = nil;
    if (!darkGrayBorderColor)
        darkGrayBorderColor = [NSColor colorWithCalibratedWhite:0.36 alpha:1.0];
    return darkGrayBorderColor;
}


+ (NSColor *)rs_borderColor {
    static NSColor *borderColor = nil;
    if (!borderColor)
        borderColor = RSGray(0.25);
    return borderColor;
}


static NSColor *_interfaceColor = nil;

+ (void)rs_updateInterfaceColor {
    //[_interfaceColor autorelease];
    _interfaceColor = nil;
}


+ (NSColor *)rs_interfaceColor {
    if (_interfaceColor)
        return _interfaceColor;
    NSColor *color = nil;
    if (color) {
        _interfaceColor = color;
        return color;
    }
    return [self rs_coolBlueColor];
}



static NSColor *coolBlueColor = nil;

+ (void)rs_setCoolBlueColor:(NSColor *)color {
    coolBlueColor = color;
}


+ (void)rs_updateCoolBlueColor {
    if ([NSColor currentControlTint] == NSGraphiteControlTint)
        [self rs_setCoolBlueColor:RSRGBColor(129, 145, 175)];
    else
        [self rs_setCoolBlueColor:RSRGBColor(82, 120, 197)];
}


+ (NSColor *)rs_coolBlueColor {
    if (!coolBlueColor)
        [self rs_updateCoolBlueColor];
    return coolBlueColor;
}


+ (NSColor *)rs_grayWindowBackgroundColor {
    static NSColor *color = nil;
    if (!color)
        color = RSGray(0.94);
    return color;
}


+ (NSColor *)rs_lightInterfaceColor {
    return [self rs_interfaceColor:0.85];
}


+ (NSColor *)rs_interfaceColor:(CGFloat)n {
    if (n < 0)
        return [[NSColor rs_interfaceColor] shadowWithLevel:0.0 - n];
    return [[NSColor rs_interfaceColor] highlightWithLevel:n];
}


@end

#pragma mark -

@implementation NSControl (RSCore)

- (void)rs_safeSetStringValue:(NSString *)s {
    [self setStringValue:s != nil ? s : @""];
}

@end


#pragma mark -

@implementation NSImage (RSCore)

+ (NSImage *)rs_image:(NSImage *)sourceImage scaledToSize:(NSSize)size {
    CGFloat resizeWidth = size.width;
    CGFloat resizeHeight = size.height;
    NSImage *resizedImage = [[NSImage alloc] initWithSize:NSMakeSize(resizeWidth, resizeHeight)];
    NSSize originalSize = [sourceImage size];
    [resizedImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setShouldAntialias:YES];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [sourceImage drawInRect:NSMakeRect(0, 0, resizeWidth, resizeHeight) fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [resizedImage unlockFocus];
    return resizedImage;
}


- (BOOL)rs_canBeDrawn {
    
    if (![self isValid])
        return NO;
    if (NSEqualSizes(NSZeroSize, [self size]))
        return NO;
    
    NSUInteger countReps = [[self representations] count];    
    if (countReps < 1)
        return NO;
    if (countReps == 1) {
        
        /*Discovered through trial and error that images that can't be drawn
         have a single representation of type NSCachedImageRep.*/
        
        id rep = [[self representations] rs_safeObjectAtIndex:0];
        if (rep == nil)
            return NO;
        if ([[rep className] isEqualToString:@"NSCachedImageRep"])
            return NO;        
    }
    
    return YES;
}


- (NSBitmapImageRep *)rs_firstBitmapImageRep {
    NSUInteger i;
    for (i = 0; i < [[self representations] count]; i++) {
        NSImageRep *oneImageRep = [[self representations] rs_safeObjectAtIndex:i];
        if (oneImageRep && [oneImageRep isKindOfClass:[NSBitmapImageRep class]])
            return (NSBitmapImageRep *)oneImageRep;
    }
    return nil;
}


@end


#pragma mark -

@implementation NSMenu (RSCore)

- (void)rs_removeAllItems {    
    NSInteger ctItems = [self numberOfItems];
    if (ctItems < 1)
        return;    
    NSInteger i;
    for (i = ctItems - 1; i >= 0; i--)        
        [self removeItemAtIndex:i];    
}


- (BOOL)rs_lastItemIsSeparatorItem {
    NSInteger ctItems = [self numberOfItems];
    if (ctItems < 1)
        return NO;
    NSMenuItem *lastItem = [self itemAtIndex:ctItems - 1];
    return [lastItem isSeparatorItem];
}


- (void)rs_addSeparatorItemIfLastItemIsNotSeparator {
    if (![self rs_lastItemIsSeparatorItem])
        [self rs_addSeparatorItem];
}


- (void)rs_addSeparatorItem {    
    [self addItem:[NSMenuItem separatorItem]];
}


- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent target:(id)target representedObject:(id)obj {
    
    if (!keyEquivalent)
        keyEquivalent = @"";
    
    NSMenuItem *menuItem = (NSMenuItem *)[self addItemWithTitle:title action:action keyEquivalent:keyEquivalent];
    
    if (target)
        [menuItem setTarget:target];
    if (obj)
        [menuItem setRepresentedObject:obj];
    return menuItem;
}


- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent target:(id)target {    
    return [self rs_addItemWithTitle:title action:action keyEquivalent:keyEquivalent target:target representedObject:nil];
}


- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action target:(id)target representedObject:(id)obj {    
    return [self rs_addItemWithTitle:title action:action keyEquivalent:nil target:target representedObject:obj];    
}


- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action target:(id)target {
    return [self rs_addItemWithTitle:title action:action keyEquivalent:nil target:target representedObject:nil];    
}


@end


#pragma mark -

@implementation NSMenuItem (RSCore)


+ (NSMenuItem *)rs_menuItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)target
                representedObject:(id)obj tag:(NSInteger)tag {
    return [[self alloc] rs_initWithTitle:aString action:aSelector target:target
                      representedObject:obj tag:tag];
}


+ (NSMenuItem *)rs_menuItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)target {
    NSMenuItem *item = [[self alloc] rs_initWithTitle:aString action:aSelector];
    if (!item)
        return nil;
    [item setTarget:target];
    return item;
}


- (id)rs_initWithTitle:(NSString *)aString action:(SEL)aSelector {
    return [self initWithTitle:aString action:aSelector keyEquivalent:@""];
}


- (id)rs_initWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)target representedObject:(id)obj tag:(NSInteger)tag {
    NSMenuItem *item = [self rs_initWithTitle:aString action:aSelector];
    if (!item)
        return nil;
    [item setTarget:target];
    [item setRepresentedObject:obj];
    [item setTag:tag];
    [item setEnabled:YES];
    return item;
}


- (void)rs_setStateWithBoolean:(BOOL)flag {
    if (flag)
        [self setState:NSOnState];
    else
        [self setState:NSOffState];
}


@end


#pragma mark -

@implementation NSOutlineView (RSCore)

- (BOOL)rs_isFirstResponderAndItemIsSelected: (id) item {
    
    /*If the app is active, and the outline view is first responder,
     and the item is selected, then return YES. The idea is that
     this is when you need to use white text against the selection
     highlight color.*/
    
    BOOL flSelected = ([self isRowSelected:[self rowForItem: item]]);
    
    if ((flSelected) && ([NSApp isActive]) && ([[self window] isKeyWindow])) {
        
        NSResponder *responder = nil;
        BOOL flFirstResponder = NO;                    
        
        responder = [[self window] firstResponder];    
        if ((responder != nil) && ([responder isKindOfClass: [NSView class]])) {
            if ([self isDescendantOf: (NSView *) responder])
                flFirstResponder = YES;
        }                    
        return (flFirstResponder);
    }
    
    return (NO);
}


- (BOOL)rs_isItemSelected:(id)item {
    return [self isRowSelected:[self rowForItem:item]];
}


- (NSArray *)rs_selectedItems {
    NSIndexSet *selectedRows = [self selectedRowIndexes];
    if (RSIsEmpty(selectedRows))
        return nil;
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[selectedRows count]];
    NSUInteger oneIndex = [selectedRows firstIndex];
    NSUInteger lastIndex = [selectedRows lastIndex];
    while (true) {
        [items rs_safeAddObject:[self itemAtRow:(NSInteger)oneIndex]];
        if (oneIndex >= lastIndex)
            break;
        oneIndex = [selectedRows indexGreaterThanIndex:oneIndex];
    }
    return items;    
}


- (void)rs_selectItemsWithArray:(NSArray *)selectedItems {
    if (RSIsEmpty(selectedItems)) {
        [self deselectAll:self];
        return;
    }
    NSUInteger i = 0;
    NSInteger ixRow = -1;
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (i = 0; i < [selectedItems count]; i++) {
        ixRow = [self rowForItem:[selectedItems objectAtIndex:i]];
        if (ixRow != -1)
            [indexSet addIndex:(NSUInteger)ixRow];
    }
    if (RSIsEmpty(indexSet))
        [self deselectAll:self];
    else
        [self selectRowIndexes:indexSet byExtendingSelection:NO];
}


@end


#pragma mark -

@implementation NSShadow (RSCore)

+ (void)rs_setShadowWithBlurRadius:(CGFloat)blurRadius color:(NSColor *)color offset:(NSSize)offset {
    static NSShadow *gShadow = nil;
    if (!gShadow)
        gShadow = [[NSShadow alloc] init];
    [gShadow setShadowBlurRadius:blurRadius];
    [gShadow setShadowColor:color];
    [gShadow setShadowOffset:offset];
    [gShadow set];
}


@end

#pragma mark -

@implementation NSString (RSCoreAppKit)

- (NSSize)rs_sizeWithFont:(NSFont *)font andWidth:(CGFloat)w {    
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(w, 1e7)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:1.0];
    [textStorage addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [textStorage length])];
    [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:2.0];    
    [layoutManager addTextContainer:textContainer];    
    [textStorage addLayoutManager:layoutManager];    
    (void)[layoutManager glyphRangeForTextContainer:textContainer];    
    NSSize size = [layoutManager usedRectForTextContainer:textContainer].size;
    [textStorage removeLayoutManager:layoutManager];
    [layoutManager removeTextContainerAtIndex:0];
    return size;
}


@end


#pragma mark -

@implementation NSTableView (RSCore)

- (NSMenu *)rs_menuForEvent:(NSEvent *)event {
    
    NSPoint pt = [self convertPoint: [event locationInWindow] fromView: nil];
    id <RSTableViewContextualMenuHandler> tableViewDelegate = (id <RSTableViewContextualMenuHandler>)[self delegate];    
    NSInteger column = [self columnAtPoint: pt];
    NSInteger row= [self rowAtPoint: pt]; 
    
    if (column >= 0 && row >= 0 && [[self delegate] respondsToSelector:@selector(menuForTableColumn:row:)]) {
        [self rs_goToRow:row];        
        return [tableViewDelegate rs_menuForTableColumn:[[self tableColumns] objectAtIndex:(NSUInteger)column] row:row];
    }
    
    return nil; 
}


- (NSInteger)rs_absoluteSelectedRow {
    return [self selectedRow];
}


- (NSIndexSet *)rs_absoluteSelectedRowIndexes {
    return [self selectedRowIndexes];
}


- (void)rs_goToRow:(NSInteger)row {
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
    //    [self selectRow:row byExtendingSelection:NO];    
    [self scrollRowToVisible:row];
}


- (void)rs_goToAbsoluteRow:(NSInteger)row {
    [self rs_goToRow:row];
}


- (BOOL)rs_isFirstResponderAndRowIsSelected: (NSInteger) row {
    
    /*If the app is active, and the table view is first responder,
     and the row is selected, then return YES. The idea is that
     this is when you need to use white text against the selection
     highlight color.*/
    
    BOOL flSelected = ([self rs_absoluteSelectedRow] == row);
    
    if ((flSelected) && ([NSApp isActive]) && ([[self window] isKeyWindow])) {
        
        NSResponder *responder = nil;
        BOOL flFirstResponder = NO;                    
        
        responder = [[self window] firstResponder];    
        if ((responder != nil) && ([responder isKindOfClass: [NSView class]])) {
            if ([self isDescendantOf: (NSView *) responder])
                flFirstResponder = YES;
        }                    
        return flFirstResponder;
    }
    
    return NO;
}


- (void)rs_setIndicatorImage:(NSImage *)image inTableColumn:(NSTableColumn *)column andRemoveOthers:(BOOL)flRemoveOthers {
    
    NSArray *tableColumns = [self tableColumns];
    NSEnumerator *enumerator = [tableColumns objectEnumerator];
    NSTableColumn *oneColumn;
    
    if (flRemoveOthers) {
        while ((oneColumn = [enumerator nextObject])) {    
            if (![oneColumn isEqualTo:column])
                [self setIndicatorImage:nil inTableColumn:oneColumn];
        }
    }
    
    [self setIndicatorImage:image inTableColumn:column];
}


- (void)rs_setFontForAllColumns:(NSFont *)font {
    NSArray *columns = [self tableColumns];
    NSUInteger i;
    for (i = 0; i < [columns count]; i++) {
        NSTableColumn *oneTableColumn = [columns rs_safeObjectAtIndex:i];
        if (!oneTableColumn)
            continue;
        NSCell *oneDataCell = [oneTableColumn dataCell];
        if (!oneDataCell)
            continue;
        [oneDataCell setFont:font];
    }
}


- (void)rs_deselectAllRows {
    NSInteger numberOfSelectedRows = [self numberOfSelectedRows];
    if (numberOfSelectedRows < 1)
        return;
    NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
    NSUInteger currentIndex = [selectedRowIndexes firstIndex];
    while (currentIndex != NSNotFound) {
        [self deselectRow:(NSInteger)currentIndex];
        currentIndex = [selectedRowIndexes indexGreaterThanIndex:currentIndex];
    }
}


@end


#pragma mark -

@implementation NSTextField (RSCore)

- (void)rs_setDrawAsEnabled:(BOOL)fl {
    if (fl)
        [self setStringValue:[self stringValue]];    
    else {
        NSDictionary *atts = [NSDictionary dictionaryWithObject:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName];
        [self setAttributedStringValue:[[NSAttributedString alloc] initWithString:[self stringValue] attributes:atts]];
    }    
}

@end


#pragma mark -

@implementation NSToolbarItem (RSCore)

- (void)rs_setLabel:(NSString *)label image:(NSImage *)image toolTip:(NSString *)toolTip target:(id)target action:(SEL)action {
    [self setLabel:label];    
    [self setPaletteLabel:label];
    [self setImage:image];
    [self setToolTip:toolTip];
    [self setTarget:target];    
    [self setAction:action];        
}

@end


#pragma mark -

@implementation NSView (RSCore)

- (BOOL)rs_isOrIsDescendedFromFirstResponder {
    NSResponder *responder = [[self window] firstResponder];
    return [NSApp isActive] && [[self window] isKeyWindow] && responder && [responder isKindOfClass:[NSView class]] && [self isDescendantOf:(NSView *)responder];
}


- (void)rs_setShadowWithBlurRadius:(CGFloat)blurRadius color:(NSColor *)color offset:(NSSize)offset {
    [NSShadow rs_setShadowWithBlurRadius:blurRadius color:color offset:offset];
}


- (NSView *)rs_firstSubviewOfClass:(Class)aClass {
    for (NSView *oneSubview in [self subviews]) {
        if ([oneSubview isKindOfClass:aClass])
            return oneSubview;
    }
    return nil;
}


- (NSView *)rs_firstSubview {
    return [[self subviews] rs_safeObjectAtIndex:0];
}


@end

#pragma mark -

@implementation NSWindowController (RSCore)

- (BOOL)rs_isOpen {
    if (![self isWindowLoaded])
        return NO;
    return [[self window] isVisible];
}


- (void)rs_closeWindow {
    if ([self isWindowLoaded])
        [[self window] performClose:self];
}

@end


