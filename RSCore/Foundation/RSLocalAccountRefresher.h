//
//  RSLocalAccountRefresher.h
//  padlynx
//
//  Created by Brent Simmons on 9/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSRefreshController.h"


/*Refreshes feeds stored locally on this Mac or iOS device.
 Main thread.*/

@interface RSLocalAccountRefresher : NSObject <RSAccountRefresher> {
@private
	NSMutableArray *feedRefreshers;
}


- (void)registerFeedRefresher:(id<RSFeedRefresher>)feedRefresher;


@end
