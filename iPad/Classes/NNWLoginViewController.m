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
#import "NNWRefreshController.h"
#import "RSWhiteButton.h"
#import "NNWGoogleAPI.h"
#import "SFHFKeychainUtils.h"

static NSString *NNWLoginTextFieldDidChangeNotification = @"NNWLoginTextFieldDidChangeNotification";


@interface NNWLoginViewController ()
- (void)validateLoginButton;
- (void)animateControlsDown;
- (void)animateKeyboardVisibleInLandscape;
- (void)animateKeyboardNotVisibleInLandscape;
@end

@implementation NNWLoginViewController

@synthesize callbackDelegate = _callbackDelegate;

#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


#pragma mark UIViewController

- (void)viewDidLoad {
	NSString *username = app_delegate.googleUsername;
	_usernameTextField.text = username ? username : @"";
	[_usernameTextField addTarget:self action:@selector(_genericDidFinishEditing:) forControlEvents:UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit];
	[_passwordTextField addTarget:self action:@selector(_genericDidFinishEditing:) forControlEvents:UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit];
	_activityIndicator.center = _loginButton.center;
	RSSetupWhiteButton(_loginButton);
	RSSetupWhiteButton(createAccountButton);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginTextFieldDidChange:) name:NNWLoginTextFieldDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayCheckmark) name:NNWRefreshSessionSubsFoundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayDefaultSubsMessage) name:NNWRefreshSessionNoSubsFoundNotification object:nil];
	[self validateLoginButton];
	_checkMarkImage.alpha = 0.0;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate:) name:NNWWillAnimateRotationToInterfaceOrientation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:NNWDidAnimateRotationToInterfaceOrientation object:nil];

	_orientation = self.interfaceOrientation;

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark Logging In

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	;
}


static NSString *NNWCantLoginToGoogleErrorTitle = @"There was an error logging in";

- (void)displayAuthenticationError {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
	[d setObject:NNWCantLoginToGoogleErrorTitle forKey:@"title"];
	[d setObject:@"The username and password combination wasn’t recognized by Google." forKey:@"baseMessage"];
	[d setObject:self forKey:@"delegate"];
	[app_delegate showAlertWithDictionary:d];
}


- (void)displayNotVerifiedError {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:4];
	[d setObject:NNWCantLoginToGoogleErrorTitle forKey:@"title"];
	[d setObject:@"Your account has not yet been verified by Google. Check your email for a Google Email Verification." forKey:@"baseMessage"];
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
	[d setObject:NNWCantLoginToGoogleErrorTitle forKey:@"title"];
	[d setObject:@"There was a totally unexpected error: %@" forKey:@"baseMessage"];
	[d setObject:self forKey:@"delegate"];
	[app_delegate showAlertWithDictionary:d];	
}


- (void)didTryGoogleLogin:(NNWHTTPResponse *)nnwResponse {
	BOOL authenticationError = nnwResponse.forbiddenError;
	BOOL notConnectedToInternet = nnwResponse.notConnectedToInternetError;
	BOOL okResponse = nnwResponse.okResponse;
	//[nnwResponse debug_showResponseBody];
	[_activityIndicator stopAnimating];
	if (authenticationError) {
		_loginButton.hidden = NO;
		/* Check for not-verified error
		 2010-02-15 01:27:22.733 NetNewsWire[4319:207] ---HTTP Response---
		 <https://www.google.com/accounts/ClientLogin?client=NNW-iPhone>
		 Error=NotVerified
		 Url=https://www.google.com/accounts/ErrorMsg?service=reader&id=nv&timeStmp=1266226040&secTok=120fd4d7f50648d9042bf541bef4fb94 */
		NSString *responseBody = [nnwResponse responseBodyString];
		if (responseBody != nil && [responseBody caseInsensitiveContains:@"Error=NotVerified"])
			[self displayNotVerifiedError];
		else
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
		[_callbackDelegate performSelectorOnMainThread:@selector(loginSuccess) withObject:nil waitUntilDone:NO];
		
		[self animateControlsDown];
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

#pragma mark Animations
-(void)animateControlsDown
{
	_animating = TRUE;
	
	[UIView beginAnimations:@"animateControlsDown" context:nil];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	
	_backgroundImage.frame = CGRectMake(_backgroundImage.frame.origin.x, 0, _backgroundImage.frame.size.width, _backgroundImage.frame.size.height);
	_usernameTextField.frame = CGRectMake(_usernameTextField.frame.origin.x, _usernameTextField.frame.origin.y+250, _usernameTextField.frame.size.width, _usernameTextField.frame.size.height);
	_passwordTextField.frame = CGRectMake(_passwordTextField.frame.origin.x,  _passwordTextField.frame.origin.y+250, _passwordTextField.frame.size.width, _passwordTextField.frame.size.height);
	_loginButton.frame = CGRectMake(_loginButton.frame.origin.x,  _loginButton.frame.origin.y+250, _loginButton.frame.size.width, _loginButton.frame.size.height);
	_titleLabel.frame = CGRectMake(_titleLabel.frame.origin.x,  _titleLabel.frame.origin.y+250, _titleLabel.frame.size.width, _titleLabel.frame.size.height);
	_explanation.frame = CGRectMake(_explanation.frame.origin.x,  _explanation.frame.origin.y+250, _explanation.frame.size.width, _explanation.frame.size.height);
	createAccountButton.frame = CGRectMake(createAccountButton.frame.origin.x,  createAccountButton.frame.origin.y+250, createAccountButton.frame.size.width, createAccountButton.frame.size.height);
	_googleAccountExplanation.frame = CGRectMake(_googleAccountExplanation.frame.origin.x,  _googleAccountExplanation.frame.origin.y+250, _googleAccountExplanation.frame.size.width, _googleAccountExplanation.frame.size.height);
	_satteliteImage.frame = CGRectMake(_satteliteImage.frame.origin.x,  _satteliteImage.frame.origin.y+250, _satteliteImage.frame.size.width, _satteliteImage.frame.size.height);
	
	_usernameTextField.alpha = 0.0;
	_passwordTextField.alpha = 0.0;
	_loginButton.alpha = 0.0;
	_titleLabel.alpha = 0.0;
	_explanation.alpha = 0.0;
	createAccountButton.alpha = 0.0;
	_googleAccountExplanation.alpha = 0.0;
	_satteliteImage.alpha = 0.0;
	
	[UIView commitAnimations];
}

-(void)displayCheckmark
{
	_showCheckmark = TRUE;
	if(_animating)
	{
		return;
	}
	
	_animating = TRUE;
	
	[UIView beginAnimations:@"displayCheckmark" context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	
	_checkMarkImage.alpha = 1.0;
	
	[UIView commitAnimations];
}

-(void) displayDefaultSubsMessage
{
	_showDefaultSubsMessage = TRUE;
	if(_animating)
	{
		return;
	}
	_satteliteImage.frame = CGRectMake(_satteliteImage.frame.origin.x,  _satteliteImage.frame.origin.y-250, _satteliteImage.frame.size.width, _satteliteImage.frame.size.height);
	
	_titleLabel.text = @"Oh Noes!";
	_titleLabel.frame = CGRectMake(_titleLabel.frame.origin.x,  _titleLabel.frame.origin.y-250, _titleLabel.frame.size.width, _titleLabel.frame.size.height);;

	_explanation.numberOfLines = 8;
	_explanation.text = @"You don't have any feeds in Google Reader yet - but you might like something to read. Would you like NetNewsWire to add a few feeds for you?\n\nTo add more feeds, visit Google Reader online, or use NetNewsWire for Macintosh.";
	_explanation.frame = CGRectMake(128, 251, 284, 150);
	
	_loginButton.frame = CGRectMake(128, 420, 285, 49);
	_loginButton.hidden = NO;
	[_loginButton setTitle:@"Add Sample Feeds" forState:UIControlStateNormal];
	[_loginButton setTitle:@"Add Sample Feeds" forState:UIControlStateDisabled];
	[_loginButton setTitle:@"Add Sample Feeds" forState:UIControlStateSelected];
	[_loginButton setTitle:@"Add Sample Feeds" forState:UIControlStateHighlighted];
	
	createAccountButton.frame = CGRectMake(128, 500, 285, 49);
	createAccountButton.hidden = NO;
	[createAccountButton setTitle:@"No way!" forState:UIControlStateNormal];
	[createAccountButton setTitle:@"No way!" forState:UIControlStateDisabled];
	[createAccountButton setTitle:@"No way!" forState:UIControlStateSelected];
	[createAccountButton setTitle:@"No way!" forState:UIControlStateHighlighted];

	[UIView beginAnimations:@"animateOhNoes" context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	
	_titleLabel.alpha = 1.0;
	_explanation.alpha = 1.0;
	_satteliteImage.alpha = 1.0;
	_loginButton.alpha = 1.0;
	createAccountButton.alpha = 1.0;
	
	[UIView commitAnimations];
	
	_animating = TRUE;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	_animating = FALSE;
	
	if(([animationID isEqualToString:@"animateControlsDown"])&&(_showDefaultSubsMessage))
		[self displayDefaultSubsMessage];
	else if((([animationID isEqualToString:@"animateControlsDown"])&&(_showCheckmark))||
		([animationID isEqualToString:@"animateSubscribeToDefaultFeeds"]))
		[self displayCheckmark];
	else if([animationID isEqualToString:@"displayCheckmark"])
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_dismissView) userInfo:nil repeats:NO];
}

-(void)_dismissView
{
	[app_delegate dismissModalViewController];
}

- (void)subscribeToFeeds {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://taplynx.com/blog/feed/atom" title:@"TapLynx Blog" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://rss.macworld.com/macworld/feeds/main" title:@"Macworld" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://feeds.arstechnica.com/arstechnica/apple/" title:@"Ars Technica Infinite Loop" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://daringfireball.net/index.xml" title:@"Daring Fireball" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://feeds.feedburner.com/NickBradbury" title:@"Nick Bradbury" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://ranchero.com/xml/rss.xml" title:@"ranchero.com" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://inessential.com/xml/rss.xml" title:@"inessential.com" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://gusmueller.com/blog/atom.xml" title:@"Gus's weblog" folderName:nil];
	NSLog(@"Done adding subscriptions");
	[self performSelectorOnMainThread:@selector(didFinishAddingFeeds) withObject:nil waitUntilDone:NO];
	[pool drain];	
}

- (void)didFinishAddingFeeds {
	[_callbackDelegate performSelectorOnMainThread:@selector(startRefreshing) withObject:nil waitUntilDone:NO];
}

#pragma mark Actions

- (IBAction)login:(id)sender {
	if(_showDefaultSubsMessage)
	{
		[UIView beginAnimations:@"animateSubscribeToDefaultFeeds" context:nil];
		[UIView setAnimationDuration:0.75];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		[UIView setAnimationDelegate:self];
		
		_titleLabel.alpha = 0.0;
		_explanation.alpha = 0.0;
		_satteliteImage.alpha = 0.0;
		_loginButton.alpha = 0.0;
		createAccountButton.alpha = 0.0;
		
		[UIView commitAnimations];
		
		[self performSelectorInBackground:@selector(subscribeToFeeds) withObject:nil];
	}
	else
	{
		_loginButton.hidden = YES;
		[_activityIndicator startAnimating];
		NSString *username = [[_usernameTextField.text copy] autorelease];
		NSString *password = [[_passwordTextField.text copy] autorelease];
		
		[_usernameTextField resignFirstResponder];
		[_passwordTextField resignFirstResponder];
		
		[self tryLoggingInToGoogleWithUsername:username andPassword:password];
	}
}


- (IBAction)createGoogleAccount:(id)sender {
	if(_showDefaultSubsMessage)
	{
		[app_delegate dismissModalViewController];
	}
	else
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.google.com/accounts/NewAccount"]];
	}
}


#pragma mark Text Field Delegate

- (void)sendTextChangedNotification {
	[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:NNWLoginTextFieldDidChangeNotification object:nil] postingStyle:NSPostWhenIdle];
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

-(void)keyboardWillShow:(NSNotification*)note
{
	_keyboardVisible = YES;
	if((_orientation == UIInterfaceOrientationLandscapeLeft)||
	   (_orientation == UIInterfaceOrientationLandscapeRight))
		[self animateKeyboardVisibleInLandscape];
}

-(void)keyboardWillHide:(NSNotification*)note
{
	_keyboardVisible = NO;
	if((_orientation == UIInterfaceOrientationLandscapeLeft)||
	   (_orientation == UIInterfaceOrientationLandscapeRight))
		[self animateKeyboardNotVisibleInLandscape];
}

- (void)animateKeyboardVisibleInLandscape
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-80, self.view.frame.size.width, self.view.frame.size.height);  
	[UIView commitAnimations];
}

- (void)animateKeyboardNotVisibleInLandscape
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+80, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

-(void)willRotate:(NSNotification*)notification
{
	NSDictionary *userInfoDict = [notification userInfo];
	NSNumber *orientationNumber = [userInfoDict objectForKey:@"orientation"];
	
	UIInterfaceOrientation orientation = [orientationNumber intValue];
	
	if(((orientation == UIInterfaceOrientationLandscapeLeft)||
		(orientation == UIInterfaceOrientationLandscapeRight))&&
	   (_keyboardVisible))
		[self animateKeyboardVisibleInLandscape];
	
	_orientation = orientation;
}

-(void)didRotate:(NSNotification*)notification
{
	NSDictionary *userInfoDict = [notification userInfo];
	NSNumber *orientationNumber = [userInfoDict objectForKey:@"orientation"];
	UIInterfaceOrientation orientation = [orientationNumber intValue];
	
	if(((orientation == UIInterfaceOrientationPortrait)||
		(orientation == UIInterfaceOrientationPortraitUpsideDown))&&
		(_keyboardVisible))
		[self animateKeyboardVisibleInLandscape];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {	
	[self sendTextChangedNotification];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self sendTextChangedNotification];	
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[self sendTextChangedNotification];
	return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == _usernameTextField) 
	{
		[_passwordTextField becomeFirstResponder];
		return NO;
	}
	else
	{
		[textField resignFirstResponder];
		return YES;
	}
	[self sendTextChangedNotification];
}


- (BOOL)textFieldShouldClear:(UITextField *)textField {
	[self sendTextChangedNotification];
	return YES;
}


#pragma mark UI

- (void)validateLoginButton {
	_loginButton.enabled = !RSStringIsEmpty(_usernameTextField.text) && !RSStringIsEmpty(_passwordTextField.text);
}


#pragma mark Notifications

- (void)_genericDidFinishEditing:(id)sender {
}


- (void)loginTextFieldDidChange:(NSNotification *)note {
	[self validateLoginButton];
}


@end
