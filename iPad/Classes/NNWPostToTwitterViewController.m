//
//  NNWPostToTwitterViewController.m
//  ModalView
//
//  Created by Nick Harris on 3/13/10.
//  Copyright 2010 NewsGator Technologies. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NNWPostToTwitterViewController.h"
#import "NGModalViewPresenter.h"
#import "NNWAppDelegate.h"
#import "NNWExtras.h"
#import "RSFetchTinyURLOperation.h"
#import "RSKeychain.h"
#import "RSOperationController.h"
#import "RSOperationTwitterCall.h"
#import "RSTwitterCallAuthorize.h"
#import "RSTwitterCallSendStatus.h"
#import "RSTwitterUtilities.h"
#import "RSWhiteButton.h"
#import "SFHFKeychainUtils.h"


static RSOperationController *gTwitterOperationController = nil;


@interface NNWPostToTwitterViewController ()

@property (nonatomic, retain) RSFetchTinyURLOperation *fetchTinyURLOperation;
@property (nonatomic, retain) NSDictionary *twitterOauthAccessToken;
@property (nonatomic, retain, readonly) RSOAuthInfo *oauthInfo;
@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *consumerSecret;
@property (nonatomic, copy) NSString *statusToSendToTwitter;
@property (nonatomic, assign) BOOL waitingForTwitterAccessToken;

- (void)fetchUsernameAndPassword;
- (void)_animateControlsDown;
- (void)_animateControlsUp;
-(void)_animateCheckMark;
- (void)_validatePostButton;
- (void)closeWindow;

@end

@implementation NNWPostToTwitterViewController

@synthesize urlString = _urlString;
@synthesize articleTitle = _articleTitle;
@synthesize tinyURLString = _tinyURLString;
@synthesize username = _username;
@synthesize password = _password;
@synthesize postDelegate = _postDelegate;
@synthesize fetchTinyURLOperation;
@synthesize twitterOauthAccessToken;
@synthesize consumerKey;
@synthesize consumerSecret;
@synthesize statusToSendToTwitter;
@synthesize waitingForTwitterAccessToken;


- (void)viewDidLoad {
	self.consumerKey = @"5NfZbgWSsOEny1H62krSA";
	self.consumerSecret = @"5nTLKp3VKaM9NXQMkLN6AOwuySUaRicBLPW9S0QaPA";
	if (gTwitterOperationController == nil)
		gTwitterOperationController = [[RSOperationController alloc] init];
	UIImage *strechImage = [[UIImage imageNamed:@"WebviewAddressField.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	_messageBorder.image = strechImage;
	_usernameTextField.background = strechImage;
	_passwordTextField.background = strechImage;
	
	NSArray *values = [NSArray arrayWithObjects:(id)[UIImage imageNamed:@"Indicator_00.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_01.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_02.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_03.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_04.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_05.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_06.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_07.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_08.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_09.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_10.png"].CGImage,
					   (id)[UIImage imageNamed:@"Indicator_11.png"].CGImage,
					   nil];
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	[animation setValues:values];
	[animation setDuration:1.0];
	[animation setAutoreverses:NO];
	[animation setRepeatCount:FLT_MAX];
	[_activityIndicator.layer addAnimation:animation forKey:@"animateLayer"];
	_activityIndicator.layer.contents = (id)[UIImage imageNamed:@"Indicator_00.png"].CGImage;
	_activityIndicator.alpha = 0.0;
	
	_checkmarkImage.alpha = 0.0;
	
	_errorView.layer.cornerRadius = 5;
	_errorView.alpha = 0.0;
	
	RSSetupWhiteButton(_postButton);
	RSSetupWhiteButton(_cancelButton);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate:) name:NNWWillAnimateRotationToInterfaceOrientation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:NNWDidAnimateRotationToInterfaceOrientation object:nil];
	
	_orientation = app_delegate.interfaceOrientation;
	
	[self fetchUsernameAndPassword];
	[self _validatePostButton];
}



static const NSInteger controlsDownOffsetY = 250;

- (void)_animateControlsDown {	
	[UIView beginAnimations:@"animateControlsDown" context:nil];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	
	_backgroundImage.frame = CGRectMake(0, 0, 540, 1020);
	
	/*This is the hard way. These should all be in a container view that moves.*/
	
	_headerImage.frame = CGRectOffset(_headerImage.frame, 0, controlsDownOffsetY);
	_messageBorder.frame = CGRectOffset(_messageBorder.frame, 0, controlsDownOffsetY);
	_textView.frame = CGRectOffset(_textView.frame, 0, controlsDownOffsetY);
	_urlLabel.frame = CGRectOffset(_urlLabel.frame, 0, controlsDownOffsetY);
	_characterCountLabel.frame = CGRectOffset(_characterCountLabel.frame, 0, controlsDownOffsetY);
	_usernameTextField.frame = CGRectOffset(_usernameTextField.frame, 0, controlsDownOffsetY);
	_passwordTextField.frame = CGRectOffset(_passwordTextField.frame, 0, controlsDownOffsetY);
	_cancelButton.frame = CGRectOffset(_cancelButton.frame, 0, controlsDownOffsetY);
	_postButton.frame = CGRectOffset(_postButton.frame, 0, controlsDownOffsetY);
	_errorView.frame = CGRectOffset(_errorView.frame, 0, controlsDownOffsetY);
	
	_headerImage.alpha = 0.0;
	_messageBorder.alpha = 0.0;
	_textView.alpha = 0.0;
	_urlLabel.alpha = 0.0;
	_characterCountLabel.alpha = 0.0;
	_usernameTextField.alpha = 0.0;
	_passwordTextField.alpha = 0.0;
	_cancelButton.alpha = 0.0;
	_postButton.alpha = 0.0;
	_errorView.alpha = 0.0;
	
	[_activityIndicator startAnimating];
	_activityIndicator.alpha = 1.0;
	
	[UIView commitAnimations];
	
	_animating = YES;
}

static const NSInteger controlsUpOffsetY = -250;

- (void)_animateControlsUp {
	[UIView beginAnimations:@"animateControlsUp" context:nil];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	
	_backgroundImage.frame = CGRectMake(0, -400, 540, 1020);
	
	_headerImage.frame = CGRectOffset(_headerImage.frame, 0, controlsUpOffsetY);
	_messageBorder.frame = CGRectOffset(_messageBorder.frame, 0, controlsUpOffsetY);
	_textView.frame = CGRectOffset(_textView.frame, 0, controlsUpOffsetY);
	_urlLabel.frame = CGRectOffset(_urlLabel.frame, 0, controlsUpOffsetY);
	_characterCountLabel.frame = CGRectOffset(_characterCountLabel.frame, 0, controlsUpOffsetY);
	_usernameTextField.frame = CGRectOffset(_usernameTextField.frame, 0, controlsUpOffsetY);
	_passwordTextField.frame = CGRectOffset(_passwordTextField.frame, 0, controlsUpOffsetY);
	_cancelButton.frame = CGRectOffset(_cancelButton.frame, 0, controlsUpOffsetY);
	_postButton.frame = CGRectOffset(_postButton.frame, 0, controlsUpOffsetY);
	_errorView.frame = CGRectOffset(_errorView.frame, 0, controlsUpOffsetY);

	_headerImage.alpha = 1.0;
	_messageBorder.alpha = 1.0;
	_textView.alpha = 1.0;
	_urlLabel.alpha = 1.0;
	_characterCountLabel.alpha = 1.0;
	_usernameTextField.alpha = 1.0;
	_passwordTextField.alpha = 1.0;
	_cancelButton.alpha = 1.0;
	_postButton.alpha = 1.0;
	
	if(_hasError)
		_errorView.alpha = 1.0;
	
	_activityIndicator.alpha = 0.0;
	
	[UIView commitAnimations];
	
	_animating = YES;
}

-(void)_animateCheckMark
{
	_activityIndicator.alpha = 0.0;
	
	[UIView beginAnimations:@"showCheckMark" context:nil];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.5];
	_checkmarkImage.alpha = 1.0;
	
	[UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	_animating = NO;
	
	if(([animationID isEqualToString:@"animateControlsDown"])&&(_hasError))
		[self _animateControlsUp];
	else if(([animationID isEqualToString:@"animateControlsDown"])&&(_postComplete)&&(!_hasError))
		[self _animateCheckMark];
	else if ([animationID isEqualToString:@"showCheckMark"])
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_dismissView) userInfo:nil repeats:NO];
}

- (void)dismissWithSuccess:(BOOL)success {
	if (success) {
		_postComplete = YES;
		_hasError = NO;
		if(!_animating)
			[self _animateCheckMark];
	}
	else
		[self closeWindow];
}


//-(void)postToTwitterDidComplete:(NSNotification*)notification
//{
//	_postComplete = YES;
//	_hasError = NO;
//	
//	[[NSNotificationCenter defaultCenter]removeObserver:self name:NNWPostToTwitterOperationDidComplete object:nil];
//	[[NSNotificationCenter defaultCenter]removeObserver:self name:NNWPostToTwitterOperationDidFail object:nil];
//	
//	if(!_animating)
//		[self _animateCheckMark];
//}

-(void)_dismissView
{
	[self cancel:self];
}

//-(void)postToTwitterDidFail:(NSNotification*)notification
//{
//	_postComplete = YES;
//	_hasError = YES;
//	
//	if(!_animating)
//		[self _animateControlsUp];
//	
//	[[NSNotificationCenter defaultCenter]removeObserver:self name:NNWPostToTwitterOperationDidComplete object:nil];
//	[[NSNotificationCenter defaultCenter]removeObserver:self name:NNWPostToTwitterOperationDidFail object:nil];
//	
//	NNWPostToTwitterOperation *postToTwitterOperation = [notification object];
//	
//	if (postToTwitterOperation.notConnectedToInternetError) {
//		_errorLabel.text = @"This device is not connected to the internet";
//		return;
//	}
//	if (postToTwitterOperation.authenticationError) {
//		_errorLabel.text = @"Incorrect username and/or password";
//		return;
//	}
//	if (postToTwitterOperation.statusCode == 503) {
//		_errorLabel.text = @"Twitter reports that it’s unavailable at the moment";
//		return;		
//	}
//	if (postToTwitterOperation.statusCode == -1) {
//		_errorLabel.text = @"We couldn’t get through to Twitter at the moment";
//		return;		
//	}
//	
//	_errorLabel.text = [NSString stringWithFormat:@"Twitter returned a %d code, which was unexpected", postToTwitterOperation.statusCode];
//}


- (void)closeWindow {
	[[NSNotificationCenter defaultCenter]postNotificationName:kNGDismissModalViewController object:nil];	
}


- (IBAction)cancel:(id)sender {
	[self closeWindow];
}


#pragma mark Security

static NSString *rs_preOAuthTwitterServiceName = @"twitter.com";

BOOL RSGetTwitterPasswordFromKeychain(NSString *twitterUsername, NSString **twitterPassword, NSError **error) {
	return RSKeychainGetPassword(rs_preOAuthTwitterServiceName, twitterUsername, twitterPassword, error);
}


BOOL RSDeleteTwitterPasswordFromKeychain(NSString *twitterUsername, NSError **error) {
	return RSKeychainDeletePassword(rs_preOAuthTwitterServiceName, twitterUsername, error);
}


- (NSString *)fetchPasswordFromKeychain {
	NSString *password = nil;
	NSError *error = nil;
	if (!RSStringIsEmpty(self.username) && RSGetTwitterPasswordFromKeychain(self.username, &password, &error))
		return password;
	return nil;
}


- (NSDictionary *)fetchTwitterOAuthAccessTokenFromKeychain:(NSString *)username {
	NSDictionary *accessToken = nil;
	NSError *error = nil;
	return RSTwitterFetchAccessTokenFromKeychain(&accessToken, username, &error) ? accessToken : nil;
}


- (void)fetchUsernameAndPassword {
	self.username = [[NSUserDefaults standardUserDefaults] stringForKey:@"tu"];
	if (RSStringIsEmpty(self.username))
		return;
	_usernameTextField.text = self.username;
	self.password = [self fetchPasswordFromKeychain];
	if (!RSStringIsEmpty(self.password))
		_passwordTextField.text = self.password;
	self.twitterOauthAccessToken = [self fetchTwitterOAuthAccessTokenFromKeychain:self.username];
}


- (RSOAuthInfo *)oauthInfo {
	RSOAuthInfo *oauthInfo = [[[RSOAuthInfo alloc] init] autorelease];
	oauthInfo.consumerKey = self.consumerKey;
	oauthInfo.consumerSecret = self.consumerSecret;
	oauthInfo.oauthToken = [self.twitterOauthAccessToken objectForKey:RSTwitterOAuthTokenKey];
	oauthInfo.oauthSecret = [self.twitterOauthAccessToken objectForKey:RSTwitterOAuthTokenSecretKey];
	return oauthInfo;
}


//- (void)_fetchUsernameAndPassword {
//	NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"tu"];
//	if (RSStringIsEmpty(username))
//		return;
//	_usernameTextField.text = username;
//	NSError *error = nil;
//	NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"twitter.com" error:&error];
//	if (!RSStringIsEmpty(password))
//		_passwordTextField.text = password;
//}

#pragma mark Alerts

- (void)showErrorView {
	_hasError = YES;
	_errorView.alpha = 1.0;
}


- (void)hideErrorView {
	_hasError = NO;
	_errorView.alpha = 0.0;
}


- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	UIAlertView *alertView = [[[UIAlertView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)] autorelease];
	alertView.title = title;
	alertView.message = message;
	[alertView addButtonWithTitle:@"OK"];
	[alertView show];
}


- (void)showUsernamePasswordError {
	_errorLabel.text = @"Incorrect username and/or password";
//	[self showAlertWithTitle:TL_USERNAME_PASSWORD_ERROR_TITLE message:TL_USERNAME_PASSWORD_ERROR_MESSAGE];
}


- (void)showOAuthValidationError {
	_errorLabel.text = @"There was an error verifying your account. It may work if you try again.";
//	[self showAlertWithTitle:TL_TWITTER_ERROR_VALIDATION message:TL_TWITTER_ERROR_VALIDATION_MESSAGE];
}


- (void)showNoInternetConnectionError {
	_errorLabel.text = @"This device is not connected to the internet";
//	[self showAlertWithTitle:TL_CANT_POST_TO_TWITTER_ERROR_TITLE message:TL_TWITTER_NO_CONNECTION_ERROR_MESSAGE];
}


- (void)showTwitterServerErrorWithStatusCode:(NSInteger)statusCode {
	_errorLabel.text = [NSString stringWithFormat:@"Twitter returned a %d code, which was unexpected", statusCode];
//	[self showAlertWithTitle:TL_TWITTER_ERROR_TITLE message:[NSString stringWithFormat:TL_TWITTER_UNKNOWN_ERROR_MESSAGE, statusCode]];
}


- (void)showInternalServerError {
	_errorLabel.text = TL_TWITTER_ERROR_INTERNAL_SERVER_MESSAGE;
	//[self showAlertWithTitle:TL_TWITTER_ERROR_TITLE message:TL_TWITTER_ERROR_INTERNAL_SERVER_MESSAGE];
}


- (void)showBadGatewayError {
	_errorLabel.text = @"Twitter is unavailable at the moment";
//	[self showAlertWithTitle:TL_TWITTER_ERROR_TITLE message:TL_TWITTER_ERROR_DOWN_MESSAGE];
}


- (void)showServiceUnavailableError {
	_errorLabel.text = @"Twitter is unavailable at the moment";
	//[self showAlertWithTitle:TL_TWITTER_ERROR_TITLE message:TL_TWITTER_ERROR_OVERLOADED_MESSAGE];
}


- (void)showNeedPasswordError {
	_errorLabel.text = TL_TWITTER_ERROR_PASSWORD_NEEDED_MESSAGE;
//	[self showAlertWithTitle:TL_TWITTER_ERROR_PASSWORD_NEEDED message:TL_TWITTER_ERROR_PASSWORD_NEEDED_MESSAGE];
}


- (void)showNeedUsernameError {
	_errorLabel.text = TL_TWITTER_ERROR_USERNAME_NEEDED_MESSAGE;
//	[self showAlertWithTitle:TL_TWITTER_ERROR_USERNAME_NEEDED message:TL_TWITTER_ERROR_USERNAME_NEEDED_MESSAGE];
}


- (void)showTwitterError:(NSError *)error {
//	[app_delegate showAlertWithError:error];
}


- (void)showTwitterErrorWithMessageFromTwitter:(NSString *)twitterErrorMessage {
	_errorLabel.text = [NSString stringWithFormat:TL_TWITTER_ERROR_GENERIC_MESSAGE, twitterErrorMessage];
//	[self showAlertWithTitle:TL_TWITTER_ERROR_TITLE message:[NSString stringWithFormat:TL_TWITTER_ERROR_GENERIC_MESSAGE, twitterErrorMessage]];
}


- (BOOL)handleErrorWithTwitterCall:(RSOperationTwitterCall *)twitterCall {
	
	/*Return YES if there was an error. See http://apiwiki.twitter.com/HTTP-Response-Codes-and-Errors */
	
	NSInteger statusCode = twitterCall.statusCode;
	if (statusCode == 200)
		return NO;
	if (twitterCall.isOAuthValidationError)
		[self showOAuthValidationError];
	else if (twitterCall.isTwitterUsernamePasswordError)
		[self showUsernamePasswordError];
	else if (twitterCall.notConnectedToInternetError)
		[self showNoInternetConnectionError];
	else if (statusCode == 500)
		[self showInternalServerError];
	else if (statusCode == 502)
		[self showBadGatewayError];
	else if (statusCode == 503)
		[self showServiceUnavailableError];
	else if (twitterCall.twitterErrorString != nil)
		[self showTwitterErrorWithMessageFromTwitter:twitterCall.twitterErrorString];
	else if (twitterCall.error != nil)
		[self showTwitterError:twitterCall.error];
	else		
		[self showTwitterServerErrorWithStatusCode:statusCode];
	return YES;
}


#pragma mark Keyboard

- (void)animateKeyboardVisibleInLandscape
{
	_keyboardAdjusted = YES;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-140, self.view.frame.size.width, self.view.frame.size.height);  
	[UIView commitAnimations];
}

- (void)animateKeyboardNotVisibleInLandscape
{
	_keyboardAdjusted = NO;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+140, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}

-(void)keyboardWillShow:(NSNotification*)note
{
	_keyboardVisible = YES;
	if(((_orientation == UIInterfaceOrientationLandscapeLeft)||
		(_orientation == UIInterfaceOrientationLandscapeRight))&&
	   (_textFieldIsResponder))
		[self animateKeyboardVisibleInLandscape];
}

-(void)keyboardWillHide:(NSNotification*)note
{
	_keyboardVisible = NO;
	if(((_orientation == UIInterfaceOrientationLandscapeLeft)||
		(_orientation == UIInterfaceOrientationLandscapeRight))&&
	   (_keyboardAdjusted))
		[self animateKeyboardNotVisibleInLandscape];
}

-(void)willRotate:(NSNotification*)notification
{
	NSDictionary *userInfoDict = [notification userInfo];
	NSNumber *orientationNumber = [userInfoDict objectForKey:@"orientation"];
	
	UIInterfaceOrientation orientation = [orientationNumber intValue];
	
	if(((orientation == UIInterfaceOrientationLandscapeLeft)||
		(orientation == UIInterfaceOrientationLandscapeRight))&&
	   (_keyboardVisible)&&(_textFieldIsResponder))
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
	   (_keyboardVisible)&&(_keyboardAdjusted))
		[self animateKeyboardVisibleInLandscape];
}

#pragma mark UITextField Delegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	if(textField == _usernameTextField)
	{
		[_passwordTextField becomeFirstResponder];
		return NO;
	}
	else
	{
		[textField resignFirstResponder];
		return YES;
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	CGRect viewFrame = self.view.frame;
	viewFrame.origin.y += _animatedDistance;
	
	_textFieldIsResponder = NO;
	/*[UIView beginAnimations:nil context:NULL];
	 [UIView setAnimationBeginsFromCurrentState:YES];
	 [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
	 [self.view setFrame:viewFrame];    
	 [UIView commitAnimations];
	 _animatedDistance = 0;*/
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
 	_textFieldIsResponder = YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	[self _validatePostButton];
	return YES;
}

#pragma mark UITextView Delegate

- (void)_updateCharacterCount {
	//BOOL origNegativeCharacters = self.negativeCharacters;
	characterCount = 140 - [_textView.text length] - [_urlLabel.text length] - 1;
	_characterCountLabel.text = [NSString stringWithFormat:@"%d", characterCount];
	_characterCountLabel.textColor = characterCount >= 0 ? [UIColor whiteColor] : [UIColor colorWithRed:1.0 green:0.0 blue:0.165 alpha:1.0];
	
	[self _validatePostButton];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if([text isEqualToString:@"\n"]) {
		[textView resignFirstResponder];
		[self _updateCharacterCount];
		return NO;
	}
	return YES;
}

- (BOOL)_urlStringNeedsTrailingSpace:(NSString *)s {
	if (RSStringIsEmpty(self.tinyURLString))
		return NO; 
	NSRange rangeOfURLString = [s rangeOfString:self.tinyURLString];
	if (rangeOfURLString.location == NSNotFound)
		return NO;
	if ([s hasSuffix:self.tinyURLString])
	/*If totally at end, means no typing has been done, so it's okay*/
		return NO;
	NSString *characterAfterURL = [s substringWithRange:NSMakeRange(rangeOfURLString.location + rangeOfURLString.length, 1)];
	if ([characterAfterURL isEqualToString:@" "] || [characterAfterURL isEqualToString:@"\n"])
		return NO;
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	if ([self _urlStringNeedsTrailingSpace:textView.text]) {
		NSRange currentRange = textView.selectedRange;
		textView.text = RSStringReplaceAll(textView.text, self.tinyURLString, [NSString stringWithFormat:@"%@ ", self.tinyURLString]);
		currentRange.location++;
		textView.selectedRange = currentRange;
	}
	[self _updateCharacterCount];
}


- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	[self _updateCharacterCount];
	return YES;
}


#pragma mark Send Status to Twitter

- (void)twitterCallSendStatusDidFinish:(RSTwitterCallSendStatus *)twitterCallSendStatus {
//	[self restoreUIToEditingState];
	if (twitterCallSendStatus.okResponse) {
		[self hideErrorView];
		[self dismissWithSuccess:YES];
		return;
	}
	[self handleErrorWithTwitterCall:twitterCallSendStatus];
//	[self showErrorView];
	_hasError = YES;
	_postComplete = YES;
	if(!_animating)
		[self _animateControlsUp];
	else
		[self showErrorView];
}


- (void)sendStatusToTwitter {
	RSTwitterCallSendStatus *twitterCallSendStatus = [[[RSTwitterCallSendStatus alloc] initWithStatus:self.statusToSendToTwitter oauthInfo:self.oauthInfo delegate:self callbackSelector:@selector(twitterCallSendStatusDidFinish:)] autorelease];
	[gTwitterOperationController addOperation:twitterCallSendStatus];
}


#pragma mark Authorize with Twitter

- (void)handleNoPassword {
//	[self restoreUIToEditingState];
	_hasError = YES;
	[self showNeedPasswordError];
	[self showErrorView];
}


- (void)handleNoUsername {
//	[self restoreUIToEditingState];
	_hasError = YES;
	[self showNeedUsernameError];
	[self showErrorView];
}



- (void)twitterCallAuthorizeDidFinish:(RSTwitterCallAuthorize *)twitterCallAuthorize {
	//	[twitterCallAuthorize debugLog];
	if ([self handleErrorWithTwitterCall:twitterCallAuthorize]) {
		_hasError = YES;
		//[self showErrorView];
		_postComplete = YES;
		if(!_animating)
			[self _animateControlsUp];
		return;
	}
	[self hideErrorView];
	NSDictionary *returnedAccessToken = twitterCallAuthorize.parsedResponse;
	if (!RSIsEmpty(returnedAccessToken)) {
		NSError *error = nil;
		RSTwitterStoreAccessTokenInKeychain(returnedAccessToken, twitterCallAuthorize.username, &error);
		/*Make sure old password is deleted.*/
		RSDeleteTwitterPasswordFromKeychain(twitterCallAuthorize.username, &error);
		if ([self.username isEqualToString:twitterCallAuthorize.username]) {			
			self.twitterOauthAccessToken = returnedAccessToken;
			if (self.waitingForTwitterAccessToken) {
				self.waitingForTwitterAccessToken = NO;
				[self sendStatusToTwitter];
				return;
			}
		}
	}
//	[self restoreUIToEditingState];
}


- (void)authorizeWithTwitter {
	RSTwitterCallAuthorize *twitterCallAuthorize = [[[RSTwitterCallAuthorize alloc] initWithOAuthInfo:self.oauthInfo username:self.username password:self.password delegate:self callbackSelector:@selector(twitterCallAuthorizeDidFinish:)] autorelease];
	[gTwitterOperationController addOperation:twitterCallAuthorize];
}


#pragma mark Post to Twitter

- (IBAction)postToTwitter:(id)sender {
	if (characterCount < 0) { //characterCount must mean charactersRemainingCount
		[self showAlertWithTitle:@"Too long" message:@"The message is longer than 140 characters"];
		return;
	}
	[self hideErrorView];
	_postComplete = NO;
	_hasError = NO;
	self.waitingForTwitterAccessToken = NO;
	self.statusToSendToTwitter = [NSString stringWithFormat:@"%@ %@", _textView.text, _urlLabel.text];
	if (RSStringIsEmpty(self.statusToSendToTwitter))
		return;
	NSString *username = _usernameTextField.text;
	if (RSStringIsEmpty(username)) {
		[self handleNoUsername];
		return;
	}
	if (![username isEqualToString:self.username]) {
		self.username = username;
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"tu"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		self.twitterOauthAccessToken = nil;
	}
	if (self.twitterOauthAccessToken == nil)
		self.twitterOauthAccessToken = [self fetchTwitterOAuthAccessTokenFromKeychain:self.username];
	if (self.twitterOauthAccessToken == nil) {
		/*Need password. Either already entered or in keychain.*/
		NSString *password = _passwordTextField.text;
		if (RSStringIsEmpty(password))
			password = [self fetchPasswordFromKeychain];
		if (RSStringIsEmpty(password)) {
			[self handleNoPassword];
			return;
		}
		self.password = password;
		self.waitingForTwitterAccessToken = YES;
		[self _animateControlsDown];
		[self authorizeWithTwitter];
		return;
	}
	
	_activityIndicator.hidden = NO;
	[self sendStatusToTwitter];
	[self _animateControlsDown];
}


#pragma mark tinyURL

- (void)createTinyURL {
	self.fetchTinyURLOperation = [[[RSFetchTinyURLOperation alloc] initWithOriginalURLString:self.urlString] autorelease];
	[self.fetchTinyURLOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchTinyURLOperationDidComplete:) name:RSFetchShortenedURLOperationDidComplete object:nil];
	[[RSOperationController sharedController] addOperation:self.fetchTinyURLOperation];	
}


- (void)fetchTinyURLOperationDidComplete:(NSNotification*)notification {
	if ([notification object] == self.fetchTinyURLOperation) {
		self.tinyURLString = self.fetchTinyURLOperation.shortenedURLString;	
		_urlLabel.text = self.tinyURLString;
		[self _updateCharacterCount];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:RSFetchShortenedURLOperationDidComplete object:nil];
		self.fetchTinyURLOperation = nil;
	}
}


#pragma mark Accessors

- (void)_addTitleAndURLToTextView {
	NSMutableString *s = [[[NSMutableString alloc] initWithString:self.articleTitle ? self.articleTitle : @""] autorelease];
	[s appendString:@" "];
	//[s appendString:self.urlString ? self.urlString : @""];
	_urlLabel.text = self.urlString ? self.urlString : @"";
	_textView.text = s;
	[self _updateCharacterCount];
}

- (void)setInfoDict:(NSDictionary *)d {
	/*Title and URL, all at once, so we know we're starting a new thing.*/
	NSString *articleTitle = [d objectForKey:@"articleTitle"];
	self.articleTitle = articleTitle;
	self.urlString = [d objectForKey:@"urlString"];
	//self.creatingTinyURL = YES;
	[self performSelector:@selector(createTinyURL) withObject:nil afterDelay:2.0];
	[self _addTitleAndURLToTextView];
	[self.view setNeedsLayout];
	[self.view setNeedsDisplay];
}

- (void)_validatePostButton {
//	_postButton.enabled = !RSStringIsEmpty(_usernameTextField.text) && !RSStringIsEmpty(_passwordTextField.text) && (characterCount >= 0);
	_postButton.enabled = !RSStringIsEmpty(_usernameTextField.text) && (characterCount >= 0);
}

@end
