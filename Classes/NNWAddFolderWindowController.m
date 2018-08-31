//
//  NNWAddFolderViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFolderWindowController.h"
#import "RSDataAccount.h"


@implementation NNWAddFolderWindowController

@synthesize folderNameTextField;


#pragma mark Init

- (id)init {
	return [self initWithWindowNibName:@"AddFolder"];
}


#pragma mark Dealloc

- (void)dealloc {
	[folderNameTextField release];
	[super dealloc];
}


#pragma mark Actions

- (void)cancel:(id)sender {
	[NSApp stopModal];
}


- (void)addFolder:(id)sender {
	NSString *folderName = [[[self.folderNameTextField stringValue] copy] autorelease];
	if (RSStringIsEmpty(folderName)) {
		[NSApp stopModal];
		return;
	}
	if ([[RSDataAccount localAccount] folderWithNameExists:folderName])
		return; //TODO: validation so we don't get to this position
	[[RSDataAccount localAccount] addFolderWithName:folderName];
	[RSDataAccount localAccount].needsToBeSavedOnDisk = YES;
	[NSApp stopModal];
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:NNWFolderAddedNotification object:self userInfo:[NSDictionary dictionaryWithObject:folderName forKey:RSNameKey]];
}


@end
