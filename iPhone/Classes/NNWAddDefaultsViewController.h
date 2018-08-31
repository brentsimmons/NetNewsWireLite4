//
//  NNWAddDefaultsViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 9/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *NNWDidPromptToAddDefaults;


@interface NNWAddDefaultsViewController : UIViewController {
@private
	IBOutlet UILabel *_cantUpgradeLabel;
	IBOutlet UIButton *_addDefaultFeedsButton;
	IBOutlet UIButton *_dontAddDefaultFeedsButton;
	IBOutlet UILabel *_addingFeedsLabel;
	IBOutlet UIActivityIndicatorView *_activityIndicator;
	UIViewController *_callbackDelegate;
	BOOL _didAddDefaults;
}

@property (assign, readonly) BOOL didAddDefaults;

- (id)initWithCallbackDelegate:(UIViewController *)callbackDelegate;
- (IBAction)addDefaultFeeds:(id)sender;
- (IBAction)dontAddDefaultFeeds:(id)sender;


@end
