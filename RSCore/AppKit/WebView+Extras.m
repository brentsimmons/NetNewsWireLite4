/*
	WebView+Extras.m
	NetNewsWire

	Created by Brent Simmons on Mon Mar 01 2004.
	Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import "WebView+Extras.h"
#import "RSFoundationExtras.h"


@interface NSObject (WebViewExtrasStringStubs)
- (NSString *)string;
- (NSAttributedString *)attributedString;
- (NSString *)selectedString;
@end


@implementation WebView (Extras)


#pragma mark Queries

- (WebDataSource *)currentWebDataSource {
	WebDataSource *ds = [[self mainFrame] dataSource];	
	if (ds)
		return ds;
	return [[self mainFrame] provisionalDataSource];
	}
	
	
- (NSURL *)currentURL {
	WebDataSource *ds = [self currentWebDataSource];
	if (!ds)
		return nil;		
	NSURLRequest *request = [ds request];
	if (!request)
		return nil;
	return [request URL];
	}
	
	
- (NSString *)currentURLString {
	NSURL *url = [self currentURL];
	if (!url)
		return nil;
	return [url absoluteString];
	}
	
	
- (NSString *)currentTitle {
	WebDataSource *ds = [self currentWebDataSource];	
	if (!ds)
		return nil;
	return [ds pageTitle];
	}


- (NSURL *)loadingURL {
	WebDataSource *ds = [[self mainFrame] provisionalDataSource];
	if (!ds)
		ds = [self currentWebDataSource];
	if (!ds)
		return nil;
	NSURLRequest *request = [ds request];
	if (!request)
		return nil;
	return [request URL];	
	}
	
	
- (NSString *)loadingURLString {
	NSURL *url = [self loadingURL];	
	if (!url)
		return nil;
	return [url absoluteString];
	}
	

- (NSString *)loadingTitle {
	WebDataSource *ds = [[self mainFrame] provisionalDataSource];	
	if (!ds)
		ds = [self currentWebDataSource];
	if (!ds)
		return nil;
	return [ds pageTitle];
	}
	
	
#pragma mark Scrolling

- (BOOL)canScrollDown {
	NSView *view = [[[self mainFrame] frameView] documentView];
	NSRect visibleRect = [view visibleRect];
	return visibleRect.size.height + visibleRect.origin.y < [view bounds].size.height - 5;
	}


- (void)scrollDown {
	[self scrollPageDown:self];
	}


- (void)scrollDownLessThanAFullPage {
	NSView *view = [[[self mainFrame] frameView] documentView];
	NSRect rect = [[view enclosingScrollView] documentVisibleRect];

	rect.origin.y = rect.origin.y + (rect.size.height -
		([[view enclosingScrollView] verticalLineScroll] * 3));    
	rect.origin.y -= 20;
	
	[view scrollRectToVisible: rect];  
	}


- (BOOL)canScrollUp {
	NSRect visibleRect = [[[[self mainFrame] frameView] documentView] visibleRect];
	return visibleRect.origin.y > 0;
	}


- (void)scrollUp {
	[self scrollPageUp:self];
	}


- (void)scrollUpLessThanAFullPage {
	NSView *view = [[[self mainFrame] frameView] documentView];
	NSRect rect = [[view enclosingScrollView] documentVisibleRect];

	rect.origin.y = rect.origin.y - (rect.size.height -
		([[view enclosingScrollView] verticalLineScroll] * 3));
    
	rect.origin.y += 20;
	if (rect.origin.y < 0)
		rect.origin.y = 0;
		
	[view scrollRectToVisible:rect];    
	}


#pragma mark Loading

- (BOOL)loadIsInProgress {
	CGFloat ep = [self estimatedProgress];	
	if ((ep > 0.999) || (ep < 0.001))
		return NO;
	return YES;	
	}
	

- (void)loadRequest:(NSURLRequest *)urlRequest {
	[[self mainFrame] loadRequest:urlRequest];
	}


- (void)loadURLString:(NSString *)urlString {
	
	NSURL *url = nil;
	NSURLRequest *urlRequest = nil;
	
	if (RSIsEmpty(urlString))
		return;
	url = [NSURL URLWithString:urlString];
	if (!url) {
		urlString = RSStringReplaceAll (urlString, @"^", @"%5E");
		urlString = RSStringReplaceAll (urlString, @"~", @"%7E");
		url = [NSURL URLWithString:urlString];
		if (!url)
			return;
		}
	urlRequest = [NSURLRequest requestWithURL:url];
	if (urlRequest)
		[self loadRequest:urlRequest];
	}


- (void)loadBlankPage {
	[self loadURLString:@"about:blank"];
	}
	
	
#pragma mark Source/Text

- (BOOL)canProvideSource {
	WebDataSource *ds = [self currentWebDataSource];
	if (!ds)
		return NO;
	id <WebDocumentRepresentation> rep = [ds representation];
	if (rep)
		return [rep canProvideDocumentSource];
	return NO;
	}
	
	
- (NSString *)htmlSource {
	WebDataSource *ds = [self currentWebDataSource];
	if (!ds)
		return nil;
	id <WebDocumentRepresentation> rep = [ds representation];
	if (!rep)
		return nil;
	if ([rep canProvideDocumentSource])
		return [rep documentSource];
	return nil;
	}
	
	
- (NSString *)text { /*Visible text*/
	NSView *documentView = [[[self mainFrame] frameView] documentView];
	if (!documentView)
		return nil;
	if ([documentView respondsToSelector:@selector(string)])
		return [documentView string];
	else if ([documentView respondsToSelector:@selector(attributedString)])
		return [[documentView attributedString] string];
	return nil;
	}
	

- (NSString *)topText {	/*Top 1000 characters*/
	NSString *s = [self text];
	if (RSIsEmpty(s))
		return nil;
	if ([s length] > 1000)
		s = [s substringToIndex:1000];
	return s;
	}
	
	
- (NSString *)selectedText {
	NSView *documentView = [[[self mainFrame] frameView] documentView];
	if (documentView && [documentView respondsToSelector:@selector(selectedString)])
		return [documentView selectedString];
	return nil;
	}

	
@end
