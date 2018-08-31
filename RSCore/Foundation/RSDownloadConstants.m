//
//  RSDownloadConstants.m
//  RSCoreTests
//
//  Created by Brent Simmons on 6/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDownloadConstants.h"
#import "RSFoundationExtras.h"


/*URLs*/

NSString *RSURLSchemeHTTP = @"http";
NSString *RSURLSchemeHTTPS = @"https";
NSString *RSURLSchemeFeed = @"feed";
NSString *RSURLSchemeFile = @"file";

BOOL RSURLIsDownloadable(NSURL *URL) {
    /*Return YES if scheme is http, https, or feed*/
    NSString *scheme = [[URL scheme] lowercaseString];
    return [scheme isEqualToString:RSURLSchemeHTTP] || [scheme isEqualToString:RSURLSchemeHTTPS] || [scheme isEqualToString:RSURLSchemeFeed];
}


NSString *RSURLKey = @"url"; //frequently needed

/*Request*/

NSString *RSHTTPMethodPost = @"POST";
NSString *RSHTTPRequestHeaderUserAgent = @"User-Agent";
NSString *RSHTTPRequestHeaderIfNoneMatch = @"If-None-Match";
NSString *RSHTTPRequestHeaderIfModifiedSince = @"If-Modified-Since";

/*Response*/

NSString *RSHTTPResponseHeaderEtag = @"ETag";
NSString *RSHTTPResponseHeaderLastModified = @"Last-Modified";

/*Notifications*/

NSString *RSErrorNotConnectedToInternetNotification = @"RSErrorNotConnectedToInternetNotification";
NSString *RSConnectedToInternetNotification = @"RSConnectedToInternetNotification";


@implementation RSHTTPConditionalGetInfo

@synthesize httpResponseEtag;
@synthesize httpResponseLastModified;


+ (id)conditionalGetInfoWithEtagResponse:(NSString *)anEtagResponse lastModifiedResponse:(NSString *)aLostModifiedResponse {
    return [[self alloc] initWithEtagResponse:anEtagResponse lastModifiedResponse:aLostModifiedResponse];
}


+ (id)conditionalGetInfoWithURLResponse:(NSURLResponse *)urlResponse {
    if (![urlResponse respondsToSelector:@selector(allHeaderFields)])
        return nil;
    NSDictionary *responseHeaders = [(NSHTTPURLResponse *)urlResponse allHeaderFields];
    if (RSIsEmpty(responseHeaders))
        return nil;
    NSString *etag = [responseHeaders rs_objectForCaseInsensitiveKey:RSHTTPResponseHeaderEtag];
    NSString *lastModified = [responseHeaders rs_objectForCaseInsensitiveKey:RSHTTPResponseHeaderLastModified];
    if (RSStringIsEmpty(etag) && RSStringIsEmpty(lastModified))
        return nil;
    return [self conditionalGetInfoWithEtagResponse:etag lastModifiedResponse:lastModified];
}


- (id)initWithEtagResponse:(NSString *)anEtagResponse lastModifiedResponse:(NSString *)aLastModifiedResponse {
    self = [super init];
    if (self == nil)
        return nil;
    httpResponseEtag = [anEtagResponse copy];
    httpResponseLastModified =[aLastModifiedResponse copy];
    return self;
}



@end
