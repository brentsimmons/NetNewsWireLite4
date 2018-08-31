//
//  RSOPMLParser.h
//  nnw
//
//  Created by Brent Simmons on 2/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


/* OPML parsing is rarely done and performance and memory isn't an issue.
 So this just creates array/dictionary-based tree structure and objects.
 If this ever becomes an issue, we can make it much better. */


@interface RSOPMLParser : RSSAXParser {
@protected
	NSMutableArray *outlineItems;
	NSMutableArray *flattenedOutlineItems;
	NSMutableArray *outlineDictStack;
}


@property (nonatomic, retain) NSMutableArray *outlineItems;
@property (nonatomic, retain) NSMutableArray *flattenedOutlineItems;


@end
