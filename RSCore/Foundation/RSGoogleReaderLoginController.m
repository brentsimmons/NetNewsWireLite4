//
//  RSGoogleReaderLoginController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSGoogleReaderLoginController.h"
#import "RSGoogleReaderHTTPResponse.h"
#import "RSGoogleReaderUtilities.h"


NSString *SLGoogleReaderAuthTokenKey = @"authToken";
NSString *SLGoogleReaderTTokenKey = @"tToken";


@interface NSObject (SLGoogleReaderStub)
+ (NSString *)googlePassword; //total hack, but temporary
@end

@interface RSGoogleReaderLoginController ()
@property (nonatomic, retain, readwrite) NSString *authToken;
@property (nonatomic, retain, readwrite) NSString *tToken;
@end

@implementation RSGoogleReaderLoginController

@synthesize authToken;
@synthesize tToken;


#pragma mark Class Methods

+ (id)sharedController {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Utilities

static NSDictionary *_dictionaryFromLoginResponseBody(NSString *s) {
	if (!s)
		return nil;
	NSArray *components = [s componentsSeparatedByString:@"\n"];
	if (RSIsEmpty(components))
		return nil;
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:10];
	NSUInteger i;
	NSUInteger ct = [components count];
	NSArray *paramComponents;
	NSString *oneName, *oneValue;
	for (i = 0; i < ct; i++) {
		paramComponents = RSArraySeparatedByFirstInstanceOfCharacter([components objectAtIndex:i], '=');
		if (RSIsEmpty(paramComponents))
			continue;
		oneName = [paramComponents objectAtIndex:0];
		if (RSIsEmpty(oneName))
			continue;
		oneValue = [paramComponents rs_safeObjectAtIndex:1];
		if (RSIsEmpty(oneValue))
			continue;
		[d rs_safeSetObject:RSURLDecodedString(oneValue) forKey:RSURLDecodedString(oneName)];
	}
	return d;
}


- (NSString *)fetchPasswordFromKeychain {
	/*Total hack to get us unstuck. We'll make passwords a per-account thing,
	 which means a bigger change -- so there's no sense fixing this now.*/
	Class credentialsClass = NSClassFromString(@"NNW3GoogleReaderCredentials");
	if (credentialsClass != nil)
		return [credentialsClass googlePassword];
	return nil;
}


- (NSString *)_loginPostBody {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:5];
	[d setObject:@"GOOGLE" forKey:@"accountType"];
	[d rs_safeSetObject:[[NSUserDefaults standardUserDefaults] objectForKey:RSGoogleReaderUsernameKey] forKey:@"Email"];
	[d rs_safeSetObject:[self fetchPasswordFromKeychain] forKey:@"Passwd"];
	[d setObject:@"reader" forKey:@"service"];
	[d setObject:RSGoogleReaderClientIdentifier forKey:@"source"];
	return [d rs_httpPostArgsString];
}


#pragma mark Login API

+ (void)addAuthTokenToRequest:(NSMutableURLRequest *)urlRequest googleAuthToken:(NSString *)googleAuthToken {
	if (RSStringIsEmpty(googleAuthToken))
		return;
	NSString *authTokenHeader = [NSString stringWithFormat:@"GoogleLogin auth=%@", googleAuthToken];
	[urlRequest setValue:authTokenHeader forHTTPHeaderField:@"Authorization"];	
}


- (void)synchronousFetchTToken {
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:RSGoogleReaderURLWithClientAppended(@"http://www.google.com/reader/api/0/token") cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
//	[urlRequest setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	[urlRequest setHTTPShouldHandleCookies:NO];
	[[self class] addAuthTokenToRequest:urlRequest googleAuthToken:self.authToken];
//	[NNWGoogle addAuthTokenToRequest:urlRequest googleAuthToken:self.authToken];
	//[urlRequest setValue:[NSString stringWithFormat:@"SID=%@", self.sid] forHTTPHeaderField:@"Cookie"];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	NSInteger statusCode = -1;
	if ([response respondsToSelector:@selector(statusCode)])
		statusCode = [(NSHTTPURLResponse *)response statusCode];
	if (statusCode == 200) {
		NSString *responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		self.tToken = responseString;		
	}
	else if (statusCode == 403)
		self.tToken = nil;
}


- (NSInteger)synchronousLogin {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:RSGoogleReaderURLWithClientAppended(@"https://www.google.com/accounts/ClientLogin") cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
	[urlRequest setHTTPMethod:@"POST"];
//	[urlRequest setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	[urlRequest setHTTPBody:[[self _loginPostBody] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	[urlRequest setHTTPShouldHandleCookies:NO];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	NSInteger statusCode = -1;
	if ([response respondsToSelector:@selector(statusCode)])
		statusCode = [(NSHTTPURLResponse *)response statusCode];
	if (statusCode == 200) {
		NSString *responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSDictionary *d = _dictionaryFromLoginResponseBody(responseString);
		self.authToken = [d objectForKey:@"Auth"];
		[self synchronousFetchTToken];
	}
	else if (statusCode == 403) {
		self.authToken = nil;
		self.tToken = nil;
	}
	[pool drain];
	return statusCode;
}


- (NSString *)loginPostBodyWithUsername:(NSString *)username andPassword:(NSString *)password {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:5];
	[d setObject:@"GOOGLE" forKey:@"accountType"];
	[d rs_safeSetObject:username forKey:@"Email"];
	[d rs_safeSetObject:password forKey:@"Passwd"];
	[d setObject:@"reader" forKey:@"service"];
	[d setObject:@"NewsGator-NetNewsWire-iPhone-2.0" forKey:@"source"];
	return [d rs_httpPostArgsString];
}


- (void)trySynchronousLoginWithUsername:(NSString *)username andPassword:(NSString *)password callbackTarget:(id)callbackTarget callbackSelector:(SEL)callbackSelector {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:RSGoogleReaderURLWithClientAppended(@"https://www.google.com/accounts/ClientLogin") cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
	[urlRequest setHTTPMethod:@"POST"];
//	[urlRequest setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	[urlRequest setHTTPBody:[[self loginPostBodyWithUsername:username andPassword:password] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	[urlRequest setHTTPShouldHandleCookies:NO];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	RSGoogleReaderHTTPResponse *nnwResponse = [RSGoogleReaderHTTPResponse responseWithURLResponse:response data:data error:error];
	[callbackTarget performSelectorOnMainThread:callbackSelector withObject:nnwResponse waitUntilDone:NO];
	[pool drain];
}


- (void)tryLoginInBackgroundThread:(NSDictionary *)infoDict {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	[[RSGoogleReaderLoginController sharedController] trySynchronousLoginWithUsername:[infoDict objectForKey:NNWGoogleUsernameKey] andPassword:[infoDict objectForKey:NNWGooglePasswordKey] callbackTarget:[infoDict objectForKey:@"target"] callbackSelector:@selector(didTryGoogleLogin:)];
	[pool drain];
}


#pragma mark Accessors

- (NSDictionary *)googleLoginInfo {
	if (RSStringIsEmpty(self.authToken))
		[self synchronousLogin];
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:2];
	[d rs_safeSetObject:self.authToken forKey:SLGoogleReaderAuthTokenKey];
	[d rs_safeSetObject:self.tToken forKey:SLGoogleReaderTTokenKey];
	return d;
}


- (void)clearLoginInfo {
	self.authToken = nil;
	self.tToken = nil;
}


@end
