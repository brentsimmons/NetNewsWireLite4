//
//  RSGoogleReaderFeedParser.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/2/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSAbstractFeedParser.h"


@interface RSGoogleReaderFeedParser : RSAbstractFeedParser {
@private
	BOOL parsingAuthor;
	BOOL parsingSource;
}

@end


