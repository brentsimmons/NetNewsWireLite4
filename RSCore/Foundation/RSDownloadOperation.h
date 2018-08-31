//
//  RSDownloadOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/19/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"
#import "RSDownloadConstants.h"


@class RSSAXParser;

@interface RSDownloadOperation : RSOperation {
@protected
	NSURL *url;
	NSMutableURLRequest *urlRequest;
	NSMutableDictionary *extraRequestHeaders;
	NSString *httpMethod;
	NSData *postBody;
	NSURLConnection *urlConnection;
	NSURLResponse *urlResponse;
	BOOL finishedReading;
	NSMutableData *responseBody;
	NSInteger statusCode;
	RSSAXParser *parser;
	BOOL didStartParser;
	BOOL useWebCache;
	BOOL usePermanentWebCache;
	NSDictionary *userInfo;
	NSError *error;
	NSString *username;
	NSString *password;
	RSDownloadStatus downloadStatus;
	RSHTTPConditionalGetInfo *conditionalGetInfoResponse;
}

/*If you set the parser, the responseBody will not be built.
 The parser will be sent each chunk of the response body as it arrives, and each chunk will be let go.

 The web cache saves data to files in temp directory, which is wiped periodically.
 Use exact same way as RSDownloadOperation. Cached response —
 or http response — is in responseBody.
 
 The parser and the web cache are mutually exclusive options. Parser wins.
*/

+ (void)setDefaultUserAgent:(NSString *)aUserAgent;

- (id)initWithURL:(NSURL *)aURL delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector parser:(id)aParser useWebCache:(BOOL)useWebCacheFlag;

@property (nonatomic, retain) NSString *httpMethod;
@property (nonatomic, retain) NSData *postBody;
@property (nonatomic, retain, readonly) NSURL *url;
@property (nonatomic, retain, readonly) NSMutableURLRequest *urlRequest;
@property (nonatomic, retain) NSMutableDictionary *extraRequestHeaders;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSMutableData *responseBody;
@property (nonatomic, retain, readonly) NSString *responseBodyString;
@property (nonatomic, retain) RSSAXParser *parser;
@property (nonatomic, retain, readonly) NSError *error;
@property (nonatomic, assign, readonly) BOOL notConnectedToInternetError;
@property (nonatomic, assign, readonly) BOOL authenticationError;
@property (nonatomic, assign) BOOL finishedReading;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign, readonly) BOOL okResponse;
@property (nonatomic, assign) BOOL didStartParser;
@property (nonatomic, assign) BOOL useWebCache;
@property (nonatomic, assign) BOOL usePermanentWebCache; // useWebCache must also be true: this just specifies which cache
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, assign, readonly) RSDownloadStatus downloadStatus;
@property (nonatomic, retain, readonly) RSHTTPConditionalGetInfo *conditionalGetInfoResponse;

/*For subclasses*/

- (void)createRequest;
- (void)download;
- (BOOL)fetchCachedObject;


- (void)debugLog;


@end
