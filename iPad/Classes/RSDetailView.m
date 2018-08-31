//
//  RSDetailView.m
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDetailView.h"
#import "RSDetailContainerView.h"


@implementation RSDetailView

@synthesize toolbar;
@synthesize detailContainerView;


#pragma mark Dealloc

- (void)dealloc {
	[toolbar release];
	[detailContainerView release];
	[super dealloc];
}


@end
