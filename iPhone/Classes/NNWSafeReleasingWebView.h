//
//  NNWSafeReleasingWebView.h
//  nnwiphone
//
//  Created by Brent Simmons on 9/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface NNWSafeReleasingWebView : UIWebView

- (void)releaseSafelyToWorkAroundOddWebKitCrashes;

@end
