//
//  NGFeedSpecifier.m
//  RSCoreTests
//
//  Created by Brent Simmons on 9/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NGFeedSpecifier.h"
#import "RSDataAccount.h"
#import "RSFeed.h"
#import "RSDownloadConstants.h"


//static CFMutableDictionaryRef gFeedSpecifiers = nil; //dictionary that doesn't copy keys: saves memory
//static pthread_mutex_t gFeedSpecifiersLock;


@interface NGFeedSpecifier ()

@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, retain, readwrite) id<NGAccount> account;
@property (nonatomic, retain, readwrite) NSString *lastModifiedHeader;
@property (nonatomic, retain, readwrite) NSString *etagHeader;
@property (nonatomic, retain, readwrite) RSFeed *feed;
@end

@implementation NGFeedSpecifier

@synthesize URL;
@synthesize account;
@synthesize name;
@synthesize homePageURL;
@synthesize deleted;
@synthesize lastModifiedHeader;
@synthesize etagHeader;
@synthesize feed;


#pragma mark Class Methods

//+ (void)initialize {
//	@synchronized([NGFeedSpecifier class]) {
//		if (gFeedSpecifiers == nil) {
//			initLockOrExit(&gFeedSpecifiersLock, @"Couldn't create feed specifiers lock.");
//			gFeedSpecifiers = CFDictionaryCreateMutable(kCFAllocatorDefault, 20, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//		}
//	}
//}


+ (id<NGFeedSpecifier>)feedSpecifierWithName:(NSString *)feedName feedURL:(NSURL *)feedURL feedHomePageURL:(NSURL *)feedHomePageURL account:(id<NGAccount>)anAccount {
	NGFeedSpecifier *feedSpecifier = nil;
//	lockOrExit(&gFeedSpecifiersLock, @"Couldn't lock feed specifiers lock.");
//	CFMutableDictionaryRef accountDictionary = (CFMutableDictionaryRef)CFDictionaryGetValue(gFeedSpecifiers, (CFStringRef)(anAccount.identifier));
//	if (accountDictionary == nil) {
//		accountDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//		CFDictionarySetValue(gFeedSpecifiers, (CFStringRef)(anAccount.identifier), accountDictionary);
//	}
//	feedSpecifier = (NGFeedSpecifier *)CFDictionaryGetValue(accountDictionary, (CFURLRef)feedURL);
	if (feedSpecifier == nil) {
		feedSpecifier = [[[NGFeedSpecifier alloc] init] autorelease];
		feedSpecifier.name = feedName;
		feedSpecifier.URL = feedURL;
		feedSpecifier.homePageURL = feedHomePageURL;
		feedSpecifier.account = anAccount;
		//CFDictionarySetValue(accountDictionary, (CFURLRef)feedSpecifier.URL, feedSpecifier);
	}
//	unlockOrExit(&gFeedSpecifiersLock, @"Couldn't unlock feed specifiers lock.");
	return feedSpecifier;
}


+ (id<NGFeedSpecifier>)feedSpecifierWithFeed:(RSFeed *)aFeed {
	NGFeedSpecifier *feedSpecifier = [[[NGFeedSpecifier alloc] init] autorelease];
	feedSpecifier.name = aFeed.userSpecifiedName;
	if (RSStringIsEmpty(feedSpecifier.name))
		feedSpecifier.name = aFeed.feedSpecifiedName;
	if (RSStringIsEmpty(feedSpecifier.name))
		feedSpecifier.name = NSLocalizedString(@"Untitled Feed", @"Feeds");
	feedSpecifier.URL = aFeed.URL;
	feedSpecifier.homePageURL = aFeed.homePageURL;
	feedSpecifier.account = aFeed.account;
	feedSpecifier.lastModifiedHeader = aFeed.httpLastModifiedResponse;
	feedSpecifier.etagHeader = aFeed.httpEtagResponse;
	feedSpecifier.feed = aFeed;
	return feedSpecifier;
}


#pragma mark Dealloc

- (void)dealloc {
	[URL release];
	[name release];
	[homePageURL release];
	[account release];
	[lastModifiedHeader release];
	[etagHeader release];
	[feed release];
	[super dealloc];
}


#pragma mark -

- (NSString *)description {
	return [NSString stringWithFormat:@"NGFeedSpecifier: %@ '%@' %@ %@", self.URL, self.name, self.homePageURL, self.account];
}


#pragma mark Values

- (void)updateWithValuesFromFeed {
	if (self.feed == nil || self.account == nil)
		return;
	RSDataAccount *feedAccount = (RSDataAccount *)(self.account);
	[feedAccount lockAccount];
	self.name = self.feed.userSpecifiedName;
	if (RSStringIsEmpty(self.name))
		self.name = self.feed.feedSpecifiedName;
	if (RSStringIsEmpty(self.name))
		self.name = NSLocalizedString(@"Untitled Feed", @"Feeds");
	self.homePageURL = self.feed.homePageURL;
	self.lastModifiedHeader = self.feed.httpLastModifiedResponse;
	self.etagHeader = self.feed.httpEtagResponse;
	[feedAccount unlockAccount];
}


#pragma mark Feed

- (void)saveCheckDate:(NSDate *)checkDate andConditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo {
	if (!self.feed)
		self.feed = [(RSDataAccount *)(self.account) feedWithURL:self.URL];
	if (!self.feed)
		return; //shouldn't happen
	if ([self.account respondsToSelector:@selector(lockAccount)])
		[(RSDataAccount *)(self.account) lockAccount];
	self.feed.lastChecked = checkDate;
	self.feed.httpEtagResponse = conditionalGetInfo.httpResponseEtag;
	self.feed.httpLastModifiedResponse = conditionalGetInfo.httpResponseLastModified;
	[self.feed markAsNeedsToBeSaved];
	if ([self.account respondsToSelector:@selector(unlockAccount)])
		[(RSDataAccount *)(self.account) unlockAccount];
}


#pragma mark Conditional 

- (NSString *)logicalLastModifiedHeader {
	return self.lastModifiedHeader; //TODO
}


- (NSString *)logicalEtagHeader {
	return self.etagHeader; //TODO
}

@end
