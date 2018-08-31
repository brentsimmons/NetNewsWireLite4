/*
	RSAboutWindowController.m
	NetNewsWire

	Created by Brent Simmons on Fri Aug 08 2003.
	Copyright (c) 2003 Ranchero Software. All rights reserved.
*/


#import "RSAboutWindowController.h"
#import "RSFoundationExtras.h"
#import "RSAppKitCategories.h"


@implementation RSAboutWindowController


- (id)init {
	self = [super initWithWindowNibName: @"AboutPanel"];
	[self window];
	return self;
	}


- (void)loadHTMLPage {
	
	NSString *filePathString = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"html"];
	NSURL *fileURL = [NSURL fileURLWithPath:filePathString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:fileURL];
	
	[[_webView mainFrame] loadRequest:urlRequest];	
	}
	
	
- (void)windowDidLoad {
	
	_flWindowDidLoad = YES;
	
	[_webView setUIDelegate:self];
	[_webView setResourceLoadDelegate:[NSApp delegate]];
//	[_webView setCustomUserAgent:NNWUserAgent];
	[_webView setPreferencesIdentifier:@"RSAboutWindow"];
	[[_webView preferences] setUserStyleSheetEnabled:NO];
	[[_webView preferences] setStandardFontFamily:@"Lucida Grande"];
	[[_webView preferences] setDefaultFontSize:12];
	
	[self loadHTMLPage];
	
	[_webView setPolicyDelegate:self];//[NSApp delegate]];
	
	[_appNameTextField setStringValue:[[NSProcessInfo processInfo] processName]];
	[_appVersionTextField rs_safeSetStringValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	}
	

- (void)showWindow:(id)sender {
	if (!_flWindowDidLoad)
		[self window];
	if (![self rs_isOpen])
		[[self window] center];
	[super showWindow:sender];
	}
	

#pragma mark WebUIDelegate

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
	NSURL *link = [elementInformation objectForKey:WebElementLinkURLKey];	
	if (link)
		[_urlTextField rs_safeSetStringValue:[link absoluteString]];
	else
		[_urlTextField setStringValue:@""];
	}


#pragma mark WebPolicyDelegate

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {	
	NSNumber *navTypeNumber = [actionInformation objectForKey:WebActionNavigationTypeKey];
	if ([navTypeNumber integerValue] == WebNavigationTypeLinkClicked) {
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
//		NNWOpenURLStringInFront([[request URL] absoluteString]);
		}	
	else
		[listener use];
	}


- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
	[listener ignore];
	}

	
@end
