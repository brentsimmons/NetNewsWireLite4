//
//  RSParsedFeedInfo.m
//  nnw
//
//  Created by Brent Simmons on 1/1/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSParsedFeedInfo.h"


NSString *RSDidParseFeedInfoNotification = @"RSDidParseFeedInfoNotification";


@implementation RSParsedFeedInfo

@synthesize feedURLString;
@synthesize homePageURLString;
@synthesize title;

#pragma mark Dealloc



- (void)sendDidParseFeedInfoNotification {
    [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSDidParseFeedInfoNotification object:self userInfo:nil];
}


@end
