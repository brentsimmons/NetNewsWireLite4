//
//  NNWInstapaperCredentialsViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 9/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* NNWInstapaperCredentialsViewControllerPostDidComplete;
extern NSString* NNWInstapaperCredentialsViewControllerPostFailed;

@protocol NNWCredentialsSheetDelegate
- (void)credentialsControllerCanceled:(UIViewController *)viewController;
- (void)credentialsControllerAccepted:(UIViewController *)viewController username:(NSString *)username password:(NSString *)password;
@property (nonatomic, retain, readonly) NSString *username;
@property (nonatomic, retain, readonly) NSString *password;
@end


@interface NNWInstapaperCredentialsViewController : UIViewController <UITextFieldDelegate> {
@private
	IBOutlet UITextField *_usernameTextField;
	IBOutlet UITextField *_passwordTextField;
	IBOutlet UIButton *_cancelButton;
	IBOutlet UIButton *_loginButton;
	IBOutlet UIImageView *_backgroundImage;
	IBOutlet UIImageView *_headerImage;
	IBOutlet UIImageView *_checkmarkImage;
	IBOutlet UIImageView *_activityIndicator;
	IBOutlet UIView *_errorView;
	IBOutlet UILabel *_errorLabel;
	id<NNWCredentialsSheetDelegate> _delegate;
	
	BOOL _animating;
	BOOL _postSuccess;
	BOOL _postFail;
	BOOL _keyboardVisible;
	BOOL _controlsAreDown;
	
	UIInterfaceOrientation _orientation;
}


- (id)initWithDelegate:(id)delegate;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@end
