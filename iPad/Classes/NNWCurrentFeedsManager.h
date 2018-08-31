//
//  NNWCurrentFeedsManager.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/17/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

/*Manages the list of feeds to display in the UI. Feeds that have one or more unread items
 or articles published in the last 24 hours*/

@interface NNWCurrentFeedsManager : NSObject {
@private
	NSMutableDictionary *feedIDs;
}


- (id)initWithFeedIDs:(NSArray *)someFeedIDs;

@property (nonatomic, retain, readonly) NSArray *currentFeedIDs;


@end
