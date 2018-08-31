//
//  NNWAddDefaultsViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 9/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWAddDefaultsViewController.h"
#import "BCFeedbackHUDViewController.h"
#import "NNWGoogleAPI.h"
#import "NNWUpgrader.h"


NSString *NNWDidPromptToAddDefaults = @"didPromptToAddDefaults";

@interface NSObject (NNWAddDefaultsViewController) 
- (void)defaultFeedsPromptDidEnd:(NNWAddDefaultsViewController *)viewController;
@end


@interface NNWAddDefaultsViewController ()
@property (assign) BOOL didAddDefaults;
@end


@implementation NNWAddDefaultsViewController

@synthesize didAddDefaults = _didAddDefaults;

- (id)initWithCallbackDelegate:(UIViewController *)callbackDelegate {
	self = [self initWithNibName:@"AddDefaults" bundle:nil];
	if (!self)
		return nil;
	_callbackDelegate = callbackDelegate;
	return self;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}


- (void)viewDidLoad {
	_cantUpgradeLabel.hidden = ![NNWUpgrader hasDatabase];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NNWDidPromptToAddDefaults];
}


#pragma mark Actions

- (IBAction)addDefaultFeeds:(id)sender {
	_addDefaultFeedsButton.hidden = YES;
	//_addingFeedsLabel.center = _addDefaultFeedsButton.center;
//	[_activityIndicator startAnimating];
//	_activityIndicator.hidden = NO;
	_dontAddDefaultFeedsButton.hidden = YES;
//	_addingFeedsLabel.hidden = NO;
	[BCFeedbackHUDViewController displayWithMessage:@"Adding Default feeds" duration:0 useActivityIndicator:YES];
	[self performSelectorInBackground:@selector(subscribeToFeeds) withObject:nil];
}


- (void)didFinishAddingFeeds {
	[BCFeedbackHUDViewController closeWindow];
	self.didAddDefaults = YES;
	[_callbackDelegate defaultFeedsPromptDidEnd:self];
	[_callbackDelegate.navigationController dismissModalViewControllerAnimated:YES];
}


- (IBAction)dontAddDefaultFeeds:(id)sender {
	self.didAddDefaults = NO;
	[_callbackDelegate defaultFeedsPromptDidEnd:self];
	[_callbackDelegate.navigationController dismissModalViewControllerAnimated:YES];
}


#pragma mark Subscribing

- (void)subscribeToFeeds {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	NNWHTTPResponse *response = [NNWGoogleAPI subscribeToFeed:@"http://taplynx.com/blog/feed/atom" title:@"TapLynx Blog" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	response = [NNWGoogleAPI subscribeToFeed:@"http://feeds.feedburner.com/NickBradbury" title:@"Nick Bradbury" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	response = [NNWGoogleAPI subscribeToFeed:@"http://ranchero.com/xml/rss.xml" title:@"ranchero.com" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	response = [NNWGoogleAPI subscribeToFeed:@"http://daringfireball.net/index.xml" title:@"Daring Fireball" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	response = [NNWGoogleAPI subscribeToFeed:@"http://gusmueller.com/blog/atom.xml" title:@"Gus's weblog" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	response = [NNWGoogleAPI subscribeToFeed:@"http://feeds.arstechnica.com/arstechnica/apple/" title:@"Ars Technica Infinite Loop" folderName:nil];
	[self performSelectorOnMainThread:@selector(didFinishAddingFeeds) withObject:nil waitUntilDone:NO];
	[pool drain];	
}


@end

