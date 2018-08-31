/*
    NNWWebView.h
    NetNewsWire

    Created by Brent Simmons on Thu Aug 07 2003.
    Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>
#import <WebKit/Webkit.h>


@interface RSMacWebView : WebView {
@private
    BOOL skipKeystrokes;
    BOOL canBeDragDestination;
    BOOL initialLoadAttempted;
    BOOL loadOnSelect;
    BOOL requestFavicons;
    NSString *initialRequestedURL;
    NSString *lastRequestedURL;
    NSString *lastLoadedURL;
    NSString *initialTitle;
    NSImage *favicon;
}


@property (nonatomic, strong) NSString *initialRequestedURL;
@property (nonatomic, strong) NSString *lastRequestedURL;
@property (nonatomic, strong) NSString *lastLoadedURL;
@property (nonatomic, strong) NSString *initialTitle;
@property (nonatomic, assign) BOOL loadOnSelect;
@property (nonatomic, strong) NSImage *favicon;
@property (nonatomic, assign) BOOL requestFavicons;
@property (nonatomic, assign) BOOL skipKeystrokes;
@property (nonatomic, assign) BOOL canBeDragDestination;

@property (nonatomic, assign, readonly) BOOL initialLoadAttempted;
@property (nonatomic, strong, readonly) NSString *displayURL;
@property (nonatomic, strong, readonly) NSString *displayTitle;
@property (nonatomic, assign, readonly) BOOL loadIsInProgress;

- (void)doLoadOnSelectIfNeeded;
- (void)detachDelegates;

@end
