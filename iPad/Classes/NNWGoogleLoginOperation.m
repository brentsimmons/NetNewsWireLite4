//
//  NNWGoogleLoginOperation.m
//  nnwiphone
//
//  Created by Brent Simmons on 11/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWGoogleLoginOperation.h"
#import "NNWGoogleLoginController.h"


@interface NNWGoogleLoginOperation ()
@property (nonatomic, assign, readwrite) NSInteger statusCode;
@end

@implementation NNWGoogleLoginOperation

@synthesize statusCode;

- (void)main {
	self.statusCode = [[NNWGoogleLoginController sharedController] synchronousLogin];
	[super main];
}


@end
