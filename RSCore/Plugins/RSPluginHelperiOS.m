//
//  RSPluginHelperiOS.m
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSPluginHelperiOS.h"
#import "RSAppDelegateProtocols.h"
#import "RSDataArticle.h"
#import "RSFeedbackHUDViewController.h"
#import "RSPluginObjects.h"


@implementation RSPluginHelperiOS

#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleDidDisplay:) name:RSDataArticleDidDisplayNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


#pragma mark Notifications

- (void)articleDidDisplay:(NSNotification *)note {
	[rs_app_delegate makeAppObserversPerformSelector:@selector(userDidViewItem:) withObject:[RSSharableItem sharableItemWithArticle:[note object]]];
}


#pragma mark NGPluginHelper protocol

- (void)startIndeterminateFeedbackWithTitle:(NSString *)title image:(UIImage *)image {
	
}


- (void)stopIndeterminateFeedback {
	
}


- (void)showSuccessMessageWithTitle:(NSString *)title image:(UIImage *)image {
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (window == nil)
		window = [[UIApplication sharedApplication].windows rs_safeObjectAtIndex:0];
	if (window == nil)
		return; //no windows should never happen
	[RSFeedbackHUDViewController displayWithMessage:title duration:3.5 useActivityIndicator:NO window:window];
}


- (void)presentError:(NSError *)error {
	[rs_app_delegate presentError:error];
}


/*Glue connecting sharing plugins to observers.*/

- (void)noteUserDidShareItem:(id<RSSharableItem>)sharableItem viaServiceIdentifier:(NSString *)serviceIdentifier {
	[rs_app_delegate makeAppObserversPerformSelector:@selector(userDidShareItem:serviceIdentifier:) withObject:sharableItem withObject:serviceIdentifier];
}


@end
