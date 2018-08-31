//
//  NNWGoogleProcessStarredItemIDsOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"


@interface NNWProcessStarredItemIDsOperation : RSOperation {
@private
	NSArray *starredItemIDs;
	NSArray *itemIDsToDownload; /*short item IDs*/
}


- (id)initWithItemIDs:(NSArray *)someItemIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

/*Delegate is expected to get itemIDsToDownload and start operations to download those items.*/

@property (nonatomic, retain, readonly) NSArray *itemIDsToDownload;

@end
