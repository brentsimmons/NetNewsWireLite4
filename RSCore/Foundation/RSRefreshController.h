//
//  RSRefreshController.h
//  padlynx
//
//  Created by Brent Simmons on 9/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSRefreshProtocols.h"


extern NSString *RSRefreshSessionDidBeginNotification;
extern NSString *RSRefreshSessionDidEndNotification;

extern NSString *RSRefreshDidUpdateFeedNotification;


/*Call on main thread only.*/

@class RSOperationController;

@interface RSRefreshController : NSObject {
@private
    NSMutableArray *accountRefreshers;
    RSOperationController *refreshOperationController; //one for all refresh ops
}


- (void)registerAccountRefresher:(id<RSAccountRefresher>)accountRefresher; //call this at startup, before refreshing

- (void)refreshAllInAccounts:(NSArray *)accountsToRefresh;
- (void)refreshFeeds:(NSArray *)feeds; //a feed knows what account it's in
- (void)cancelSession;

@property (nonatomic, strong, readonly) RSOperationController *refreshOperationController;


@end
