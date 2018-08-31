//
//  RSErrors.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSErrors.h"
#import "RSFoundationExtras.h"


NSString *RSErrorDateKey = @"errorDate";
NSString *RSLoggableErrorDidHappenNotification = @"RSLoggableErrorDidHappenNotification";


@implementation RSErrors

+ (NSError *)errorWithCode:(NSInteger)errorCode errorString:(NSString *)errorString {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo rs_safeSetObject:errorString forKey:NSLocalizedDescriptionKey];
	[userInfo rs_safeSetObject:[NSDate date] forKey:RSErrorDateKey];
	return [NSError errorWithDomain:RSAppIdentifier() code:errorCode userInfo:userInfo];
}


+ (NSError *)genericHTTPError:(NSInteger)statusCode {
	return [self errorWithCode:RSErrorHTTPGeneric errorString:[self genericHTTPErrorString:statusCode]];
}


#define RS_UNKNOWN_ERROR NSLocalizedString(@"Unknown Error", @"Generic")
#define RS_ERROR_HTTP_GENERIC NSLocalizedString(@"the server returned an unexpected response code: %ld %@", @"Error message")

+ (NSString *)genericHTTPErrorString:(NSInteger)statusCode {
	NSString *localizedStringForStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
	if (RSStringIsEmpty(localizedStringForStatusCode))
		localizedStringForStatusCode = RS_UNKNOWN_ERROR;
	return [NSString stringWithFormat:RS_ERROR_HTTP_GENERIC, (long)statusCode, localizedStringForStatusCode];
}



+ (void)logErrorMessage:(NSString *)message {
	NSError *error = [self errorWithCode:RSErrorGeneric errorString:message];
	[[NSNotificationCenter defaultCenter] postNotificationName:RSLoggableErrorDidHappenNotification object:error userInfo:nil];
}


@end
