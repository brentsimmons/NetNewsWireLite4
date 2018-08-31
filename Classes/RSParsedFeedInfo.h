//
//  RSParsedFeedInfo.h
//  nnw
//
//  Created by Brent Simmons on 1/1/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*A feed object can watch this notification to see when a parser updates its info.
 It should compare feedURLString to its own feed URL.
 [notification object] will be this object.*/

extern NSString *RSDidParseFeedInfoNotification;


@interface RSParsedFeedInfo : NSObject {
@private
	NSString *feedURLString;
	NSString *homePageURLString;
	NSString *title;
}


@property (nonatomic, retain) NSString *feedURLString;
@property (nonatomic, retain) NSString *homePageURLString;
@property (nonatomic, retain) NSString *title;

- (void)sendDidParseFeedInfoNotification; //always sends on main thread


@end
