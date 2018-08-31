//
//  RSLocalAccountCoreDataArticleSaverOperation.m
//  padlynx
//
//  Created by Brent Simmons on 9/6/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSLocalAccountCoreDataArticleSaverOperation.h"
#import "RSDataManagedObjects.h"
#import "RSParsedEnclosure.h"
#import "RSParsedNewsItem.h"
#import "RSRefreshController.h"


@interface RSLocalAccountCoreDataArticleSaverOperation ()

@property (nonatomic, strong) NSArray *existingArticles;
@property (nonatomic, strong) NSArray *parsedArticles;
@property (nonatomic, strong) NSManagedObjectContext *temporaryMOC;
@property (nonatomic, strong) NSString *accountIdentifier;
@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, strong) NSMutableSet *managedObjectIDsOfItemsInFeed;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;

- (BOOL)saveArticle:(RSParsedNewsItem *)parsedArticle;
- (void)markMissingItemsAsDeleted;

@end


@implementation RSLocalAccountCoreDataArticleSaverOperation

@synthesize accountIdentifier;
@synthesize existingArticles;
@synthesize feedURL;
@synthesize parsedArticles;
@synthesize temporaryMOC;
@synthesize managedObjectIDsOfItemsInFeed;
@synthesize unreadCount;


#pragma mark Init

- (id)initWithParsedArticles:(NSArray *)someParsedArticles feedURL:(NSURL *)aFeedURL accountIdentifier:(NSString *)anAccountIdentifier {
    self = [super initWithDelegate:nil callbackSelector:nil];
    if (self == nil)
        return nil;
    accountIdentifier = anAccountIdentifier;
    feedURL = aFeedURL;
    parsedArticles = someParsedArticles;
    managedObjectIDsOfItemsInFeed = [NSMutableSet setWithCapacity:[someParsedArticles count]];
    return self;
}


#pragma mark Dealloc



#pragma mark NSOperation

- (void)main {
    if ([self isCancelled])
        return;
    @autoreleasepool {
        self.temporaryMOC = [rs_app_delegate temporaryManagedObjectContext];
        BOOL quitEarly = NO;
        for (RSParsedNewsItem *oneArticle in self.parsedArticles) {
            if (self.isCancelled || ![self saveArticle:oneArticle]) {
                quitEarly = YES;
                break;
            }
        }
        if (!quitEarly && ![self isCancelled])
            [self markMissingItemsAsDeleted];
        self.existingArticles = nil;
        self.parsedArticles = nil;
        [rs_app_delegate saveManagedObjectContext:self.temporaryMOC];
        self.temporaryMOC = nil;
        
        if (![self isCancelled]) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
            [userInfo rs_safeSetObject:self.feedURL forKey:RSURLKey];
            [userInfo rs_safeSetObject:self.accountIdentifier forKey:@"account"];
            [userInfo rs_safeSetObject:[NSNumber numberWithUnsignedInteger:self.unreadCount] forKey:@"unreadCount"];
            [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSRefreshDidUpdateFeedNotification object:self userInfo:userInfo];
        }

    }
    [super main];
}


#pragma mark Deleting

- (void)markMissingItemsAsDeleted {
//    NSLog(@"ids in feed: %@ %@", self.feedURL, self.managedObjectIDsOfItemsInFeed);
    for (RSDataArticle *oneArticle in self.existingArticles) {
        NSManagedObjectID *oneObjectID = [oneArticle objectID];
        if (![self.managedObjectIDsOfItemsInFeed containsObject:oneObjectID]) {
            oneArticle.markedForDeletion = [NSNumber numberWithBool:YES];
//            NSLog(@"oneArticle being deleted: %@ - %@", [oneArticle objectID], oneArticle);
        }
    }
}


#pragma mark Saving

- (NSArray *)existingArticles {
    if (existingArticles != nil)
        return existingArticles;
    @autoreleasepool {
        existingArticles = [RSDataArticle articlesForFeedWithURL:self.feedURL accountID:accountIdentifier moc:self.temporaryMOC];
    }
    return existingArticles;
}


- (RSDataArticle *)existingArticleForParsedArticleThatHasGuid:(RSParsedNewsItem *)parsedArticle {
    NSArray *articles = self.existingArticles;
    if (RSIsEmpty(articles))
        return nil;
    NSArray *existingArticlesWithGuid = [articles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"guid == %@", parsedArticle.guid]];
    return [existingArticlesWithGuid rs_safeObjectAtIndex:0];
}


- (BOOL)existingArticle:(RSDataArticle *)existingArticle isSameAsParsedArticleWithoutGuid:(RSParsedNewsItem *)parsedArticle {
    /*Find match based on two out of three on title, link, and pubDate.*/
    if (!RSStringIsEmpty(existingArticle.guid))
        return NO;
    BOOL titlesMatch = NO;
    NSInteger ctMatches = 0;
    if (existingArticle.title != nil && [existingArticle.title isEqualToString:parsedArticle.title]) {
        titlesMatch = YES;
        ctMatches++;
    }
    if (existingArticle.datePublished != nil && [existingArticle.datePublished compare:parsedArticle.pubDate] == NSOrderedSame)
        ctMatches++;
    if (ctMatches > 1)
        return YES;
    if (existingArticle.link != nil && [existingArticle.link isEqualToString:parsedArticle.link])
        ctMatches++;
    if (ctMatches > 1)
        return YES;
    if (ctMatches < 1)
        return NO;
    if (!titlesMatch && existingArticle.plainTextTitle != nil && [existingArticle.plainTextTitle isEqualToString:parsedArticle.plainTextTitle]) {
        ctMatches++;
    }
    return ctMatches > 1;
}


- (RSDataArticle *)existingArticleForParsedArticleWithoutGuid:(RSParsedNewsItem *)parsedArticle {
    /*Find an existing article with no guid, that matches two out of three on title, link, and pubDate.*/
    NSArray *articles = self.existingArticles;
    if (RSIsEmpty(articles))
        return nil;
    for (RSDataArticle *oneArticle in articles) {
        if ([self existingArticle:oneArticle isSameAsParsedArticleWithoutGuid:parsedArticle])
            return oneArticle;
    }
    return nil;
}


- (RSDataArticle *)existingArticleForParsedArticle:(RSParsedNewsItem *)parsedArticle {
    if (!RSStringIsEmpty(parsedArticle.guid))
        return [self existingArticleForParsedArticleThatHasGuid:parsedArticle];
    return [self existingArticleForParsedArticleWithoutGuid:parsedArticle];
}


static BOOL equalStrings(NSString *s1, NSString *s2) {
    if (s1 == nil && s2 == nil)
        return YES;
    if (s1 != nil && s2 == nil)
        return NO;
    if (s1 == nil && s2 != nil)
        return NO;
    return [s1 isEqualToString:s2];
}


- (void)updateEnclosure:(RSDataEnclosure *)enclosure withParsedEnclosure:(RSParsedEnclosure *)parsedEnclosure {
    enclosure.bitRate = [NSNumber numberWithInteger:parsedEnclosure.bitrate];
    enclosure.fileSize = [NSNumber numberWithInteger:parsedEnclosure.fileSize];
    enclosure.height = [NSNumber numberWithInteger:parsedEnclosure.height];
    enclosure.mediaType = [NSNumber numberWithInteger:parsedEnclosure.mediaType];
    enclosure.medium = parsedEnclosure.medium;
    enclosure.mimeType = parsedEnclosure.mimeType;
    /*enclosure.URL already set*/
    enclosure.width = [NSNumber numberWithInteger:parsedEnclosure.width];
}


- (void)updateArticle:(RSDataArticle *)article withParsedArticle:(RSParsedNewsItem *)parsedArticle {
    [self.managedObjectIDsOfItemsInFeed addObject:[article objectID]];
    @autoreleasepool {
    
        if (!equalStrings(article.authorEmail, parsedArticle.authorEmail))
            article.authorEmail = parsedArticle.authorEmail;    
        if (!equalStrings(article.authorName, parsedArticle.author))
            article.authorName = parsedArticle.author;    
        if (!equalStrings(article.authorURL, parsedArticle.authorURL))
            article.authorURL = parsedArticle.authorURL;
        //article.categories = [parsedArticle.categories componentsJoinedByString:@"  "];
        article.dateModified = parsedArticle.dateModified;
        article.datePublished = parsedArticle.pubDate;
        
        if (!equalStrings(article.guid, parsedArticle.guid))
            article.guid = parsedArticle.guid;
        if (!equalStrings(article.link, parsedArticle.link))
            article.link = parsedArticle.link;
        if (!equalStrings(article.originalSourceFeedURL, parsedArticle.originalSourceURL))
            article.originalSourceFeedURL = parsedArticle.originalSourceURL;
        if (!equalStrings(article.originalSourceTitle, parsedArticle.originalSourceName))
            article.originalSourceTitle = parsedArticle.originalSourceName;
        if (!equalStrings(article.permalink, parsedArticle.permalink))    
            article.permalink = parsedArticle.permalink;
        if (!equalStrings(article.plainTextTitle, parsedArticle.plainTextTitle))
            article.plainTextTitle = parsedArticle.plainTextTitle;
        if (!equalStrings(article.plainTextPreview, parsedArticle.preview))
            article.plainTextPreview = parsedArticle.preview;
        if (!equalStrings(article.summary, parsedArticle.summary))
            article.summary = parsedArticle.summary;
        if (!equalStrings(article.thumbnailURL, parsedArticle.thumbnailURL))
            article.thumbnailURL = parsedArticle.thumbnailURL;
        if (!equalStrings(article.title, parsedArticle.title))
            article.title = parsedArticle.title;
        
        article.titleIsHTML = [NSNumber numberWithBool:parsedArticle.titleIsHTML];
        
        NSDate *dateForDisplay = article.datePublished;
        if (dateForDisplay == nil)
            dateForDisplay = article.dateModified;
        if (dateForDisplay == nil)
            dateForDisplay = article.dateServiceArrived;
        if (dateForDisplay == nil)
            dateForDisplay = article.dateArrived; //always exists
        article.dateForDisplay = dateForDisplay;
        
        RSDataArticleContent *articleContent = article.content;
        if (articleContent == nil)
            articleContent = [article insertArticleContentWithMOC:self.temporaryMOC];
        if (!equalStrings(articleContent.htmlText, parsedArticle.htmlText))
            articleContent.htmlText = parsedArticle.htmlText;
        if (!equalStrings(articleContent.xmlBaseURL, parsedArticle.xmlBaseURL))
            articleContent.xmlBaseURL = parsedArticle.xmlBaseURL;
        
        if (RSIsEmpty(parsedArticle.enclosures)) {
            article.hasAudioEnclosure = [NSNumber numberWithBool:NO];
            article.hasVideoEnclosure = [NSNumber numberWithBool:NO];
            article.enclosures = nil;
        }
        else {
            BOOL foundAudioEnclosure = NO;
            BOOL foundVideoEnclosure = NO;
            NSMutableSet *enclosureSet = [NSMutableSet setWithCapacity:[parsedArticle.enclosures count]];
            for (RSParsedEnclosure *oneParsedEnclosure in parsedArticle.enclosures) {
                NSURL *parsedEnclosureURL = [NSURL URLWithString:oneParsedEnclosure.urlString];
                if (parsedEnclosureURL == nil)
                    continue;
                if (oneParsedEnclosure.mediaType == RSMediaTypeAudio)
                    foundAudioEnclosure = YES;
                else if (oneParsedEnclosure.mediaType == RSMediaTypeVideo)
                    foundVideoEnclosure = YES;
                
                RSDataEnclosure *enclosure = [article insertEnclosureWithURL:parsedEnclosureURL moc:self.temporaryMOC];//[article fetchOrInsertEnclosureWithURL:parsedEnclosureURL moc:self.temporaryMOC];
                [enclosureSet addObject:enclosure];
                [self updateEnclosure:enclosure withParsedEnclosure:oneParsedEnclosure];
            }
            article.enclosures = enclosureSet;
            article.hasAudioEnclosure = [NSNumber numberWithBool:foundAudioEnclosure];
            article.hasVideoEnclosure = [NSNumber numberWithBool:foundVideoEnclosure];
        }
    }
}


- (BOOL)saveArticle:(RSParsedNewsItem *)parsedArticle {
    @autoreleasepool {
        RSDataArticle *article = [self existingArticleForParsedArticle:parsedArticle];
        if (article == nil)
            article = [RSDataArticle insertArticleWithFeedURL:self.feedURL accountID:accountIdentifier moc:self.temporaryMOC];
        [self updateArticle:article withParsedArticle:parsedArticle];
        if (![article.read boolValue])
            self.unreadCount = self.unreadCount + 1;
    }
    return YES;
}


@end
