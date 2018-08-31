//
//  RSConfigDataFeedSyncer.h
//  RSCoreTests
//
//  Created by Brent Simmons on 9/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NGRefreshProtocols.h"


/*Makes sure that the feeds in storage include the feeds from the config file.
 Deletes feeds that no longer exist in the config file.
 (Well, okay, it can be used more generally in the future if need be.
 But then the name should probably be changed.)
 
 The word "sync" just refers to making sure feed storage reflects
 the config data. Nothing to do with syncing via GR or whatever.*/

@class RSDataAccount;

@interface RSConfigDataFeedSyncer : NSObject {
@private
	NSArray *configFeedURLs;
	RSDataAccount *account;
}


@property (nonatomic, retain) NSArray *configFeedURLs;
@property (nonatomic, retain) RSDataAccount *account;

- (BOOL)syncStoredFeedsWithConfigFeeds;


@end
