//
//  RSRefreshProtocols.h
//  padlynx
//
//  Created by Brent Simmons on 9/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSPluginProtocols.h"
#import "RSAbstractFeedParser.h"


typedef enum _RSAccountType {
	RSAccountTypeLocal, //On My Mac, iPad, etc. There is only one.
	RSAccountTypeGlobal, //all-unread, today, etc. There is only one.
	RSAccountTypeApplePubSub,
	RSAccountTypeGoogleReader,
	RSAccountTypeTwitter,
	RSAccountTypeFacebook,
	RSAccountTypePluginDefined
} RSAccountType;


@protocol RSAccount <NSObject>

/*Accounts must be accessed on the main thread only.*/

@required
@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, retain, readonly) NSString *identifier; //must be unique per account and never change for a given account
@property (nonatomic, retain) NSString *login; //username: okay to return nil if account doesn't have one
@property (nonatomic, retain, readonly) NSString *title; //human-readable: should be localized
@property (nonatomic, assign, readonly) NSInteger accountType;
@property (nonatomic, retain, readonly) NSArray *allFeedsThatCanBeRefreshed; //all downloadable, not-suspended feeds. NSURL array. (Or non-compound, non-mutable, thread-safe objects.)
@property (nonatomic, assign, readonly) NSUInteger unreadCount; //for everything in the account

- (BOOL)isSubscribedToFeedWithURL:(NSURL *)aFeedURL;

@end


/*Main thread only.*/

@protocol RSAccountRefresher <RSPlugin, NSObject>

@required
- (BOOL)wantsToRefreshAccount:(id<RSAccount>)account;
- (void)refreshAll:(id<RSAccount>)accountToRefresh operationController:(id)operationController;
- (void)refreshFeeds:(NSArray *)feedsToRefresh account:(id<RSAccount>)accountToRefresh operationController:(id)operationController;

@end

/*Main thread only.*/

@protocol RSFeedRefresher <RSPlugin, NSObject>

@required
- (BOOL)wantsToRefreshFeed:(id)feed accountToRefresh:(id<RSAccount>)accountToRefresh; //feed is usually an NSURL
- (void)refreshFeed:(id)feed account:(id<RSAccount>)accountToRefresh operationController:(id)operationController;

@end


/*The below runs in operations, in the background. Direct access to RSAccount is not allowed.*/

@protocol RSArticleSaver <RSPlugin, RSFeedParserDelegate, NSObject>

@required
- (id)initWithAccountIdentifier:(NSString *)accountIdentifier;

@end
