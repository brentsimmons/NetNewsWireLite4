//
//  RSRSSParser.h
//  nnw
//
//  Created by Brent Simmons on 2/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSAbstractFeedParser.h"


@interface RSRSSParser : RSAbstractFeedParser {
@private
	BOOL inImageTree;
}


@end

/* http://cyber.law.harvard.edu/rss/rss.html */
