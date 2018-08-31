//
//  RSLocalAccountFeedMetadataCache.h
//  nnw
//
//  Created by Brent Simmons on 12/17/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSSQLiteDatabaseController.h"


/*The database gets deleted every n days, so that feeds with broken conditional get implementations
 still get refreshed eventually, even if late.*/

/*Thread-safe. Uses locks around database access.*/

@class RSHTTPConditionalGetInfo;


@interface RSLocalAccountFeedMetadataCache : RSSQLiteDatabaseController {
@private
	pthread_mutex_t databaseLock;
}


+ (RSLocalAccountFeedMetadataCache *)sharedCache;

- (RSHTTPConditionalGetInfo *)conditionalGetInfoForFeedURL:(NSURL *)feedURL;

/*Setting is asynchronous. You can do a set, then a get, and not get what you set.
 The theory is that that would be an extraordinarily rare thing to want to do --
 it's okay to set the conditional get info lazily, low-priority, in the background,
 because the very worst case is just re-downloading a feed instead of getting a 304.*/

- (void)setConditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo forFeedURL:(NSURL *)feedURL;

- (NSData *)contentHashForFeedURL:(NSURL *)feedURL;
- (void)setContentHash:(NSData *)contentHash forFeedURL:(NSURL *)feedURL; //setting is asynchronous here too

- (void)deleteInfoForFeedURL:(NSURL *)feedURL; //asynchronous, high-priority

@end


