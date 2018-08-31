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
#if !RS_IPAD
#import "NNWUpgrader.h"
#endif
#if RS_IPAD
#import "RSWhiteButton.h"
#endif

NSString *NNWDidPromptToAddDefaults = @"didPromptToAddDefaults";

@interface NSObject (NNWAddDefaultsViewController) 
- (void)defaultFeedsPromptDidEnd:(NNWAddDefaultsViewController *)viewController;
@end


@interface NNWAddDefaultsViewController ()
@property (assign) BOOL didAddDefaults;
@end


@implementation NNWAddDefaultsViewController

@synthesize didAddDefaults = _didAddDefaults;

- (id)initWithCallbackDelegate:(id)callbackDelegate {
#if RS_IPAD
	self = [self initWithNibName:@"AddDefaultsiPad" bundle:nil];
#else
	self = [self initWithNibName:@"AddDefaults" bundle:nil];
#endif
	if (!self)
		return nil;
	_callbackDelegate = callbackDelegate;
	return self;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
//	return interfaceOrientation == UIInterfaceOrientationPortrait;
}


- (void)viewDidLoad {
#if !RS_IPAD
	_cantUpgradeLabel.hidden = ![NNWUpgrader hasDatabase];
#endif
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NNWDidPromptToAddDefaults];
#if RS_IPAD
	RSSetupWhiteButton(_addDefaultFeedsButton);
	RSSetupWhiteButton(_dontAddDefaultFeedsButton);
#endif
}


#pragma mark Actions

- (IBAction)addDefaultFeeds:(id)sender {
	_addDefaultFeedsButton.hidden = YES;
	_dontAddDefaultFeedsButton.hidden = YES;
	[BCFeedbackHUDViewController displayWithMessage:@"Adding Default feeds" duration:0 useActivityIndicator:YES];
	[self performSelectorInBackground:@selector(subscribeToFeeds) withObject:nil];
}


- (void)didFinishAddingFeeds {
	[BCFeedbackHUDViewController closeWindow];
	self.didAddDefaults = YES;
	[_callbackDelegate defaultFeedsPromptDidEnd:self];
//	[_callbackDelegate.navigationController dismissModalViewControllerAnimated:YES];
}


- (IBAction)dontAddDefaultFeeds:(id)sender {
	self.didAddDefaults = NO;
	[_callbackDelegate defaultFeedsPromptDidEnd:self];
//	[_callbackDelegate.navigationController dismissModalViewControllerAnimated:YES];
}


#pragma mark Subscribing

- (void)subscribeToFeeds {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://taplynx.com/blog/feed/atom" title:@"TapLynx Blog" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://rss.macworld.com/macworld/feeds/main" title:@"Macworld" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://feeds.arstechnica.com/arstechnica/apple/" title:@"Ars Technica Infinite Loop" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://daringfireball.net/index.xml" title:@"Daring Fireball" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://blog.roguesheep.com/feed/" title:@"Inside RogueSheep" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://netnewswireapp.com/feed/" title:@"NetNewsWire Blog" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://inessential.com/xml/rss.xml" title:@"inessential.com" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://ranchero.com/xml/rss.xml" title:@"ranchero.com" folderName:nil];
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];	
	(void)[NNWGoogleAPI subscribeToFeed:@"http://gusmueller.com/blog/atom.xml" title:@"Gus's weblog" folderName:nil];
	[self performSelectorOnMainThread:@selector(didFinishAddingFeeds) withObject:nil waitUntilDone:NO];
	[pool drain];	
}


@end

