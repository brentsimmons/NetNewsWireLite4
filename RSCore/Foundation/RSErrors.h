//
//  RSErrors.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *RSErrorDateKey;
extern NSString *RSLoggableErrorDidHappenNotification;

enum {
	RSErrorGeneric = -1,
	/*http*/
	RSErrorAuthenticationFailed = 0,
	RSErrorServiceEncounteredError,
	RSErrorBadRequest,
	RSErrorHTTPGeneric,
};


@interface RSErrors : NSObject {
}


+ (NSError *)errorWithCode:(NSInteger)errorCode errorString:(NSString *)errorString;
+ (NSError *)genericHTTPError:(NSInteger)statusCode;
+ (NSString *)genericHTTPErrorString:(NSInteger)statusCode;

+ (void)logErrorMessage:(NSString *)message;

	
@end
