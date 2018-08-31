//
//  NNWProcessUnreadItemIDsOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/25/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"


@interface NNWProcessUnreadItemIDsOperation : RSOperation {
@private
	NSArray *unreadItemIDs;
	NSArray *itemIDsToDownload;
	
}

- (id)initWithItemIDs:(NSArray *)someItemIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

/*Delegate is expected to get itemIDsToDownload and start operations to download those items.*/

@property (nonatomic, retain, readonly) NSArray *itemIDsToDownload;


@end
