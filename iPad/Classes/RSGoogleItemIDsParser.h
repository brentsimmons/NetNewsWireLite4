//
//  RSGoogleItemIDsParser.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


@protocol RSGoogleItemIDsParserDelegate
@required
- (void)itemIDsParserDidComplete:(id)itemIDsParser;
- (BOOL)itemIDsParser:(id)itemIDsParser didParseItemID:(NSString *)itemID; /*Return YES to consume itemID*/
@end


@interface RSGoogleItemIDsParser : RSSAXParser {
@private
	NSMutableArray *itemIDs;
	BOOL inItemID;
	id delegate;
}


@property (nonatomic, retain, readonly) NSMutableArray *itemIDs;
@property (nonatomic, assign) id <RSGoogleItemIDsParserDelegate> delegate;


@end
