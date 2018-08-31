/*
	WebView+Extras.h
	NetNewsWire

	Created by Brent Simmons on Mon Mar 01 2004.
	Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface WebView (Extras)


/*Queries*/

- (WebDataSource *)currentWebDataSource;
- (NSURL *)currentURL;
- (NSString *)currentURLString;
- (NSString *)currentTitle;
- (NSString *)loadingTitle;
- (NSString *)loadingURLString;
- (NSURL *)loadingURL;	
- (NSString *)loadingURLString;
- (NSString *)loadingTitle;


/*Scrolling*/

- (BOOL)canScrollDown;
- (void)scrollDown;
- (void)scrollDownLessThanAFullPage;
- (BOOL)canScrollUp;
- (void)scrollUp;
- (void)scrollUpLessThanAFullPage;


/*Loading*/

- (BOOL)loadIsInProgress;
- (void)loadRequest:(NSURLRequest *)urlRequest;
- (void)loadURLString:(NSString *)urlString;
- (void)loadBlankPage;


/*Source/Text*/

- (BOOL)canProvideSource;	
- (NSString *)htmlSource;	
- (NSString *)text; /*Visible text*/
- (NSString *)topText; /*Top 1000 characters*/		
- (NSString *)selectedText;


@end
