//
//  RSTwitterUtilities.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*The access token is a dictionary returned from RSTwitterCallAuthorize -
 from https://api.twitter.com/oauth/access_token
 This token allows us to make further calls to the Twitter API via OAuth.*/

BOOL RSTwitterFetchAccessTokenFromKeychain(NSDictionary **accessToken, NSString *username, NSError **error);
BOOL RSTwitterStoreAccessTokenInKeychain(NSDictionary *accessToken, NSString *username, NSError **error);


