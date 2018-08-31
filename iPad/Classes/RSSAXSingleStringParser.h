//
//  RSSAXSingleStringParser.h
//  bobcat
//
//  Created by Brent Simmons on 3/7/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


NSString *RSParseSingleStringWithTag(NSData *xmlData, NSString *tagName);


@interface RSSAXSingleStringParser : RSSAXParser {
@private
	NSString *_tagName;
	NSString *_returnedString;
}


@property (nonatomic, retain) NSString *tagName; /*Whose string value we'll get*/
@property (nonatomic, retain) NSString *returnedString;


@end
