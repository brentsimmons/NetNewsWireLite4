//
//  NNWPageThumbnailCache.m
//  NetNewsWire
//
//  Created by Brent Simmons on 10/10/06.
//  Copyright 2006 Ranchero Software. All rights reserved.
//


#import <WebKit/WebKit.h>
#import "NNWPageThumbnailCache.h"
#import "RSFileUtilities.h"
#import "RSImageFolderCache.h"
#import "WebView+Extras.h"


NSString *_NNWPageThumbnailCacheFolderName = @"PageThumbnails.noindex";


@interface NNWPageThumbnailCache ()

@property (nonatomic, retain) NSURL *currentURL;
@property (nonatomic, retain) NSMutableArray *thumbnailRequests;
@property (nonatomic, retain) RSMacWebView *webview;
@property (nonatomic, retain) NSWindow *window;
@property (nonatomic, retain) RSImageFolderCache *imageFolderCache;

- (void)_createWindow;	
- (void)_createWebView;
- (void)_startLoadingNextURL;
- (void)_pushURL:(NSURL *)aURL;
@end


@implementation NNWPageThumbnailCache


#pragma mark Class Methods

+ (id)sharedCache {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
	}


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	thumbnailRequests = [[NSMutableArray arrayWithCapacity:10] retain];

	NSString *folder = RSCacheFolderForAppSubFolder(_NNWPageThumbnailCacheFolderName, NO);
	NSDate *dateCacheLastNuked = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateWebPageScreenShotCacheLastNuked"];
	if (dateCacheLastNuked == nil)
		dateCacheLastNuked = [NSDate distantPast];
	NSDate *dateThreeWeeksAgo = [NSDate rs_dateWithNumberOfDaysInThePast:7 * 3];
	if ([dateThreeWeeksAgo earlierDate:dateCacheLastNuked] == dateCacheLastNuked) {
		if (RSFileExists(folder))
			RSFileDelete(folder);
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateWebPageScreenShotCacheLastNuked"];
	}

	RSCacheFolderForAppSubFolder(_NNWPageThumbnailCacheFolderName, YES);
	imageFolderCache = [[RSImageFolderCache alloc] initWithFolder:folder];
	[self _createWindow];
	[self _createWebView];
	return self;
	}
	

#pragma mark Dealloc

- (void)dealloc {
	[thumbnailRequests release];
	[currentURL release];
	[super dealloc];
	}
	
	
#pragma mark Window


- (NSRect)webviewRect {
	return NSMakeRect(0, [NSScroller scrollerWidthForControlSize:NSRegularControlSize], kNNWPageThumbWidth, kNNWPageThumbHeight);
	}
	

- (NSRect)webviewRectWithScrollbar {
	NSRect r = [self webviewRect];
	r.size.width += [NSScroller scrollerWidthForControlSize:NSRegularControlSize];
	r.size.height += [NSScroller scrollerWidthForControlSize:NSRegularControlSize];
	r.origin.y = 0;
	return r;
	}
	

- (void)_createWindow {
	NSRect r = [self webviewRectWithScrollbar];
	window = [[NSWindow alloc] initWithContentRect:r styleMask:0 backing:NSBackingStoreRetained defer:NO];
	[window setFrame:NSMakeRect(80000, 80000, r.size.width, r.size.height) display:NO];
	}
	
	
- (void)_createWebView {
	self.webview = [[[RSMacWebView alloc] initWithFrame:[self webviewRectWithScrollbar] frameName:nil groupName:nil] autorelease];
	[self.webview setPreferencesIdentifier:@"Thumbnail"];
	[self.webview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[self.webview setSkipKeystrokes:YES];
	[self.webview setFrameLoadDelegate:self];
	[self.webview setResourceLoadDelegate:self];
	[self.webview setUIDelegate:self];
	[self.webview setApplicationNameForUserAgent:RSAppName()];
	[self.webview setRequestFavicons:NO];
	[self.webview setHostWindow:window];
	//[webview setDragDestination:NO];
	[self.webview setMaintainsBackForwardList:NO];
	[[self.webview preferences] setAutosaves:NO];
	[[self.webview preferences] setJavaScriptCanOpenWindowsAutomatically:NO];
	[[self.webview preferences] setUserStyleSheetEnabled:NO];
	[[self.webview preferences] setAllowsAnimatedImageLooping:NO];
	[[self.webview preferences] setJavaEnabled:NO];
	[[self.webview preferences] setJavaScriptEnabled:NO];
	[[self.webview preferences] setPlugInsEnabled:NO];
	[[self.webview preferences] setUserStyleSheetEnabled:[[self.webview preferences] userStyleSheetEnabled]];
	[[self.window contentView] addSubview:self.webview];
	[self.webview setFrame:[self webviewRectWithScrollbar]];
	}


#pragma mark Thumbnail

- (CGImageRef)createThumbnailForCurrentPage {
	if (!self.window || !self.webview)
		return nil;
	[self.window display];
	[self.webview lockFocus];
	NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:[self webviewRect]] autorelease];
	[self.webview unlockFocus];
	if (!bitmap)
		return nil;
	return [bitmap CGImage];
	}
	

- (void)_writeImageToDisk:(CGImageRef)image forURLString:(NSString *)urlString {
	if (image != nil && !RSIsEmpty(urlString))
		[self.imageFolderCache saveCGImage:image withFilename:[RSImageFolderCache filenameForURLString:urlString] error:nil];
}


- (void)setImage:(CGImageRef)image forURLString:(NSString *)urlString {
	if (image == nil)
		return;
	[self _writeImageToDisk:image forURLString:urlString];
}


- (void)doThumbnail {
	CGImageRef image = [self createThumbnailForCurrentPage];
	NSString *homeURLString = [self.currentURL absoluteString];
	if (image == nil || RSIsEmpty(homeURLString)) {
		[self _startLoadingNextURL];
		return;
		}
	[self setImage:image forURLString:homeURLString];
	[self _startLoadingNextURL];
	}
	

- (CGImageRef)imageForURLString:(NSString *)urlString {
	if (RSIsEmpty(urlString))
		return nil;
	return [self.imageFolderCache cgImageForFilename:[RSImageFolderCache filenameForURLString:urlString]];
}


- (CGImageRef)thumbnailForURL:(NSURL *)aURL {
	NSString *homeURLString = [aURL absoluteString];
	if (RSIsEmpty(homeURLString))
		return nil;
	CGImageRef image = [self imageForURLString:homeURLString];
	if (image != nil)
		return image;
	[self _pushURL:aURL];
	return nil;
	}
	
	
#pragma mark Queue

- (void)_pushURL:(NSURL *)aURL {
	[self.thumbnailRequests rs_addObjectIfNotIdentical:aURL];
	if (!currentURL)
		[self _startLoadingNextURL];
	}
	

- (NSURL *)_popURL {
	NSURL *aURL;
	while (true) {
		aURL = [[[self.thumbnailRequests lastObject] retain] autorelease];
		if (!aURL)
			return nil;
		[self.thumbnailRequests removeObject:aURL];
		return aURL;
		}
	return nil;
	}
	

- (void)_startLoadingNextURL {
	self.currentURL = nil;
	NSURL *aURL = [self _popURL];
	if (!aURL)
		return;
	self.currentURL = aURL;
	NSString *homeURLString = [aURL absoluteString];//[dataSource homeURLString];
	if (RSIsEmpty(homeURLString))
		[self _startLoadingNextURL];
	else
		[self.webview loadURLString:homeURLString];
	}
	

#pragma mark Web Frame Delegate

	
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (frame == [self.webview mainFrame])
		[self doThumbnail];
	}


- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	if (frame == [self.webview mainFrame])
		[self _startLoadingNextURL];
	}


- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	if (frame == [self.webview mainFrame])
		[self _startLoadingNextURL];
	}


#pragma mark WebResourceDelegate


- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource {
	return [NSString rs_uuidString];
	}


- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource {
	[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
	

@end
