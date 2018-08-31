//
//  BCFeedbackHUDViewController.h
//  bobcat
//
//  Created by Brent Simmons on 3/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


/*TODO: review this code. It's weird.*/

@interface RSFeedbackHUDViewController : UIViewController {
@protected
	NSString *_message;
	NSTimeInterval _duration;
	NSTimer *_timer;
	UIActivityIndicatorView *_activityIndicator;
	BOOL _useActivityIndicator;
	UIWindow *window;
}


+ (RSFeedbackHUDViewController *)displayWithMessage:(NSString *)message duration:(NSTimeInterval)duration useActivityIndicator:(BOOL)useActivityIndicator window:(UIWindow *)aWindow;
+ (void)closeWindow;


@end
