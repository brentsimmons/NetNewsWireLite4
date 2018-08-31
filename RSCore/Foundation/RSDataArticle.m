//
//  NNWArticle.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataArticle.h"
#import "RSCoreDataUtilities.h"
#import "RSDataManagedObjects.h"
#import "RSMimeTypes.h"


NSString *RSDataArticleDidDisplayNotification = @"RSDataArticleDidDisplayNotification";
NSString *RSDataArticleReadStatusDidChangeNotification = @"RSDataArticleReadStatusDidChangeNotification";
NSString *RSDataDidDeleteArticlesNotification = @"RSDataDidDeleteArticlesNotification";
NSString *RSMultipleArticlesDidChangeReadStatusNotification = @"RSMultipleArticlesDidChangeReadStatusNotification";

@interface RSDataArticle (CoreDataGeneratedPrimitiveAccessors)

- (NSString *)primitiveCategories;
- (NSDate *)primitiveDateServiceArrived;
- (NSSet *)primitiveEnclosures;
- (NSNumber *)primitiveServiceNoLongerTracked;
- (void)setPrimitiveServiceNoLongerTracked:(NSNumber *)value;

@end


@implementation RSDataArticle

@dynamic accountID;
@dynamic appearsInFeed;
@dynamic authorEmail;
@dynamic authorName;
@dynamic authorURL;
@dynamic categories;
@dynamic commentsURL;
@dynamic dateArrived;
@dynamic dateForDisplay;
@dynamic dateModified;
@dynamic datePublished;
@dynamic dateServiceArrived;
@dynamic feedURL;
@dynamic followed;
@dynamic guid;
@dynamic hasAudioEnclosure;
@dynamic hasVideoEnclosure;
@dynamic link;
@dynamic markedForDeletion;
@dynamic originalSourceFeedURL;
@dynamic originalSourceTitle;
@dynamic permalink;
@dynamic plainTextTitle;
@dynamic plainTextPreview;
@dynamic read;
@dynamic savedToReadLater;
@dynamic serviceNoLongerTracked;
@dynamic serviceSpecifiedOriginalGuid;
@dynamic starred;
@dynamic summary;
@dynamic thumbnailURL;
@dynamic title;
@dynamic titleIsHTML;
@dynamic userDeleted;

@dynamic content;
@dynamic enclosures;


//- (void)willTurnIntoFault {
//    [categoriesArray release];
//    categoriesArray = nil;
//}
//
//
//- (void)prepareForDeletion {
//    [categoriesArray release];
//    categoriesArray = nil;    
//}


//static NSString *rs_categoriesSeparator = @"  "; //two spaces should do the trick

//- (NSArray *)categoriesArray {
//    if (categoriesArray != nil)
//        return categoriesArray;
//    NSString *categoriesString = [self primitiveCategories];
//    if (RSStringIsEmpty(categoriesString))
//        return nil;
//    categoriesArray = [[categoriesString componentsSeparatedByString:rs_categoriesSeparator] retain];
//    return categoriesArray;
//}
//
//
//- (void)setCategoriesArray:(NSArray *)anArray {
//    if (RSIsEmpty(anArray)) {
//        self.categories = nil;
//        categoriesArray = nil;
//    }
//    else {
//        self.categories = [anArray componentsJoinedByString:rs_categoriesSeparator];
//        categoriesArray = [anArray retain];
//    }
//}


//+ (RSDataArticle *)fetchArticleWithGuid:(NSString *)aGuid account:(id<RSAccount>)anAccount feedURL:(NSURL *)aFeedURL moc:(NSManagedObjectContext *)moc {
//    NSString *feedURLString = [aFeedURL absoluteString];
//    if (RSStringIsEmpty(aGuid) || RSStringIsEmpty(feedURLString) || RSStringIsEmpty(anAccount.identifier))
//        return nil;
//    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
//    [request setEntity:[NSEntityDescription entityForName:RSDataEntityNameArticle inManagedObjectContext:moc]];
//    [request setFetchLimit:1];
//    [request setPredicate:[NSPredicate predicateWithFormat:@"(feedURL == %@) && (accountID == %@) && (guid == %@)", feedURLString, anAccount.identifier, aGuid]];
//    NSError *error = nil;
//    return [[moc executeFetchRequest:request error:&error] rs_safeObjectAtIndex:0];    
//    
//}


+ (RSDataArticle *)insertArticleWithMOC:(NSManagedObjectContext *)moc {
    return (RSDataArticle *)RSInsertObject(RSDataEntityNameArticle, moc);
}


+ (RSDataArticle *)insertArticleWithFeedURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    RSDataArticle *anArticle = [self insertArticleWithMOC:moc];
    anArticle.feedURL = [feedURL absoluteString];
    anArticle.dateArrived = [NSDate date];
    anArticle.accountID = accountID;
    return anArticle;
}


#pragma mark Feeds

+ (NSArray *)articlesWithPredicate:(NSPredicate *)aPredicate sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc{
    if (aPredicate == nil)
        return nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setIncludesPropertyValues:YES];
    [request setReturnsObjectsAsFaults:NO];
    [request setEntity:[NSEntityDescription entityForName:RSDataEntityNameArticle inManagedObjectContext:moc]];
    [request setPredicate:aPredicate];
    if (aSortDescriptor != nil)
        [request setSortDescriptors:[NSArray arrayWithObject:aSortDescriptor]];
    NSError *error = nil;
    return [moc executeFetchRequest:request error:&error];    
}


+ (NSUInteger)unreadCountWithPredicate:(NSPredicate *)aPredicate moc:(NSManagedObjectContext *)moc {
    if (aPredicate == nil || moc == nil)
        return 0;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setIncludesPropertyValues:NO];
    [request setEntity:[NSEntityDescription entityForName:RSDataEntityNameArticle inManagedObjectContext:moc]];
    [request setPredicate:aPredicate];
    NSError *error = nil;
    NSUInteger anUnreadCount = [moc countForFetchRequest:request error:&error];
    return anUnreadCount;
}


/*Today*/

+ (NSPredicate *)predicateForArticlesPublishedTodayInAccountWithID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    NSDate *today = [[RSDateManager sharedManager] firstSecondOfToday];
    NSDate *tomorrow = [[RSDateManager sharedManager] firstSecondOfTomorrow];
    return [NSPredicate predicateWithFormat:@"(dateForDisplay >= %@) && (dateForDisplay < %@) && (markedForDeletion == 0) && (accountID == %@)", today, tomorrow, accountID];
}


+ (NSPredicate *)predicateForCountOfUnreadArticlesPublishedTodayInAccountWithID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    if (accountID == nil || moc == nil)
        return nil;
    NSDate *today = [[RSDateManager sharedManager] firstSecondOfToday];
    NSDate *tomorrow = [[RSDateManager sharedManager] firstSecondOfTomorrow];
    return [NSPredicate predicateWithFormat:@"(dateForDisplay >= %@) && (dateForDisplay < %@) && (read == 0) && (markedForDeletion == 0) && (accountID == %@)", today, tomorrow, accountID];    
}


+ (NSArray *)articlesPublishedTodayInAccountWithID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc {
    if (RSStringIsEmpty(accountID))
        return nil;
    return [self articlesWithPredicate:[self predicateForArticlesPublishedTodayInAccountWithID:accountID moc:moc] sortDescriptor:aSortDescriptor moc:moc];
}


+ (NSPredicate *)predicateForArticlesForFeedWithURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    return [NSPredicate predicateWithFormat:@"(feedURL == %@) && (markedForDeletion == 0) && (accountID == %@)", [feedURL absoluteString], accountID];
}


+ (NSUInteger)countOfUnreadArticlesPublishedTodayInAccountWithID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    NSPredicate *aPredicate = [self predicateForCountOfUnreadArticlesPublishedTodayInAccountWithID:accountID moc:moc];
    return [self unreadCountWithPredicate:aPredicate moc:moc];
}


+ (NSArray *)articlesForFeedWithURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    NSString *feedURLString = [feedURL absoluteString];
    if (RSStringIsEmpty(feedURLString) || RSStringIsEmpty(accountID))
        return nil;
    return [self articlesWithPredicate:[self predicateForArticlesForFeedWithURL:feedURL accountID:accountID moc:moc] sortDescriptor:nil moc:moc];
}


+ (NSPredicate *)predicateForArticlesForFeedsWithURLs:(NSArray *)feedURLStrings accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    /*Note: when we actually use the userDeleted flag, we'll have to respect it here.*/
    return [NSPredicate predicateWithFormat:@"(feedURL in %@) && (markedForDeletion == 0) && (accountID == %@)", feedURLStrings, accountID];
}


+ (NSArray *)sortedArticlesForFeedsWithURLs:(NSArray *)feedURLStrings accountID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc {
    if (RSIsEmpty(feedURLStrings) || RSStringIsEmpty(accountID))
        return nil;
    return [self articlesWithPredicate:[self predicateForArticlesForFeedsWithURLs:feedURLStrings accountID:accountID moc:moc] sortDescriptor:aSortDescriptor moc:moc];
}


+ (NSPredicate *)predicateForUnreadArticlesForFeedWithURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    return [NSPredicate predicateWithFormat:@"(feedURL == %@) && (read == 0) && (markedForDeletion == 0) && (accountID == %@)", [feedURL absoluteString], accountID];
}


+ (NSPredicate *)predicateForUnreadArticlesForFeedsWithURLs:(NSArray *)feedURLStrings accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    /*Note: when we actually use the userDeleted flag, we'll have to respect it here.*/
    return [NSPredicate predicateWithFormat:@"(feedURL in %@) && (read == 0) && (markedForDeletion == 0) && (accountID == %@)", feedURLStrings, accountID];
}


+ (NSArray *)unreadArticlesForFeedsWithURLs:(NSArray *)feedURLStrings accountID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc {
    if (RSIsEmpty(feedURLStrings))
        return nil;
    NSPredicate *predicate = [self predicateForUnreadArticlesForFeedsWithURLs:feedURLStrings accountID:accountID moc:moc];
    return [self articlesWithPredicate:predicate sortDescriptor:aSortDescriptor moc:moc];
}


+ (NSPredicate *)predicateForUnreadArticlesInAccountWithID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    return [NSPredicate predicateWithFormat:@"(read == 0) && (markedForDeletion == 0) && (accountID == %@)", accountID];    
}


+ (NSArray *)unreadArticlesInAccountWithID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc {
    if (RSIsEmpty(accountID))
        return nil;
    NSPredicate *predicate = [self predicateForUnreadArticlesInAccountWithID:accountID moc:moc];
    return [self articlesWithPredicate:predicate sortDescriptor:aSortDescriptor moc:moc];
}


+ (NSUInteger)unreadCountForArticlesWithFeedURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    NSString *feedURLString = [feedURL absoluteString];
    if (RSStringIsEmpty(feedURLString) || RSStringIsEmpty(accountID))
        return 0;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setIncludesPropertyValues:NO];
    [request setEntity:[NSEntityDescription entityForName:RSDataEntityNameArticle inManagedObjectContext:moc]];
    [request setPredicate:[self predicateForUnreadArticlesForFeedWithURL:feedURL accountID:accountID moc:moc]];
    NSError *error = nil;
    NSUInteger anUnreadCount = [moc countForFetchRequest:request error:&error];
    return anUnreadCount;
}


+ (BOOL)anyArticlesExist:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:RSDataEntityNameArticle inManagedObjectContext:moc]];
    NSError *error = nil;
    NSUInteger numberOfArticles = [moc countForFetchRequest:request error:&error];
    if (numberOfArticles == NSNotFound || numberOfArticles < 1)
        return NO;
    return YES;
}


#pragma mark Title and Link 

- (NSString *)bestLink {
    if (RSStringIsEmpty(self.permalink))
        return self.link;
    return self.permalink;
}


- (void)bestSharingTitle:(NSString **)aTitle andLink:(NSString **)aLink {
    NSString *articleTitle = self.plainTextTitle;
    if (RSStringIsEmpty(articleTitle))
        articleTitle = self.title;
    if (!RSStringIsEmpty(articleTitle))
        *aTitle = articleTitle;
    *aLink = [self bestLink];
}


//#pragma mark Dates
//
//- (NSDate *)bestDate {
//    /*datePublished if available, or other date*/
//    if (self.datePublished != nil)
//        return self.datePublished;
//    if (self.dateModified != nil)
//        return self.dateModified;
//    return self.dateArrived; //should always exist
//}


#pragma mark Marking Read/Unread

- (void)markAsRead:(BOOL)flag {
    if ([self.read boolValue] == flag)
        return;
    self.read = [NSNumber numberWithBool:flag];
    [[NSNotificationCenter defaultCenter] postNotificationName:RSDataArticleReadStatusDidChangeNotification object:self userInfo:nil];
}


#pragma mark Content

- (RSDataArticleContent *)insertArticleContentWithMOC:(NSManagedObjectContext *)moc {
    RSDataArticleContent *anArticleContent = (RSDataArticleContent *)RSInsertObject(RSDataEntityNameArticleContent, moc);
    self.content = anArticleContent;
    return anArticleContent;
}


#pragma mark Deleting

+ (NSPredicate *)predicateForItemsMarkedForDeletion {
    return [NSPredicate predicateWithFormat:@"markedForDeletion == 1"];    
}


+ (NSArray *)articlesMarkedForDeletion:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setIncludesPropertyValues:NO];
    [request setEntity:[NSEntityDescription entityForName:RSDataEntityNameArticle inManagedObjectContext:moc]];
    [request setPredicate:[self predicateForItemsMarkedForDeletion]];
    NSError *error = nil;
    return [moc executeFetchRequest:request error:&error];
}


+ (void)deleteArticlesMarkedForDeletion:(NSManagedObjectContext *)moc {
    NSArray *articlesMarkedForDeletion = [self articlesMarkedForDeletion:moc];
    if (RSIsEmpty(articlesMarkedForDeletion)) {
//        NSLog(@"No articles marked for deletion.");
        return;
    }
    //NSUInteger numberOfArticles = [articlesMarkedForDeletion count];
//    NSLog(@"%d articles marked for deletion.", (int)numberOfArticles);
    NSUInteger indexOfArticle = 0;
    for (RSDataArticle *oneArticle in articlesMarkedForDeletion) {
        [moc deleteObject:oneArticle];
        indexOfArticle++;
        if (indexOfArticle > 100)
            break;
    }
}


+ (void)markAsDeletedAllArticlesForFeedURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc {
    if (feedURL == nil || RSStringIsEmpty(accountID) || moc == nil)
        return;
    NSArray *articles = [self articlesForFeedWithURL:feedURL accountID:accountID moc:moc];
    if (RSIsEmpty(articles))
        return;
    for (RSDataArticle *oneArticle in articles) {
        if (![oneArticle.markedForDeletion boolValue])
            oneArticle.markedForDeletion = [NSNumber numberWithBool:YES];
    }
}


#pragma mark Enclosures

- (NSSet *)fetchSetOfEnclosuresWithValue:(id)value forKey:(NSString *)key moc:(NSManagedObjectContext *)moc {
    if (RSIsEmpty(self.enclosures))
        return nil;
    NSPredicate *localPredicate = [RSPredicateWithEquality(key) predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:value forKey:RSDataGenericSubstitionKey]];
    return [self.enclosures filteredSetUsingPredicate:localPredicate];
}


- (RSDataEnclosure *)fetchEnclosureWithURL:(NSURL *)aURL moc:(NSManagedObjectContext *)moc {
    NSSet *setOfEnclosuresWithURL = [self fetchSetOfEnclosuresWithValue:[aURL absoluteString] forKey:@"URL" moc:moc];
    if (RSIsEmpty(setOfEnclosuresWithURL))
        return nil;
    return [setOfEnclosuresWithURL anyObject];
}


- (RSDataEnclosure *)insertEnclosureWithURL:(NSURL *)aURL moc:(NSManagedObjectContext *)moc {
    RSDataEnclosure *anEnclosure = (RSDataEnclosure *)RSInsertObject(RSDataEntityNameEnclosure, moc);
    anEnclosure.URL = [aURL absoluteString];
    [self addEnclosuresObject:anEnclosure];
    return anEnclosure;
}


- (RSDataEnclosure *)fetchOrInsertEnclosureWithURL:(NSURL *)aURL moc:(NSManagedObjectContext *)moc {
    RSDataEnclosure *anEnclosure = [self fetchEnclosureWithURL:aURL moc:moc];
    if (anEnclosure == nil)
        anEnclosure = [self insertEnclosureWithURL:aURL moc:moc];
    return anEnclosure;
}


- (void)updateHasAudioAndVideoEnclosures {
    if (self.enclosures == nil) {
        self.hasAudioEnclosure = [NSNumber numberWithBool:NO];
        self.hasVideoEnclosure = [NSNumber numberWithBool:NO];
    }
    BOOL foundVideoEnclosure = NO;
    BOOL foundAudioEnclosure = NO;
    for (RSDataEnclosure *oneEnclosure in self.enclosures) {
        if ([oneEnclosure.mediaType integerValue] == RSMediaTypeAudio)
            foundAudioEnclosure = YES;
        else if ([oneEnclosure.mediaType integerValue] == RSMediaTypeVideo)
            foundVideoEnclosure = YES;
        if (foundAudioEnclosure && foundVideoEnclosure)
            break;
    }
    self.hasAudioEnclosure = [NSNumber numberWithBool:foundAudioEnclosure];
    self.hasVideoEnclosure = [NSNumber numberWithBool:foundVideoEnclosure];
}


- (RSDataEnclosure *)anyEnclosureWithMediaType:(RSMediaType)mediaType {
    for (RSDataEnclosure *oneEnclosure in self.enclosures) {
        if ([oneEnclosure.mediaType unsignedIntegerValue] == mediaType)
            return oneEnclosure;
    }
    return nil;
}


- (RSDataEnclosure *)bestAudioEnclosure {
    /*Just getting the first one. Not sure what "best" would mean."*/
    return [self anyEnclosureWithMediaType:RSMediaTypeAudio];
}


- (RSDataEnclosure *)bestMovieEnclosure {
    /*Just getting first one. //TODO: check size, bitrate, etc.*/
    return [self anyEnclosureWithMediaType:RSMediaTypeVideo];
}


- (RSDataEnclosure *)richestMediaEnclosure {
    RSDataEnclosure *mediaEnclosure = [self bestMovieEnclosure];
    if (mediaEnclosure == nil)
        mediaEnclosure = [self bestAudioEnclosure];
    return mediaEnclosure;
}


- (NSArray *)allEnclosuresWithMediaType:(RSMediaType)mediaType {
    NSMutableArray *tempArray = [NSMutableArray array];
    for (RSDataEnclosure *oneEnclosure in self.enclosures) {
        if ([oneEnclosure.mediaType unsignedIntegerValue] == mediaType)
            [tempArray addObject:oneEnclosure];
    }
    return tempArray;
}


- (NSArray *)allImageEnclosures {
    return [self allEnclosuresWithMediaType:RSMediaTypeImage];
}


- (NSArray *)allEnclosuresWithMediaTypeNotInHTMLText:(RSMediaType)mediaType {
    NSMutableArray *filteredEnclosures = [NSMutableArray array];
    NSString *articleContent = self.content.htmlText;
    for (RSDataEnclosure *oneEnclosure in [self allEnclosuresWithMediaType:mediaType]) {
        NSString *oneEnclosureURLString = oneEnclosure.URL;
        if (!RSStringIsEmpty(oneEnclosureURLString) && [articleContent rangeOfString:oneEnclosureURLString].location == NSNotFound)
            [filteredEnclosures addObject:oneEnclosure];
    }
    return filteredEnclosures;
}


- (NSArray *)allImageEnclosuresNotInHTMLText {
    return [self allEnclosuresWithMediaTypeNotInHTMLText:RSMediaTypeImage];
}


- (BOOL)thumbnailAppearsInHTMLText {
    NSString *thumbnailURLString = self.thumbnailURL;
    if (RSStringIsEmpty(thumbnailURLString))
        return NO;
    return [self.content.htmlText rangeOfString:thumbnailURLString].location != NSNotFound;
}


- (NSArray *)arrayOfURLStringsWithArrayOfEnclosures:(NSArray *)someEnclosures {
    NSMutableArray *urlStrings = [NSMutableArray array];
    for (RSDataEnclosure *oneEnclosure in someEnclosures)
        [urlStrings rs_safeAddObject:oneEnclosure.URL];
    return urlStrings;
}


- (NSArray *)allImagesNotInHTMLText { //enclosure URLs plus thumbnail
    NSMutableArray *imageURLStrings = [NSMutableArray array];
    NSArray *imageEnclosuresNotInHTMLText = [self allImageEnclosuresNotInHTMLText];
    NSArray *enclosureURLStrings = [self arrayOfURLStringsWithArrayOfEnclosures:imageEnclosuresNotInHTMLText];
    [imageURLStrings addObjectsFromArray:enclosureURLStrings];
    if (![self thumbnailAppearsInHTMLText] && !RSStringIsEmpty(self.thumbnailURL))
        [imageURLStrings addObject:self.thumbnailURL];
    return imageURLStrings;
}


- (BOOL)enclosure:(RSDataEnclosure *)enclosure isBiggerThan:(RSDataEnclosure *)otherEnclosure {
    /*Best guess. Bigger filesize means bigger; bigger height and/or width means bigger.*/
    return [enclosure.fileSize unsignedIntegerValue] > [otherEnclosure.fileSize unsignedIntegerValue] || [enclosure.width unsignedIntegerValue] > [otherEnclosure.width unsignedIntegerValue] || [enclosure.height unsignedIntegerValue] > [otherEnclosure.height unsignedIntegerValue];
}


- (RSDataEnclosure *)biggestImageEnclosureNotInHTMLText {
    /*We can't always know what the biggest one is, for sure, so it might just be the first one.*/
    NSArray *imageEnclosuresNotInHTMLText = [self allEnclosuresWithMediaTypeNotInHTMLText:RSMediaTypeImage];
    if (RSIsEmpty(imageEnclosuresNotInHTMLText))
        return nil;
    RSDataEnclosure *biggestImageEnclosure = [imageEnclosuresNotInHTMLText objectAtIndex:0];
    for (RSDataEnclosure *oneEnclosure in imageEnclosuresNotInHTMLText) {
        if (oneEnclosure == biggestImageEnclosure)
            continue; //first one
        if ([oneEnclosure.fileSize unsignedIntegerValue] > [biggestImageEnclosure.fileSize unsignedIntegerValue]) {
            biggestImageEnclosure = oneEnclosure;
            continue;
        }
        if ([self enclosure:oneEnclosure isBiggerThan:biggestImageEnclosure])
            biggestImageEnclosure = oneEnclosure;
    }
    return biggestImageEnclosure;
}


- (NSURL *)URLOfBiggestImageEnclosureNotInHTMLText {
    RSDataEnclosure *enclosure = [self biggestImageEnclosureNotInHTMLText];
    if (enclosure == nil || enclosure.URL == nil)
        return nil;
    return [NSURL URLWithString:enclosure.URL];
}


- (NSURL *)URLOfBiggestImageNotInHTMLText {
    NSURL *URL = [self URLOfBiggestImageEnclosureNotInHTMLText];
    if (URL != nil)
        return URL;
    if ([self thumbnailAppearsInHTMLText] || self.thumbnailURL == nil)
        return nil;
    return [NSURL URLWithString:self.thumbnailURL];
}


- (CGSize)sizeOfEnclosureImageWithURL:(NSURL *)imageURL {
    NSArray *imageEnclosures = [self allEnclosuresWithMediaType:RSMediaTypeImage];
    if (RSIsEmpty(imageEnclosures))
        return CGSizeZero;
    NSString *imageURLString = [imageURL absoluteString];
    for (RSDataEnclosure *oneEnclosure in [self allEnclosuresWithMediaType:RSMediaTypeImage]) {
        if ([imageURLString isEqualToString:oneEnclosure.URL]) {
            return CGSizeMake([oneEnclosure.width floatValue], [oneEnclosure.height floatValue]);
        }
    }
    return CGSizeZero;
}


@end


@implementation RSDataArticle (GoogleReaderSyncing)

- (BOOL)googleSynced {
    return [self.accountID hasPrefix:@"gr-"];
}


- (BOOL)logicalGoogleReadStateLocked {
    if ([[self primitiveServiceNoLongerTracked] boolValue])
        return YES;
    NSDate *dateCrawled = [self primitiveDateServiceArrived];
    if (dateCrawled == nil || !self.googleSynced)
        return NO;
    //TODO: google read state locked thing
//    if ([dateCrawled earlierDate:[NSDate rs_dateWithNumberOfDaysInThePast:30]] == dateCrawled || [dateCrawled earlierDate:[self.feed serviceFirstTrackedItemDate]] == dateCrawled) {
//        self.serviceNoLongerTracked = [NSNumber numberWithBool:YES];
//        return YES;
//    }
    return NO;
}


@end


