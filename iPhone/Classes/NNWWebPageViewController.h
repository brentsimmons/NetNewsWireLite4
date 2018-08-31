//
//  NNWWebPageViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@class BCNavTitleView, BCCenteredActivityTitleView;

@interface NNWWebPageViewController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate> {
@private
	NSURLRequest *_initialRequest;
	UIWebView *_webView;
	BOOL _loadingWebPage;
	NSInteger _emailMenuItemIndex;
	NSInteger _postToTwitterMenuItemIndex;
	NSInteger _openInSafariMenuItemIndex;
	NSInteger _sendToInstapaperMenuItemIndex;
	BOOL _actionSheetShowing;
	UIBarButtonItem *_goBackToolbarItem;
	UIBarButtonItem *_goForwardToolbarItem;
	UIBarButtonItem *_actionMenuToolbarItem;
	UILabel *_titleLabel;
	BCNavTitleView *_titleViewContainer;
	UIActivityIndicatorView *_activityIndicator;
}

- (id)initWithURLRequest:(NSURLRequest *)request;
- (void)loadHTML;

+ (NNWWebPageViewController *)viewControllerWithState:(NSDictionary *)state;

@end
