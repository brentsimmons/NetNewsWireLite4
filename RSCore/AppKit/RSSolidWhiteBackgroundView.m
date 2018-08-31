//
//  RSSolidWhiteBackgroundView.m
//  RancheroAppKit
//
//  Created by Brent Simmons on 1/15/06.
//  Copyright 2006 Ranchero Software. All rights reserved.
//

#import "RSSolidWhiteBackgroundView.h"


@implementation RSSolidWhiteBackgroundView


- (void)commonInit {
	[self setBackgroundColor:[NSColor whiteColor]];
	}
	

- (id)initWithFrame:(NSRect)r {
	if (![super initWithFrame:r])
		return nil;
	[self commonInit];
	return self;
	}


- (id)initWithCoder:(NSCoder *)coder {
	if (![super initWithCoder:coder])
		return nil;
	[self commonInit];
	return self;
	}
	
	
@end
