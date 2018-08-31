//
//  NNWGroupItemCell.m
//  nnw
//
//  Created by Brent Simmons on 12/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWGroupItemCell.h"


@implementation NNWGroupItemCell


#pragma mark Drawing

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    return nil;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
//    cellFrame.origin.x = 0.0f;
//    cellFrame.size.width = [controlView bounds].size.width;
    cellFrame.origin.y = cellFrame.origin.y - 1.0f;
    cellFrame.size.height = cellFrame.size.height + 3.0f;
    
    NSRect rectOfRow = cellFrame;
    rectOfRow.origin.x = 0.0f;
    rectOfRow.size.width = [controlView bounds].size.width;
    
    [[(NSOutlineView *)controlView backgroundColor] set];
    NSRectFillUsingOperation(rectOfRow, NSCompositeSourceOver);

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSColor colorWithDeviceRed:0.7f green:0.6f blue:0.5f alpha:1.0f] forKey:NSForegroundColorAttributeName];
    [attributes setObject:[NSFont boldSystemFontOfSize:13.0f] forKey:NSFontAttributeName];
    [attributes setObject:[NSNumber numberWithFloat:0.4f] forKey:NSKernAttributeName];

    
    static NSColor *titleColor = nil;
    if (titleColor == nil)
        //            unreadChicletColor = [[NSColor colorWithDeviceRed:153.0f/255.0f green:167.0f/255.0f blue:199.0f/255.0f alpha:1.0f] retain];
        titleColor = [[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.4f];
    [attributes setObject:titleColor forKey:NSForegroundColorAttributeName];

    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:self.stringValue attributes:attributes];

    CGRect rTitle = cellFrame;
    rTitle.origin.x = 10.0f;
    rTitle.size.width = cellFrame.size.width - rTitle.origin.x;
    rTitle.size.height = 15.0f;
    rTitle = CGRectCenteredVerticallyInRect(rTitle, cellFrame);
    //rTitle.origin.y = rTitle.origin.y + 4.0f;
    rTitle = CGRectIntegral(rTitle);
    [titleString drawInRect:rTitle];    
}


@end
