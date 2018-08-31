//
//  NNWInstapaperCredentialsViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 9/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NNWInstapaperCredentialsViewController.h"
#import "RSWhiteButton.h"
#import "NNWAppDelegate.h"

NSString* NNWInstapaperCredentialsViewControllerPostDidComplete = @"NNWInstapaperCredentialsViewControllerPostDidComplete";
NSString* NNWInstapaperCredentialsViewControllerPostFailed = @"NNWInstapaperCredentialsViewControllerPostFailed";

@interface NNWInstapaperCredentialsViewController ()
-(void)_animateControlsDown;
-(void)_animateControlsUp;
-(void)_animateCheckMark;
-(void)_dismissView;
-(void)_validateLoginButton;
@end

@implementation NNWInstapaperCredentialsViewController

#pragma mark Init

- (id)initWithDelegate:(id)delegate {
	self = [self initWithNibName:@"InstapaperCredentials" bundle:nil];
	if (!self)
		return nil;
	_delegate = delegate;
	return self;
}


#pragma mark UIViewController

- (void)viewDidLoad {
	NSString *username = _delegate.username;
	if (!username)
		username = @"";
	NSString *password = _delegate.password;
	if (!password)
		password = @"";
	_usernameTextField.text = username;
	_passwordTextField.text = password;
	[self _validateLoginButton];
	
	_usernameTextField.delegate = self;
	_passwordTextField.delegate = self;
	
	[_usernameTextField addTarget:self action:@selector(_genericDidFinishEditing:) forControlEvents:UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit];
	[_passwordTextField addTarget:self action:@selector(_genericDidFinishEditing:) forControlEvents:UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit];
	
	NSArray *values = [NSArray arrayWithObjects:(id)[UIImage imageNamed:@"IndicatorDark_00.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_01.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_02.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_03.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_04.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_05.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_06.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_07.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_08.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_09.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_10.png"].CGImage,
					   (id)[UIImage imageNamed:@"IndicatorDark_11.png"].CGImage,
					   nil];
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	[animation setValues:values];
	[animation setDuration:1.0];
	[animation setAutoreverses:NO];
	[animation setRepeatCount:FLT_MAX];
	[_activityIndicator.layer addAnimation:animation forKey:@"animateLayer"];
	
	_checkmarkImage.alpha = 0.0;
	_activityIndicator.alpha = 0.0;
	_orientation = app_delegate.interfaceOrientation;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate:) name:NNWWillAnimateRotationToInterfaceOrientation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:NNWDidAnimateRotationToInterfaceOrientation object:nil];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(postSucceeded) name:NNWInstapaperCredentialsViewControllerPostDidComplete object:nil];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(postFailed:) name:NNWInstapaperCredentialsViewControllerPostFailed object:nil];
	
	RSSetupWhiteButton(_loginButton);
	RSSetupWhiteButton(_cancelButton);
	
	_errorView.layer.cornerRadius = 5;
	_errorView.alpha = 0.0;
}

- (void)animateKeyboardVisibleInLandscape
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-140, self.view.frame.size.width, self.view.frame.size.height);  
	[UIView commitAnimations];
}

- (void)animateKeyboardNotVisibleInLandscape
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+140, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
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

#pragma mark Delegate

- (void)_callDelegate:(BOOL)userDidCancel {
	[[self retain] autorelease];
	if (userDidCancel)
		[_delegate credentialsControllerCanceled:self];
	else
	{
		_postFail = FALSE;
		_postSuccess = FALSE;
		
		[self _animateControlsDown];
		
		// start the animation
		[_delegate credentialsControllerAccepted:self username:[[[_usernameTextField text] copy] autorelease] password:[[[_passwordTextField text] copy] autorelease]];
	}
}

-(void)postFailed:(NSNotification*)notification
{
	NSDictionary *info = [notification userInfo];
	_errorLabel.text = [info objectForKey:@"errorMessage"];
	
	_postFail = TRUE;
	if((!_animating)&&(_controlsAreDown))
		[self _animateControlsUp];
}

-(void)postSucceeded
{
	//NSLog(@"postSucceded");
	_postSuccess = TRUE;
	if(!_animating)
		[self _animateCheckMark];
	
	[[NSNotificationCenter defaultCenter]removeObserver:self name:NNWInstapaperCredentialsViewControllerPostDidComplete object:nil];
	[[NSNotificationCenter defaultCenter]removeObserver:self name:NNWInstapaperCredentialsViewControllerPostFailed object:nil];
	
}

#pragma mark Animations
-(void)_animateControlsDown
{
	_controlsAreDown = YES;
	[UIView beginAnimations:@"animateControlsDown" context:nil];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	
	_backgroundImage.frame = CGRectMake(0, 0, 540, 870);
	
	_headerImage.frame = CGRectMake(_headerImage.frame.origin.x, _headerImage.frame.origin.y+250, _headerImage.frame.size.width, _headerImage.frame.size.height);
	_usernameTextField.frame = CGRectMake(_usernameTextField.frame.origin.x, _usernameTextField.frame.origin.y+250, _usernameTextField.frame.size.width, _usernameTextField.frame.size.height);
	_passwordTextField.frame = CGRectMake(_passwordTextField.frame.origin.x, _passwordTextField.frame.origin.y+250, _passwordTextField.frame.size.width, _passwordTextField.frame.size.height);
	_cancelButton.frame = CGRectMake(_cancelButton.frame.origin.x, _cancelButton.frame.origin.y+250, _cancelButton.frame.size.width, _cancelButton.frame.size.height);
	_loginButton.frame = CGRectMake(_loginButton.frame.origin.x, _loginButton.frame.origin.y+250, _loginButton.frame.size.width, _loginButton.frame.size.height);
	_errorView.frame = CGRectMake(_errorView.frame.origin.x, _errorView.frame.origin.y+250, _errorView.frame.size.width, _errorView.frame.size.height);
	
	_headerImage.alpha = 0.0;
	_usernameTextField.alpha = 0.0;
	_passwordTextField.alpha = 0.0;
	_cancelButton.alpha = 0.0;
	_loginButton.alpha = 0.0;
	_errorView.alpha = 0.0;
	
	_activityIndicator.alpha = 1.0;
	
	[UIView commitAnimations];
	
	_animating = YES;
}

-(void)_animateControlsUp
{
	_controlsAreDown = NO;
	[UIView beginAnimations:@"animateControlsUp" context:nil];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	
	_backgroundImage.frame = CGRectMake(0, -250, 540, 870);
	
	_headerImage.frame = CGRectMake(_headerImage.frame.origin.x, _headerImage.frame.origin.y-250, _headerImage.frame.size.width, _headerImage.frame.size.height);
	_usernameTextField.frame = CGRectMake(_usernameTextField.frame.origin.x, _usernameTextField.frame.origin.y-250, _usernameTextField.frame.size.width, _usernameTextField.frame.size.height);
	_passwordTextField.frame = CGRectMake(_passwordTextField.frame.origin.x, _passwordTextField.frame.origin.y-250, _passwordTextField.frame.size.width, _passwordTextField.frame.size.height);
	_cancelButton.frame = CGRectMake(_cancelButton.frame.origin.x, _cancelButton.frame.origin.y-250, _cancelButton.frame.size.width, _cancelButton.frame.size.height);
	_loginButton.frame = CGRectMake(_loginButton.frame.origin.x, _loginButton.frame.origin.y-250, _loginButton.frame.size.width, _loginButton.frame.size.height);
	_errorView.frame = CGRectMake(_errorView.frame.origin.x, _errorView.frame.origin.y-250, _errorView.frame.size.width, _errorView.frame.size.height);
	
	_headerImage.alpha = 1.0;
	_usernameTextField.alpha = 1.0;
	_passwordTextField.alpha = 1.0;
	_cancelButton.alpha = 1.0;
	_loginButton.alpha = 1.0;
	
	if(_postFail)
		_errorView.alpha = 1.0;
	
	_activityIndicator.alpha = 0.0;
	
	[UIView commitAnimations];
	
	_animating = YES;
}

-(void)_animateCheckMark
{
	[UIView beginAnimations:@"showCheckMark" context:nil];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.5];
	
	_activityIndicator.alpha = 0.0;
	_checkmarkImage.alpha = 1.0;
	
	[UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	_animating = FALSE;
	if(([animationID isEqualToString:@"animateControlsDown"])&&(_postFail))
		[self _animateControlsUp];
	else if (([animationID isEqualToString:@"animateControlsDown"])&&(_postSuccess))
		[self _animateCheckMark];
	else if ([animationID isEqualToString:@"showCheckMark"])
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_dismissView) userInfo:nil repeats:NO];
}

-(void)_dismissView
{
	[self _callDelegate:YES];
}

#pragma mark TextFieldDelegate
-(void) _validateLoginButton {
	_loginButton.enabled = !RSStringIsEmpty(_usernameTextField.text);// && !RSStringIsEmpty(_passwordTextField.text));
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	[self _validateLoginButton];
	return YES;
}

#pragma mark Actions

- (void)ok:(id)sender {
	[self _callDelegate:NO];	
}


- (void)cancel:(id)sender {
	[self _callDelegate:YES];	
}


#pragma mark Notifications

- (void)_genericDidFinishEditing:(id)sender {
}


@end
