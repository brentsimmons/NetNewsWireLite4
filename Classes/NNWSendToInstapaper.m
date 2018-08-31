//
//  NNWSendToInstapaper.m
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSendToInstapaper.h"
#import "NNWInstapaperCredentialsEditor.h"
#import "RSErrors.h"
#import "RSPluginProtocols.h"


@interface NNWSendToInstapaper ()

@property (nonatomic, assign) BOOL runningFeedbackWindow;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, strong) NNWInstapaperCredentialsEditor *instapaperCredentialsEditor;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSURLConnection *URLConnection;
@property (nonatomic, strong) id<RSPluginHelper> pluginHelper;
@property (nonatomic, assign) SEL callbackSelector;
@property (nonatomic, strong) id callbackTarget;
@property (nonatomic, assign, readwrite) BOOL didSucceed;
@property (nonatomic, strong, readwrite) id<RSSharableItem> sharableItem;

- (void)runAPICall;

@end


@implementation NNWSendToInstapaper

@synthesize URLConnection;
@synthesize callbackSelector;
@synthesize callbackTarget;
@synthesize didSucceed;
@synthesize instapaperCredentialsEditor;
@synthesize password;
@synthesize pluginHelper;
@synthesize runningFeedbackWindow;
@synthesize sharableItem;
@synthesize statusCode;
@synthesize username;


#pragma mark Init

- (id)initWithSharableItem:(id<RSSharableItem>)aSharableItem pluginHelper:(id<RSPluginHelper>)aPluginHelper callbackTarget:(id)aCallbackTarget callbackSelector:(SEL)aCallbackSelector {
    self = [super init];
    if (self == nil)
        return nil;
    sharableItem = aSharableItem;
    pluginHelper = aPluginHelper;
    callbackTarget = aCallbackTarget; //yes, because app may dispose of the plugin command
    callbackSelector = aCallbackSelector;
    instapaperCredentialsEditor = [[NNWInstapaperCredentialsEditor alloc] init];
    return self;
}


#pragma mark Dealloc



#pragma mark Feedback/Progress Window

- (void)runFeedbackWindow {
    if (self.runningFeedbackWindow)
        return;
    self.runningFeedbackWindow = YES;
    [self.pluginHelper startIndeterminateFeedbackWithTitle:NSLocalizedStringFromTable(@"Sending to Instapaper", @"Instapaper", @"Progress window") image:[NSImage imageNamed:@"toolbar_main_instapaper"]];    
}


- (void)stopFeedbackWindow {
    if (self.runningFeedbackWindow)
        [self.pluginHelper stopIndeterminateFeedback];
    self.runningFeedbackWindow = NO;
}


#pragma mark Callback

- (void)doCallback {
    if (!self.didSucceed) //showing success message if it did succeed -- don't close the window in that case
        [self stopFeedbackWindow];
    if (self.callbackTarget != nil)
        [self.callbackTarget performSelector:self.callbackSelector withObject:self];
}


#pragma mark Credentials

- (void)askUserForCredentials {
    [self stopFeedbackWindow];
    if (![self.instapaperCredentialsEditor editInstapaperCredentials]) {
        self.didSucceed = NO;
        [self doCallback];
        return; //user canceled
    }
    [self performSelectorOnMainThread:@selector(sendToInstapaper) withObject:nil waitUntilDone:NO];
}


#pragma mark API

- (void)sendToInstapaper {
    
    self.username = self.instapaperCredentialsEditor.username;
    self.password = self.instapaperCredentialsEditor.password;
    
    if (RSStringIsEmpty(self.username)) {
        [self askUserForCredentials];
        return;
    }
    
    [self runFeedbackWindow];    
    [self runAPICall];
}


#pragma mark HTTP

- (NSString *)postBody {
    
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [d rs_safeSetObject:self.username forKey:@"username"];
    if (!RSStringIsEmpty(self.password))
        [d setObject:self.password forKey:@"password"];
    
    NSURL *URLToSend = self.sharableItem.URL;
    if (URLToSend == nil)
        URLToSend = self.sharableItem.permalink;
    [d rs_safeSetObject:[URLToSend absoluteString] forKey:@"url"];
    
    if (RSStringIsEmpty(self.sharableItem.title))
        [d setObject:@"1" forKey:@"auto-title"];
    else
        [d setObject:self.sharableItem.title forKey:@"title"];
    return [d rs_httpPostArgsString];
}


- (void)runAPICall {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.instapaper.com/api/add"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:self.pluginHelper.userAgent forHTTPHeaderField:@"User-Agent"];
    [urlRequest setHTTPBody:[self.postBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    [urlRequest setHTTPShouldHandleCookies:NO];
    self.URLConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
}


#pragma mark Errors


- (void)displayError:(NSError *)error {
    
    if ([error code] == NSUserCancelledError && [[error domain] isEqualToString:NSCocoaErrorDomain])
        return;
    
    NSMutableDictionary *userInfoCopy = [[error userInfo] mutableCopy];
    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Can’t post to Instapaper because: %@", @"Instapaper", @"Instapaper error message"), [error localizedDescription]];
    if (![errorMessage hasSuffix:@"."])
        errorMessage = [NSString stringWithFormat:@"%@.", errorMessage];
    [userInfoCopy setObject:errorMessage forKey:NSLocalizedDescriptionKey];
    NSError *errorCopy = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfoCopy];
    
    [self.pluginHelper presentError:errorCopy];
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response respondsToSelector:@selector(statusCode)])
        self.statusCode = [(NSHTTPURLResponse *)response statusCode];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.didSucceed = NO;
    [self displayError:error];
    [self doCallback];
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [[challenge sender] cancelAuthenticationChallenge:challenge];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil; //bite me
}


/* http://www.instapaper.com/api */

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.didSucceed = NO;
    if (self.statusCode == 403) {
        [self askUserForCredentials];
        return;
    }
    
    if (self.statusCode > 299) {
        NSInteger errorCode = RSErrorHTTPGeneric;
        NSString *errorString = [RSErrors genericHTTPErrorString:self.statusCode];
        if (self.statusCode == 400) {
            errorCode = RSErrorBadRequest;
            errorString = NSLocalizedStringFromTable(@"the server reported that a bad request was made", @"Instapaper", @"Instapaper error message");
        }
        else if (self.statusCode == 500) {
            errorCode = RSErrorServiceEncounteredError;
            errorString = NSLocalizedStringFromTable(@"the server encountered an error", @"Instapaper", @"Instapaper error message");
        }
        [self displayError:[RSErrors errorWithCode:errorCode errorString:errorString]];
    }
    
    if (self.statusCode == 200 || self.statusCode == 201) {
        self.didSucceed = YES;
        [self.pluginHelper showSuccessMessageWithTitle:NSLocalizedStringFromTable(@"It worked!", @"Instapaper", @"Success message") image:[NSImage imageNamed:@"toolbar_main_instapaper"]];
    }
    
    [self doCallback];    
}


@end
