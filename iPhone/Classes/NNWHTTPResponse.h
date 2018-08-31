//
//  NNWHTTPResponse.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/26/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NNWHTTPResponse : NSObject {
@private
	NSURLResponse *_urlResponse;
	NSData *_data;
	NSError *_error;
	NSError *_parseError;
	id _returnedObject;
}


+ (NNWHTTPResponse *)responseWithURLResponse:(NSURLResponse *)urlResponse data:(NSData *)data error:(NSError *)error;

@property (nonatomic, retain) id returnedObject;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain, readonly) NSString *responseBodyString;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSError *parseError;
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, assign, readonly) BOOL okResponse;
@property (nonatomic, assign, readonly) BOOL notConnectedToInternetError;
@property (nonatomic, assign, readonly) BOOL networkError;
@property (nonatomic, assign, readonly) BOOL badGoogleToken;
@property (nonatomic, assign, readonly) BOOL forbiddenError; /*403 - Google auth. error*/

- (void)debug_showResponseBody;


@end
