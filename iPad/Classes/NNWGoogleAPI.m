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
#import "RSGoogleItemIDsParser.h"


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
		[postBodyDictionaryCopy safeSetObject:[googleLoginInfo objectForKey:NNWGoogleTToken] forKey:@"T"];
	return [self sendRequest:[self urlRequest:urlString postBodyDictionary:postBodyDictionaryCopy]];
}


#pragma mark API Calls


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
	[postBody setObject:NNWGoogleLongItemIDsForShortItemIDs(itemIDs) forKey:NNWGoogleItemIDsParameterName];
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
	[postBody setObject:NNWGoogleLongItemIDForShortItemID(googleID) forKey:NNWGoogleItemIDsParameterName];
	[postBody setObject:feedID forKey:NNWGoogleFeedIDsParameterName];
	return [self sendRequestWithURLString:NNWGoogleEditTagURL postBodyDictionary:postBody];	
}


NSString *NNWGoogleItemIDsLimit = @"10000";
NSString *NNWGoogleItemIDsURLFormat = @"http://www.google.com/reader/api/0/stream/items/ids?%@";
NSString *NNWGoogleStatesParameterName = @"s";
NSString *NNWGoogleLimitParameterName = @"n";

NSString *NNWGoogleReadingListState = @"user/-/state/com.google/reading-list";
NSString *NNWGoogleExcludeParameterName = @"xt";

NSString *NNWGoogleFetchItemsByIDURL = @"http://www.google.com/reader/api/0/stream/items/contents?output=atom";
static NSString *NNWGoogleItemIDPrefix = @"tag:google.com,2005:reader/item/";
static NSString *NNWGoogleItemIDPrefixFormat = @"tag:google.com,2005:reader/item/%@";

NSString *NNWGoogleShortItemIDForLongItemID(NSString *itemID) {
	if (RSStringIsEmpty(itemID))
		return itemID;
	NSUInteger lengthOfID = [itemID length];
	if (lengthOfID == 16)
		return itemID;
	if (lengthOfID > 32)
		return [itemID substringFromIndex:32];
	if (![itemID caseSensitiveContains:@"/"]) /*Shouldn't get here*/
		return itemID;
	return [[itemID componentsSeparatedByString:@"/"] lastObject];
}


NSArray *NNWGoogleShortItemIDsForLongItemIDs(NSArray *longItemIDs) {
	if (RSIsEmpty(longItemIDs))
		return longItemIDs;
	NSMutableArray *shortItemIDs = [NSMutableArray arrayWithCapacity:[longItemIDs count]];
	for (NSString *oneLongItemID in longItemIDs)
		[shortItemIDs safeAddObject:NNWGoogleShortItemIDForLongItemID(oneLongItemID)];
	return shortItemIDs;
}


NSArray *NNWGoogleArrayOfLongItemIDsForSetOfShortItemIDs(NSSet *shortItemIDs) {
	if (RSIsEmpty(shortItemIDs))
		return nil;
	NSMutableArray *longItemIDs = [NSMutableArray arrayWithCapacity:[shortItemIDs count]];
	for (NSString *oneShortItemID in shortItemIDs)
		[longItemIDs safeAddObject:NNWGoogleLongItemIDForShortItemID(oneShortItemID)];
	return longItemIDs;
}


NSSet *NNWGoogleSetOfShortItemIDsForArrayOfLongItemIDs(NSArray *longItemIDs) {
	if (RSIsEmpty(longItemIDs))
		return nil;
	NSMutableSet *shortItemIDs = [NSMutableSet setWithCapacity:[longItemIDs count]];
	for (NSString *oneLongItemID in longItemIDs)
		[shortItemIDs rs_addObject:NNWGoogleShortItemIDForLongItemID(oneLongItemID)];
	return shortItemIDs;	
}


NSString *NNWGoogleLongItemIDForShortItemID(NSString *shortItemID) {
	if (shortItemID == nil)
		return nil;
	NSUInteger lengthOfID = [shortItemID length];
	if (lengthOfID == 48)
		return shortItemID;
	if (lengthOfID < 33) 
		return [NSString stringWithFormat:NNWGoogleItemIDPrefixFormat, shortItemID];
	if ([shortItemID hasPrefix:NNWGoogleItemIDPrefix]) /*Shouldn't get here*/
		return shortItemID;
	return [NSString stringWithFormat:NNWGoogleItemIDPrefixFormat, shortItemID];
}

NSArray *NNWGoogleLongItemIDsForShortItemIDs(NSArray *shortItemIDs) {
	if (RSIsEmpty(shortItemIDs))
		return shortItemIDs;
	NSMutableArray *longItemIDs = [NSMutableArray arrayWithCapacity:[shortItemIDs count]];
	for (NSString *oneShortItemID in shortItemIDs)
		[longItemIDs safeAddObject:NNWGoogleLongItemIDForShortItemID(oneShortItemID)];
	return longItemIDs;
	
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
