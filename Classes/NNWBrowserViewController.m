//
//  NNWBrowserViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/30/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWBrowserViewController.h"
#import "NNWMainWindowController.h"
#import "RSBrowserTextField.h"
#import "RSMacwebview.h"
#import "RSPluginObjects.h"
#import "Webview+Extras.h"
#import "NNWToolbar.h"


@interface NNWBrowserViewController ()

@property (nonatomic, assign) BOOL pageLoadInProgress;
@property (nonatomic, assign, readonly) double estimatedProgress;

- (void)updateUI;
- (void)setURLStringForBrowserTextField:(NSString *)urlString;

@end


@implementation NNWBrowserViewController

@synthesize backButtonClosesView;
@synthesize toolbar;
@synthesize webview;
@synthesize pageLoadInProgress;
@synthesize addressField;
@synthesize backForwardButtons;
@synthesize delegate;
@synthesize reloadButton;


#pragma mark Init

- (id)init {
    return [self initWithNibName:@"BrowserView" bundle:nil];
}


#pragma mark Dealloc

- (void)dealloc {
    [webview setFrameLoadDelegate:nil];
    [webview setPolicyDelegate:nil];
    
}


#pragma mark AwakeFromNib

- (void)awakeFromNib {
    NSRect rWebView = [self.webview frame];
    NSUInteger webviewAutoresizingMask = [self.webview autoresizingMask];
    self.webview = nil;
    [self.webview removeFromSuperview];
    self.webview = [[RSMacWebView alloc] initWithFrame:rWebView frameName:nil groupName:nil];
    [self.webview setAutoresizingMask:webviewAutoresizingMask];
    [self.view addSubview:self.webview];
    [self.webview setFrameLoadDelegate:self];
    [self.webview setPolicyDelegate:self];
    [self.webview setUIDelegate:self];
//    [self.webview setPreferences:[WebPreferences standardPreferences]];
    [self.reloadButton setTarget:self.webview];
    ((NNWBrowserContentView *)[self view]).controller = self;
}


#pragma mark Public API

- (void)openURL:(NSURL *)aURL {
    [self view]; //just to make sure it's loaded
    if (aURL != nil) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:aURL]];
        [self setURLStringForBrowserTextField:[aURL absoluteString]];
    }
}


- (void)detachDelegates {
    [self.webview detachDelegates];
    self.delegate = nil;
}


#pragma mark UI

- (double)estimatedProgress {
    if (!self.pageLoadInProgress)
        return 0.0;
    return [self.webview estimatedProgress];
}


- (void)setProgressIndicatorRunning:(BOOL)fl {
    [self.addressField setInProgress:fl];
    if (fl)
        [self.addressField setEstimatedProgress:self.estimatedProgress];
    else
        [self.addressField setEstimatedProgress:0.0];
    self.pageLoadInProgress = fl;
    [self.toolbar setNeedsDisplay:YES];
}


- (void)takeTitleFromwebview {
    if (!self.webview)
        [self.addressField setTitle:@""];
    [self.addressField setTitle:[self.webview currentTitle]];
}


- (void)takeProgressFromwebview {
    if (!self.webview)
        [self setProgressIndicatorRunning:NO];
    else
        [self setProgressIndicatorRunning:[self.webview loadIsInProgress]];
}


- (void)setURLStringForBrowserTextField:(NSString *)urlString {
    [self.addressField setDisplayTitle:NO];
    if ([urlString caseInsensitiveCompare:@"about:blank"] != NSOrderedSame)
        [self.addressField setURLString:urlString];
    [self updateUI];
}


- (void)setImageForBrowserTextField:(NSImage *)image {
    [self.addressField setImage:image];
    [self updateUI];
}


- (void)validateButtons {
    BOOL flBackEnabled = NO;
    BOOL flForwardEnabled = NO;
    if (self.webview) {
        flBackEnabled = [self.webview canGoBack];
        flForwardEnabled = [self.webview canGoForward];
    }
    [self.backForwardButtons setEnabled:flBackEnabled || self.backButtonClosesView forSegment:0];
    [self.backForwardButtons setEnabled:flForwardEnabled forSegment:1];
//    [self.backButton setEnabled:flBackEnabled];
//    [self.forwardButton setEnabled:flForwardEnabled];
    
}


- (void)makeAddressFieldFirstResponder {
    [[[self view] window] makeFirstResponder:self.addressField];    
    [self updateUI];
}


- (void)makeWebViewFirstResponder {
    [[[self view] window] makeFirstResponder:self.webview];    
}


- (void)updateAddressField {
    if ([self.webview loadIsInProgress]) {
        NSString *loadingURLString = [self.webview loadingURLString];
        if (!RSIsEmpty(loadingURLString))
            [self setURLStringForBrowserTextField:loadingURLString];
        else {
            NSString *s = [self.webview displayURL];
            if (!RSIsEmpty(s))
                [self setURLStringForBrowserTextField:s];
        }
    }
    else
        [self setURLStringForBrowserTextField:[self.webview displayURL]];
}


- (void)selectTextInAddressField {
    [self.addressField selectText:self];
}


- (void)updateUI {
    [self takeTitleFromwebview];
    [self takeProgressFromwebview];
    [self validateButtons];
}


#pragma mark Events

//- (void)swipeWithEvent:(NSEvent *)event {    
//    if ([event deltaX] > 0.0f) {
//        if ([self.webview canGoBack])
//            [self goBack:nil];
//        else
//            [self closeBrowser:nil];
//    }
//    else if ([event deltaX] < 0.0f)
//        [self goForward:nil];
//    else
//        [super swipeWithEvent:event];
//}


#pragma mark Actions

- (void)goBack:(id)sender {
//    if (![self.webview canGoBack]) {
//        if (self.delegate != nil && self.backButtonClosesView)
//            [self.delegate browserViewControllerDidEndByUserGoingBack:self];
//        return;
//    }
    [self.webview goBack:sender];
    [self updateUI];
}


- (void)goForward:(id)sender {
    [self.webview goForward:sender];
    [self updateUI];
}


- (IBAction)backForwardSegmentClicked:(id)sender {
    if ([self.backForwardButtons selectedSegment] == 0)
        [self goBack:sender];
    else if ([self.backForwardButtons selectedSegment] == 1)
        [self goForward:sender];
}


- (IBAction)openSpecifiedURL:(id)sender {
    
    NSString *originalValue = [sender stringValue];
    NSString *s = [originalValue copy];    
    if (RSStringIsEmpty(s))
        return;
    s = [s rs_stringByTrimmingWhitespace];
    
    if (![s rs_contains:@"."] && ![s rs_contains:@"/"])// && ![s hasPrefix:NNWHTMLReportScheme])
        s = [NSString stringWithFormat:@"%@.com", s];        
    if (![s hasPrefix:@"http"] && ![s rs_contains:@":"])
        s = [NSString stringWithFormat:@"http://%@", s];
    
    if (![s isEqualToString:originalValue])
        [sender rs_safeSetStringValue:s];
    [self.webview loadURLString:s];
    [[self.webview window] makeFirstResponder:self.webview];
    [[self.webview window] performSelectorOnMainThread:@selector(makeFirstResponder:) withObject:self.webview waitUntilDone:NO];
    [self updateUI];
}


- (void)closeBrowser:(id)sender {
    [self.delegate closeBrowserViewController:self];
}


#pragma mark Delegate

- (void)notifyDelegateThatViewDidChange {
    [self.delegate browserViewControllerDidChange:self];
}

@end


#pragma mark -

@implementation NNWBrowserViewController (WebFrameLoadDelegate)

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame == [self.webview mainFrame])
        [self setProgressIndicatorRunning:YES];
    [self updateUI];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame == [self.webview mainFrame]) {
        [self updateAddressField];
        [self setProgressIndicatorRunning:YES];
    }
    [self updateUI];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
    if (frame == [self.webview mainFrame]) {
        [self updateAddressField];
        [self setProgressIndicatorRunning:YES];
    }
    [self updateUI];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
    if (frame == [self.webview mainFrame]) {
        [self setImageForBrowserTextField:image];
    }
    if ([sender respondsToSelector:@selector(setFavicon:)])
        [(RSMacWebView*)sender setFavicon:image];
    
    [self updateUI];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
//    BOOL isErrorPage = RSEqualNotEmptyStrings([sender currentURLString], @"about:blank");
//    WebFrameView *frameView = [[sender mainFrame] frameView];
////    if ([frameView respondsToSelector:@selector(_scrollView)]) {
////        /*This makes sure scrollbars don't disappear.*/
////        NSScrollView *scrollView = [[[sender mainFrame] frameView] _scrollView];
////        if (scrollView && [scrollView respondsToSelector:@selector(setScrollingMode:andLock:)])
////            [scrollView setScrollingMode:0 andLock:YES];
////    }
//
    [(RSMacWebView *)sender setLastLoadedURL:[sender currentURLString]];
    if (frame == [self.webview mainFrame]) {
        [self updateAddressField];
        [self setProgressIndicatorRunning:NO];
//        [self checkForLinkedFeed];
//        [self updateFeedButton];
    }
    [self updateUI];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
//    if (frame == [self.webview mainFrame]) { //TODO: crash on offline
//        [self updateAddressField];
//        [self setProgressIndicatorRunning:NO];
//    }
    if ([[error domain] isEqualToString:WebKitErrorDomain] && [error code] == WebKitErrorFrameLoadInterruptedByPolicyChange)
        goto didFail_exit; /*Downloading file. Ignore error (not really an error).*/
//    NNWTab *tab = [self _tabForFrame:frame];
//    if (tab && ![tab isClosing]) {
//        [tab setLastRequestDidFail:YES];
//        NSString *urlString = [[error userInfo] stringForKey:NSErrorFailingURLStringKey];
//        if (!urlString)
//            urlString = [sender currentURLString];
//        [tab setLastRequestedURL:urlString];
//        [frame loadAlternateHTMLString:NNWHTMLErrorPage(urlString, error) baseURL:nil forUnreachableURL:[NSURL URLWithString:urlString]];
//    }
didFail_exit:
    [self updateUI];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
    [self updateUI];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
//    WebFrameView *frameView = [[sender mainFrame] frameView];
//    if ([frameView respondsToSelector:@selector(_scrollView)]) {
//        /*This makes sure scrollbars don't disappear.*/
//        NSScrollView *scrollView = [[[sender mainFrame] frameView] _scrollView];
//        if (scrollView && [scrollView respondsToSelector:@selector(setScrollingMode:andLock:)])
//            [scrollView setScrollingMode:0 andLock:YES];
//    }
//    if (frame == [[self currentWebView] mainFrame]) {
//        NNWTab *tab = [self _tabForFrame:frame];
//        if (tab && ![tab isClosing])
//            [tab setLastRequestDidFail:YES];
//        [self updateAddressField];
//        [_externalWebViewContainer setProgressIndicatorRunning:NO];
//        [[NSApp delegate] resetStatus];
//        [self updateFeedButton];
//    }
//    [self updateUI];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
//    [self setTabsAreDirty:YES];
//    [[NSNotificationCenter defaultCenter] postNotificationName:NNWWebViewDidUpdateNotification object:sender];
//    [self _setTabForFrameNeedsDisplay:frame];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didChangeLocationWithinPageForFrame:(WebFrame *)frame {
    if (frame == [self.webview mainFrame]) {
        [self updateAddressField];
    }
    [self updateUI];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame {
    [self updateUI];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender didCancelClientRedirectForFrame:(WebFrame *)frame {
    [self updateUI];
    [self notifyDelegateThatViewDidChange];
}


- (void)webView:(WebView *)sender willCloseFrame:(WebFrame *)frame {
    [self updateUI];
    
    /*Make sure the HTML display remains first responder.*/
    
    if (frame == [self.webview mainFrame]) {
        
        NSResponder *fr = [[self.webview window] firstResponder];
        
        if ([fr isKindOfClass:[NSView class]]) {
            if ([(NSView *) fr isDescendantOf:[self view]]) {
                [[[self view] window] makeFirstResponder:self.webview];
                [self performSelectorOnMainThread:@selector(makeWebViewFirstResponder) withObject:nil waitUntilDone:NO];
            }
        }        
    }
    
    [self updateUI];
    [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    [self notifyDelegateThatViewDidChange];
}


@end


#pragma mark -

@implementation NNWBrowserViewController (WebPolicyDelegate)


- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    NSNumber *navTypeNumber = [actionInformation objectForKey:WebActionNavigationTypeKey];
    NSInteger navType = -1;    
    if (navTypeNumber != nil)
        navType = [navTypeNumber integerValue];
    
    if ([[[[request URL] scheme] lowercaseString] isEqualToString:@"marsedit"]) {
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        return;
    }

    if (navType == WebNavigationTypeLinkClicked) {
        if ([rs_app_delegate systemShouldOpenURLString:[[request URL] absoluteString]]) {
            [[NSWorkspace sharedWorkspace] openURL:[request URL]];
            [listener ignore];
            return;
        }
    }
    
    [listener use];
}


- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    NSNumber *navTypeNumber = [actionInformation objectForKey:WebActionNavigationTypeKey];
    NSInteger navType = -1;
    NSString *urlString = [[request URL] absoluteString];
    
    if (navTypeNumber != nil)
        navType = [navTypeNumber integerValue];
    
    [listener ignore];
    
    if (urlString == nil || navType != WebNavigationTypeLinkClicked) /*no popups*/
        return;
    if ([rs_app_delegate systemShouldOpenURLString:urlString]) {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        return;
    }

    [[webView mainFrame] loadRequest:request];
}


- (void)webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    BOOL flDownloadOnlyType = NO;
    
    /*Open the URL in the default browser if can't display.*/
    
    if ([type rs_contains: @"javascript"]) {
        [listener use];
        return;
    }
    
    if ([type isEqualToString:@"application/x-diskcopy"] || /*Prevent Speed Download hijack, which triggers Apple*/
        [type isEqualToString:@"application/x-gzip"] ||    /*bug where plugins don't seem to get disposed*/
        [type isEqualToString:@"application/mac-binhex40"] ||
        [type isEqualToString:@"application/x-compress"] ||
        [type isEqualToString:@"application/macbinary"] ||
        [type isEqualToString:@"application/zip"] ||
        [type isEqualToString:@"application/x-stuffit"] ||
        [type isEqualToString:@"application/x-tar"] ||
        [type isEqualToString:@"application/pdf"] || /*Acrobat plugin crashes on 10.4, so always dl pdfs*/
        [type isEqualToString:@"application/x-pdf"] ||
        [type isEqualToString:@"application/acrobat"] ||
        [type isEqualToString:@"applications/vnd.pdf"] ||
        [type isEqualToString:@"text/pdf"] ||
        [type isEqualToString:@"text/x-pdf"] ||
        [type hasPrefix:@"application/x-zip"] ||
        [type isEqualToString:@"application/octet-stream"])
        flDownloadOnlyType = YES;
    
    BOOL isFeed = NO;
    if ([request URL] && ([type hasPrefix:@"application/rss+xml"] || [type hasPrefix:@"application/atom+xml"]))
        isFeed = YES;
    
    if (!flDownloadOnlyType && !isFeed && [WebView canShowMIMEType:type]) {
        [listener use];
        return;
    }
    if (isFeed)
        [[NSApp delegate] performSelector:@selector(handleSubscribeToFeedRequest:) withObject:[[request URL] absoluteString]];
    else
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    
    [listener ignore];
}


- (void)webView:(WebView *)webView unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame {
}


@end


#pragma mark -

@implementation NNWBrowserViewController (WebUIDelegate)

- (void)sendURLDidUpdateNotification:(NSString *)urlString notificationName:(NSString *)notificationName {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo rs_safeSetObject:urlString forKey:RSURLKey];
    [userInfo rs_safeSetObject:[self view] forKey:@"view"];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
    NSURL *link = [elementInformation objectForKey:WebElementLinkURLKey];
    [self sendURLDidUpdateNotification:link ? [link absoluteString] : nil notificationName:NNWMouseOverURLDidUpdateNotification];
}


static NSString *urlStringFromElementDictionary(NSDictionary *dict) {
    id url = [dict objectForKey:@"WebElementLinkURL"];
    if (!url)
        return nil;    
    if ([url isKindOfClass:[NSURL class]])
        return [url absoluteString];
    if (![url isKindOfClass:[NSString class]])
        return nil;
    return url;
}

- (NNWMainWindowController *)mainWindowController {
    return [[[self view] window] windowController];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    
    /*We only care about links. Everything just use the default.*/
    
    NSString *link = urlStringFromElementDictionary(element);
    if (link == nil)
        return defaultMenuItems;
    NSURL *aURL = [NSURL URLWithString:link];
    if (aURL == nil)
        return defaultMenuItems;
    
    NSMenu *browserContextualMenu = [[NSMenu alloc] initWithTitle:@"Browser Contextual Menu for Links"];
    [[self mainWindowController] addSharingPluginCommandsToMenu:browserContextualMenu withSharableItem:[RSSharableItem sharableItemWithURL:aURL]];
    
    NSArray *items = [[browserContextualMenu itemArray] copy];
    [browserContextualMenu removeAllItems];
    return items;
}


@end


@implementation NNWBrowserContentView

@synthesize controller;

- (WebView *)webview {
    return self.controller.webview;
}

- (void)swipeWithEvent:(NSEvent *)event {    
    if ([event deltaX] > 0.0f) {
        if ([[self webview] canGoBack])
            [self.controller goBack:nil];
        else
            [self tryToPerform:@selector(performClose:) with:event];
    }
    else if ([event deltaX] < 0.0f)
        [self.controller goForward:nil];
    else
        [super swipeWithEvent:event];
}

@end
