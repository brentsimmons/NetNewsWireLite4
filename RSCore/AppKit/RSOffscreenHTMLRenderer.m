//
//  NNWHTMLMailRenderer.m
//  NetNewsWire
//
//  Created by Brent Simmons on 12/30/07.
//  Copyright 2007 NewsGator Technologies, Inc. All rights reserved.
//


#import "RSOffscreenHTMLRenderer.h"
#import "RSMacWebView.h"
#import "RSFoundationExtras.h"


@interface RSOffscreenHTMLRenderer ()

@property (nonatomic, retain) NSString *html;
@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *appName;
@property (nonatomic, retain) NSWindow *window;
@property (nonatomic, retain) RSMacWebView *webView;
@property (nonatomic, retain, readwrite) WebArchive *webArchive;
@property (nonatomic, retain, readwrite) NSString *title;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL callback;
@property (nonatomic, retain, readwrite) NSError *webViewLoadError;

- (void)createWindow;
- (void)createWebView;

@end


@implementation RSOffscreenHTMLRenderer

@synthesize html;
@synthesize baseURL;
@synthesize appName;
@synthesize window;
@synthesize webView;
@synthesize webArchive;
@synthesize title;
@synthesize target;
@synthesize callback;
@synthesize webViewLoadError;


#pragma mark Init

- (id)initWithHTML:(NSString *)someHTML baseURL:(NSURL *)aBaseURL appName:(NSString *)anAppName callback:(SEL)aCallback target:(id)aTarget {
	self = [super init];
	if (self == nil)
		return nil;
	html = [someHTML retain];
	baseURL = [aBaseURL retain];
	appName = [anAppName retain];
	callback = aCallback;
	target = aTarget;
	[self createWindow];
	[self createWebView];
	return self;
	}
	

#pragma mark Dealloc

- (void)dealloc {
	[webView release];
	[window close]; //released when closed
	[html release];
	[title release];
	[webArchive release];
	[appName release];
	[webViewLoadError release];
	[super dealloc];
	}


#pragma mark Window

- (NSRect)webviewRect {
	return NSMakeRect(0, [NSScroller scrollerWidthForControlSize:NSRegularControlSize], 400, 400);
	}
	

- (NSRect)webviewRectWithScrollbar {
	NSRect r = [self webviewRect];
	r.size.width += [NSScroller scrollerWidthForControlSize:NSRegularControlSize];
	r.size.height += [NSScroller scrollerWidthForControlSize:NSRegularControlSize];
	r.origin.y = 0;
	return r;
	}
	

- (void)createWindow {
	NSRect r = [self webviewRectWithScrollbar];
	self.window = [[[NSWindow alloc] initWithContentRect:r styleMask:0 backing:NSBackingStoreRetained defer:NO] autorelease];
	[self.window setFrame:NSMakeRect(70000, 70000, r.size.width, r.size.height) display:NO];
	[self.window setReleasedWhenClosed:YES];
	}
	
	
- (void)createWebView {
	self.webView = [[[RSMacWebView alloc] initWithFrame:[self webviewRectWithScrollbar] frameName:nil groupName:nil] autorelease];
	[self.webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[self.webView setSkipKeystrokes:YES];
	[self.webView setFrameLoadDelegate:self];
	[self.webView setResourceLoadDelegate:self];
	[self.webView setUIDelegate:self];
	[self.webView setApplicationNameForUserAgent:self.appName];
	[self.webView setRequestFavicons:NO];
	[self.webView setHostWindow:self.window];
	self.webView.canBeDragDestination = NO;
	[self.webView setMaintainsBackForwardList:NO];
	[[self.window contentView] addSubview:self.webView];
	[self.webView setFrame:[self webviewRectWithScrollbar]];
	}


#pragma mark Callback

- (void)callCallback {
	[self.target performSelector:self.callback withObject:self];
	}


#pragma mark Rendering

- (void)renderWebPage {
	[[self.webView mainFrame] loadHTMLString:self.html baseURL:self.baseURL];
	}


- (WebArchive *)webArchive {
	if (webArchive == nil)
		self.webArchive = [[[self.webView mainFrame] dataSource] webArchive];
	return webArchive;
	}


- (NSString *)title {
	if (!title)
		self.title = [[[self.webView mainFrame] dataSource] pageTitle];
	return title;
	}


#pragma mark Web Frame Delegate

	
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (frame == [self.webView mainFrame])
		[self callCallback];
	}


- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	if (frame == [self.webView mainFrame]) {
		self.webViewLoadError = error;
		[self callCallback];
	}
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	if (frame == [self.webView mainFrame]) {
		self.webViewLoadError = error;
		[self callCallback];
	}
}


#pragma mark WebResourceDelegate

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource {
	return [NSString rs_uuidString];
	}


- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource {
	[[challenge sender] cancelAuthenticationChallenge:challenge];
	}


@end
