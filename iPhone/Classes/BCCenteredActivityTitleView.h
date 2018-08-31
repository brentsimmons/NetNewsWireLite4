//
//  BCCenteredActivityTitleView.h
//  bobcat
//
//  Created by Brent Simmons on 3/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BCCenteredActivityTitleView : UIView {
@protected
	UIActivityIndicatorView *_activityIndicator;
	NSInteger _offsetX;
}


@property (nonatomic, assign) NSInteger offsetX;

- (void)startActivity;
- (void)stopActivity;


@end
