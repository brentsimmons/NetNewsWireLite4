//
//  NNWWebPageViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "RSContainerViewProtocols.h"


@class NGModalViewPresenter;
@class NNWWebPageToolbarView;
@class NNWBrowserAddressTextField;


@interface NNWWebPageViewController : UIViewController <RSContentViewController, UITextFieldDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
@private
	UIToolbar *toolbar;
	UIWebView *webView;
	UITextField *addressField;
	UIBarButtonItem *popoverItem;
	UIBarButtonItem *backForwardButtonsItem;
	UIButton *backButton;
	UIButton *forwardButton;
	UIBarButtonItem *addressFieldItem;
	UIBarButtonItem *actionMenuItem;	
	NSInteger _emailMenuItemIndex;
	NSInteger _postToTwitterMenuItemIndex;
	NSInteger _openInSafariMenuItemIndex;
	NSInteger _sendToInstapaperMenuItemIndex;
	BOOL showingActionSheet;
	UIBarButtonItem *activityIndicatorButtonItem;
	UIBarButtonItem *flexibleSpaceItem;
	UIButton *actionMenuButton;
	NGModalViewPresenter *modalViewPresenter;
	UIActionSheet *actionSheet;
	id representedObject;
	NNWWebPageToolbarView *webPageToolbarView;
	UIBarButtonItem *barButtonContainer;
	UIActivityIndicatorView *activityIndicator;
}


@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UITextField *addressField;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *popoverItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backForwardButtonsItem;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *forwardButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *addressFieldItem;
@property (nonatomic, retain) UIBarButtonItem *actionMenuItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *flexibleSpaceItem;
@property (nonatomic, retain) IBOutlet UIButton *actionMenuButton;

@property (nonatomic, retain) IBOutlet NNWWebPageToolbarView *webPageToolbarView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonContainer;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)showActionMenu:(id)sender;

- (void)loadURL:(NSURL *)url;

- (void)restoreState;

@end


@interface NNWWebPageToolbarView : UIView {
@private
	UIView *backForwardButtonsContainer;
	UIButton *backButton;
	UIButton *forwardButton;
	NNWBrowserAddressTextField *browserAddressTextField;
	UIActivityIndicatorView *activityIndicator;
	UIButton *actionMenuButton;
	BOOL didConfigureButtons;
}


@property (nonatomic, retain) IBOutlet UIView *backForwardButtonsContainer;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *forwardButton;
@property (nonatomic, retain) IBOutlet NNWBrowserAddressTextField *browserAddressTextField;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UIButton *actionMenuButton;


@end
