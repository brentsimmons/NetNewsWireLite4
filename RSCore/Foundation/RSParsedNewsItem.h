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
//    NSString *pubDateString;
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
@property (nonatomic, strong) NSString *guid;
@property (nonatomic, assign) BOOL guidIsPermalink;
@property (nonatomic, strong) NSMutableArray *categories;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray *enclosures;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *permalink;
@property (nonatomic, strong) NSString *xmlBaseURLForContent;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *xmlBaseURLForSummary;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorURL;
//@property (nonatomic, retain) NSString *pubDateString;
@property (nonatomic, strong) NSString *sourceTitle;
@property (nonatomic, strong) NSString *audioURL;
@property (nonatomic, strong) NSString *movieURL;
@property (nonatomic, strong) NSString *mediaThumbnailURL;
@property (nonatomic, strong, readonly) NSString *htmlText; /*content, or summary if content is empty*/
@property (nonatomic, strong, readonly) NSString *xmlBaseURL; /*xmlBaseURLForContent, or xmlBaseURLForSummary is xmlBaseURLForContent is empty*/
@property (nonatomic, assign, getter=isGoogleReadStateLocked) BOOL googleReadStateLocked;
@property (nonatomic, strong) NSString *googleSourceID;
@property (nonatomic, strong) NSString *googleCrawlTimestampString;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) NSString *googleOriginalID;
@property (nonatomic, strong) NSString *originalSourceName;
@property (nonatomic, strong) NSString *originalSourceURL;
@property (nonatomic, strong) NSString *itunesSummary;
@property (nonatomic, strong) NSString *itunesSubtitle;
@property (nonatomic, assign, getter=isGoogleSynced) BOOL googleSynced;
@property (nonatomic, strong) NSString *mediaTitle;
@property (nonatomic, strong) NSString *mediaCredit;
@property (nonatomic, assign) BOOL mediaCreditRoleIsPhotographer;

/*Calculated lazily -- since these items may not be needed*/

@property (nonatomic, strong) NSDate *pubDate;
@property (nonatomic, strong) NSDate *dateModified;
@property (nonatomic, strong, readonly) NSData *hashOfReadOnlyAttributes;
@property (nonatomic, strong) NSString *preview;
@property (nonatomic, strong) NSString *plainTextTitle;
@property (nonatomic, strong) NSString *thumbnailURL;
@property (nonatomic, assign) NSTimeInterval googleCrawlTimestamp;

- (void)addCategory:(NSString *)category;
- (void)addEnclosure:(RSParsedEnclosure *)enclosure;

- (NSArray *)enclosuresPlist; //array of dictionaries representation

- (NSDictionary *)dictionaryRepresentation; //for testing

@end
