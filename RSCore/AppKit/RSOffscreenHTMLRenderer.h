//
//  NNWHTMLMailRenderer.h
//  NetNewsWire
//
//  Created by Brent Simmons on 12/30/07.
//  Copyright 2007 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@class RSMacWebView;

@interface RSOffscreenHTMLRenderer : NSObject {
@private
	SEL callback;
	id target;
	RSMacWebView *webView;
	NSWindow *window;
	NSString *html;
	NSURL *baseURL;
	WebArchive *webArchive;
	NSString *title;
	NSString *appName;
	NSError *webViewLoadError;
}


- (id)initWithHTML:(NSString *)someHTML baseURL:(NSURL *)aBaseURL appName:(NSString *)appName callback:(SEL)aCallback target:(id)aTarget;

- (void)renderWebPage;

@property (nonatomic, retain, readonly) WebArchive *webArchive;
@property (nonatomic, retain, readonly) NSString *title;
@property (nonatomic, retain, readonly) NSError *webViewLoadError;


@end
