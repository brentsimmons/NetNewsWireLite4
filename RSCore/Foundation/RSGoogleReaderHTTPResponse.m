//
//  RSGoogleReaderHTTPResponse.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/26/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleReaderHTTPResponse.h"


@implementation RSGoogleReaderHTTPResponse

@synthesize urlResponse = _urlResponse, data = _data, error = _error, parseError = _parseError, returnedObject= _returnedObject;

+ (RSGoogleReaderHTTPResponse *)responseWithURLResponse:(NSURLResponse *)aURLResponse data:(NSData *)someData error:(NSError *)anError {
	RSGoogleReaderHTTPResponse *response = [[[self alloc] init] autorelease];
	response.urlResponse = aURLResponse;
	response.data = someData;
	response.error = anError;
	return response;
}


- (void)dealloc {
	[_urlResponse release];
	[_data release];
	[_error release];
	[_parseError release];
	[_returnedObject release];
	[super dealloc];
}


- (NSInteger)statusCode {
	if ([self.urlResponse respondsToSelector:@selector(statusCode)])
		return [(NSHTTPURLResponse *)(self.urlResponse) statusCode];
	return -1;
}


- (BOOL)okResponse {
	return !self.error && self.statusCode == 200;
}


- (BOOL)notConnectedToInternetError {
	return self.error && [self.error code] == NSURLErrorNotConnectedToInternet;
}


- (BOOL)networkError {
	/*Usually means that the request should be re-tried.*/
	if (!self.error)
		return NO;
	NSInteger errorCode = [self.error code];
	return errorCode == NSURLErrorUnknown || errorCode == NSURLErrorTimedOut || errorCode == NSURLErrorCannotFindHost || errorCode == NSURLErrorCannotConnectToHost || errorCode == NSURLErrorNetworkConnectionLost || errorCode == NSURLErrorDNSLookupFailed || errorCode == NSURLErrorNotConnectedToInternet;
}


- (BOOL)badGoogleToken {
//	if (self.statusCode == 401 || self.statusCode == 301 || self.statusCode == 302 || self.statusCode == 400)
//		return YES;
//	if ([self.urlResponse respondsToSelector:@selector(allHeaderFields)]) {
//		if ([[(NSHTTPURLResponse *)self.urlResponse allHeaderFields] objectForKey:@"X-Reader-Google-Bad-Token"] != nil)
//			NSLog(@"bad google token");
//	}
	if ([self.urlResponse respondsToSelector:@selector(allHeaderFields)])
		return [[(NSHTTPURLResponse *)self.urlResponse allHeaderFields] objectForKey:@"X-Reader-Google-Bad-Token"] != nil; /*Accompanied by 400 response code*/
	return NO;
}


- (BOOL)forbiddenError {
	/*403 - Google authentication error*/
	return self.statusCode == 403;
}


@end
