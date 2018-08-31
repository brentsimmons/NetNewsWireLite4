//
//  NNWSplitViewWithDarkDivider.m
//  RSCoreTests
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSplitViewWithDarkDivider.h"


@implementation NNWSplitViewWithDarkDivider


- (NSColor *)dividerColor {
    static NSColor *aDividerColor = nil;
    if (aDividerColor == nil)
        aDividerColor = [[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.15f];
    return aDividerColor;
}


//- (void)drawDividerInRect:(NSRect)rect {
////    [[NSColor colorWithDeviceWhite:0.55f alpha:1.0f] set];
//    static NSColor *backgroundColor = nil;
//    if (backgroundColor == nil)
//        backgroundColor = [[[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] shadowWithLevel:0.2f] retain];
//    [backgroundColor set];
//    NSRectFillUsingOperation(rect, NSCompositeSourceOver);
//    
//}

@end
