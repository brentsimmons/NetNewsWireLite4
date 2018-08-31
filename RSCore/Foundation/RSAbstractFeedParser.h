//
//  RSAbstractFeedParser.h
//  RSCoreTests
//
//  Created by Brent Simmons on 5/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


/*Must be sub-classed -- see RSRSSParser and RSGoogleReaderFeedParser*/

@class RSParsedNewsItem;

@protocol RSFeedParserDelegate
@required
- (void)feedParserDidComplete:(id)feedParser;
@optional
- (BOOL)feedParser:(id)feedParser didParseNewsItem:(RSParsedNewsItem *)newsItem; //Return YES to consume newsItem
@end


@interface RSAbstractFeedParser : RSSAXParser {
@protected
	NSMutableDictionary *headerItems;
	NSMutableArray *newsItems;
	RSParsedNewsItem *newsItem;
	id <RSFeedParserDelegate> delegate;
	BOOL delegateRespondsToDidParseNewsItem;
	BOOL parsingNewsItem;
	NSString *feedTitle;
	NSString *feedHomePageURL;
}


@property (nonatomic, retain) NSMutableDictionary *headerItems;
@property (nonatomic, retain) NSMutableArray *newsItems; //empty if delegate consumed each newsItem
@property (nonatomic, retain) RSParsedNewsItem *newsItem;
@property (nonatomic, assign) id <RSFeedParserDelegate> delegate;
@property (nonatomic, assign) BOOL delegateRespondsToDidParseNewsItem;
@property (nonatomic, assign) BOOL parsingNewsItem;
@property (nonatomic, retain) NSString *feedTitle;
@property (nonatomic, retain) NSString *feedHomePageURL;

/*For subclasses to over-ride or use.*/

- (void)addHeaderItem:(const char *)localName prefix:(const char *)prefix;
- (void)addNewsItem;
- (void)removeNewsItemIfDelegateWishes; //Calls delegate: deletes current item if delegate responds with YES
- (void)notifyDelegateThatFeedParserDidComplete;
- (void)processEnclosure;
- (void)addThumbnailURLIfNoThumbnail:(NSString *)urlString;
- (void)processMediaThumbnail;
- (void)processMediaCredit;
- (NSString *)staticNameForLocalName:(const char *)localName prefix:(const char *)prefix;
- (void)addNewsItemElement:(const char *)localName prefix:(const char *)prefix;
- (BOOL)parserWantsAttributesForTagWithLocalName:(const char *)localName prefix:(const char *)prefix;


@end
