//
//  NNWRefreshController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/11/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWSyncUnreadItemsOperation.h"


extern NSString *NNWRefreshSessionDidBeginNotification;
extern NSString *NNWRefreshSessionDidEndNotification;

extern NSString *NNWRefreshSessionNoSubsFoundNotification;
extern NSString *NNWRefreshSessionSubsFoundNotification;


extern NSString *NNWLastRefreshDateKey;

@class RSOperationController;

@interface NNWRefreshController : NSObject <NNWSyncUnreadItemsOperationDelegate> {
@private
	NSArray *allGoogleFeedIDs;
	BOOL syncSessionIsRunning;
	RSOperationController *refreshOperationController;
}

+ (NNWRefreshController *)sharedController;
- (BOOL)runRefreshSession;


@end
