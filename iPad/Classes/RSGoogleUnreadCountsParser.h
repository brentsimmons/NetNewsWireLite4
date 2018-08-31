//
//  RSGoogleUnreadCountsParser.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


@interface RSGoogleUnreadCountsParser : RSSAXParser {
@private
	NSMutableArray *unreadCounts;
	BOOL inUnreadCountsList;
	NSUInteger currentNameSpecifier;
}


@property (nonatomic, retain, readonly) NSMutableArray *unreadCounts;


@end
