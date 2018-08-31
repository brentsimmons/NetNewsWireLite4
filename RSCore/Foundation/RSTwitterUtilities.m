//
//  RSTwitterUtilities.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSTwitterUtilities.h"
#import "RSFoundationExtras.h"
#import "RSKeychain.h"


NSString *RSTwitterOAuthTokenKey = @"oauth_token";
NSString *RSTwitterOAuthTokenSecretKey = @"oauth_token_secret";


#pragma mark Keychain

static NSString *RSTwitterAccessCodeServiceName(void) {
	/*The name includes the name of the app, as in appname: TwitterAccessToken.
	 I think that iPhone apps get their own private keychain, so it's not that big a deal.
	 But I could be wrong -- and, anyway, this code needs to work on Macs too.*/
	static NSString *twitterAccessCodeServiceName = nil;
	if (twitterAccessCodeServiceName == nil)
		twitterAccessCodeServiceName = [[NSString stringWithFormat:@"%@: TwitterAccessToken", RSAppName()] retain];
	return twitterAccessCodeServiceName;
}


BOOL RSTwitterFetchAccessTokenFromKeychain(NSDictionary **accessToken, NSString *username, NSError **error) {
	NSString *accessTokenString = nil;
	if (!RSKeychainGetPassword(RSTwitterAccessCodeServiceName(), username, &accessTokenString, error))
		return NO;
	if (RSIsEmpty(accessTokenString))
		return YES; //no error: it just wasn't found
	NSPropertyListFormat plistFormat = kCFPropertyListXMLFormat_v1_0;
	NSString *errorString = nil;
	*accessToken = [NSPropertyListSerialization propertyListFromData:[accessTokenString dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:&plistFormat errorDescription:&errorString];
	if (errorString != nil) {
		[errorString release]; //Docs say to release it
		return NO;
	}
	return YES;
}


BOOL RSTwitterStoreAccessTokenInKeychain(NSDictionary *accessToken, NSString *username, NSError **error) {
	NSString *errorString = nil;
	NSData *twitterAccessTokenData = [NSPropertyListSerialization dataFromPropertyList:accessToken format:kCFPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	if (errorString != nil) {
		[errorString release]; //Docs say to release it
		return NO;
	}
	NSString *twitterAccessTokenString = [[[NSString alloc] initWithData:twitterAccessTokenData encoding:NSUTF8StringEncoding] autorelease];
	return RSKeychainSetPassword(RSTwitterAccessCodeServiceName(), username, twitterAccessTokenString, error);
}



