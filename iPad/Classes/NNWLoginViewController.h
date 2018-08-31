//
//  NNWLoginViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NNWLoginViewController : UIViewController {
@private
	IBOutlet UITextField *_usernameTextField;
	IBOutlet UITextField *_passwordTextField;
	IBOutlet UIActivityIndicatorView *_activityIndicator;
	IBOutlet UIButton *_loginButton;
	IBOutlet UILabel *_titleLabel;
	IBOutlet UILabel *_explanation;
	IBOutlet UILabel *_googleAccountExplanation;
	IBOutlet UIView *_mainBackgroundView;
	IBOutlet UIButton *createAccountButton;
	IBOutlet UIImageView *_backgroundImage;
	IBOutlet UIImageView *_satteliteImage;
	IBOutlet UIImageView *_checkMarkImage;
	
	BOOL _animating;
	BOOL _showCheckmark;
	BOOL _showDefaultSubsMessage;
	BOOL _keyboardVisible;
	UIInterfaceOrientation _orientation;
	
	id _callbackDelegate;
	CGFloat _animatedDistance;
	
}


@property (nonatomic, assign) id callbackDelegate;

- (IBAction)login:(id)sender;
- (IBAction)createGoogleAccount:(id)sender;


@end
