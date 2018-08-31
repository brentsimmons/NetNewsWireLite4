//
//  NNWHTTPResponse.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/26/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWHTTPResponse.h"
#import "NNWAppDelegate.h"
#import "RSDownloadConstants.h"


@implementation NNWHTTPResponse

@synthesize urlResponse = _urlResponse, data = _data, error = _error, parseError = _parseError, returnedObject= _returnedObject;

+ (NNWHTTPResponse *)responseWithURLResponse:(NSURLResponse *)urlResponse data:(NSData *)data error:(NSError *)error {
	NNWHTTPResponse *response = [[[self alloc] init] autorelease];
	response.urlResponse = urlResponse;
	response.data = data;
	response.error = error;
	if (error && [error code] == NSURLErrorNotConnectedToInternet)
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:RSErrorNotConnectedToInternetNotification object:nil] waitUntilDone:NO];
	else if (!error)
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:RSConnectedToInternetNotification object:nil] waitUntilDone:NO];
		
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


- (NSString *)responseBodyString {
	return [[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding] autorelease];
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
	if ([self.urlResponse respondsToSelector:@selector(allHeaderFields)])
		return [[(NSHTTPURLResponse *)self.urlResponse allHeaderFields] objectForKey:@"X-Reader-Google-Bad-Token"] != nil;
	return NO;
}


- (BOOL)forbiddenError {
	/*403 - Google authentication error*/
	return self.statusCode == 403;
}



- (void)debug_showResponseBody {
	NSLog(@"---HTTP Response---\n<%@>\n%@", [self.urlResponse URL], self.responseBodyString);
}


@end
