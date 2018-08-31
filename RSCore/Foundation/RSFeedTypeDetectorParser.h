//
//  RSFeedTypeDetectorParser.h
//  RSCoreTests
//
//  Created by Brent Simmons on 6/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"
#import "RSFeedTypeDetector.h"


/*Used by RSFeedTypeDetector as a last-ditch attempt to figure out what type
 of feed some data is.*/


@interface RSFeedTypeDetectorParser : RSSAXParser {
@private
	RSFeedType feedType;
	NSUInteger countStartElements;
}


@property (nonatomic, assign, readonly) RSFeedType feedType;


@end
