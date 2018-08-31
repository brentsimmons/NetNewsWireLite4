//
//  RSTwitterCallAuthorize.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSTwitterCallAuthorize.h"
#import "RSDownloadConstants.h"
#import "RSFoundationExtras.h"
#import "RSTwitterUtilities.h"


@implementation RSTwitterCallAuthorize

#pragma mark Init

- (id)initWithOAuthInfo:(RSOAuthInfo *)oaInfo username:(NSString *)aUsername password:(NSString *)aPassword delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"] oauthInfo:oaInfo delegate:aDelegate callbackSelector:aCallbackSelector];
	if (self == nil)
		return nil;
	username = [[aUsername precomposedStringWithCanonicalMapping] retain];
	password = [[aPassword precomposedStringWithCanonicalMapping] retain];
	return self;
}


#pragma mark Request

- (void)createRequest {
	self.oauthInfo.oauthToken = nil;
	self.oauthInfo.oauthSecret = nil; //need to make sure
	self.httpMethod = RSHTTPMethodPost;
	self.postBodyDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"client_auth", @"x_auth_mode", self.password, @"x_auth_password", self.username, @"x_auth_username", nil];
	[super createRequest];
}


#pragma mark Response

- (void)buildParsedResponse {
	if (!self.okResponse)
		return;
	NSString *response = [[[NSString alloc] initWithData:self.responseBody encoding:NSUTF8StringEncoding] autorelease];
	NSMutableDictionary *twitterResponse = [NSMutableDictionary dictionary];
	@try {
		for (NSString *oneNameValuePair in [response componentsSeparatedByString:@"&"]) {
			NSArray *oneNameValueComponents = [oneNameValuePair componentsSeparatedByString:@"="];
			[twitterResponse setObject:[oneNameValueComponents objectAtIndex:1] forKey:[oneNameValueComponents objectAtIndex:0]];
		}		
		self.parsedResponse = twitterResponse;
	}
	@catch (id obj) {
	}
}


@end



