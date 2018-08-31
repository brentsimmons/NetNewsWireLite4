//
//  NNWSendToInstapaper.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 6/20/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

/* Instapaper API: http://blog.instapaper.com/post/73123968/read-later-api */

#import "NNWSendToInstapaper.h"
#import "BCFeedbackHUDViewController.h"
#import "NNWAppDelegate.h"
#import "NNWErrors.h"
#import "NNWInstapaperCredentialsViewController.h"
#import "NGModalViewPresenter.h"
#import "SFHFKeychainUtils.h"


NSString *_NNWInstapaperAccountKey = @"iusername";
NSString *NNWInstapaperServiceName = @"Instapaper";
NSString *_NNWInstapaperDomain = @"www.instapaper.com";
NSString *_NNWInstapaperPath = @"/api/add";


@interface NNWSendToInstapaper ()
@property (nonatomic, retain) NSDictionary *infoDict;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, assign) int statusCode;
@property (nonatomic, readonly) NSString *postBody;
@property (nonatomic, retain) NNWInstapaperCredentialsViewController *credentialsController;
@property (nonatomic, readonly) NSString *feedbackOperationIdentifier;
- (void)_doCallback;
@end

@implementation NNWSendToInstapaper

@synthesize infoDict = _infoDict, urlConnection = _urlConnection, statusCode = _statusCode, credentialsController = _credentialsController, feedbackOperationIdentifier = _feedbackOperationIdentifier;

#pragma mark Init

- (id)initWithInfoDict:(NSDictionary *)infoDict callbackTarget:(id)callbackTarget {
	if (![super init])
		return nil;
	_infoDict = [infoDict retain];
	_callbackTarget = callbackTarget;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[_infoDict release];
	[_urlConnection release];
	[_credentialsController release];
	[_feedbackOperationIdentifier release];
	[_modalViewPresenter release];
	[super dealloc];
}


#pragma mark Credentials

- (void)_askUserForCredentials {
	if(!_modalViewPresenter)
	{
		self.credentialsController = [[[NNWInstapaperCredentialsViewController alloc] initWithDelegate:self] autorelease];
		_modalViewPresenter = [[[NGModalViewPresenter alloc]initWithViewController:self.credentialsController]retain];
		[_modalViewPresenter presentModalView];
	}
}


- (NSString *)username {
	return [[NSUserDefaults standardUserDefaults] stringForKey:_NNWInstapaperAccountKey];
}


- (NSString *)password {
	NSError *error = nil;
	return [SFHFKeychainUtils getPasswordForUsername:[[NSUserDefaults standardUserDefaults] stringForKey:_NNWInstapaperAccountKey] andServiceName:NNWInstapaperServiceName error:&error];
}


- (void)credentialsControllerCanceled:(NNWInstapaperCredentialsViewController *)viewController {	
	self.credentialsController = nil;
	[_modalViewPresenter dismissModalView];
	[_modalViewPresenter release];
	_modalViewPresenter = nil;
	//[self _doCallback];
}


- (void)_savePasswordInKeychain:(NSString *)password username:(NSString *)username {
	NSError *error = nil;
	[SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:NNWInstapaperServiceName updateExisting:YES error:&error];
}


- (void)credentialsControllerAccepted:(NNWInstapaperCredentialsViewController *)viewController username:(NSString *)username password:(NSString *)password {
	if (RSStringIsEmpty(username))
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:_NNWInstapaperAccountKey];
	else
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:_NNWInstapaperAccountKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	if (!RSStringIsEmpty(self.username)) {
		NSString *currentPassword = self.password;
		if (!RSStringIsEmpty(currentPassword) || !RSStringIsEmpty(password))
			[self _savePasswordInKeychain:password username:self.username];
	}
	
	self.credentialsController = nil;
	[self run];
}


#pragma mark Post Body

- (NSString *)postBody {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
	[d safeSetObject:self.username forKey:@"username"];
	if (!RSStringIsEmpty(self.password))
		[d setObject:self.password forKey:@"password"];
	[d safeSetObject:[self.infoDict objectForKey:@"url"] forKey:@"url"];
	NSString *title = [self.infoDict objectForKey:@"title"];
	if (RSStringIsEmpty(title))
		[d setObject:@"1" forKey:@"auto-title"];
	else
		[d setObject:title forKey:@"title"];
	return [d httpPostArgsString];
}


#pragma mark Run - Do Share

- (void)_runAPICall {
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.instapaper.com/api/add"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	[urlRequest setHTTPBody:[self.postBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	[urlRequest setHTTPShouldHandleCookies:NO];
	self.urlConnection = [[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
}


- (void)run {
	if (RSStringIsEmpty(self.username)) {
		if(_modalViewPresenter)
		{
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
			[userInfo setObject:@"Username and/or password is incorrect" forKey:@"errorMessage"];
			[self rs_postNotificationOnMainThread:NNWInstapaperCredentialsViewControllerPostFailed object:nil userInfo:userInfo];
		}
		[self _askUserForCredentials];
		return;
	}
	
	// if we don't have the modal view showing, then use the Feedback view
	if(!_modalViewPresenter)
		[BCFeedbackHUDViewController displayWithMessage:@"Sending to Instapaper" duration:0 useActivityIndicator:YES];
	
	[self _runAPICall];
}


- (void)_doCallback {
	[[self retain] autorelease];
	[BCFeedbackHUDViewController closeWindow];		
	[_callbackTarget performSelector:@selector(sendToInstapaperDidComplete:) withObject:self];
}


#pragma mark Errors


- (void)_displayError:(NSError *)error {
	if ([error code] == NSUserCancelledError && [[error domain] isEqualToString:NSCocoaErrorDomain])
		return;
	NSMutableDictionary *userInfoCopy = [[[error userInfo] mutableCopy] autorelease];
	NSString *errorMessage = [NSString stringWithFormat:@"Can’t send to Instapaper because: %@", [error localizedDescription]];
	if (![errorMessage hasSuffix:@"."])
		errorMessage = [NSString stringWithFormat:@"%@.", errorMessage];
	[userInfoCopy setObject:errorMessage forKey:NSLocalizedDescriptionKey];
	NSError *errorCopy = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfoCopy];
	[app_delegate showAlertWithError:errorCopy];
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if ([response respondsToSelector:@selector(statusCode)])
		self.statusCode = [(NSHTTPURLResponse *)response statusCode];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self _displayError:error];
	[self _doCallback];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if ((self.statusCode == 403)||(self.statusCode == 401)) {
		[BCFeedbackHUDViewController closeWindow];	
		
		if(!_modalViewPresenter)
			[self _askUserForCredentials];
		
		
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
		[userInfo setObject:@"Username and/or password is incorrect" forKey:@"errorMessage"];
		[self rs_postNotificationOnMainThread:NNWInstapaperCredentialsViewControllerPostFailed object:nil userInfo:userInfo];
		
		return;
	}
	if (self.statusCode > 299) {
		NSInteger errorCode = NNWErrorHTTPGeneric;
		NSString *errorString = [NNWErrors genericHTTPErrorString:self.statusCode];
		if (self.statusCode == 400) {
			errorCode = NNWErrorBadRequest;
			errorString = @"The server reported that a bad request was made";
		}
		else if (self.statusCode == 500) {
			errorCode = NNWErrorServiceEncounteredError;
			errorString = @"The server encountered an error";
		}
		[self _displayError:[NNWErrors errorWithCode:errorCode errorString:errorString]];
		
		
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
		[userInfo setObject:@"Username and/or password is incorrect" forKey:@"errorMessage"];
		[self rs_postNotificationOnMainThread:NNWInstapaperCredentialsViewControllerPostFailed object:nil userInfo:userInfo];
	}
	else
	{
		[[NSNotificationCenter defaultCenter]postNotificationOnMainThread:NNWInstapaperCredentialsViewControllerPostDidComplete];
	}
	
	[self _doCallback];	
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	[[challenge sender] cancelAuthenticationChallenge:challenge];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}


@end
