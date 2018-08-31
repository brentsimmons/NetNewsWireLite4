//
//  NGFeedSpecifier.h
//  RSCoreTests
//
//  Created by Brent Simmons on 9/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLPluginProtocols.h"
#import "NGRefreshProtocols.h"


/*Thread-safe, as long as you create these with feedSpecifierWithName.*/

@class RSFeed;
@class RSHTTPConditionalGetInfo;

@interface NGFeedSpecifier : NSObject <NGFeedSpecifier> {
@private
	NSURL *URL;
	id<NGAccount> account;
	NSString *name;
	NSURL *homePageURL;
//	NSString *logicalLastModifiedHeader;
//	NSString *logicalEtagHeader;
	BOOL deleted;
	RSFeed *feed;
}

/*They're uniqued by feedURL and account. You can see if two NGFeedSpecifiers are equal using ==.*/

+ (id<NGFeedSpecifier>)feedSpecifierWithName:(NSString *)feedName feedURL:(NSURL *)feedURL feedHomePageURL:(NSURL *)feedHomePageURL account:(id<NGAccount>)anAccount;
+ (id<NGFeedSpecifier>)feedSpecifierWithFeed:(RSFeed *)aFeed;


@property (nonatomic, retain, readonly) NSURL *URL;
@property (nonatomic, retain, readonly) id<NGAccount> account;

@property (nonatomic, retain, retain) NSString *name;
@property (nonatomic, retain, retain) NSURL *homePageURL;
@property (nonatomic, assign) BOOL deleted;
@property (nonatomic, retain, readonly) NSString *lastModifiedHeader;
@property (nonatomic, retain, readonly) NSString *etagHeader;

@property (nonatomic, retain, readonly) NSString *logicalLastModifiedHeader;
@property (nonatomic, retain, readonly) NSString *logicalEtagHeader;

- (void)saveCheckDate:(NSDate *)checkDate andConditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo;
- (void)updateWithValuesFromFeed;

@end
