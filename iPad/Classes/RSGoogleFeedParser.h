//
//  RSGoogleFeedParser.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/2/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


@class RSParsedNewsItem;

@protocol RSGoogleFeedParserDelegate
@required
- (void)feedParserDidComplete:(id)feedParser;
@optional
- (BOOL)feedParser:(id)feedParser didParseNewsItem:(RSParsedNewsItem *)newsItem; /*Return YES to consume newsItem*/
@end


@interface RSGoogleFeedParser : RSSAXParser {
@private
	NSMutableArray *newsItems;
	RSParsedNewsItem *newsItem;
	BOOL parsingNewsItem;
	BOOL parsingAuthor;
	BOOL parsingSource;
	id <RSGoogleFeedParserDelegate> delegate;
	BOOL delegateRespondsToDidParseNewsItem;
}

@property (nonatomic, retain, readonly) NSMutableArray *newsItems; /*empty if delete consumed each newsItem*/
@property (nonatomic, assign) id <RSGoogleFeedParserDelegate> delegate;

@end


