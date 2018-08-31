//
//  RSMenuItemWithURLString.m
//  nnw
//
//  Created by Brent Simmons on 12/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSMenuItemWithURLString.h"


@implementation RSMenuItemWithURLString

@synthesize urlString;


#pragma mark Dealloc

- (void)dealloc {
	[urlString release];
	[super dealloc];
}


@end
