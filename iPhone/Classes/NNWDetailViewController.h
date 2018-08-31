//
//  NNWDetailViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@class NNWNewsItemProxy, NNWNewsItem, NNWNewsViewController, BCCenteredActivityTitleView;

@interface NNWDetailViewController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate> {
@private
	UIWebView *_webView;
	NNWNewsItemProxy *_newsItemProxy;
	NNWNewsItem *_newsItem;
	NSString *_lastHTMLString;
	BOOL _loadingWebPage;
	UIBarButtonItem *_starToolbarItem;
	UIBarButtonItem *_actionMenuToolbarItem;
	UIBarButtonItem *_nextUnreadToolbarItem;
	UISegmentedControl *_upDownControl;
	NSInteger _emailMenuItemIndex;
	NSInteger _postToTwitterMenuItemIndex;
	NSInteger _openInSafariMenuItemIndex;
	NSInteger _sendToInstapaperMenuItemIndex;
	BOOL _actionSheetShowing;
	NNWNewsViewController *_newsViewController;
	BCCenteredActivityTitleView *_activityContainerView;
	BOOL needsLoadWhenAppearsNext;
}


- (id)initWithNewsItemProxy:(NNWNewsItemProxy *)newsItemProxy;
- (void)loadHTML;

+ (NNWDetailViewController *)viewControllerWithState:(NSDictionary *)state;

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NNWNewsItemProxy *newsItemProxy;
@property (nonatomic, retain) NNWNewsItem *newsItem;
@property (nonatomic, assign) NNWNewsViewController *newsViewController;

@end

