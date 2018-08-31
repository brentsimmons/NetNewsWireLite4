//
//  NNWSourceListCell.m
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSourceListCell.h"


@implementation NNWSourceListCell

@synthesize countForDisplay;
@synthesize isFolder;
@synthesize selected;
@synthesize shouldDrawSmallImage;
@synthesize smallImage;


#pragma mark Init

- (id)copyWithZone:(NSZone *)zone {
    NNWSourceListCell *cell = (NNWSourceListCell *)[super copyWithZone:zone];    
    //cell.smallImage = self.smallImage;
    return cell;
}


#pragma mark Dealloc

//- (void)dealloc {
//    [smallImage release];
//    [super dealloc];
//}


#pragma mark Drawing

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    return nil;
}

static const CGFloat kSourceListSmallImageHeight = 16.0f;
static const CGFloat kSourceListSmallImageWidth = 16.0f;
static const CGFloat kSourceListFaviconPaddingRight = 8.0f;

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect textFrame = aRect;
    textFrame.origin.x = textFrame.origin.x + kSourceListSmallImageWidth + kSourceListFaviconPaddingRight;
    textFrame.size.width = textFrame.size.width - (kSourceListSmallImageWidth + kSourceListFaviconPaddingRight);
    textFrame.origin.y += 1.0f;
    [super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    NSRect rView = [[[(NSTableView *)controlView enclosingScrollView] contentView] bounds];

    NSRect rScrollView = [[(NSTableView *)controlView enclosingScrollView] bounds];
    NSRect rOutlineView = [controlView bounds];

    CGFloat outlineWidth = rScrollView.size.width;
    BOOL verticalScrollerIsShowing = rOutlineView.size.height > rScrollView.size.height;
    CGFloat scrollerWidth = [[[[(NSTableView *)controlView enclosingScrollView] verticalScroller] class] scrollerWidth];
    if (verticalScrollerIsShowing) {
        outlineWidth = rScrollView.size.width - scrollerWidth;
    }
    rView.size.width = outlineWidth;

    cellFrame.size.width = (rView.size.width - cellFrame.origin.x) - 2;        
    NSRect rOriginalCellFrame = cellFrame;

    cellFrame.origin.x = cellFrame.origin.x + 3.0f;
    if (!self.shouldDrawSmallImage) {
        cellFrame = rOriginalCellFrame;
        cellFrame.origin.x = 10.0f;
        cellFrame.size.width = CGRectGetWidth([[[(NSTableView *)controlView enclosingScrollView] contentView] bounds]) - cellFrame.origin.x;
        cellFrame = CGRectIntegral(cellFrame);
    }

    NSRect r = cellFrame;

    NSRect rFavicon = r;

    rFavicon.size.width = kSourceListSmallImageWidth + 2;
    rFavicon.size.height = kSourceListSmallImageHeight;
    if (!self.shouldDrawSmallImage)
        rFavicon.size.width = 0.0f;

    cellFrame.origin.x += rFavicon.size.width;
    cellFrame.size.width -= rFavicon.size.width;
    if (self.shouldDrawSmallImage) {
        cellFrame.origin.x += 3;
        cellFrame.size.width -= 3;
    }
    cellFrame.origin.y = cellFrame.origin.y + 1;
    cellFrame.size.height = cellFrame.size.height - 1;
    rFavicon.origin.y = NSMidY(cellFrame) - (rFavicon.size.height / 2);
    rFavicon = NSIntegralRect(rFavicon);

    if (!self.shouldDrawSmallImage) {
        rFavicon.size.width = 0.0f;
    }
    
    if (self.shouldDrawSmallImage && self.smallImage != nil) {
        CGContextRef currentContext = [[NSGraphicsContext currentContext] graphicsPort];
        CGRect rFaviconDrawingRect = rFavicon;
        rFaviconDrawingRect.size.height = kSourceListSmallImageHeight;
        rFaviconDrawingRect.size.width = kSourceListSmallImageWidth;
        rFaviconDrawingRect = CGRectIntegral(rFaviconDrawingRect);
        CGContextSaveGState(currentContext);

        CGContextTranslateCTM(currentContext, CGRectGetMinX(rFaviconDrawingRect), CGRectGetMaxY(rFaviconDrawingRect));
        CGContextScaleCTM(currentContext, 1, -1);
        CGContextTranslateCTM(currentContext, -rFaviconDrawingRect.origin.x, -rFaviconDrawingRect.origin.y);
        
        if (self.selected)
            CGContextSetBlendMode(currentContext, kCGBlendModeNormal);
        else
            CGContextSetBlendMode (currentContext, kCGBlendModeMultiply);
        CGContextDrawImage(currentContext, rFaviconDrawingRect, (CGImageRef)(self.smallImage));
        CGContextRestoreGState(currentContext);
    }
    
    CGRect rTitle = cellFrame;
    if (self.shouldDrawSmallImage) {
        rTitle.origin.x = CGRectGetMaxX(rFavicon) + 4.0f;
        rTitle.size.width = CGRectGetWidth([[[(NSTableView *)controlView enclosingScrollView] contentView] bounds]) - rTitle.origin.x;
    }
    
    NSRect unreadRect = NSZeroRect;
    
    if (self.countForDisplay > 0) {
        NSString *tempString = [NSString stringWithFormat:@"%ld", (long)(self.countForDisplay)];
        NSUInteger ctDigits = [tempString length];
        static NSUInteger wNine = 0;
        
        NSFont *boldFont = [NSFont boldSystemFontOfSize:11.0];
        if (wNine < 1) {
            NSAttributedString *nineString = [[NSAttributedString alloc] initWithString:@"9" attributes:[NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, nil]];
            wNine = (NSUInteger)[nineString size].width;
        }
        NSUInteger wUnread = (ctDigits * wNine);//; - 1;// + 15;
        static NSBezierPath *pUnread = nil;
        if (!pUnread) {
            pUnread = [NSBezierPath bezierPath];
            [pUnread setLineWidth:14.0];
            [pUnread setLineCapStyle:NSRoundLineCapStyle];
        }
        
        static NSColor *unreadChicletColor = nil;
        if (unreadChicletColor == nil)

            unreadChicletColor = [[NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f] highlightWithLevel:0.4f];
        [unreadChicletColor set];

        if (self.selected)

            [[[NSColor selectedTextBackgroundColor] shadowWithLevel:0.5] set];
        [pUnread moveToPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width - (wUnread + 11), (NSInteger)NSMidY(cellFrame))];
        [pUnread lineToPoint:NSMakePoint((cellFrame.origin.x + cellFrame.size.width) - 13, (NSInteger)NSMidY(cellFrame))];

        

        [pUnread stroke];
        [pUnread removeAllPoints];

        NSMutableDictionary *atts = [NSMutableDictionary dictionaryWithCapacity:2];
        [atts setObject:boldFont forKey:NSFontAttributeName];

        [atts setObject:[(NSOutlineView *)controlView backgroundColor] forKey:NSForegroundColorAttributeName];

        
        NSAttributedString *unreadString = [[NSAttributedString alloc] initWithString:tempString attributes:atts];
        unreadRect = cellFrame;
        unreadRect.origin.x = (cellFrame.origin.x + cellFrame.size.width) - (wUnread + 13); //25;
        unreadRect.origin.x += 1.5;
        unreadRect.size.width = wUnread;
        unreadRect.origin.y = (NSInteger)NSMidY(unreadRect) - 7;
        unreadRect = NSIntegralRect(unreadRect);
        [unreadString drawAtPoint:NSMakePoint(unreadRect.origin.x, unreadRect.origin.y- 0)];

        if (wUnread > 0) {
            rTitle.size.width -= (wUnread + 17);
            cellFrame.size.width -= (wUnread + 17);
        }        
    }

    NSString *s = [self stringValue];
    if (s == nil)
        s = @"";
    if ([s length] > 300)
        s = [s substringToIndex:250];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:2];
    [attributes setObject:[NSColor textColor] forKey:NSForegroundColorAttributeName];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    
    if (self.selected) {
        [attributes setObject:[NSFont boldSystemFontOfSize:12.0f] forKey:NSFontAttributeName];
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
        [shadow setShadowBlurRadius:1.0f];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0f alpha:0.75f]];
        [attributes setObject:shadow forKey:NSShadowAttributeName];
    }
    else        
        [attributes setObject:[NSFont systemFontOfSize:12.0f] forKey:NSFontAttributeName];
    
    if (!self.shouldDrawSmallImage) {
        static NSColor *backgroundColor = nil;
        if (backgroundColor == nil)
            backgroundColor = [NSColor colorWithDeviceWhite:0.0f alpha:1.0f];
        [attributes setObject:backgroundColor forKey:NSForegroundColorAttributeName];
    }

    [s drawInRect:rTitle withAttributes:attributes];
    
    self.smallImage = nil;
}


@end
