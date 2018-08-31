//
//  NNWErrors.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWErrors.h"

NSString *NNWErrorDomain = @"com.newsgator.NetNewsWire";

@implementation NNWErrors

+ (NSError *)errorWithCode:(NSInteger)errorCode errorString:(NSString *)errorString {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo safeSetObject:errorString forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:NNWErrorDomain code:errorCode userInfo:userInfo];
}


+ (NSError *)genericHTTPError:(NSInteger)statusCode {
	return [self errorWithCode:NNWErrorHTTPGeneric errorString:[self genericHTTPErrorString:statusCode]];
}


+ (NSString *)genericHTTPErrorString:(NSInteger)statusCode {
	NSString *localizedStringForStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
	if (RSStringIsEmpty(localizedStringForStatusCode))
		localizedStringForStatusCode = @"Unknown Error";
	return [NSString stringWithFormat:@"the server returned an unexpected response code: %d %@", statusCode, localizedStringForStatusCode];
}


@end
