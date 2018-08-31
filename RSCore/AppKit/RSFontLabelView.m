/*
    RSFontLabelView.m
    RancheroAppKit

    Created by Brent Simmons on Thu Dec 04 2003.
    Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import "RSFontLabelView.h"
#import "NSBezierPath_AMAdditons.h"
#import "RSAppKitCategories.h"


@implementation RSFontLabelView


- (BOOL) isOpaque {
    return (NO);
    }
    

- (BOOL) isFlipped {
    return (YES);
    }
    
    
- (void) setChosenFont: (NSFont *) font {
    _chosenFont = font;
    [self setNeedsDisplay: YES];
    }


- (void) drawRect: (NSRect) rect {

    CGFloat desc, x, y;    
    NSAttributedString *attString = nil;
    NSRect bounds = [self bounds];
    CGFloat fontSize;
    NSFont *fontToUse = _chosenFont;
    NSString *fontSizeString;
    NSArray *stringComponents;
    NSString *fontString;
    
    
    NSRect rclip = NSIntegralRect(bounds);
    rclip.origin.x += 1.5;
    rclip.size.width -= 3;
    rclip.origin.y += 1.5;
    rclip.size.height -= 3;
    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:rclip cornerRadius:3.0];
    [p setLineWidth:1.0];
    [NSGraphicsContext saveGraphicsState];
    [p addClip];
    [[NSColor lightGrayColor] set];
    [RSGray(0.97) set];
    NSRectFill(bounds);

    if (_chosenFont != nil) {
        fontSize = [_chosenFont pointSize];
        fontSizeString = [NSString stringWithFormat: @"%f", fontSize];
        stringComponents = [fontSizeString componentsSeparatedByString: @"."];
        fontSizeString = [stringComponents objectAtIndex: 0];
        fontString = [NSString stringWithFormat: @"%@ %@", [_chosenFont displayName], fontSizeString];
        
        if (fontSize > 13.0) {
            
            fontToUse = [NSFont fontWithName: [_chosenFont fontName] size: 13.0];        
            if (fontToUse == nil)
                fontToUse = _chosenFont;
        }
        
        attString = [[NSAttributedString alloc] initWithString: fontString
                                                     attributes: [NSDictionary dictionaryWithObject: fontToUse forKey: NSFontAttributeName]];
        
        desc = [fontToUse descender];
        y = ((bounds.size.height - ([attString size].height + fabs(desc))) / 2.0f) + 1.0f;
        x = NSMidX (bounds) - ([attString size].width / 2.0f);
        
        [attString drawAtPoint: NSMakePoint (x, y)];
    }
        
    [NSGraphicsContext restoreGraphicsState];
    [RSGray(0.65f) set];
    [p stroke];
    }


@end
