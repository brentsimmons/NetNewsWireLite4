//
//  NNWErrors.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *NNWErrorDomain;

enum {
	/*http*/
	NNWErrorAuthenticationFailed,
	NNWErrorServiceEncounteredError,
	NNWErrorBadRequest,
	NNWErrorHTTPGeneric,
};

@interface NNWErrors : NSObject

+ (NSError *)errorWithCode:(NSInteger)errorCode errorString:(NSString *)errorString;
+ (NSError *)genericHTTPError:(NSInteger)statusCode;
+ (NSString *)genericHTTPErrorString:(NSInteger)statusCode;

@end