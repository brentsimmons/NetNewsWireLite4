//
//  RSFolderUndoSpecifier.m
//  nnw
//
//  Created by Brent Simmons on 1/23/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFolderUndoSpecifier.h"


@implementation RSFolderUndoSpecifier

@synthesize accountID;
@synthesize folderName;


#pragma mark Dealloc

- (void)dealloc {
	[accountID release];
	[folderName release];
	[super dealloc];
}

@end
