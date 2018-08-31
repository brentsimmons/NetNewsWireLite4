//
//  NNWSubscriber.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWSubscriber.h"
#import "NNWSubscribeProgressWindowController.h"
#import "NNWSubscribeRequest.h"
#import "RSDataAccount.h"
#import "RSDownloadConstants.h"
#import "RSErrors.h"
#import "RSFeed.h"
#import "RSFolder.h"
#import "RSSingleStringParser.h"


NSString *NNWSubscribeDidSucceedNotification = @"NNWSubscribeDidSucceedNotification";
NSString *NNWSubscribeDidFailNotification = @"NNWSubscribeDidFailNotification";



@interface NNWSubscriber ()

@property (nonatomic, retain) NNWFeedFinder *feedFinder;
@property (nonatomic, retain, readwrite) NNWSubscribeRequest *subscribeRequest;
@property (nonatomic, retain, readwrite) NSError *error;
@property (nonatomic, retain, readwrite) NSString *password;
@property (nonatomic, retain, readwrite) NSString *username;
@property (nonatomic, retain, readwrite) NSURL *foundFeedURL;
@property (nonatomic, retain, readwrite) NSString *foundTitle;
@property (nonatomic, retain, readwrite) RSFeed *feedAdded;

- (void)addFeed;

@end


@implementation NNWSubscriber

@synthesize error;
@synthesize feedAdded;
@synthesize feedFinder;
@synthesize foundFeedURL;
@synthesize foundTitle;
@synthesize password;
@synthesize subscribeRequest;
@synthesize username;


#pragma mark Init

- (id)initWithSubscribeRequest:(NNWSubscribeRequest *)aSubscribeRequest {
	NSParameterAssert(aSubscribeRequest != nil);
	self = [super init];
	if (self == nil)
		return nil;
	subscribeRequest = [aSubscribeRequest retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[error release];
	[feedAdded release];
	[feedFinder release];
	[foundFeedURL release];
	[foundTitle release];
	[password release];
	[subscribeRequest release];
	[username release];
	[super dealloc];
}


#pragma mark Subscribe

- (void)subscribe {
	[NNWSubscribeProgressWindowController runWindowWithBackgroundWindow:self.subscribeRequest.backgroundWindow];
	self.feedFinder = [[[NNWFeedFinder alloc] initWithURL:self.subscribeRequest.feedURL delegate:self] autorelease];
	[self.feedFinder findFeed];	
}


#pragma mark Callback

- (void)_finish {
	self.feedFinder = nil;
	if (self.error == nil)
		[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:NNWSubscribeDidSucceedNotification object:self userInfo:nil];
	else
		[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:NNWSubscribeDidFailNotification object:self userInfo:nil];
}


#pragma mark FeedFinder Delegate

- (void)feedFinder:(NNWFeedFinder *)aFeedFinder didFindFeedAtURL:(NSURL *)url {

	self.foundFeedURL = url;
	self.username = aFeedFinder.username;
	self.password = aFeedFinder.password;
	
	if ([((RSDataAccount *)(self.subscribeRequest.account)) feedWithURL:url]) //already subscribed-to?
		self.error = [RSErrors errorWithCode:NNWSubscriberFailureAlreadySubscribed errorString:NSLocalizedStringFromTable(@"The feed is already in your Feeds list.", @"Subscribing", @"Error sheet")];
	
	else { //add to feeds list
		if (RSStringIsEmpty(self.subscribeRequest.title))
			self.foundTitle = RSParseSingleStringWithTag(self.feedFinder.responseBody, @"title"); //@"title" works for both RSS and Atom 
		[self addFeed];		
	}
	
	[NNWSubscribeProgressWindowController closeWindow];
	[self _finish];
}



- (void)feedFinder:(NNWFeedFinder *)feedFinder didFailWithError:(NSError *)anError {
	
	[NNWSubscribeProgressWindowController closeWindow];
	
	if (anError == nil) //no error means user-canceled
		self.error = [RSErrors errorWithCode:NNWSubscriberFailureUserCanceled errorString:@""];
	else {
		NSMutableDictionary *userInfoCopy = [[[anError userInfo] mutableCopy] autorelease];
		NSString *errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Can’t subscribe to feed because: %@", @"Subscribing", @"Subscribe error message"), [anError localizedDescription]];
		if (![errorMessage hasSuffix:@"."])
			errorMessage = [NSString stringWithFormat:@"%@.", errorMessage];
		[userInfoCopy setObject:errorMessage forKey:NSLocalizedDescriptionKey];
		self.error = [NSError errorWithDomain:[anError domain] code:NNWSubscriberFailureCouldNotFindFeed userInfo:userInfoCopy];		
	}
	
	[self _finish];
}


#pragma mark Subs List

- (void)addFeed {
	
	RSFeed *feed = [RSFeed feedWithURL:self.foundFeedURL account:self.subscribeRequest.account];
	
	feed.userSpecifiedName = self.subscribeRequest.title;
	feed.feedSpecifiedName = self.foundTitle;
	feed.username = self.username;
	feed.password = self.password;
	if (!RSStringIsEmpty(feed.password))
		[feed savePasswordInKeychain];
	
	[((RSDataAccount *)(self.subscribeRequest.account)) addFeed:feed atEndOfFolder:self.subscribeRequest.parentFolder];

	feed.needsToBeSavedOnDisk = YES;
	((RSDataAccount *)(self.subscribeRequest.account)).needsToBeSavedOnDisk = YES;
	
	self.feedAdded = feed;
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:feed forKey:NNWFeedKey];
	[userInfo setObject:feed.URL forKey:RSURLKey];
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:NNWFeedAddedNotification object:self userInfo:userInfo];
}


@end
