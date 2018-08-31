//
//  RSOperationTwitterCall.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSDownloadOperation.h"


enum {
	RSTwitterMaxCharacters = 140
};

extern NSString *RSTwitterOAuthTokenKey; //@"oauth_token"
extern NSString *RSTwitterOAuthTokenSecretKey; //@"oauth_token_secret"

/*Pure data class, just to simplify the parameter lists for Twitter calls.*/

@interface RSOAuthInfo : NSObject {
@private
	NSString *consumerKey;
	NSString *consumerSecret;
	NSString *oauthToken;
	NSString *oauthSecret;
}


@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *consumerSecret;
@property (nonatomic, retain) NSString *oauthToken;
@property (nonatomic, retain) NSString *oauthSecret;


@end


@interface RSOperationTwitterCall : RSDownloadOperation {
@private
	RSOAuthInfo *oauthInfo;
	NSDictionary *postBodyDictionary;
	NSString *oauthAuthorizationHeader;
	id parsedResponse;
	NSString *twitterErrorString;
}


- (id)initWithURL:(NSURL *)aURL oauthInfo:(RSOAuthInfo *)oaInfo delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;


@property (nonatomic, retain) id parsedResponse;
@property (nonatomic, assign, readonly) BOOL isTwitterUsernamePasswordError;
@property (nonatomic, assign, readonly) BOOL isOAuthValidationError;
@property (nonatomic, retain, readonly) NSString *twitterErrorString;

/*For subclasses*/

@property (nonatomic, retain) NSDictionary *postBodyDictionary;
@property (nonatomic, retain) RSOAuthInfo *oauthInfo;

- (void)buildParsedResponse; //over-ride this and set self.parsedResponse


@end
