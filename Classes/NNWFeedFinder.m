//
//  NNWFeedFinder.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFeedFinder.h"
#import "NNWCredentialsWindowController.h"
#import "RSDownloadConstants.h"
#import "RSErrors.h"
#import "RSFeedTypeDetector.h"
#import "RSSDiscovery.h"


@interface NNWFeedFinder ()

@property (nonatomic, assign) id<NNWFeedFinderDelegate> delegate;
@property (nonatomic, assign, readwrite) NSInteger statusCode;
@property (nonatomic, retain) NSMutableDictionary *urlsRead;
@property (nonatomic, retain) NSTimer *keepAliveTimer;
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain, readwrite) NSMutableData *responseBody;
@property (nonatomic, retain, readwrite) NSURL *originalURL;
@property (nonatomic, retain, readwrite) NSURL *permanentURL;

- (void)_readURL:(NSURL *)url;

@end


@implementation NNWFeedFinder

@synthesize delegate;
@synthesize keepAliveTimer;
@synthesize originalURL;
@synthesize password;
@synthesize permanentURL;
@synthesize responseBody;
@synthesize statusCode;
@synthesize urlRequest;
@synthesize urlsRead;
@synthesize username;

#pragma mark Init

- (id)initWithURL:(NSURL *)url delegate:(id<NNWFeedFinderDelegate>)aDelegate {
	self = [super init];
	if (self == nil)
		return nil;
	originalURL = [url retain];
	delegate = aDelegate;
	urlsRead = [[NSMutableDictionary dictionaryWithCapacity:20] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self.keepAliveTimer rs_invalidateIfValid];
	delegate = nil;
	[keepAliveTimer release];
	[originalURL release];
	[password release];
	[permanentURL release];
	[responseBody release];
	[urlRequest release];
	[urlsRead release];
	[username release];
	[super dealloc];
}


#pragma mark Find Feed Process

- (void)findFeed {
	[self performSelectorInBackground:@selector(_beginFindFeed:) withObject:self.originalURL];
}


- (void)_beginFindFeed:(NSURL *)url {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	self.permanentURL = url;
	self.keepAliveTimer = [[[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:60 * 60 * 24 * 365 * 10 target:self selector:@selector(_bogusSelector) userInfo:nil repeats:NO] autorelease];
	[[NSRunLoop currentRunLoop] addTimer:self.keepAliveTimer forMode:NSDefaultRunLoopMode];
	[self performSelector:@selector(_readURL:) withObject:url afterDelay:0.01];
	[[NSRunLoop currentRunLoop] run];
	[pool drain];
}


- (void)_readURL:(NSURL *)url {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableURLRequest *aURLRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
	self.permanentURL = url;
	[aURLRequest setValue:rs_app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	[aURLRequest setHTTPShouldHandleCookies:NO];
	self.urlRequest = aURLRequest;
	[self.urlsRead rs_setBool:YES forKey:[url absoluteString]];
	self.responseBody = [NSMutableData data];
	(void)[[[NSURLConnection alloc] initWithRequest:aURLRequest delegate:self] autorelease];
	[pool drain];
}


- (void)_cleanup {
	[self.keepAliveTimer rs_invalidateIfValid];
	self.keepAliveTimer = nil;
}


#pragma mark Delegate

- (void)_callDelegateDidFail:(NSError *)error {
	if ([NSThread isMainThread])
		[self.delegate feedFinder:self didFailWithError:error];
	else
		[self performSelectorOnMainThread:@selector(_callDelegateDidFail:) withObject:error waitUntilDone:NO];
}


- (void)_callDelegateDidFindFeed:(NSURL *)url {
	if ([NSThread isMainThread])
		[self.delegate feedFinder:self didFindFeedAtURL:url];
	else
		[self performSelectorOnMainThread:@selector(_callDelegateDidFindFeed:) withObject:url waitUntilDone:NO];	
}


#pragma mark RSS Discovery

+ (NSURL *)_findURLViaLinkTag:(NSData *)data baseURL:(NSURL *)baseURL {
	NSString *s = RSStringUsefulStringWithData(data);
	if (RSStringIsEmpty(s))
		return nil;
	NSString *linkTagURLString = [RSSDiscovery getLinkTagURL:s];
	if (RSStringIsEmpty(linkTagURLString))
		return nil;
	if ([linkTagURLString hasPrefix:@"http://"] || [linkTagURLString hasPrefix:@"https://"])
		return [NSURL URLWithString:linkTagURLString];
	return [NSURL URLWithString:linkTagURLString relativeToURL:baseURL];
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if ([response respondsToSelector:@selector(statusCode)])
		self.statusCode = [(NSHTTPURLResponse *)response statusCode];
	if (self.statusCode == 404) {
		[self _callDelegateDidFail:[RSErrors genericHTTPError:404]];
		[connection cancel];
		[self _cleanup];
	}
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ([error code] != NSURLErrorUserCancelledAuthentication) {
		[self _callDelegateDidFail:error];
		[self _cleanup];		
	}
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.responseBody appendData:data];
}


#define NNW_ERROR_COULD_NOT_FIND_FEED NSLocalizedStringFromTable(@"could not find a feed", @"Subscribing", @"Feed Finder error message")

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	/*If feed, then finish up.
	 If page, do RSS discovery.
	 If discovery fails, it's an error: notify user.
	 If discovery succeeds, then read the discovered feed.*/
	
	if (self.statusCode == 200) {
		
		if (RSDataIsFeed(self.responseBody))
			[self _callDelegateDidFindFeed:self.permanentURL];
		
		else if (RSDataIsProbablyMedia(self.responseBody))
			[self _callDelegateDidFail:[RSErrors errorWithCode:NNWErrorCouldNotFindFeed errorString:NNW_ERROR_COULD_NOT_FIND_FEED]];			
			
		else { /*probably a page -- try RSS discovery*/
			NSURL *linkTagURL = [NNWFeedFinder _findURLViaLinkTag:self.responseBody baseURL:[self.urlRequest URL]];
			if (linkTagURL && ![self.urlsRead rs_boolForKey:[linkTagURL absoluteString]]) {
				[self _readURL:linkTagURL];
				return;
			}
			[self _callDelegateDidFail:[RSErrors errorWithCode:NNWErrorCouldNotFindFeed errorString:NNW_ERROR_COULD_NOT_FIND_FEED]];			
		}
	}
	
	else
		[self _callDelegateDidFail:[RSErrors genericHTTPError:self.statusCode]];
	
	[self _cleanup];
}


- (void)runCredentialsWindow:(NSMutableDictionary *)credentialsDictionary {

	NNWCredentialsWindowController *credentialsWindowController = [[[NNWCredentialsWindowController alloc] init] autorelease];
	[credentialsWindowController window];
	NSString *usernameAndPasswordQuoted = NSLocalizedStringFromTable(@"Enter username and password for “%@.”", @"Subscribing", @"Credentials sheet message");
	NSString *credentialsMessage = [NSString stringWithFormat:usernameAndPasswordQuoted, [credentialsDictionary objectForKey:RSURLKey]];
	[credentialsWindowController.messageTextField setStringValue:credentialsMessage];
	
	NNWCredentialsResult *credentialsResult = [credentialsWindowController runModalForBackgroundWindow:nil];
	if (credentialsResult != nil)
		[credentialsDictionary setObject:credentialsResult forKey:@"result"];
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
	/*Ask user for username and password. If they hit cancel, cancel this whole thing.*/

	NSMutableDictionary *credentialsDictionary = [NSMutableDictionary dictionary];
	[credentialsDictionary setObject:RSURLKey forKey:[[challenge protectionSpace] realm]];
	if ([credentialsDictionary objectForKey:RSURLKey] == nil)
		[credentialsDictionary setObject:[self.urlRequest URL] forKey:RSURLKey];
	[self performSelectorOnMainThread:@selector(runCredentialsWindow:) withObject:credentialsDictionary waitUntilDone:YES];
	
	NNWCredentialsResult *credentialsResult = [credentialsDictionary objectForKey:@"result"];
	self.username = credentialsResult.username;
	self.password = credentialsResult.password;
	
	if (credentialsResult != nil && credentialsResult.userDidCancel) {
		[[challenge sender] cancelAuthenticationChallenge:challenge];
		[connection cancel];
		[self _callDelegateDidFail:nil];
		[self _cleanup];		
	}
	else {
		NSURLCredential *credential = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistencePermanent];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	}
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
	/*If 301, save new permanent URL.
	 If 302, follow redirect.*/
	if (!response) { /*Not a redirect?*/
		self.urlRequest = request;
		return request;
	}
	if ([self.urlsRead rs_boolForKey:[[request URL] absoluteString]]) { /*Loop?*/
		[connection cancel];
		[self _callDelegateDidFail:nil];
		[self _cleanup];
		return nil;
	}
	[self.urlsRead rs_setBool:YES forKey:[[request URL] absoluteString]];
	if ([response respondsToSelector:@selector(statusCode)] && [(NSHTTPURLResponse *)response statusCode] == 301)
		self.permanentURL = [request URL];
	self.urlRequest = request;
	return request;
}


@end
