//
//  RSFeedSpecifier.m
//  RSCoreTests
//
//  Created by Brent Simmons on 9/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeedSpecifier.h"
#import "RSDataAccount.h"
#import "RSFeed.h"


@interface RSFeedSpecifier ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, retain, readwrite) NSURL *homePageURL;
@property (nonatomic, retain, readwrite) id<RSAccount> account;
@end


@implementation RSFeedSpecifier

@synthesize URL;
@synthesize account;
@synthesize name;
@synthesize homePageURL;


#pragma mark Class Methods


+ (id<RSFeedSpecifier>)feedSpecifierWithName:(NSString *)feedName feedURL:(NSURL *)feedURL feedHomePageURL:(NSURL *)feedHomePageURL account:(id<RSAccount>)anAccount {
	RSFeedSpecifier *feedSpecifier = nil;
	if (feedSpecifier == nil) {
		feedSpecifier = [[[RSFeedSpecifier alloc] init] autorelease];
		feedSpecifier.name = feedName;
		feedSpecifier.URL = feedURL;
		feedSpecifier.homePageURL = feedHomePageURL;
		feedSpecifier.account = anAccount;
	}
	return feedSpecifier;
}


+ (id<RSFeedSpecifier>)feedSpecifierWithFeed:(RSFeed *)aFeed {
	RSFeedSpecifier *feedSpecifier = [[[RSFeedSpecifier alloc] init] autorelease];
	feedSpecifier.name = aFeed.userSpecifiedName;
	if (RSStringIsEmpty(feedSpecifier.name))
		feedSpecifier.name = aFeed.feedSpecifiedName;
	if (RSStringIsEmpty(feedSpecifier.name))
		feedSpecifier.name = NSLocalizedString(@"Untitled Feed", @"Feeds");
	feedSpecifier.URL = aFeed.URL;
	feedSpecifier.homePageURL = aFeed.homePageURL;
	feedSpecifier.account = aFeed.account;
	return feedSpecifier;
}


#pragma mark Dealloc

- (void)dealloc {
	[URL release];
	[name release];
	[homePageURL release];
	[account release];
	[super dealloc];
}


#pragma mark -

- (NSString *)description {
	return [NSString stringWithFormat:@"RSFeedSpecifier: %@ '%@' %@ %@", self.URL, self.name, self.homePageURL, self.account];
}


@end

