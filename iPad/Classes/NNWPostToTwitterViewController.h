//
//  NNWPostToTwitterViewController.h
//  ModalView
//
//  Created by Nick Harris on 3/13/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RSFetchTinyURLOperation;

@interface NNWPostToTwitterViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate> {
	IBOutlet UIImageView *_messageBorder;
	IBOutlet UIImageView *_backgroundImage;
	IBOutlet UIImageView *_headerImage;
	IBOutlet UIImageView *_checkmarkImage;
	IBOutlet UITextView *_textView;
	IBOutlet UILabel *_characterCountLabel;
	IBOutlet UILabel *_urlLabel;
	IBOutlet UITextField *_usernameTextField;
	IBOutlet UITextField *_passwordTextField;
	IBOutlet UIImageView *_activityIndicator;
	IBOutlet UIButton *_cancelButton;
	IBOutlet UIButton *_postButton;
	IBOutlet UIView *_errorView;
	IBOutlet UILabel *_errorLabel;
	
	NSString *_urlString;
	NSString *_articleTitle;
	NSString *_tinyURLString;
	NSString *_username;
	NSString *_password;
	UIColor *_baseColor;
	BOOL _negativeCharacters;
	BOOL _needsTinyURL;
	BOOL _hasError;
	BOOL _postComplete;
	BOOL _animating;
	CGFloat _animatedDistance;
	BOOL _rotating;
	BOOL _creatingTinyURL;
	NSInteger characterCount;
	id _postDelegate;
	
	UIInterfaceOrientation _orientation;
	BOOL _keyboardVisible;
	BOOL _textFieldIsResponder;
	BOOL _keyboardAdjusted;
	
	RSFetchTinyURLOperation *fetchTinyURLOperation;
	NSDictionary *twitterOauthAccessToken;
	NSString *consumerKey;
	NSString *consumerSecret;
	NSString *statusToSendToTwitter;
	BOOL waitingForTwitterAccessToken;
}

@property (nonatomic, retain) NSString *tinyURLString;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, retain) NSString *urlString;
@property (nonatomic, retain) NSString *articleTitle;
@property (nonatomic, assign) id postDelegate;

- (void)setInfoDict:(NSDictionary *)infoDict;
- (IBAction)postToTwitter:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

@end
