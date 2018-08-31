//
//  NNWDownloadItemsOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/18/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWGoogleAPICallOperation.h"
#import "RSGoogleFeedParser.h"


/*Downloads, parses, and saves the incoming items. No delegate or callback, since it does it all.*/

@interface NNWDownloadItemsOperation : NNWGoogleAPICallOperation <RSGoogleFeedParserDelegate> {
@private
	NSArray *itemIDs;
	NSArray *allGoogleFeedIDs;
	NSMutableArray *lockedReadItemIDs;
	NSMutableArray *heldNewsItems;
//	NSManagedObjectContext *managedObjectContext;
}


- (id)initWithItemIDs:(NSArray *)someItemIDs allFeedIDs:(NSArray *)allFeedIDs delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector;

@property (nonatomic, retain, readonly) NSMutableArray *lockedReadItemIDs;

@end
