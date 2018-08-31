//
//  RSParsedNewsItem.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/23/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSParsedNewsItem.h"
#import "RSDateParser.h"
#import "RSEntityDecoder.h"
#import "RSFoundationExtras.h"
#import "RSParsedEnclosure.h"


@interface RSParsedNewsItem ()
@property (nonatomic, assign) BOOL didCalculateThumbnailURL;
@end


@implementation RSParsedNewsItem

@synthesize read;
@synthesize starred, titleIsHTML, guid, categories;
@synthesize guidIsPermalink;
@synthesize title, enclosures, link, permalink;
@synthesize plainTextTitle;
@synthesize xmlBaseURLForContent, content;
@synthesize xmlBaseURLForSummary, summary;
@synthesize author;
@synthesize pubDate, /*pubDateString,*/ sourceTitle;
@synthesize preview;
@synthesize movieURL, audioURL;
@synthesize thumbnailURL;
@synthesize didCalculateThumbnailURL;
@synthesize mediaThumbnailURL;
@synthesize googleReadStateLocked;
@synthesize googleCrawlTimestampString;
@synthesize googleSourceID;
@synthesize dateModified;
@synthesize links;
@synthesize authorEmail;
@synthesize authorURL;
@synthesize googleOriginalID;
@synthesize originalSourceName;
@synthesize originalSourceURL;
@synthesize itunesSummary;
@synthesize itunesSubtitle;
@synthesize googleSynced;
@synthesize mediaTitle;
@synthesize mediaCredit;
@synthesize mediaCreditRoleIsPhotographer;
@synthesize googleCrawlTimestamp;

#pragma mark Dealloc



#pragma mark Categories

- (void)addCategory:(NSString *)category {
    if (self.categories == nil)
        self.categories = [NSMutableArray array];
    [self.categories rs_safeAddObject:category];
}


#pragma mark Enclosures

- (void)addEnclosure:(RSParsedEnclosure *)enclosure {
    if (self.enclosures == nil)
        self.enclosures = [NSMutableArray array];
    [self.enclosures rs_safeAddObject:enclosure];
}


#pragma mark Hash

static NSString *RSParsedNewsItemEmptyString = @"";

- (NSData *)hashOfReadOnlyAttributes {
    if (hashOfReadOnlyAttributes != nil)
        return hashOfReadOnlyAttributes;
    NSMutableString *s = [NSMutableString stringWithString:RSParsedNewsItemEmptyString];
    [s rs_safeAppendString:self.guid];
    [s rs_safeAppendString:self.title];
    [s rs_safeAppendString:self.link];
    [s rs_safeAppendString:self.content];
    [s rs_safeAppendString:self.summary];
    [s rs_safeAppendString:self.author];
    [s rs_safeAppendString:self.googleSourceID];
    if (!RSIsEmpty(self.categories))
        [s rs_safeAppendString:[self.categories componentsJoinedByString:RSParsedNewsItemEmptyString]];
    hashOfReadOnlyAttributes = [NSData rs_md5HashWithString:s];
    return hashOfReadOnlyAttributes;
}


#pragma mark Calculated

- (NSString *)htmlText {
    if (RSStringIsEmpty(self.content))
        return self.summary;
    return self.content;
}


- (NSString *)xmlBaseURL {
    if (RSStringIsEmpty(self.xmlBaseURLForContent))
        return self.xmlBaseURLForSummary;
    return self.xmlBaseURLForContent;
}


- (NSString *)plainTextTitle {
    if (plainTextTitle != nil)
        return plainTextTitle;
    plainTextTitle = [self.title rs_stringByMakingPlainTextTitle];
    if (RSStringIsEmpty(plainTextTitle))
        plainTextTitle = [self.preview rs_stringByMakingPlainTextTitle];
    return plainTextTitle;
}


- (NSString *)preview {
    if (preview != nil)
        return preview;
    NSString *previewSource = RSStringIsEmpty(self.summary) ? self.content : self.summary;
    if (!RSStringIsEmpty(previewSource)) {
        NSMutableString *strippedPreview = [NSMutableString rs_mutableStringWithStrippedHTML:previewSource maxCharacters:300];
        strippedPreview = [RSStringWithDecodedEntities(strippedPreview) mutableCopy];
        [strippedPreview rs_replaceXMLCharacterReferences];
//        if ([strippedPreview rangeOfString:@"&amp;" options:0].location != NSNotFound)
//            [strippedPreview replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [strippedPreview length])];
        [strippedPreview rs_collapseWhitespace];
        self.preview = strippedPreview;
    }
    return preview;
}


- (NSString *)thumbnailURL {
    /*May be set directly, in the case where the thumbnail URL is present in the feed as media:thumbnail. Otherwise calculated from the description.*/
    if (self.mediaThumbnailURL != nil)
        return self.mediaThumbnailURL;
    if (thumbnailURL != nil || self.didCalculateThumbnailURL)
        return thumbnailURL;
    self.didCalculateThumbnailURL = YES;
    NSString *thumbnailURLString = [NSString rs_firstImgURLStringInHTML:self.htmlText];
    if (thumbnailURLString != nil && ![thumbnailURLString hasPrefix:@"http"]) {
        /*Calculate relative to permalink.*/
        NSString *baseURLString = self.permalink;
        if (RSStringIsEmpty(baseURLString))
            baseURLString = self.link;
        if (!RSStringIsEmpty(baseURLString)) {
            NSURL *baseURL = [NSURL URLWithString:baseURLString];
            if (baseURL != nil) {
                NSURL *aThumbnailURL = [NSURL URLWithString:thumbnailURLString relativeToURL:baseURL];
                if (aThumbnailURL != nil)
                    thumbnailURLString = [aThumbnailURL absoluteString];
            }                
        }
    }
    self.thumbnailURL = thumbnailURLString;
    return thumbnailURL;
}


- (NSTimeInterval)googleCrawlTimestamp {
    if (googleCrawlTimestamp > 0)
        return googleCrawlTimestamp;
    if (self.googleCrawlTimestampString != nil && [self.googleCrawlTimestampString length] != 13)
        self.googleCrawlTimestamp = [self.googleCrawlTimestampString doubleValue] / 1000.000f;
    return googleCrawlTimestamp;
}


#pragma mark Testing

- (NSArray *)enclosuresPlist {
    if (RSIsEmpty(self.enclosures))
        return nil;
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[self.enclosures count]];
    for (RSParsedEnclosure *oneEnclosure in self.enclosures)
        [tempArray rs_safeAddObject:[oneEnclosure dictionaryRepresentation]];
    return tempArray;
}


- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d rs_setBool:self.read forKey:@"read"];
    [d rs_setBool:self.starred forKey:@"starred"];
    [d rs_setBool:self.titleIsHTML forKey:@"titleIsHTML"];
    [d rs_safeSetObject:self.guid forKey:@"guid"];
    [d rs_setBool:self.guidIsPermalink forKey:@"guidIsPermalink"];
    [d rs_safeSetObject:self.categories forKey:@"categories"];
    [d rs_safeSetObject:self.title forKey:@"title"];
    [d rs_safeSetObject:[self enclosuresPlist] forKey:@"enclosures"];
    [d rs_safeSetObject:self.link forKey:@"link"];
    [d rs_safeSetObject:self.permalink forKey:@"permalink"];
    [d rs_safeSetObject:self.xmlBaseURLForContent forKey:@"xmlBaseURLForContent"];
    [d rs_safeSetObject:self.content forKey:@"content"];
    [d rs_safeSetObject:self.xmlBaseURLForSummary forKey:@"xmlBaseURLForSummary"];
    [d rs_safeSetObject:self.summary forKey:@"summary"];
    [d rs_safeSetObject:self.author forKey:@"author"];
    [d rs_safeSetObject:self.authorEmail forKey:@"authorEmail"];
    [d rs_safeSetObject:self.authorURL forKey:@"authorURL"];
    [d rs_safeSetObject:self.sourceTitle forKey:@"sourceTitle"];
    [d rs_safeSetObject:self.audioURL forKey:@"audioURL"];
    [d rs_safeSetObject:self.movieURL forKey:@"movieURL"];
    [d rs_safeSetObject:self.mediaThumbnailURL forKey:@"mediaThumbnailURL"];
    [d rs_safeSetObject:self.htmlText forKey:@"htmlText"];
    [d rs_safeSetObject:self.xmlBaseURL forKey:@"xmlBaseURL"];
    [d rs_setBool:self.isGoogleReadStateLocked forKey:@"googleReadStateLocked"];
    [d rs_safeSetObject:self.googleSourceID forKey:@"googleSourceID"];
    [d rs_safeSetObject:self.googleCrawlTimestampString forKey:@"googleCrawlTimestampString"];
    [d rs_safeSetObject:self.links forKey:@"links"];
    [d rs_safeSetObject:self.googleOriginalID forKey:@"googleOriginalID"];
    [d rs_safeSetObject:self.originalSourceName forKey:@"originalSourceName"];
    [d rs_safeSetObject:self.originalSourceURL forKey:@"originalSourceURL"];
    [d rs_safeSetObject:self.itunesSummary forKey:@"itunesSummary"];
    [d rs_safeSetObject:self.itunesSubtitle forKey:@"itunesSubtitle"];
    [d rs_setBool:self.isGoogleSynced forKey:@"googleSynced"];
    [d rs_safeSetObject:self.pubDate forKey:@"pubDate"];
    [d rs_safeSetObject:self.dateModified forKey:@"dateUpdated"];
    [d rs_safeSetObject:self.hashOfReadOnlyAttributes forKey:@"hashOfReadOnlyAttributes"];
    [d rs_safeSetObject:self.preview forKey:@"preview"];
    [d rs_safeSetObject:self.plainTextTitle forKey:@"plainTextTitle"];
    [d rs_safeSetObject:self.thumbnailURL forKey:@"thumbnailURL"];
    [d rs_safeSetObject:[NSNumber numberWithDouble:self.googleCrawlTimestamp] forKey:@"googleCrawlTimestamp"];
    
    return d;
}


@end
