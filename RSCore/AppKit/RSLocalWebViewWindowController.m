/*
    RSLocalWebViewWindowController.m
    RancheroAppKit

    Created by Brent Simmons on Tue Aug 03 2004.
    Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import <WebKit/WebKit.h>
#import "RSLocalWebViewWindowController.h"
#import "RSWebBrowser.h"


NSString *RSLocalWebViewPrefsIdentifier = @"RSLocalWebViewWindow";
NSString *RSLocalWebViewNibName = @"LocalWebView";


@interface RSLocalWebViewWindowController (Private)
- (void) setFilename: (NSString *) f;
@end


@implementation RSLocalWebViewWindowController


- (id) initWithFilename: (NSString *) f {
    self = [super initWithWindowNibName: RSLocalWebViewNibName];
    if (self) {
        [self setFilename: f];
        //[self window];
        }
    return (self);
    }
    

    

- (NSString *) filename {
    return (_filename);
    }
    
    
- (void) setFilename: (NSString *) f {
    _filename = f;
    }
    

- (void) loadHTMLPage {
    
    NSString *filePathString = [[NSBundle mainBundle]
        pathForResource: [self filename] ofType: @"html"];
    NSURL *fileURL = [NSURL fileURLWithPath: filePathString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL: fileURL];
    
    [[_webView mainFrame] loadRequest: urlRequest];    
    }


- (void) setWebViewPreferences {
    
    WebPreferences *prefs = [_webView preferences];
    NSString *standardFontFamilyName = [[NSFont systemFontOfSize: 12.0] familyName];
    NSString *fixedFontFamilyName = [[NSFont userFixedPitchFontOfSize: 10.0] familyName];
    
    [prefs setAutosaves: NO];
    [prefs setUserStyleSheetEnabled: YES];
    [prefs setUserStyleSheetEnabled: NO]; /*ensure prefs exist*/

    [prefs setStandardFontFamily: standardFontFamilyName];
    [prefs setFixedFontFamily: fixedFontFamilyName];
    [prefs setSerifFontFamily: standardFontFamilyName];
    [prefs setSansSerifFontFamily: standardFontFamilyName];
    [prefs setDefaultFontSize:12];
    [prefs setDefaultFixedFontSize:10];
    [prefs setJavaEnabled: NO];
    [prefs setJavaScriptEnabled: YES];
    [prefs setJavaScriptCanOpenWindowsAutomatically: NO];
    [prefs setPlugInsEnabled: NO];
    [prefs setAllowsAnimatedImages: NO];
    [prefs setAllowsAnimatedImageLooping: NO];
    [prefs setLoadsImagesAutomatically: YES];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
- (void) windowDidLoad {

    [_webView setPreferencesIdentifier: RSLocalWebViewPrefsIdentifier];
    [self setWebViewPreferences];
    [_webView setUIDelegate: self];
    [_webView setPolicyDelegate: self];
    [_webView setFrameLoadDelegate: self];
    [_webView setApplicationNameForUserAgent: [[NSProcessInfo processInfo] processName]];

    [self loadHTMLPage];    
    }
    

#pragma mark Web policy delegate

- (void) webView: (WebView *) webView
    decidePolicyForNavigationAction: (NSDictionary *) actionInformation
    request: (NSURLRequest *) request
    frame: (WebFrame *) frame
    decisionListener: (id<WebPolicyDecisionListener>) listener {
    
    /*Open the URL in the default browser if clicked on a link that isn't a file url.*/
    
    NSNumber *navTypeNumber = [actionInformation objectForKey: WebActionNavigationTypeKey];
    NSInteger navType = -1;
    
    if (navTypeNumber != nil)
        navType = [navTypeNumber integerValue];
        
    if (navType == WebNavigationTypeLinkClicked) { 
        if (![[[request URL] scheme] isEqualToString: @"file"]) { /*open in default browser?*/
            [listener ignore];
            [RSWebBrowser browserOpenInFront: [[request URL] absoluteString]];
            return;
            }
        }
    
    [listener use];
    }


- (void) webView: (WebView *) webView
    decidePolicyForNewWindowAction: (NSDictionary *) actionInformation
    request: (NSURLRequest *) request
    newFrameName: (NSString *) frameName
    decisionListener: (id <WebPolicyDecisionListener>) listener {
    
    [self webView: webView decidePolicyForNavigationAction: actionInformation
        request: request frame: nil decisionListener: listener];
    }


#pragma mark Web UI Delegate

- (NSArray *) webView: (WebView *) sender
    contextMenuItemsForElement: (NSDictionary *) element
    defaultMenuItems: (NSArray *) defaultMenuItems {

    return (nil);
    }


#pragma mark Web resource load delegate

- (void) webView: (WebView *) sender didReceiveTitle: (NSString *) title forFrame: (WebFrame *) frame {
    if (frame == [_webView mainFrame])
        [_mainWindow setTitle: title];
    }


@end
