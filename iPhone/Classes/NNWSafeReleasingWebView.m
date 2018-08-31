//
//  NNWSafeReleasingWebView.m
//  nnwiphone
//
//  Created by Brent Simmons on 9/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NNWSafeReleasingWebView.h"


@implementation NNWSafeReleasingWebView

- (void)releaseSafelyToWorkAroundOddWebKitCrashes {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(releaseSafelyToWorkAroundOddWebKitCrashes) withObject:nil waitUntilDone:NO];
		return;
	}
	self.delegate = nil;
	[self stopLoading];
	[self performSelector:@selector(autorelease) withObject:nil afterDelay:4.0];
}


@end
