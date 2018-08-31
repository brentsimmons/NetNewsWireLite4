/*
    NNWWebView.h
    NetNewsWire

    Created by Brent Simmons on Thu Aug 07 2003.
    Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import "RSMacWebView.h"
#import "WebView+Extras.h"
#import "RSFoundationExtras.h"


@interface NSObject (RSWebViewHandleKeystroke)
- (BOOL)handleKeyStroke:(NSEvent *)event inView:(NSView *)view;
@end


@interface RSMacWebView ()
@property (nonatomic, assign, readwrite) BOOL initialLoadAttempted;
@end


@implementation RSMacWebView

@synthesize initialRequestedURL;
@synthesize lastRequestedURL;
@synthesize lastLoadedURL;
@synthesize initialLoadAttempted;
@synthesize initialTitle;
@synthesize loadOnSelect;
@synthesize favicon;
@synthesize requestFavicons;
//@synthesize displayURL;
//@synthesize displayTitle;
@synthesize skipKeystrokes;
@synthesize canBeDragDestination;

#pragma mark Dealloc



#pragma mark Delegates

- (void)detachDelegates {
    [self setUIDelegate:nil];
    [self setResourceLoadDelegate:nil];
    [self setFrameLoadDelegate:nil];
    [self setPolicyDelegate:nil];    
}


#pragma mark Drag/drop

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if (!self.canBeDragDestination)
        return NSDragOperationNone;
    return [super draggingEntered:sender];
    }
    

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    if (!self.canBeDragDestination)
        return NSDragOperationNone;
    return [super draggingUpdated:sender];
    }
    
    
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    if (!self.canBeDragDestination)
        return NO;
    return [super prepareForDragOperation:sender];
    }
    
    
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    if (!self.canBeDragDestination)
        return NO;
    return [super performDragOperation:sender];
    }


#pragma mark Accessors

- (BOOL)loadIsInProgress {

    NSString *urlString = [self loadingURLString];    
    if (urlString && [urlString hasPrefix:@"about"])
        return NO;

    if ([super loadIsInProgress]) {
        self.initialLoadAttempted = YES;
        return YES;
        }
    return NO;
    }
    

- (NSString *)displayURL {
    NSString *currentURLString = [self currentURLString];
    if (!RSStringIsEmpty(currentURLString))
        return currentURLString;
    if (self.loadIsInProgress)
        return self.lastRequestedURL;
    if (!RSStringIsEmpty(self.lastLoadedURL))
        return self.lastLoadedURL;
    return self.initialRequestedURL;
    }
    

- (NSString *)displayTitle {
    NSString *s = [self currentTitle];
    if (!RSStringIsEmpty(s))
        return s;
    return self.initialTitle;
    }
    
    
- (void)doLoadOnSelect {
    [self loadURLString:self.initialRequestedURL];        
    }


- (void)doLoadOnSelectIfNeeded {
    if (self.loadOnSelect && !self.initialLoadAttempted)
        [self doLoadOnSelect];
    }


#pragma mark Load request

- (void)loadRequest:(NSURLRequest *)urlRequest {
    [super loadRequest:urlRequest];
    self.loadOnSelect = NO;
    self.initialLoadAttempted = YES;
    if (self.initialRequestedURL == nil)
        self.initialRequestedURL = [[urlRequest URL] absoluteString];
    self.lastRequestedURL = [[urlRequest URL] absoluteString];
    }


#pragma mark Events
    
- (void)keyDown:(NSEvent *)event {
    
    NSString *s = [event charactersIgnoringModifiers];
    if (!RSIsEmpty(s)) {
        unichar ch = [s characterAtIndex:0];

        if (ch != ' ' && !self.skipKeystrokes) {

            if ([self respondsToSelector:@selector(handleKeyStroke:inView:)]) {
                if ([self handleKeyStroke:event inView:self])
                    return;
            }
        }
        
    [super keyDown:event];
    }

}
@end
