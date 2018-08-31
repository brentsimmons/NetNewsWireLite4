/*
    RSBrowserTextField.m
    RancheroAppKit

    Created by Brent Simmons on Sun Nov 23 2003.
    Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import "RSBrowserTextField.h"
#import "RSBrowserAddressCell.h"
#import "RSAppKitUtilities.h"
#import "RSAppKitCategories.h"


@implementation RSBrowserTextField


- (void) commonInit {
    
    RSBrowserAddressCell *imageTextCell = [[RSBrowserAddressCell alloc] init];
    
    _progressIndicator = nil;
    [self setCell: imageTextCell];
    [self setDrawsBackground:NO];
    [[self cell] setDrawsBackground:NO];
    [[self cell] setBordered: NO];
    [[self cell] setBezeled: NO]; 
    [[self cell] setEditable: YES]; 
    [[self cell] setScrollable: YES]; 
    [[self cell] setWraps: NO];
    [[self cell] setFont: [NSFont systemFontOfSize: 13.0]];
    [[self cell] setTextColor:[[NSColor colorWithDeviceRed:157.0f/255.0f green:194.0f/255.0f blue:235.0f/255.0f alpha:1.0f] shadowWithLevel:0.75f]];
    [self setStringValue: @""];
    if ([[self cell] respondsToSelector: @selector (setFocusRingType:)])
        [[self cell] setFocusRingType: NSFocusRingTypeNone];
    [[self cell] setImage: [NSImage imageNamed: @"site"]];
    }
    
    
- (id) initWithFrame: (NSRect) frame {
    
    self = [super initWithFrame: frame];    
    if (self)
        [self commonInit];
    return (self);
    }
    
    
- (id) initWithCoder: (NSCoder *) coder {
    
    self = [super initWithCoder: coder];    
    if (self)
        [self commonInit];
    return (self);
    }


- (BOOL) inProgress {
    return (_flInProgress);
    }
    

- (NSRect) progressIndicatorRect {
    NSRect r = [self bounds];
    r.size.width = 20;
    r.origin.y += 2;
    r.origin.x += 2;
    return (r);
    }
    
    
- (void) updateCellImage {
        [[self cell] setImage: _image];
    }
    
    
- (void) startProgressIndicator {
    
    [self updateCellImage];
    }
    
    
- (void) stopProgressIndicator {
    

    [self updateCellImage];
    }
    
    
- (void) setInProgress: (BOOL) fl {
    
    BOOL flOrig = _flInProgress;
    
    _flInProgress = fl;
    
    if (flOrig == _flInProgress)
        return;
    
    if (_flInProgress)
        [self startProgressIndicator];
    else
        [self stopProgressIndicator];
    
    [[self cell] setPageLoadInProgress:fl];
    }
    

- (void)setEstimatedProgress:(double)ep {
    [[self cell] setEstimatedProgress:ep];
    }
    
    
- (void) setImage: (NSImage *) image {
    _image = image;
    [self updateCellImage];
    [self setNeedsDisplay: YES];
    }


- (void) setTitle: (NSString *) s {
    _title = [s copy];
    if (_flDisplayTitle) {
        [self rs_safeSetStringValue: s];
        [self setNeedsDisplay: YES];
        }
    }
    
    
- (void) setURLString: (NSString *) s {
    _urlString = [s copy];
    if (!_flDisplayTitle) {
        [self rs_safeSetStringValue: s];
        [self setNeedsDisplay: YES];
        }
    }
    
    
- (void) setDisplayTitle: (BOOL) fl {
    if (_flDisplayTitle != fl)
        [self setNeedsDisplay: YES];
    _flDisplayTitle = fl;
    }


#pragma mark Cursor rects

- (NSRect) iconRect {
    NSRect r = [self bounds];
    r.size.width = 20;
    return (r);
    }
    
    
- (void) resetCursorRects {
    [self addCursorRect: [self iconRect] cursor: [NSCursor arrowCursor]];
    }
    

#pragma mark Drag source

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) isLocal {
    return (NSDragOperationCopy);
    }


- (void) mouseDown: (NSEvent *) event {
    
    NSPoint localPoint = [self convertPoint: [event locationInWindow] fromView: nil];

    if ((!_flInProgress) && (NSPointInRect (localPoint, [self iconRect]))) {
        NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSDragPboard];
        NSRect r = NSInsetRect ([self frame], 2, 2);
        NSBitmapImageRep *bitmap;
        NSImage *image = [[NSImage alloc] initWithSize: r.size];
        NSImage *viewImage = [[NSImage alloc] initWithSize: r.size];
        
        [[self superview] lockFocus];
        bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect: r];    
        [[self superview] unlockFocus];
        
        [viewImage lockFocus];
        [bitmap draw];
        [viewImage unlockFocus];
        
        [image lockFocus];
        [viewImage compositeToPoint: NSMakePoint (0, 0) operation: NSCompositeSourceOver fraction: 0.5];
        [image unlockFocus];
        
        RSCopyURLStringAndNameToPasteboard(_urlString, _title, pb);
//        [NSString copyURLString: _urlString name: _title toPasteboard: pb];
            
        [self dragImage: image at: NSMakePoint (0, r.size.height) offset: NSMakeSize (0, 0)
            event: event pasteboard: pb source: self slideBack: YES];
        }
    
    else
        [super mouseDown: event];
    }
    

#pragma mark Drawing

- (BOOL)isOpaque {
    return NO;
}

    
@end
