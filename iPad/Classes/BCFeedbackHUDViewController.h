//
//  BCFeedbackHUDViewController.h
//  bobcat
//
//  Created by Brent Simmons on 3/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BCFeedbackHUDViewController : UIViewController {
@protected
	NSString *_message;
	NSTimeInterval _duration;
	NSTimer *_timer;
	UIActivityIndicatorView *_activityIndicator;
	BOOL _useActivityIndicator;
}


+ (BCFeedbackHUDViewController *)displayWithMessage:(NSString *)message duration:(NSTimeInterval)duration useActivityIndicator:(BOOL)useActivityIndicator;
+ (void)closeWindow;


@end
