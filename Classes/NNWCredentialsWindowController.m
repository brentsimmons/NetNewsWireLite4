//
//  NNWCredentialsWindowController.m
//  nnw
//
//  Created by Brent Simmons on 12/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWCredentialsWindowController.h"


@implementation NNWCredentialsResult

@synthesize username;
@synthesize password;
@synthesize userDidCancel;


#pragma mark Dealloc

- (void)dealloc {
	[username release];
	[password release];
	[super dealloc];
}

@end


#pragma mark -


@interface NNWCredentialsWindowController ()

@property (assign) BOOL userDidCancel;
@end


@implementation NNWCredentialsWindowController

@synthesize imageView;
@synthesize messageTextField;
@synthesize password;
@synthesize passwordTextField;
@synthesize userDidCancel;
@synthesize username;
@synthesize usernameTextField;

#pragma mark Init

- (id)init {
	return [super initWithWindowNibName:@"Credentials"];
}


#pragma mark Dealloc

- (void)dealloc {
	[imageView release];
	[messageTextField release];
	[password release];
	[passwordTextField release];
	[username release];
	[usernameTextField release];
	[super dealloc];
}


#pragma mark Actions

- (void)cancel:(id)sender {
	self.userDidCancel = YES;
	[NSApp stopModal];
}


- (void)ok:(id)sender {
	[NSApp stopModal];
}


#pragma mark Modal

- (NNWCredentialsResult *)runModalForBackgroundWindow:(NSWindow *)aBackgroundWindow {
	
	if (rs_app_delegate.runningModalSheet)
		return nil;
	rs_app_delegate.runningModalSheet = YES;
	
	[NSApp beginSheet:[self window] modalForWindow:aBackgroundWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:[self window]];
	
	NNWCredentialsResult *credentialsResult = [[[NNWCredentialsResult alloc] init] autorelease];
	credentialsResult.userDidCancel = self.userDidCancel;
	credentialsResult.username = [[[self.usernameTextField stringValue] copy] autorelease];
	credentialsResult.password = [[[self.passwordTextField stringValue] copy] autorelease];
	
	[NSApp endSheet:[self window]];
	[[self window] orderOut:self];
	rs_app_delegate.runningModalSheet = NO;
	
	return credentialsResult;
}


@end
