//
//  RSLocalAccountStreamingArticleSaver.m
//  padlynx
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSLocalAccountStreamingArticleSaver.h"
#import "RSRefreshProtocols.h"
#import "RSLocalAccountCoreDataArticleSaverOperation.h"
#import "RSParsedNewsItem.h"


@interface RSLocalAccountStreamingArticleSaver ()
@property (nonatomic, retain) id<RSAccount> account;
@property (nonatomic, retain) NSMutableArray *heldItems;
@property (nonatomic, retain) id<RSFeedSpecifier> feedSpecifier;
@end


@implementation RSLocalAccountStreamingArticleSaver

@synthesize account;
@synthesize heldItems;
@synthesize feedSpecifier;


#pragma mark Init

- (id)initWithAccount:(id<RSAccount>)anAccount feedSpecifier:(id<RSFeedSpecifier>)aFeedSpecifier {
	self = [super init];
	if (self == nil)
		return nil;
	account = [(id)anAccount retain];
	heldItems = [[NSMutableArray array] retain];
	feedSpecifier = [(id)aFeedSpecifier retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[(id)account release];
	[heldItems release];
	[(id)feedSpecifier release];
	[super dealloc];
}


#pragma mark Saving

- (void)saveHeldItems {
	/*Create an operation on the special serial Core Data Queue for saving news items.*/
	RSLocalAccountCoreDataArticleSaverOperation *localAccountCoreDataArticleSaverOperation = [[[RSLocalAccountCoreDataArticleSaverOperation alloc] initWithParsedArticles:self.heldItems feedSpecifier:self.feedSpecifier account:self.account] autorelease];
	[rs_app_delegate addCoreDataBackgroundOperation:localAccountCoreDataArticleSaverOperation];
}


#pragma mark Parser Delegate

- (void)feedParserDidComplete:(id)feedParser {
	if ([self.heldItems count] > 0)
		[self saveHeldItems];
	self.heldItems = nil;
}


- (BOOL)feedParser:(id)feedParser didParseNewsItem:(RSParsedNewsItem *)newsItem {
	[self.heldItems rs_safeAddObject:newsItem];
	if ([self.heldItems count] >= 10) {
		[self saveHeldItems];
		self.heldItems = [NSMutableArray array];
	}
	return YES;
}



@end
