//
//  RSAtomParser.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/2/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSAbstractFeedParser.h"


@interface RSAtomParser : RSAbstractFeedParser {
@private
	BOOL parsingAuthor;
	BOOL inXHTML; //inline html, not escaped or in CDATA
	BOOL inSource; //not parsing for now, but need to ignore <title> etc.
	NSURL *xmlBaseURLForFeed;
	NSURL *xmlBaseURLForEntry;
}


@end
