//
//  RSDownloadConstants.h
//  RSCoreTests
//
//  Created by Brent Simmons on 6/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*These can be used anywhere, not just with RSDownloadOperation.
 It's a good idea to add RSDownloadConstants.h to your prefix file.*/


typedef enum _RSDownloadStatus {
    RSDownloadPending = 0,
    RSDownloadInProgress,
    RSDownloadComplete,
    RSDownloadCanceled
} RSDownloadStatus;


/* HTTP Request Status Codes http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html */

typedef enum _RSHTTPStatusCode {
    RSHTTPStatusOK = 200,
    RSHTTPStatusMovedPermanently = 301,
    RSHTTPStatusMovedTemporarily = 302,
    RSHTTPStatusNotModified = 304,
    RSHTTPStatusBadRequest = 400,
    RSHTTPStatusUnauthorized = 401,
    RSHTTPStatusForbidden = 403,
    RSHTTPStatusNotFound = 404,
    RSHTTPStatusGone = 410,
    RSHTTPStatusServerError = 500,
    RSHTTPStatusNotImplemented = 501,
    RSHTTPStatusBadGateway = 502,
    RSHTTPStatusServiceNotAvailable = 503
} RSHTTPStatusCode;


/*URLs*/

extern NSString *RSURLSchemeHTTP; //@"http"
extern NSString *RSURLSchemeHTTPS; //@"https"
extern NSString *RSURLSchemeFile; //@"file"
extern NSString *RSURLSchemeFeed; //@"feed"

BOOL RSURLIsDownloadable(NSURL *URL); //YES if scheme is http, https, or feed

extern NSString *RSURLKey; //@"url" -- often needed in dictionaries

/*Request*/

extern NSString *RSHTTPMethodPost; //@"POST"
extern NSString *RSHTTPRequestHeaderUserAgent; //@"User-Agent"
extern NSString *RSHTTPRequestHeaderIfNoneMatch; //@"If-None-Match" - etag request header (conditional GET)
extern NSString *RSHTTPRequestHeaderIfModifiedSince; //@"If-Modified-Since" - used with last modified date (conditional GET)

/*Response*/

extern NSString *RSHTTPResponseHeaderEtag; //@"ETag"
extern NSString *RSHTTPResponseHeaderLastModified; //@"Last-Modified"

/*Notifications*/

extern NSString *RSErrorNotConnectedToInternetNotification;
extern NSString *RSConnectedToInternetNotification;


@interface RSHTTPConditionalGetInfo : NSObject {
@private
    NSString *httpResponseEtag;
    NSString *httpResponseLastModified;
}

+ (id)conditionalGetInfoWithEtagResponse:(NSString *)anEtagResponse lastModifiedResponse:(NSString *)aLostModifiedResponse;
+ (id)conditionalGetInfoWithURLResponse:(NSURLResponse *)urlResponse;

- (id)initWithEtagResponse:(NSString *)anEtagResponse lastModifiedResponse:(NSString *)aLastModifiedResponse;

@property (nonatomic, strong) NSString *httpResponseEtag;
@property (nonatomic, strong) NSString *httpResponseLastModified;

@end
