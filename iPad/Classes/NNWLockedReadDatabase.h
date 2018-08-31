//
//  NNWLockedReadDatabase.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWSQLite3DatabaseController.h"


@interface NNWLockedReadDatabase : NNWSQLite3DatabaseController {
}


+ (NNWLockedReadDatabase *)sharedController;

- (BOOL)googleItemIDIsLockedRead:(NSString *)googleItemID;
- (void)addLockedReadGoogleItemID:(NSString *)googleItemID;
- (void)removeLockedReadItemsFromLongItemIDs:(NSMutableArray *)googleItemIDs;

- (void)runAddLockedReadGoogleItemIDsAsOperation:(NSArray *)googleItemIDs;
- (void)removeLockedItemsFromSet:(NSMutableSet *)itemIDs;


@end
