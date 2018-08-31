//
//  RSGoogleSubsListParser.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/27/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


@interface RSGoogleSubsListParser : RSSAXParser {
@private
	NSMutableArray *subs;
	NSString *lastCategoryID;
	NSString *lastCategoryLabel;
	NSUInteger currentNameSpecifier;
	BOOL inSubsList;
	BOOL inSub;
	BOOL inCategories;
}


@property (nonatomic, retain) NSMutableArray *subs;


@end
