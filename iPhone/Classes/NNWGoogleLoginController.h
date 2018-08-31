//
//  NNWGoogleLoginController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


//extern NSString *NNWGoogleSIDToken;
extern NSString *NNWGoogleAuthToken;
extern NSString *NNWGoogleTToken;


@interface NNWGoogleLoginController : NSObject {
@private
	//	NSString *_sid;
	NSString *authToken;
	NSString *_tToken;
}


+ (id)sharedController;

/*Will attempt to login if needed. Keys are NNWGoogleAuthToken and NNWGoogleTToken.
 Synchronous. Call from background thread only.*/
- (NSDictionary *)googleLoginInfo; 
- (void)clearLoginInfo;

- (void)trySynchronousLoginWithUsername:(NSString *)username andPassword:(NSString *)password callbackTarget:(id)callbackTarget callbackSelector:(SEL)callbackSelector;
- (NSInteger)synchronousLogin;


@end
