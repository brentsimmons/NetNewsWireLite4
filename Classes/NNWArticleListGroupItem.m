//
//  NNWArticleListGroupItem.m
//  nnw
//
//  Created by Brent Simmons on 12/27/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleListGroupItem.h"


@implementation NNWArticleListGroupItem

@synthesize title;

#pragma mark Dealloc

- (void)dealloc {
	[title release];
	[super dealloc];
}

@end
