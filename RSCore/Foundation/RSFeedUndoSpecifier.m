//
//  RSFeedUndoSpecifier.m
//  nnw
//
//  Created by Brent Simmons on 1/23/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeedUndoSpecifier.h"


@implementation RSFeedUndoSpecifier

@synthesize articleIDsMarkedForDeletion;
@synthesize feed;
@synthesize folderName;


#pragma mark Dealloc

- (void)dealloc {
	[articleIDsMarkedForDeletion release];
	[feed release];
	[folderName release];
	[super dealloc];
}


@end
