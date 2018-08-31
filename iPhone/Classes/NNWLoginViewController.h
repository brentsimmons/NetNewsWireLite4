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
	IBOutlet UIView *_mainBackgroundView;
	id _callbackDelegate;
	
}


@property (nonatomic, assign) id callbackDelegate;

- (IBAction)login:(id)sender;
- (IBAction)createGoogleAccount:(id)sender;


@end
