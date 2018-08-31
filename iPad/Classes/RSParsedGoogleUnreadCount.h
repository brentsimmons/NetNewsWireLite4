//
//  RSParsedGoogleUnreadCount.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RSParsedGoogleUnreadCount : NSObject {
@private
	NSString *googleID;
	NSInteger unreadCount;
	NSDate *googleCrawlDateOfMostRecentUnreadItem; /*newestItemTimestampUsec in XML*/
}


@property (nonatomic, retain) NSString *googleID;
@property (nonatomic, assign) NSInteger unreadCount;
@property (nonatomic, retain) NSDate *googleCrawlDateOfMostRecentUnreadItem;

- (void)setGoogleCrawlDateOfMostRecentUnreadItemWithString:(NSString *)dateString;


@end
