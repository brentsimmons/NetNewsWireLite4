//
//  RSGoogleReaderItemIDsParser.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


@interface RSParsedGoogleItemID : NSObject {
@private
	NSString *itemID;
	NSMutableArray *directStreamIDs;
	NSTimeInterval timestamp;
	BOOL read;
	BOOL starred;
}

@property (nonatomic, retain, readonly) NSString *itemID;
@property (nonatomic, retain, readonly) NSMutableArray *directStreamIDs; //if status ID (read or starred) won't appear
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;
@property (nonatomic, assign, readonly) BOOL read;
@property (nonatomic, assign, readonly) BOOL starred;

@end


@protocol RSGoogleReaderItemIDsParserDelegate
@required
- (void)itemIDsParserDidComplete:(id)itemIDsParser;
- (BOOL)itemIDsParser:(id)itemIDsParser didParseItemID:(RSParsedGoogleItemID *)itemID; // Return YES to consume itemID
@end


@interface RSGoogleReaderItemIDsParser : RSSAXParser {
@private
	NSMutableArray *itemIDs;
	RSParsedGoogleItemID *currentID;
	BOOL inList;
	NSUInteger listLevel;
	BOOL inItemID;
	BOOL inTimestamp;
	NSTimeInterval oldestAllowedTimestamp;
	id delegate;
	BOOL shouldParseStreamIDs;
	BOOL shouldParseTimestamps;
}


@property (nonatomic, retain, readonly) NSMutableArray *itemIDs; // Array of NSStrings -- just the actual IDs, not RSParsedGoogleItemIDs
@property (nonatomic, assign) id <RSGoogleReaderItemIDsParserDelegate> delegate;
@property (nonatomic, assign) BOOL shouldParseStreamIDs;
@property (nonatomic, assign) BOOL shouldParseTimestamps;


@end
