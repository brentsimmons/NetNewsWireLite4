//
//  RSParsedNewsItem.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

/*Safe to use on any thread - but should only be used on that one thread.*/

@interface RSParsedNewsItem : NSObject {
@private
	BOOL read;
	BOOL googleReadStateLocked;
	BOOL starred;
	BOOL titleIsHTML;
	NSString *guid;
	NSMutableArray *categories;
	NSString *title;
	NSString *plainTextTitle;
	NSMutableArray *enclosures;
	NSString *link;
	NSString *permalink;
	NSString *xmlBaseURLForContent;
	NSString *content;
	NSString *xmlBaseURLForSummary;
	NSString *summary;
	NSString *author;
	NSDate *googleCrawlTimestamp;
	NSString *googleCrawlTimestampString;
	NSString *googleSourceID;
	NSDate *pubDate;
	NSString *pubDateString;
	NSString *sourceTitle;
	NSString *preview;
	NSData *hashOfReadOnlyAttributes;
	NSString *audioURL;
	NSString *movieURL;
	BOOL didCalculateThumbnailURL;
	NSString *thumbnailURL;
	NSString *mediaThumbnailURL;
}

/* Note about guids: With Google syncing, the guid is the last (unique) part of tag:google.com,2005:reader/item/7155b6e5ed5871b8 */

@property (nonatomic, assign) BOOL read;
@property (nonatomic, assign, getter=isGoogleReadStateLocked) BOOL googleReadStateLocked;
@property (nonatomic, assign) BOOL starred;
@property (nonatomic, assign) BOOL titleIsHTML;
@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *enclosures;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *permalink;
@property (nonatomic, retain) NSString *xmlBaseURLForContent;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSString *xmlBaseURLForSummary;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *googleSourceID;
@property (nonatomic, retain) NSString *googleCrawlTimestampString;
@property (nonatomic, retain) NSString *pubDateString;
@property (nonatomic, retain) NSString *sourceTitle;
@property (nonatomic, retain) NSString *audioURL;
@property (nonatomic, retain) NSString *movieURL;
@property (nonatomic, retain) NSString *mediaThumbnailURL;
@property (nonatomic, retain, readonly) NSString *htmlText; /*content, or summary if content is empty*/
@property (nonatomic, retain, readonly) NSString *xmlBaseURL; /*xmlBaseURLForContent, or xmlBaseURLForSummary is xmlBaseURLForContent is empty*/

/*Calculated lazily -- since these items may not be needed*/

@property (nonatomic, retain) NSDate *pubDate;
@property (nonatomic, retain) NSDate *googleCrawlTimestamp;
@property (nonatomic, retain, readonly) NSData *hashOfReadOnlyAttributes;
@property (nonatomic, retain) NSString *preview;
@property (nonatomic, retain) NSString *plainTextTitle;
@property (nonatomic, retain) NSString *thumbnailURL;

- (void)addCategory:(NSString *)category;
- (void)addEnclosure:(NSDictionary *)enclosure;
//- (void)setGoogleCrawlTimestampWithString:(NSString *)timestampString;


@end
