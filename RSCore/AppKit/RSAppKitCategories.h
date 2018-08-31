//
//  RSAppKitExtras.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (RSCore)

- (void)rs_appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(CGFloat)radius;
- (void)rs_drawRect:(NSRect)rect withGradientFrom:(NSColor*)colorStart to:(NSColor*)colorEnd;

@end


void RSSetInterfaceColor(CGFloat f);
NSColor *RSInterfaceColor(CGFloat n);

NSColor *RSGray(CGFloat grayValue);
NSColor *RSRGBColor(NSUInteger red, NSUInteger green, NSUInteger blue);

extern NSString *NSColorInterfaceColor;

@interface NSColor (RSCore)


+ (NSColor *)rs_grayWithFloat:(CGFloat)f;
+ (NSColor *)rs_interfaceColor;
+ (NSColor *)rs_interfaceColor:(CGFloat)n;
+ (NSColor *)rs_grayBorderColor;
+ (NSColor *)rs_darkGrayBorderColor;
+ (NSColor *)rs_borderColor;
+ (void)rs_updateInterfaceColor;
+ (NSColor *)rs_interfaceColor;
+ (void)rs_setCoolBlueColor:(NSColor *)color;
+ (void)rs_updateCoolBlueColor;
+ (NSColor *)rs_coolBlueColor;
+ (NSColor *)rs_grayWindowBackgroundColor;
+ (NSColor *)rs_lightInterfaceColor;
+ (NSColor *)rs_interfaceColor:(CGFloat)n;


@end


@interface NSControl (RSCore)

- (void)rs_safeSetStringValue:(NSString *)s;

@end


@interface NSImage (RSCore)

+ (NSImage *)rs_image:(NSImage *)sourceImage scaledToSize:(NSSize)size;
- (BOOL)rs_canBeDrawn;
- (NSBitmapImageRep *)rs_firstBitmapImageRep;

@end


@interface NSMenu (RSCore)

- (void)rs_removeAllItems;
- (void)rs_addSeparatorItemIfLastItemIsNotSeparator;
- (void)rs_addSeparatorItem;
- (BOOL)rs_lastItemIsSeparatorItem;

- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent target:(id)target representedObject:(id)obj;	
- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action target:(id)target representedObject:(id)obj;	
- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent target:(id)target;
- (NSMenuItem *)rs_addItemWithTitle:(NSString *)title action:(SEL)action target:(id)target;

@end


@interface NSMenuItem (RSCore)

+ (NSMenuItem *)rs_menuItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)target representedObject:(id)obj tag:(NSInteger)tag;
+ (NSMenuItem *)rs_menuItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)target;
- (id)rs_initWithTitle:(NSString *)aString action:(SEL)aSelector;
- (id)rs_initWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)target representedObject:(id)obj tag:(NSInteger)tag;
- (void)rs_setStateWithBoolean:(BOOL)flag;

@end


@interface NSOutlineView (RSCore)

- (BOOL)rs_isFirstResponderAndItemIsSelected: (id) item;
- (BOOL)rs_isItemSelected:(id)item;
- (NSArray *)rs_selectedItems;
- (void)rs_selectItemsWithArray:(NSArray *)selectedItems;

@end


@interface NSShadow (RSCore)

+ (void)rs_setShadowWithBlurRadius:(CGFloat)blurRadius color:(NSColor *)color offset:(NSSize)offset;


@end


@interface NSString (RSCoreAppKit)

- (NSSize)rs_sizeWithFont:(NSFont *)font andWidth:(CGFloat)w;

@end


@protocol RSTableViewContextualMenuHandler

- (NSMenu *)rs_menuForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end

@interface NSTableView (RSCore)

- (NSMenu *)rs_menuForEvent:(NSEvent *)event;
- (void)rs_goToRow:(NSInteger)row;
- (void)rs_goToAbsoluteRow:(NSInteger)row;
- (BOOL)rs_isFirstResponderAndRowIsSelected:(NSInteger)row;
- (void)rs_setIndicatorImage:(NSImage *)image inTableColumn:(NSTableColumn *)column andRemoveOthers:(BOOL)flRemoveOthers;
- (void)rs_setFontForAllColumns:(NSFont *)font;
- (NSInteger)rs_absoluteSelectedRow;
- (NSIndexSet *)rs_absoluteSelectedRowIndexes;
- (void)rs_deselectAllRows;

@end


@interface NSTextField (RSCore)

- (void)rs_setDrawAsEnabled:(BOOL)fl;

@end


@interface NSToolbarItem (RSCore)

- (void)rs_setLabel:(NSString *)label image:(NSImage *)image toolTip:(NSString *)toolTip target:(id)target action:(SEL)action;

@end


@interface NSView (RSCore)

- (BOOL)rs_isOrIsDescendedFromFirstResponder;
- (void)rs_setShadowWithBlurRadius:(CGFloat)blurRadius color:(NSColor *)color offset:(NSSize)offset;
- (NSView *)rs_firstSubviewOfClass:(Class)aClass;
- (NSView *)rs_firstSubview;

@end


@interface NSWindowController (RSCore)

- (BOOL)rs_isOpen; /*Window is loaded from nib and is visible*/
- (void)rs_closeWindow;

@end
