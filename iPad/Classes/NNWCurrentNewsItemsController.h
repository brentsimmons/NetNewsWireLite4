//
//  NNWCurrentNewsItemsController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *NNWCurrentNewsItemsDidUpdateNotification;
extern NSString *NNWCurrentNewsItemsKey; /*key in userInfo dictionary*/


@class RSOperationController;
@class NNWNewsItemsFetchOperation;


@interface NNWCurrentNewsItemsController : NSObject {
@private
	NSMutableArray *newsItems;
	RSOperationController *fetchNewsItemsOperationController;
	NNWNewsItemsFetchOperation *currentNewsItemsFetchOperation;
}


@property (retain) NSMutableArray *newsItems;

- (void)fetchNewsItemsForSourceIDs:(NSArray *)sourceIDs;
- (void)fetchStarredNewsItems;
- (void)fetchLatestNewsItems;


@end
