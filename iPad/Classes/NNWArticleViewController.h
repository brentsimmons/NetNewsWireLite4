//
//  NNWArticleViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "RSContainerViewProtocols.h"


@class NNWNewsItemProxy, NGModalViewPresenter;

@interface NNWArticleViewController : UIViewController <RSContentViewController, RSUserSelectedObjectSource, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
@private
	id representedObject;
	UIWebView *webView;
	NNWNewsItemProxy *newsItem;
	NSString *html;
	NSURL *baseURL;
	UIBarButtonItem *popoverItem;
	UIBarButtonItem *upDownButtonsItem;
	UIButton *upButton;
	UIButton *downButton;
	UIBarButtonItem *flexibleSpaceItem;
	UIBarButtonItem *actionMenuItem;
	UIBarButtonItem *starItem;
	UIBarButtonItem *nextUnreadItem;
	NSInteger _emailMenuItemIndex;
	NSInteger _postToTwitterMenuItemIndex;
	NSInteger _openInSafariMenuItemIndex;
	NSInteger _sendToInstapaperMenuItemIndex;
	BOOL showingActionSheet;
	UIActionSheet *actionSheet;
	NGModalViewPresenter *modalViewPresenter;
	UIButton *nextUnreadButton;
	UIBarButtonItem *fixedSpaceItem;
	UIButton *actionMenuButton;
	id userSelectedObject;
}


@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) NNWNewsItemProxy *newsItem; /*Updates display on change*/

@property (nonatomic, retain) IBOutlet UIBarButtonItem *popoverItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *upDownButtonsItem;
@property (nonatomic, retain) IBOutlet UIButton *upButton;
@property (nonatomic, retain) IBOutlet UIButton *downButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *flexibleSpaceItem;
@property (nonatomic, retain) UIButton *actionMenuButton;
@property (nonatomic, retain) UIBarButtonItem *actionMenuItem;
@property (nonatomic, retain) UIBarButtonItem *starItem;
@property (nonatomic, retain) UIBarButtonItem *nextUnreadItem;
@property (nonatomic, retain) UIButton *nextUnreadButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *fixedSpaceItem;

- (IBAction)goUp:(id)sender;
- (IBAction)goDown:(id)sender;
- (IBAction)showActionMenu:(id)sender;
- (IBAction)toggleStar:(id)sender;
- (IBAction)gotoNextUnread:(id)sender;


@end


@interface NNWArticleContainerView : UIView {
}


@end
