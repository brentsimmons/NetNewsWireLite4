//
//  RSGoogleReaderSynchronousAPICalls.m
//  RSCoreTests
//
//  Created by Brent Simmons on 12/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSGoogleReaderSynchronousAPICalls.h"
#import "RSGoogleReaderConstants.h"
#import "RSGoogleReaderHTTPResponse.h"
#import "RSGoogleReaderLoginController.h"
#import "RSGoogleReaderUtilities.h"


@implementation RSGoogleReaderSynchronousAPICalls


static NSString *gUserAgent = nil;

+ (void)setUserAgent:(NSString *)aUserAgent {
	[gUserAgent autorelease];
	gUserAgent = [aUserAgent retain];
}


#pragma mark Synchronous Login

static NSString *NNWGoogleErrorKey = @"Error";

- (RSGoogleReaderLoginResponseCode)googleErrorResponseCodeForErrorString:(NSString *)errorString {
	if (RSStringIsEmpty(errorString))
		return RSGoogleReaderLoginResponseCodeUnknown;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringBadAuthentication])
		return RSGoogleReaderLoginResponseCodeBadAuthentication;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringNotVerified])
		return RSGoogleReaderLoginResponseCodeNotVerified;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringTermsNotAgreed])
		return RSGoogleReaderLoginResponseCodeTermsNotAgreed;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringCaptchaRequired])
		return RSGoogleReaderLoginResponseCodeCaptchaRequired;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringUnknown])
		return RSGoogleReaderLoginResponseCodeUnknown;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringAccountDeleted])
		return RSGoogleReaderLoginResponseCodeAccountDeleted;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringAccountDisabled])
		return RSGoogleReaderLoginResponseCodeAccountDisabled;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringServiceDisabled])
		return RSGoogleReaderLoginResponseCodeServiceDisabled;
	if ([errorString isEqualToString:SLGoogleReaderLoginErrorResponseStringServiceUnavailable])
		return RSGoogleReaderLoginResponseCodeServiceUnavailable;
	return RSGoogleReaderLoginResponseCodeUnknown;
}


//- (RSGoogleReaderLoginResponseCode)synchronousLogin {
//	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NNWGoogle urlWithClientAppended:@"https://www.google.com/accounts/ClientLogin"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
//	[urlRequest setHTTPMethod:@"POST"];
//	[urlRequest setValue:NNWUserAgent forHTTPHeaderField:@"User-Agent"];
//	[urlRequest setHTTPBody:[[self _loginPostBody] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
//	[urlRequest setHTTPShouldHandleCookies:NO];
//	NSURLResponse *response = nil;
//	NSError *error = nil;
//	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
//	if ([response respondsToSelector:@selector(statusCode)])
//		self.statusCode = [(NSHTTPURLResponse *)response statusCode];
//	NSString *responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
//	if (self.statusCode != 200) {
//		NSLog(@"Google login status code: %ld", (long)(self.statusCode));
//		NSLog(@"Google response: %@", responseString ? responseString : @"none");
//	}
//	NSDictionary *d = _dictionaryFromLoginResponseBody(responseString);
//	self.loginResponse = d;
//	if (self.statusCode == 200)
//		return RSGoogleReaderLoginResponseCodeSuccess;
//	NNWGoogleLoginResponseCode responseCode = [self googleErrorResponseCodeForErrorString:[d objectForKey:NNWGoogleErrorKey]];
//	if (responseCode == RSGoogleReaderLoginResponseCodeCaptchaRequired)
//		RSWebBrowserOpenURLInFront(@"https://www.google.com/accounts/DisplayUnlockCaptcha"); //TODO: don't do this hack
//	return responseCode;
//}


#pragma mark Synchronous Requests

+ (NSMutableDictionary *)postBodyDictionary {
	NSMutableDictionary *postBodyDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
	NSDictionary *googleLoginInfo = [[RSGoogleReaderLoginController sharedController] googleLoginInfo];
	if (!googleLoginInfo)
		return nil;
	[postBodyDictionary rs_safeSetObject:[googleLoginInfo objectForKey:@"t"] forKey:@"T"];
	return postBodyDictionary;
}


+ (NSMutableURLRequest *)urlRequest:(NSString *)urlString postBodyDictionary:(NSDictionary *)postBodyDictionary {
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:RSGoogleReaderURLWithClientAppended(urlString) cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
	if (postBodyDictionary) {
		[urlRequest setHTTPMethod:@"POST"];
		[urlRequest setHTTPBody:[[postBodyDictionary rs_httpPostArgsString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	}
	if (gUserAgent != nil)
		[urlRequest setValue:gUserAgent forHTTPHeaderField:@"User-Agent"];
	[urlRequest setHTTPShouldHandleCookies:NO];
	[RSGoogleReaderLoginController addAuthTokenToRequest:urlRequest googleAuthToken:[[[RSGoogleReaderLoginController sharedController] googleLoginInfo] objectForKey:SLGoogleReaderAuthTokenKey]];
	return urlRequest;
}


+ (RSGoogleReaderHTTPResponse *)sendRequest:(NSURLRequest *)urlRequest {
	NSURLResponse *response = nil;
	NSError *error = nil;
	if ([[urlRequest HTTPMethod] isEqualToString:@"POST"]) {
		urlRequest = [[urlRequest mutableCopy] autorelease];
		[(NSMutableURLRequest *)urlRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	}
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	return [RSGoogleReaderHTTPResponse responseWithURLResponse:response data:data error:error];
}


+ (RSGoogleReaderHTTPResponse *)sendRequestWithURLString:(NSString *)urlString postBodyDictionary:(NSDictionary *)postBodyDictionary {
	RSGoogleReaderHTTPResponse *response = [self sendRequest:[self urlRequest:urlString postBodyDictionary:postBodyDictionary]];
	if (!response.badGoogleToken)
		return response;
	//	[[NNWDownloadController sharedController] reloginToGoogle];
	NSDictionary *googleLoginInfo = [[RSGoogleReaderLoginController sharedController] googleLoginInfo];
	NSMutableDictionary *postBodyDictionaryCopy = [[postBodyDictionary mutableCopy] autorelease];
	if ([postBodyDictionaryCopy objectForKey:@"T"])
		[postBodyDictionaryCopy rs_safeSetObject:[googleLoginInfo objectForKey:@"t"] forKey:@"T"];
	return [self sendRequest:[self urlRequest:urlString postBodyDictionary:postBodyDictionaryCopy]];
}


#pragma mark API Calls - Feeds/Folders/Tags/Status

+ (RSGoogleReaderHTTPResponse *)updateNewsItem:(NSString *)googleItemID googleFeedID:(NSString *)googleFeedID starStatus:(BOOL)starred {
	NSMutableDictionary *postBodyDictionary = [self postBodyDictionary];
	if (!postBodyDictionary)
		return nil;
	[postBodyDictionary setObject:@"edit-tags" forKey:@"ac"];
	[postBodyDictionary setObject:@"user/-/state/com.google/starred" forKey:starred ? @"a" : @"r"];
	[postBodyDictionary setObject:@"true" forKey:@"async"];
	[postBodyDictionary setObject:googleItemID forKey:@"i"];
	[postBodyDictionary rs_safeSetObject:googleFeedID forKey:@"s"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/edit-tag" postBodyDictionary:postBodyDictionary];		
}


+ (RSGoogleReaderHTTPResponse *)updateNewsItem:(NSString *)googleID starStatus:(BOOL)starred { /*Old*/
	return [self updateNewsItem:googleID googleFeedID:nil starStatus:starred];
}


+ (RSGoogleReaderHTTPResponse *)subscribeToFeed:(NSString *)urlString title:(NSString *)title folderName:(NSString *)folderName {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"subscribe" forKey:@"ac"];
	[postBody rs_safeSetObject:SLGoogleReaderCalculatedIDForFolderName(folderName) forKey:@"a"];
	if (!RSStringIsEmpty(title))
		[postBody setObject:title forKey:@"t"];
	[postBody setObject:[NSString stringWithFormat:@"feed/%@", urlString] forKey:@"s"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/subscription/edit" postBodyDictionary:postBody];	
}


+ (RSGoogleReaderHTTPResponse *)unsubscribeFromFeed:(NSString *)urlString {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"unsubscribe" forKey:@"ac"];
	[postBody setObject:[NSString stringWithFormat:@"feed/%@", urlString] forKey:@"s"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/subscription/edit" postBodyDictionary:postBody];	
}


+ (RSGoogleReaderHTTPResponse *)renameFeed:(NSString *)feedURLString newTitle:(NSString *)newTitle {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"edit" forKey:@"ac"];
	[postBody setObject:[NSString stringWithFormat:@"feed/%@", feedURLString] forKey:@"s"];
	[postBody setObject:newTitle forKey:@"t"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/subscription/edit" postBodyDictionary:postBody];	
}


+ (RSGoogleReaderHTTPResponse *)moveFeed:(NSString *)feedURLString oldFolderName:(NSString *)oldFolderName newFolderName:(NSString *)newFolderName {
	/*oldFolderName xor newFolderName can be nil: means top-level folder*/
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"edit" forKey:@"ac"];
	[postBody setObject:SLGoogleReaderCalculatedIDForFeedURLString(feedURLString) forKey:@"s"];
	[postBody rs_safeSetObject:SLGoogleReaderCalculatedIDForFolderName(oldFolderName) forKey:@"r"];
	[postBody rs_safeSetObject:SLGoogleReaderCalculatedIDForFolderName(newFolderName) forKey:@"a"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/subscription/edit" postBodyDictionary:postBody];	
}


+ (RSGoogleReaderHTTPResponse *)addTag:(NSString *)name oneFeedURLString:(NSString *)oneFeedURLString oneFeedTitle:(NSString *)oneFeedTitle {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"edit" forKey:@"ac"];
	[postBody setObject:[NSString stringWithFormat:@"user/-/label/%@", SLGoogleReaderNameForFolderName(name)] forKey:@"a"];
	[postBody setObject:[NSString stringWithFormat:@"feed/%@", oneFeedURLString] forKey:@"s"];
	[postBody setObject:oneFeedTitle forKey:@"t"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/subscription/edit" postBodyDictionary:postBody];	
}


+ (RSGoogleReaderHTTPResponse *)deleteTag:(NSString *)name {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"disable-tags" forKey:@"ac"];
	[postBody setObject:[NSString stringWithFormat:@"user/-/label/%@", SLGoogleReaderNameForFolderName(name)] forKey:@"s"];
	[postBody setObject:name forKey:@"t"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/disable-tag" postBodyDictionary:postBody];
}


+ (RSGoogleReaderHTTPResponse *)markItemsRead:(NSArray *)googleItemIDs googleFeedIDs:(NSArray *)googleFeedIDs { /*new*/
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"edit-tags" forKey:@"ac"];
	[postBody setObject:@"user/-/state/com.google/read" forKey:@"a"];
	[postBody setObject:@"true" forKey:@"async"];
	[postBody setObject:googleItemIDs forKey:@"i"];
	[postBody rs_safeSetObject:googleFeedIDs forKey:@"s"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/edit-tag" postBodyDictionary:postBody];	
}


+ (RSGoogleReaderHTTPResponse *)markItemsRead:(NSArray *)itemIDs { /*old*/
	return [self markItemsRead:itemIDs googleFeedIDs:nil];
}


+ (RSGoogleReaderHTTPResponse *)markItemsUnread:(NSArray *)googleItemIDs googleFeedIDs:(NSArray *)googleFeedIDs { /*new*/
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"edit-tags" forKey:@"ac"];
	[postBody setObject:@"user/-/state/com.google/read" forKey:@"r"];
	[postBody setObject:@"true" forKey:@"async"];
	[postBody setObject:googleItemIDs forKey:@"i"];
	[postBody rs_safeSetObject:googleFeedIDs forKey:@"s"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/edit-tag" postBodyDictionary:postBody];
}


+ (RSGoogleReaderHTTPResponse *)markItemsUnread:(NSArray *)itemIDs { /*old*/
	return [self markItemsUnread:itemIDs googleFeedIDs:nil];
}



@end

