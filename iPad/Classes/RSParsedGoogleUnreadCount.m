//
//  RSParsedGoogleUnreadCount.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSParsedGoogleUnreadCount.h"


@implementation RSParsedGoogleUnreadCount

@synthesize googleID, unreadCount, googleCrawlDateOfMostRecentUnreadItem;


#pragma mark Dealloc

- (void)dealloc {
	[googleID release];
	[googleCrawlDateOfMostRecentUnreadItem release];
	[super dealloc];
}


#pragma mark Crawl Date

- (void)setGoogleCrawlDateOfMostRecentUnreadItemWithString:(NSString *)dateString {
	if (dateString == nil)
		return;
	if ([dateString length] > 13) /*For some reason they're longer in this one feed. Chop off last characters.*/
		dateString = [dateString substringToIndex:13];
	self.googleCrawlDateOfMostRecentUnreadItem = [NSDate dateWithTimeIntervalSince1970:([dateString doubleValue] / 1000.000f)];
}

@end
