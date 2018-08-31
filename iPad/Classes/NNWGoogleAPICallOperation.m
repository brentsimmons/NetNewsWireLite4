//
//  NNWGoogleAPICallOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWGoogleAPICallOperation.h"
#import "NNWGoogleAPI.h"
#import "NNWGoogleLoginController.h"
#import "NNWGoogleUtilities.h"
#import "NNWOperationConstants.h"
#import "RSGoogleItemIDsParser.h"
#import "RSGoogleSubsListParser.h"
#import "RSGoogleUnreadCountsParser.h"


@interface NNWGoogleAPICallOperation ()
@property (nonatomic, retain) NSMutableDictionary *postBodyDict;
@property (nonatomic, assign) BOOL didRetryWithNewGoogleToken;
@end


@implementation NNWGoogleAPICallOperation

@synthesize postBodyDict, didRetryWithNewGoogleToken;

#pragma mark Init

- (id)initWithBaseURL:(NSURL *)baseURL queryDict:(NSDictionary *)aQueryDict postBodyDict:(NSDictionary *)aPostBodyDict delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector parser:(RSSAXParser *)aParser {
	NSString *baseURLString = [baseURL absoluteString];
	if (!RSIsEmpty(aQueryDict)) {
		if (![baseURLString hasSuffix:@"?"])
			baseURLString = [NSString stringWithFormat:@"%@?", baseURLString];
		baseURLString = [NSString stringWithFormat:@"%@%@", baseURLString, [aQueryDict httpPostArgsString]];
	}
	if (!RSIsEmpty(aPostBodyDict)) {
		postBodyDict = [aPostBodyDict retain];
		httpMethod = [RSHTTPMethodPost retain];
	}
	return [super initWithURL:[NNWGoogleUtilities urlWithClientAppended:baseURLString] delegate:aDelegate callbackSelector:aCallbackSelector parser:aParser useWebCache:NO];
}


#pragma mark Dealloc

- (void)dealloc {
	[postBodyDict release];
	[super dealloc];
}


#pragma mark RSOperation

- (void)createRequest {
	NSDictionary *googleLoginInfo = [[NNWGoogleLoginController sharedController] googleLoginInfo];
	if (!RSIsEmpty(self.postBodyDict)) {
		[self.postBodyDict safeSetObject:[googleLoginInfo objectForKey:NNWGoogleTToken] forKey:@"T"];
		self.postBody = [[self.postBodyDict httpPostArgsString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	}
	[super createRequest];
	[NNWGoogleAPI addAuthTokenToRequest:self.urlRequest googleAuthToken:[googleLoginInfo objectForKey:NNWGoogleAuthToken]];
//	if (!RSStringIsEmpty([googleLoginInfo objectForKey:@"sid"]))
//		[self.urlRequest setValue:[NSString stringWithFormat:@"SID=%@", [googleLoginInfo objectForKey:@"sid"]] forHTTPHeaderField:@"Cookie"];
}


#pragma mark NSURLConnection Delegate

- (void)handleBadGoogleToken {
	[self.urlConnection cancel];
	if (self.didRetryWithNewGoogleToken) {
		self.finishedReading = YES;
		return;
	}
	self.didRetryWithNewGoogleToken = YES;
	[[NNWGoogleLoginController sharedController] synchronousLogin];
	self.urlResponse = nil;
	self.statusCode = 0;
	[self createRequest];
	self.urlConnection = [[[NSURLConnection alloc] initWithRequest:self.urlRequest delegate:self] autorelease];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.urlResponse = response;
	if ([response respondsToSelector:@selector(statusCode)])
		self.statusCode = [(NSHTTPURLResponse *)response statusCode];
	if ([urlResponse respondsToSelector:@selector(allHeaderFields)] && [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"X-Reader-Google-Bad-Token"] != nil) {
		[self handleBadGoogleToken];
		return;
	}	
	[super connection:connection didReceiveResponse:response];
}


@end


@implementation NNWGoogleAPICallOperation (NNWConvenienceMethods)

+ (NNWGoogleAPICallOperation *)downloadItemIDsAPICallWithStatesToRetrieve:(NSArray *)statesToRetrieve statesToIgnore:(NSArray *)statesToIgnore itemIDsToIgnore:(NSArray *)itemIDsToIgnore delegate:(id)aDownloadDelegate callbackSelector:(SEL)aCallbackSelector {
	RSGoogleItemIDsParser *googleItemIDsParser = [[[RSGoogleItemIDsParser alloc] init] autorelease];
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query safeSetObject:statesToRetrieve forKey:NNWGoogleStatesParameterName];
	[query safeSetObject:statesToIgnore forKey:NNWGoogleExcludeParameterName];
	[query setObject:NNWGoogleItemIDsLimit forKey:NNWGoogleLimitParameterName];
	return [[[NNWGoogleAPICallOperation alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.google.com/reader/api/0/stream/items/ids"] queryDict:query postBodyDict:nil delegate:aDownloadDelegate callbackSelector:aCallbackSelector parser:googleItemIDsParser] autorelease];
}


+ (NNWGoogleAPICallOperation *)downloadSubscriptionsAPICallWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	NNWGoogleAPICallOperation *downloadSubscriptionsOperation = [[[NNWGoogleAPICallOperation alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.google.com/reader/api/0/subscription/list?output=xml"] queryDict:nil postBodyDict:nil delegate:aDelegate callbackSelector:aCallbackSelector parser:[RSGoogleSubsListParser xmlParser]] autorelease];
	downloadSubscriptionsOperation.operationType = NNWOperationTypeDownloadSubscriptions;
	return downloadSubscriptionsOperation;
}


+ (NNWGoogleAPICallOperation *)downloadUnreadCounts:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	NNWGoogleAPICallOperation *downloadUnreadCountsOperation = [[[NNWGoogleAPICallOperation alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.google.com/reader/api/0/unread-count?output=xml"] queryDict:nil postBodyDict:nil delegate:aDelegate callbackSelector:aCallbackSelector parser:[RSGoogleUnreadCountsParser xmlParser]] autorelease];
	downloadUnreadCountsOperation.operationType = NNWOperationTypeDownloadUnreadCounts;
	return downloadUnreadCountsOperation;
}


@end
