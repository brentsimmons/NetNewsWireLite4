//
//  RSParsedNewsItem.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

/*Safe to use on any thread - but should only be used on that one thread.
 Should not be used concurrently on multiple threads.*/

/*Some things are calculated lazily, on-demand -- these tend to be the expensive things.
 If they're not needed, we can avoid doing unneeded work at parse time.*/

@class RSParsedEnclosure;

@interface RSParsedNewsItem : NSObject {
@private
	BOOL read;
	BOOL starred;
	BOOL titleIsHTML;
	NSString *guid;
	BOOL guidIsPermalink;
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
	NSString *author; //name, hopefully
	NSString *authorEmail;
	NSString *authorURL;
	NSDate *pubDate;
//	NSString *pubDateString;
	NSDate *dateModified;
	NSString *sourceTitle;
	NSString *preview;
	NSData *hashOfReadOnlyAttributes;
	NSString *audioURL;
	NSString *movieURL;
	BOOL didCalculateThumbnailURL;
	NSString *thumbnailURL;
	NSString *mediaThumbnailURL;
	NSString *googleSourceID;
	NSString *googleOriginalID; //Guid from original feed, as reported by Google
	BOOL googleReadStateLocked;
	NSString *googleCrawlTimestampString;
	NSTimeInterval googleCrawlTimestamp;
	NSMutableArray *links; //Atom multiple links
	NSString *originalSourceName;
	NSString *originalSourceURL;
	NSString *itunesSummary;
	NSString *itunesSubtitle;
	BOOL googleSynced;
	NSString *mediaTitle;
	NSString *mediaCredit;
	BOOL mediaCreditRoleIsPhotographer;
}

/* Note about guids: With Google syncing, the guid is the last (unique) part of tag:google.com,2005:reader/item/7155b6e5ed5871b8 */

@property (nonatomic, assign) BOOL read;
@property (nonatomic, assign) BOOL starred;
@property (nonatomic, assign) BOOL titleIsHTML;
@property (nonatomic, retain) NSString *guid;
@property (nonatomic, assign) BOOL guidIsPermalink;
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
@property (nonatomic, retain) NSString *authorEmail;
@property (nonatomic, retain) NSString *authorURL;
//@property (nonatomic, retain) NSString *pubDateString;
@property (nonatomic, retain) NSString *sourceTitle;
@property (nonatomic, retain) NSString *audioURL;
@property (nonatomic, retain) NSString *movieURL;
@property (nonatomic, retain) NSString *mediaThumbnailURL;
@property (nonatomic, retain, readonly) NSString *htmlText; /*content, or summary if content is empty*/
@property (nonatomic, retain, readonly) NSString *xmlBaseURL; /*xmlBaseURLForContent, or xmlBaseURLForSummary is xmlBaseURLForContent is empty*/
@property (nonatomic, assign, getter=isGoogleReadStateLocked) BOOL googleReadStateLocked;
@property (nonatomic, retain) NSString *googleSourceID;
@property (nonatomic, retain) NSString *googleCrawlTimestampString;
@property (nonatomic, retain) NSMutableArray *links;
@property (nonatomic, retain) NSString *googleOriginalID;
@property (nonatomic, retain) NSString *originalSourceName;
@property (nonatomic, retain) NSString *originalSourceURL;
@property (nonatomic, retain) NSString *itunesSummary;
@property (nonatomic, retain) NSString *itunesSubtitle;
@property (nonatomic, assign, getter=isGoogleSynced) BOOL googleSynced;
@property (nonatomic, retain) NSString *mediaTitle;
@property (nonatomic, retain) NSString *mediaCredit;
@property (nonatomic, assign) BOOL mediaCreditRoleIsPhotographer;

/*Calculated lazily -- since these items may not be needed*/

@property (nonatomic, retain) NSDate *pubDate;
@property (nonatomic, retain) NSDate *dateModified;
@property (nonatomic, retain, readonly) NSData *hashOfReadOnlyAttributes;
@property (nonatomic, retain) NSString *preview;
@property (nonatomic, retain) NSString *plainTextTitle;
@property (nonatomic, retain) NSString *thumbnailURL;
@property (nonatomic, assign) NSTimeInterval googleCrawlTimestamp;

- (void)addCategory:(NSString *)category;
- (void)addEnclosure:(RSParsedEnclosure *)enclosure;

- (NSArray *)enclosuresPlist; //array of dictionaries representation

- (NSDictionary *)dictionaryRepresentation; //for testing

@end
