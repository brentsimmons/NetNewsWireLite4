//
//  RSGoogleReaderAPICallOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleReaderAPICallOperation.h"
#import "NNWOperationConstants.h"
#import "RSGoogleReaderConstants.h"
#import "RSGoogleReaderItemIDsParser.h"
#import "RSGoogleReaderLoginController.h"
#import "RSGoogleReaderSubsListParser.h"
#import "RSGoogleReaderUtilities.h"


@interface RSGoogleReaderAPICallOperation ()
@property (nonatomic, retain) NSMutableDictionary *postBodyDict;
@property (nonatomic, assign) BOOL didRetryWithNewGoogleToken;
@end


@implementation RSGoogleReaderAPICallOperation

@synthesize postBodyDict, didRetryWithNewGoogleToken;

#pragma mark Init

- (id)initWithBaseURL:(NSURL *)baseURL queryDict:(NSDictionary *)aQueryDict postBodyDict:(NSDictionary *)aPostBodyDict delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector parser:(RSSAXParser *)aParser {
	NSString *baseURLString = [baseURL absoluteString];
	if (!RSIsEmpty(aQueryDict)) {
		if (![baseURLString hasSuffix:@"?"])
			baseURLString = [NSString stringWithFormat:@"%@?", baseURLString];
		baseURLString = [NSString stringWithFormat:@"%@%@", baseURLString, [aQueryDict rs_httpPostArgsString]];
	}
	if (!RSIsEmpty(aPostBodyDict)) {
		postBodyDict = [aPostBodyDict retain];
		httpMethod = [RSHTTPMethodPost retain];
	}
	return [super initWithURL:RSGoogleReaderURLWithClientAppended(baseURLString) delegate:aDelegate callbackSelector:aCallbackSelector parser:aParser useWebCache:NO];
}


#pragma mark Dealloc

- (void)dealloc {
	[postBodyDict release];
	[super dealloc];
}


#pragma mark RSOperation

- (void)createRequest {
	NSDictionary *googleLoginInfo = [[RSGoogleReaderLoginController sharedController] googleLoginInfo];
	if (!RSIsEmpty(self.postBodyDict)) {
		[self.postBodyDict rs_safeSetObject:[googleLoginInfo objectForKey:SLGoogleReaderTTokenKey] forKey:@"T"];
		self.postBody = [[self.postBodyDict rs_httpPostArgsString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	}
	[super createRequest];
	[RSGoogleReaderLoginController addAuthTokenToRequest:self.urlRequest googleAuthToken:[googleLoginInfo objectForKey:SLGoogleReaderAuthTokenKey]];
}


#pragma mark NSURLConnection Delegate

- (void)handleBadGoogleToken {
	[self.urlConnection cancel];
	if (self.didRetryWithNewGoogleToken) {
		self.finishedReading = YES;
		return;
	}
	self.didRetryWithNewGoogleToken = YES;
	[[RSGoogleReaderLoginController sharedController] synchronousLogin];
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


@implementation RSGoogleReaderAPICallOperation (RSConvenienceMethods)

+ (RSGoogleReaderAPICallOperation *)downloadItemIDsAPICallWithStatesToRetrieve:(NSArray *)statesToRetrieve statesToIgnore:(NSArray *)statesToIgnore itemIDsToIgnore:(NSArray *)itemIDsToIgnore delegate:(id)aDownloadDelegate callbackSelector:(SEL)aCallbackSelector {
	RSGoogleReaderItemIDsParser *googleItemIDsParser = [[[RSGoogleReaderItemIDsParser alloc] init] autorelease];
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query rs_safeSetObject:statesToRetrieve forKey:RSGoogleReaderStatesParameterName];
	[query rs_safeSetObject:statesToIgnore forKey:RSGoogleReaderExcludeParameterName];
	[query setObject:RSGoogleReaderItemIDsLimit forKey:RSGoogleReaderLimitParameterName];
	return [[[RSGoogleReaderAPICallOperation alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.google.com/reader/api/0/stream/items/ids"] queryDict:query postBodyDict:nil delegate:aDownloadDelegate callbackSelector:aCallbackSelector parser:googleItemIDsParser] autorelease];
}


+ (RSGoogleReaderAPICallOperation *)downloadSubscriptionsAPICallWithDelegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	RSGoogleReaderAPICallOperation *downloadSubscriptionsOperation = [[[RSGoogleReaderAPICallOperation alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.google.com/reader/api/0/subscription/list?output=xml"] queryDict:nil postBodyDict:nil delegate:aDelegate callbackSelector:aCallbackSelector parser:[RSGoogleReaderSubsListParser xmlParser]] autorelease];
	downloadSubscriptionsOperation.operationType = NNWOperationTypeDownloadSubscriptions;
	return downloadSubscriptionsOperation;
}


@end
