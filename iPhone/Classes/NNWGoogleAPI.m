//
//  NNWGoogleAPI.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//


#import "NNWGoogleAPI.h"
#import "NNWAppDelegate.h"
#import "NNWGoogleLoginController.h"
#import "NNWGoogleUtilities.h"
#import "NNWHTTPResponse.h"
#import "RSGoogleXMLParser.h"


@implementation NNWGoogleAPI

#pragma mark Utilities

+ (NSMutableDictionary *)postBodyDictionary {
	NSMutableDictionary *postBodyDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
	NSDictionary *googleLoginInfo = [[NNWGoogleLoginController sharedController] googleLoginInfo];
	if (!googleLoginInfo)
		return nil;
	[postBodyDictionary safeSetObject:[googleLoginInfo objectForKey:NNWGoogleTToken] forKey:@"T"];
	return postBodyDictionary;
}


+ (void)addAuthTokenToRequest:(NSMutableURLRequest *)urlRequest googleAuthToken:(NSString *)googleAuthToken {
	if (RSStringIsEmpty(googleAuthToken))
		return;
	NSString *authToken = [NSString stringWithFormat:@"GoogleLogin auth=%@", googleAuthToken];
	[urlRequest setValue:authToken forHTTPHeaderField:@"Authorization"];	
}


+ (void)addAuthTokenToRequest:(NSMutableURLRequest *)urlRequest {
	[self addAuthTokenToRequest:urlRequest googleAuthToken:[[[NNWGoogleLoginController sharedController] googleLoginInfo] objectForKey:NNWGoogleAuthToken]];
}


+ (NSMutableURLRequest *)urlRequest:(NSString *)urlString postBodyDictionary:(NSDictionary *)postBodyDictionary {
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NNWGoogleUtilities urlWithClientAppended:urlString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
	if (postBodyDictionary) {
		[urlRequest setHTTPMethod:@"POST"];
		[urlRequest setHTTPBody:[[postBodyDictionary httpPostArgsString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	}
	[urlRequest setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	[urlRequest setHTTPShouldHandleCookies:NO];
	[self addAuthTokenToRequest:urlRequest];
	//	NSString *sid = [[[NNWGoogleLoginController sharedController] googleLoginInfo] objectForKey:@"sid"];
	//	if (!RSStringIsEmpty(sid))
	//		[urlRequest setValue:[NSString stringWithFormat:@"SID=%@", sid] forHTTPHeaderField:@"Cookie"];
	return urlRequest;
}


+ (NNWHTTPResponse *)sendRequest:(NSURLRequest *)urlRequest {
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	return [NNWHTTPResponse responseWithURLResponse:response data:data error:error];
}


+ (NNWHTTPResponse *)sendRequestWithURLString:(NSString *)urlString postBodyDictionary:(NSDictionary *)postBodyDictionary {
	NNWHTTPResponse *response = [self sendRequest:[self urlRequest:urlString postBodyDictionary:postBodyDictionary]];
	if (!response.badGoogleToken)
		return response;
	[[NNWGoogleLoginController sharedController] clearLoginInfo];
	NSDictionary *googleLoginInfo = [[NNWGoogleLoginController sharedController] googleLoginInfo];
	NSMutableDictionary *postBodyDictionaryCopy = [[postBodyDictionary mutableCopy] autorelease];
	if ([postBodyDictionaryCopy objectForKey:@"T"])
		[postBodyDictionaryCopy safeSetObject:[googleLoginInfo objectForKey:@"t"] forKey:@"T"];
	return [self sendRequest:[self urlRequest:urlString postBodyDictionary:postBodyDictionaryCopy]];
}


#pragma mark API Calls

+ (NNWHTTPResponse *)downloadSubscriptionsList {
	NNWHTTPResponse *response = [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/subscription/list?output=xml" postBodyDictionary:nil];
	if (response.okResponse) {
		RSGoogleXMLParser *parser = [[RSGoogleXMLParser alloc] init];
		NSError *error = nil;
		[parser parseData:response.data error:&error];
		response.returnedObject = parser.subscriptions;
		response.parseError = error;
		[parser release];
	}
	return response;
}


+ (NNWHTTPResponse *)downloadUnreadCounts {
	NNWHTTPResponse *response = [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/unread-count?output=xml" postBodyDictionary:nil];	
	if (response.okResponse) {
		RSGoogleXMLParser *parser = [[RSGoogleXMLParser alloc] init];
		NSError *error = nil;
		[parser parseData:response.data error:&error];
		response.returnedObject = parser.unreadCounts ;
		response.parseError = error;
		[parser release];
	}
	return response;
}


NSString *NNWGoogleEditTagsActionName = @"edit-tags";
NSString *NNWGoogleActionParameterName = @"ac";
NSString *NNWGoogleReadState = @"user/-/state/com.google/read";
NSString *NNWGoogleStarredState = @"user/-/state/com.google/starred";
NSString *NNWGoogleAdd = @"a";
NSString *NNWGoogleRemove = @"r";
NSString *NNWGoogleTrue = @"true";
NSString *NNWGoogleAsync = @"async";
NSString *NNWGoogleItemIDsParameterName = @"i";
NSString *NNWGoogleFeedIDsParameterName = @"s";
NSString *NNWGoogleEditTagURL = @"http://www.google.com/reader/api/0/edit-tag";

+ (NNWHTTPResponse *)markItemsRead:(NSArray *)itemIDs feedIDs:(NSArray *)feedIDs {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:NNWGoogleEditTagsActionName forKey:NNWGoogleActionParameterName];
	[postBody setObject:NNWGoogleReadState forKey:NNWGoogleAdd];
	[postBody setObject:NNWGoogleTrue forKey:NNWGoogleAsync];
	[postBody setObject:itemIDs forKey:NNWGoogleItemIDsParameterName];
	[postBody setObject:feedIDs forKey:NNWGoogleFeedIDsParameterName];
	return [self sendRequestWithURLString:NNWGoogleEditTagURL postBodyDictionary:postBody];
}


+ (NNWHTTPResponse *)updateNewsItem:(NSString *)googleID feedID:(NSString *)feedID starStatus:(BOOL)starStatus {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:NNWGoogleEditTagsActionName forKey:NNWGoogleActionParameterName];
	[postBody setObject:NNWGoogleStarredState forKey:starStatus ? NNWGoogleAdd : NNWGoogleRemove];
	[postBody setObject:NNWGoogleTrue forKey:NNWGoogleAsync];
	[postBody setObject:googleID forKey:NNWGoogleItemIDsParameterName];
	[postBody setObject:feedID forKey:NNWGoogleFeedIDsParameterName];
	return [self sendRequestWithURLString:NNWGoogleEditTagURL postBodyDictionary:postBody];	
}


#pragma mark Item IDs

static NSString *NNWGoogleItemRefs = @"itemRefs";
static NSString *NNWGoogleDirectStreamIds = @"directStreamIds";
static NSString *NNWGoogleSlashRead = @"/read";
static NSString *NNWGoogleIDString = @"id";
static NSString *NNWHexFormat = @"%qx";

+ (NSArray *)parseItemIDs:(NSData *)data {
	RSGoogleXMLParser *parser = [RSGoogleXMLParser xmlParser];
	NSError *error = nil;
	[parser parseData:data error:&error];
	NSArray *itemIDs = [parser listNamed:NNWGoogleItemRefs];
	/*Transform into array of ids. Also turn signed 64-bit ids to unsigned hex ids, which matches guids.*/
	NSMutableArray *convertedArray = [NSMutableArray array];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	for (NSDictionary *oneDict in itemIDs) {
		NSArray *stateArray = [oneDict objectForKey:NNWGoogleDirectStreamIds];
		if (RSIsEmpty(stateArray))
			continue;
		BOOL isRead = NO;
		for (NSString *oneState in stateArray) {
			if ([oneState hasSuffix:NNWGoogleSlashRead]) {
				isRead = YES;
				break;
			}
		}
		if (!isRead)
			continue;
		NSString *signed64bitID = [oneDict objectForKey:NNWGoogleIDString];
		if (RSStringIsEmpty(signed64bitID))
			continue;
		NSString *hexValue = [NSString stringWithFormat:NNWHexFormat, [signed64bitID longLongValue]];
		[convertedArray safeAddObject:hexValue];
	}
	[pool drain];
	return convertedArray;	
}


static NSString *NNWGoogleItemIDsLimit = @"100";
static NSString *NNWGoogleItemIDsURLFormat = @"http://www.google.com/reader/api/0/stream/items/ids?%@";
static NSString *NNWGoogleStatesParameterName = @"s";
static NSString *NNWGoogleLimitParameterName = @"n";

+ (NNWHTTPResponse *)downloadItemIDs {
	NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
	NSMutableArray *states = [NSMutableArray arrayWithCapacity:3];
	[states addObject:NNWGoogleReadState];
	[queryDict setObject:states forKey:NNWGoogleStatesParameterName];
	[queryDict setObject:NNWGoogleItemIDsLimit forKey:NNWGoogleLimitParameterName];
	NSString *queryArgs = [queryDict httpPostArgsString];
	NSString *urlString = [NSString stringWithFormat:NNWGoogleItemIDsURLFormat, queryArgs];
	return [self sendRequestWithURLString:urlString postBodyDictionary:nil];
}


+ (NSArray *)downloadAndParseItemIDsOfReadItems {
	NNWHTTPResponse *response = [self downloadItemIDs];
	if (response.okResponse)
		return [self parseItemIDs:response.data];
	return nil;
}


+ (NSString *)_calculatedGoogleID:(NSString *)name prefix:(NSString *)prefix {
	if (RSStringIsEmpty(name))
		return nil;
	if ([name hasPrefix:prefix])
		return name;
	NSMutableString *s = [NSMutableString stringWithString:prefix];
	[s appendString:name];
	return s;
}


+ (NSString *)googleNameForNNWFolderName:(NSString *)folderName {
	/*Illegal characters in Google names: " < > ? & / \ ^
	 Translate to: _ [ ] _ + | | _*/
	if (RSStringIsEmpty(folderName))
		return folderName;
	NSMutableString *googleName = [NSMutableString stringWithString:folderName];
	[googleName replaceOccurrencesOfString:@"\"" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"<" withString:@"[" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@">" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"?" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"&" withString:@"+" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"/" withString:@"|" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"\\" withString:@"|" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	[googleName replaceOccurrencesOfString:@"^" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [googleName length])];
	return googleName;
}


+ (NSString *)_calculatedGoogleIDForFolderName:(NSString *)folderName {
	return [self _calculatedGoogleID:[self googleNameForNNWFolderName:folderName] prefix:@"user/-/label/"];
}


+ (NNWHTTPResponse *)subscribeToFeed:(NSString *)urlString title:(NSString *)title folderName:(NSString *)folderName {
	NSMutableDictionary *postBody = [self postBodyDictionary];
	if (!postBody)
		return nil;
	[postBody setObject:@"subscribe" forKey:@"ac"];
	[postBody safeSetObject:[self _calculatedGoogleIDForFolderName:folderName] forKey:@"a"];
	if (!RSStringIsEmpty(title))
		[postBody setObject:title forKey:@"t"];
	[postBody setObject:[NSString stringWithFormat:@"feed/%@", urlString] forKey:@"s"];
	return [self sendRequestWithURLString:@"http://www.google.com/reader/api/0/subscription/edit" postBodyDictionary:postBody];	
}


@end
