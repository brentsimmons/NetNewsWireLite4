//
//  RSDownloadOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/19/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSDownloadOperation.h"
#import "RSDownloadConstants.h"
#import "RSFoundationExtras.h"
#import "RSSAXParser.h"
#import "RSWebCacheController.h"


static NSString *defaultUserAgent = nil;

@interface RSDownloadOperation ()
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, assign, readwrite) RSDownloadStatus downloadStatus;
- (void)download;
@end


@implementation RSDownloadOperation

@synthesize url, urlRequest, extraRequestHeaders;
@synthesize httpMethod, postBody, urlConnection, urlResponse, finishedReading;
@synthesize responseBody, statusCode;
@synthesize parser, didStartParser;
@synthesize useWebCache, usePermanentWebCache, error, userInfo;
@synthesize downloadStatus;
@synthesize username, password;


#pragma mark Default User Agent

+ (void)setDefaultUserAgent:(NSString *)aUserAgent {
    defaultUserAgent = aUserAgent;
}


#pragma mark Init

- (id)initWithURL:(NSURL *)aURL delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector parser:(id)aParser useWebCache:(BOOL)useWebCacheFlag {
    self = [super initWithDelegate:aDelegate callbackSelector:aCallbackSelector];
    if (!self)
        return nil;
    url = aURL;
    parser = aParser;
    if (parser == nil)
        useWebCache = useWebCacheFlag;
    extraRequestHeaders = [NSMutableDictionary dictionary];
    return self;
}


#pragma mark Dealloc



#pragma mark Cache

- (BOOL)fetchCachedObject {
    if (self.usePermanentWebCache)
        self.responseBody = [[[RSPermanentWebCacheController sharedController] cachedObjectAtURL:self.url] mutableCopy];
    else
        self.responseBody = [[[RSWebCacheController sharedController] cachedObjectAtURL:self.url] mutableCopy];
    return self.responseBody != nil;
}


#pragma mark NSOperation

- (BOOL)isConcurrent {
    return NO;
}


- (void)cancel {
    if (self.parser != nil)
        [self.parser stopParsing];
    [super cancel];
    self.downloadStatus = RSDownloadCanceled;
}


- (void)main {
    if (!self.useWebCache || ![self fetchCachedObject]) /*Short-circuit is significant*/
        [self download];
    [self notifyObserversThatOperationIsComplete];
}


#pragma mark Downloading

- (void)createRequest {
    self.urlRequest = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    if (defaultUserAgent != nil)
        [self.urlRequest setValue:defaultUserAgent forHTTPHeaderField:RSHTTPRequestHeaderUserAgent];
    [self.urlRequest setValue:@"close" forHTTPHeaderField:@"Connection"];
    for (NSString *oneKey in self.extraRequestHeaders)
        [self.urlRequest setValue:[self.extraRequestHeaders objectForKey:oneKey] forHTTPHeaderField:oneKey];
    [self.urlRequest setHTTPShouldHandleCookies:NO];
    if (!RSStringIsEmpty(self.httpMethod))
        [self.urlRequest setHTTPMethod:self.httpMethod];
    if ([self.httpMethod isEqualToString:RSHTTPMethodPost])
        [self.urlRequest setHTTPBody:self.postBody];
}


- (void)download {
    /*TODO: increment and decrement network activity*/
    self.downloadStatus = RSDownloadInProgress;
    [self createRequest];
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:self.urlRequest delegate:self];
    do {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10.0, true);
        if ([self isCancelled]) {
            [self.urlConnection cancel];
            break;
        }
    } while (!self.finishedReading);
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.urlResponse = response;
    if (self.parser == nil)
        self.responseBody = [[NSMutableData alloc] init];
    if ([response respondsToSelector:@selector(statusCode)]) {
        self.statusCode = [(NSHTTPURLResponse *)response statusCode];
//        if (self.statusCode >= 400) {
//            [connection cancel];
//            self.finishedReading = YES;
//        }
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([self isCancelled]) {
        [self.urlConnection cancel];
        return;
    }
    if (self.parser == nil)
        [self.responseBody appendData:data];
    else {
        @autoreleasepool {
            if (self.statusCode < 400) {
                if (self.didStartParser)
                    [self.parser parseChunk:data error:nil];
                else {
                    self.didStartParser = YES;
                    [self.parser startParsing:data];
                }
            }
        }
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)anError {
    //self.responseBody = nil;
    self.error = anError;
    if (self.notConnectedToInternetError)
        [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSErrorNotConnectedToInternetNotification object:self userInfo:nil];
    self.finishedReading = YES;
    self.downloadStatus = RSDownloadComplete;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.parser != nil) {
        @autoreleasepool {
            if (self.didStartParser && ![self isCancelled])
                [self.parser endParsing];
        }
    }
    if (self.useWebCache && self.statusCode == 200) {
        if (self.usePermanentWebCache)
            [[RSPermanentWebCacheController sharedController] storeObject:self.responseBody url:self.url];
        else
            [[RSWebCacheController sharedController] storeObject:self.responseBody url:self.url];
    }
    if (!self.notConnectedToInternetError)
        [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSConnectedToInternetNotification object:self userInfo:nil];
    self.finishedReading = YES;
    self.downloadStatus = RSDownloadComplete;
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if (!RSStringIsEmpty(self.username) && !RSStringIsEmpty(self.password) && [challenge previousFailureCount] < 3) {
        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceForSession];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
        return;
    }    
    [[challenge sender] cancelAuthenticationChallenge:challenge];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}


#pragma mark Errors and Status

- (BOOL)notConnectedToInternetError {
    /*The extra error code 22 and NSPOSIXErrorDomain comes from testing -- happens on our development iPod Touch.*/
    return error != nil && ([error code] == NSURLErrorNotConnectedToInternet || ([error code] == 22 && [[error domain] isEqualToString:NSPOSIXErrorDomain]));
}


- (NSInteger)didFailErrorCode {
    return self.error ? [self.error code] : 0;
}


- (BOOL)authenticationError {
    NSInteger code = self.statusCode;
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"didFailWithAuthenticationError: %d %@", code, self.url);
#endif
    if (code == 401)
        return YES;
    code = [self didFailErrorCode];
    return code == NSURLErrorUserAuthenticationRequired || code == NSURLErrorUserCancelledAuthentication;
}


- (BOOL)okResponse {
    /*The check for NSHTTPURLResponse is because the response may not be an NSHTTPURLResponse -- it may be an ok response from a local URL protocol handler.*/
    return self.error == nil && (self.statusCode == 200 || ![self.urlResponse isKindOfClass:[NSHTTPURLResponse class]]);
}


- (NSString *)responseBodyString {
    if (self.responseBody == nil)
        return nil;
    return [[NSString alloc] initWithData:self.responseBody encoding:NSUTF8StringEncoding];
}


- (void)debugLog {
    NSLog(@"request headers: %@", [self.urlRequest allHTTPHeaderFields]);
    NSLog(@"status code: %ld", (long)[(NSHTTPURLResponse *)(self.urlResponse) statusCode]);
    NSLog(@"response headers: %@", [(NSHTTPURLResponse *)(self.urlResponse) allHeaderFields]);
    NSLog(@"response body: %@", self.responseBodyString);
}


- (RSHTTPConditionalGetInfo *)conditionalGetInfoResponse {
    if (conditionalGetInfoResponse == nil)
        conditionalGetInfoResponse = [RSHTTPConditionalGetInfo conditionalGetInfoWithURLResponse:self.urlResponse];
    return conditionalGetInfoResponse;
}


@end
