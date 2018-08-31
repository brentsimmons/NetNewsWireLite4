//
//  NNWAddFeedsSeparator.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedsSeparator.h"


@interface NNWAddFeedsSeparator ()

@property (nonatomic, retain) NSView *view;
@end


@implementation NNWAddFeedsSeparator

#pragma mark Init

- (id)initWithTitle:(NSString *)aTitle {
	self = [super init];
	if (self == nil)
		return nil;
	windowTitle = [aTitle retain];
	return self;
}


- (BOOL)isGroupItem {
	return YES;
}


@end
