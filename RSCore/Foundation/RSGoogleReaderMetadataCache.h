//
//  RSGoogleMetadataCache.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSSQLiteDatabaseController.h"


@interface RSGoogleReaderMetadataCache : RSSQLiteDatabaseController {
@private
	pthread_mutex_t databaseLock;
}

+ (RSGoogleReaderMetadataCache *)sharedCache;


- (void)saveLockedReadGoogleItemIDs:(NSArray *)googleItemIDs;
- (void)saveDownloadedGoogleItemIDs:(NSArray *)googleItemIDs;

- (void)removeLockedAndDownloadedItemsFromSet:(NSMutableSet *)shortItemIDs;


@end
