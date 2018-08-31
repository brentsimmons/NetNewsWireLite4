//
//  RSGoogleReaderLoginController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *SLGoogleReaderAuthTokenKey;
extern NSString *SLGoogleReaderTTokenKey;


@interface RSGoogleReaderLoginController : NSObject {
@private
	NSString *authToken;
	NSString *tToken;
}


+ (id)sharedController;

/*Will attempt to login if needed. Keys are SLGoogleReaderAuthTokenKey and SLGoogleReaderTTokenKey. Synchronous. Call from background thread only.*/
- (NSDictionary *)googleLoginInfo; 
- (void)clearLoginInfo;

- (void)trySynchronousLoginWithUsername:(NSString *)username andPassword:(NSString *)password callbackTarget:(id)callbackTarget callbackSelector:(SEL)callbackSelector;
- (NSInteger)synchronousLogin;

+ (void)addAuthTokenToRequest:(NSMutableURLRequest *)urlRequest googleAuthToken:(NSString *)googleAuthToken;

@end
