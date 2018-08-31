//
//  RSOperationTwitterCall.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <CommonCrypto/CommonHMAC.h>
#import "RSOperationTwitterCall.h"
#import "RSFoundationExtras.h"
#import "RSTwitterUtilities.h"
#import "RSSingleStringParser.h"


static NSString *RSOAuthSignedString(NSString *clearText, NSString *keyText);
static NSString *RSOAuthHeaderStringWithDictionary(NSDictionary *oauthHeaderDictionary);


@interface RSOperationTwitterCall ()
@property (nonatomic, retain) NSString *oauthAuthorizationHeader;
@property (nonatomic, retain, readwrite) NSString *twitterErrorString;
@end


@implementation RSOperationTwitterCall

@synthesize parsedResponse;
@synthesize postBodyDictionary;
@synthesize oauthInfo;
@synthesize oauthAuthorizationHeader;
@synthesize twitterErrorString;

#pragma mark Init

- (id)initWithURL:(NSURL *)aURL oauthInfo:(RSOAuthInfo *)oaInfo delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithURL:aURL delegate:aDelegate callbackSelector:aCallbackSelector parser:nil useWebCache:NO];
	if (self == nil)
		return nil;
	oauthInfo = [oaInfo retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[oauthInfo release];
	[parsedResponse release];
	[postBodyDictionary release];
	[oauthAuthorizationHeader release];
	[twitterErrorString release];
	[super dealloc];
}


#pragma mark NSOperation

- (void)main {
	[self download];
	[self buildParsedResponse];
	[self notifyObserversThatOperationIsComplete];
}


#pragma mark Request

- (NSData *)postBody {
	if (postBody == nil && !RSIsEmpty(self.postBodyDictionary)) {
		NSString *postBodyString = [NSString rs_stringWithURLEncodedNameValuePairsFromDictionarySortedByKey:self.postBodyDictionary];
		//NSLog(@"postBodyString: %@", postBodyString);
		postBody = [[postBodyString dataUsingEncoding:NSUTF8StringEncoding] retain];
	}
	return postBody;
}


- (void)buildAuthorizationHeader {
	
	NSString *oauthNonce = [NSString rs_uuidString];
	NSString *timestamp = [[NSDate date] rs_unixTimestampStringWithNoDecimal];
	
	NSMutableDictionary *oauthSignatureDictionary = [NSMutableDictionary dictionary];
	[oauthSignatureDictionary setObject:self.oauthInfo.consumerKey forKey:@"oauth_consumer_key"];
	[oauthSignatureDictionary setObject:oauthNonce forKey:@"oauth_nonce"];
	[oauthSignatureDictionary setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
	[oauthSignatureDictionary setObject:timestamp forKey:@"oauth_timestamp"];
	[oauthSignatureDictionary setObject:self.oauthInfo.oauthToken ? self.oauthInfo.oauthToken : @"" forKey:@"oauth_token"];
	[oauthSignatureDictionary setObject:@"1.0" forKey:@"oauth_version"];
	[oauthSignatureDictionary addEntriesFromDictionary:self.postBodyDictionary];
	NSString *oauthSignature = [NSString rs_stringWithURLEncodedNameValuePairsFromDictionarySortedByKey:oauthSignatureDictionary];
	/*oauthSignature gets encoded a second time (including the post body)*/
	NSString *oauthBaseSignature = [NSString stringWithFormat:@"POST&%@&%@", [[self.url absoluteString] rs_stringWithURLEncoding], [oauthSignature rs_stringWithURLEncoding]];
	//NSLog(@"oauthBaseSignature: %@", oauthBaseSignature);
	
	NSMutableDictionary *oauthHeaderDictionary = [NSMutableDictionary dictionary];
	[oauthHeaderDictionary setObject:oauthNonce forKey:@"oauth_nonce"];
	[oauthHeaderDictionary setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
	[oauthHeaderDictionary setObject:timestamp forKey:@"oauth_timestamp"];
	[oauthHeaderDictionary setObject:self.oauthInfo.consumerKey forKey:@"oauth_consumer_key"];
	[oauthHeaderDictionary setObject:self.oauthInfo.oauthToken ? self.oauthInfo.oauthToken : @"" forKey:@"oauth_token"];
	NSString *keyForSigning = [NSString stringWithFormat:@"%@&", self.oauthInfo.consumerSecret];
	if (!RSStringIsEmpty(self.oauthInfo.oauthSecret))
		keyForSigning = [NSString stringWithFormat:@"%@%@", keyForSigning, self.oauthInfo.oauthSecret];
	//NSLog(@"keyForSigning: %@", keyForSigning);
	NSString *signedString = RSOAuthSignedString(oauthBaseSignature, keyForSigning);
	//NSLog(@"signedString: %@", signedString);
	[oauthHeaderDictionary setObject:signedString forKey:@"oauth_signature"];
	[oauthHeaderDictionary setObject:@"1.0" forKey:@"oauth_version"];
	NSString *oauthHeaderString = [NSString stringWithFormat:@"OAuth %@", RSOAuthHeaderStringWithDictionary(oauthHeaderDictionary)];
	[self.urlRequest setValue:oauthHeaderString forHTTPHeaderField:@"Authorization"];
	//NSLog(@"authorization: %@", oauthHeaderString);
	self.oauthAuthorizationHeader = oauthHeaderString;
}


- (void)createRequest {
	if ([self.httpMethod isEqualToString:RSHTTPMethodPost])
		[self.extraRequestHeaders setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
	[self buildAuthorizationHeader];
	[self.extraRequestHeaders setObject:self.oauthAuthorizationHeader forKey:@"Authorization"];
	[super createRequest];

}


#pragma mark Response

- (void)buildParsedResponse {
	/*For sub-classes*/
}


- (BOOL)isTwitterUsernamePasswordError {
	if (self.statusCode != 401)
		return NO;
	NSString *body = self.responseBodyString;
	return [body rs_caseInsensitiveContains:@"invalid"] && [body rs_caseInsensitiveContains:@"password"];
}


- (BOOL)isOAuthValidationError {
	/*Response body: @"Failed to validate oauth signature and token"*/
	if (self.statusCode != 401)
		return NO;
	NSString *body = self.responseBodyString;
	return [body rs_caseInsensitiveContains:@"validate"] && [body rs_caseInsensitiveContains:@"oauth"];	
}


- (NSString *)twitterErrorString {
	/*<hash>
	<request>/statuses/update.xml</request>
	<error>Status is a duplicate.</error>
	</hash>*/
	if (twitterErrorString != nil)
		return twitterErrorString;
	NSString *body = self.responseBodyString;
	if (body == nil)
		return nil;
	if (![body rs_contains:@"<error>"]) {
		twitterErrorString = [body retain];
		return twitterErrorString;
	}
	self.twitterErrorString = RSParseSingleStringWithTag(self.responseBody, @"error");
	return twitterErrorString;
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//	[[challenge sender] cancelAuthenticationChallenge:challenge]; //Don't want behavior of RSDownloadOperation where it sends username/password
	[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}


@end

#pragma mark -
#pragma mark C Utilities


static NSString *RSOAuthHeaderStringWithDictionary(NSDictionary *oauthHeaderDictionary) {
	NSMutableArray *headerArray = [NSMutableArray arrayWithCapacity:[oauthHeaderDictionary count]];
	for (NSString *oneKey in oauthHeaderDictionary)
		[headerArray addObject:[NSString stringWithFormat:@"%@=\"%@\"", oneKey, [[oauthHeaderDictionary objectForKey:oneKey] rs_stringWithURLEncoding]]];
	return [headerArray componentsJoinedByString:@", "];			 
}


static NSString *RSOAuthSignedString(NSString *clearText, NSString *keyText) {
	NSData *clearDataToEncode = [clearText dataUsingEncoding:NSUTF8StringEncoding];;
	NSData *keyData = [keyText dataUsingEncoding:NSUTF8StringEncoding];
	
	unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, [keyData bytes], [keyData length]);
	CCHmacUpdate(&hmacContext, [clearDataToEncode bytes], [clearDataToEncode length]);
	CCHmacFinal(&hmacContext, digest);
	
	return [[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] base64EncodedStringWithLineLength:0];
}


#pragma mark -

@implementation RSOAuthInfo

@synthesize consumerKey;
@synthesize consumerSecret;
@synthesize oauthToken;
@synthesize oauthSecret;

- (void)dealloc {
	[consumerKey release];
	[consumerSecret release];
	[oauthToken release];
	[oauthSecret release];
	[super dealloc];
}


@end
