//
//  NNWSubscribeRequest.m
//  nnw
//
//  Created by Brent Simmons on 1/5/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSubscribeRequest.h"


@implementation NNWSubscribeRequest

@synthesize account;
@synthesize backgroundWindow;
@synthesize feedURL;
@synthesize parentFolder;
@synthesize title;


- (void)dealloc {
	[account release];
	[backgroundWindow release];
	[feedURL release];
	[parentFolder release];
	[title release];
	[super dealloc];
}

@end
