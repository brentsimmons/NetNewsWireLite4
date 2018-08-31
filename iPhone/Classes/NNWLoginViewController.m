//
//  NNWLoginViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWLoginViewController.h"
#import "NNWAppDelegate.h"
#import "NNWGoogleLoginController.h"
#import "NNWHTTPResponse.h"
#import "SFHFKeychainUtils.h"


@implementation NNWLoginViewController

@synthesize callbackDelegate = _callbackDelegate;

- (void)viewDidLoad {
	NSString *username = app_delegate.googleUsername;
	_usernameTextField.text = username ? username : @"";
	[_usernameTextField addTarget:self action:@selector(_genericDidFinishEditing:) forControlEvents:UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit];
	[_passwordTextField addTarget:self action:@selector(_genericDidFinishEditing:) forControlEvents:UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit];
	_activityIndicator.center = _loginButton.center;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}


//- (void)dealloc {
//    [super dealloc];
//}


#pragma mark Logging In

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	;
}


- (void)displayAuthenticationError {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
	[d setObject:@"Can’t login to Google" forKey:@"title"];
	[d setObject:@"The username and password combination wasn’t recognized by Google." forKey:@"baseMessage"];
	[d setObject:self forKey:@"delegate"];
	[app_delegate showAlertWithDictionary:d];
}


- (void)displayNotConnectedError {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
	[d setObject:@"Offline Error" forKey:@"title"];
	[d setObject:@"Can’t login to Google because of an error: no internet connection." forKey:@"baseMessage"];
	[d setObject:self forKey:@"delegate"];
	[app_delegate showAlertWithDictionary:d];
}


- (void)displayUnknownError:(NSError *)error {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
	[d setObject:@"Can’t login to Google" forKey:@"title"];
	[d setObject:@"There was a totally unexpected error: %@" forKey:@"baseMessage"];
	[d setObject:self forKey:@"delegate"];
	[app_delegate showAlertWithDictionary:d];	
}


- (void)didTryGoogleLogin:(NNWHTTPResponse *)nnwResponse {
	BOOL authenticationError = nnwResponse.forbiddenError;
	BOOL notConnectedToInternet = nnwResponse.notConnectedToInternetError;
	BOOL okResponse = nnwResponse.okResponse;
	[_activityIndicator stopAnimating];
	if (authenticationError) {
		_loginButton.hidden = NO;
		[self displayAuthenticationError];
	}
	else if (notConnectedToInternet) {
		_loginButton.hidden = NO;
		[self displayNotConnectedError];
	}
	else if (okResponse) {
		NSString *username = [[_usernameTextField.text copy] autorelease];
		NSString *password = [[_passwordTextField.text copy] autorelease];
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:NNWGoogleUsernameKey];
		NSError *error = nil;
		[SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:NNWGoogleServiceName updateExisting:YES error:&error];
		[((UIViewController *)_callbackDelegate).navigationController dismissModalViewControllerAnimated:YES];
		[_callbackDelegate performSelectorOnMainThread:@selector(loginSuccess) withObject:nil waitUntilDone:NO];
	}
	else {		
		_loginButton.hidden = NO;
		[self displayUnknownError:nnwResponse.error];
	}
}


- (void)tryLoggingInToGoogleWithUsername:(NSString *)username andPassword:(NSString *)password {
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
	[infoDict safeSetObject:username forKey:NNWGoogleUsernameKey];
	[infoDict safeSetObject:password forKey:NNWGooglePasswordKey];
	[infoDict setObject:self forKey:@"target"];
	[NSThread detachNewThreadSelector:@selector(tryLoginInBackgroundThread:) toTarget:[NNWGoogleLoginController sharedController] withObject:infoDict];
}


#pragma mark Actions

- (IBAction)login:(id)sender {
	_loginButton.hidden = YES;
	[_activityIndicator startAnimating];
	NSString *username = [[_usernameTextField.text copy] autorelease];
	NSString *password = [[_passwordTextField.text copy] autorelease];
	[self tryLoggingInToGoogleWithUsername:username andPassword:password];
}


- (IBAction)createGoogleAccount:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.google.com/accounts/NewAccount"]];
}


#pragma mark Text Field Delegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

#pragma mark Notifications

- (void)_genericDidFinishEditing:(id)sender {
}

@end
