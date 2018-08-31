//
//  NNWArticle.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RSDataCategory.h"
#import "RSMimeTypes.h"
#import "RSRefreshProtocols.h"


extern NSString *RSDataArticleDidDisplayNotification;
extern NSString *RSDataArticleReadStatusDidChangeNotification;
extern NSString *RSMultipleArticlesDidChangeReadStatusNotification; //for mark all as read/unread
extern NSString *RSDataDidDeleteArticlesNotification;

@class RSDataArticleContent;
@class RSDataEnclosure;


@interface RSDataArticle : NSManagedObject

@property (nonatomic, retain) NSString *accountID;
@property (nonatomic, retain) NSNumber *appearsInFeed;
@property (nonatomic, retain) NSString *authorEmail;
@property (nonatomic, retain) NSString *authorName;
@property (nonatomic, retain) NSString *authorURL;
@property (nonatomic, retain) NSString *commentsURL;
@property (nonatomic, retain) NSDate *dateArrived;
@property (nonatomic, retain) NSDate *dateForDisplay;
@property (nonatomic, retain) NSDate *dateModified;
@property (nonatomic, retain) NSDate *datePublished;
@property (nonatomic, retain) NSDate *dateServiceArrived;
@property (nonatomic, retain) NSString *feedURL;
@property (nonatomic, retain) NSNumber *followed;
@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSNumber *hasAudioEnclosure;
@property (nonatomic, retain) NSNumber *hasVideoEnclosure;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSNumber *markedForDeletion;
@property (nonatomic, retain) NSString *originalSourceFeedURL;
@property (nonatomic, retain) NSString *originalSourceTitle;
@property (nonatomic, retain) NSString *permalink;
@property (nonatomic, retain) NSString *plainTextTitle;
@property (nonatomic, retain) NSString *plainTextPreview;
@property (nonatomic, retain) NSNumber *read;
@property (nonatomic, retain) NSNumber *savedToReadLater;
@property (nonatomic, retain) NSNumber *serviceNoLongerTracked;
@property (nonatomic, retain) NSString *serviceSpecifiedOriginalGuid;
@property (nonatomic, retain) NSNumber *starred;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSString *thumbnailURL;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSNumber *titleIsHTML;
@property (nonatomic, retain) NSNumber *userDeleted;

@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) RSDataArticleContent *content;
@property (nonatomic, retain) NSSet *enclosures;



+ (RSDataArticle *)insertArticleWithFeedURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc;

//+ (RSDataArticle *)fetchArticleWithGuid:(NSString *)aGuid account:(id<RSAccount>)anAccount feedURL:(NSURL *)aFeedURL moc:(NSManagedObjectContext *)moc;

+ (NSArray *)articlesForFeedWithURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc;
+ (NSArray *)sortedArticlesForFeedsWithURLs:(NSArray *)feedURLStrings accountID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc;

+ (BOOL)anyArticlesExist:(NSManagedObjectContext *)moc;
+ (NSUInteger)unreadCountForArticlesWithFeedURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc;
//+ (NSArray *)unreadArticlesForFeedWithURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc;
+ (NSArray *)unreadArticlesForFeedsWithURLs:(NSArray *)feedURLStrings accountID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc;
+ (NSUInteger)countOfUnreadArticlesPublishedTodayInAccountWithID:(NSString *)accountID moc:(NSManagedObjectContext *)moc;
+ (NSArray *)articlesPublishedTodayInAccountWithID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc;
+ (NSArray *)unreadArticlesInAccountWithID:(NSString *)accountID sortDescriptor:(NSSortDescriptor *)aSortDescriptor moc:(NSManagedObjectContext *)moc;

- (RSDataArticleContent *)insertArticleContentWithMOC:(NSManagedObjectContext *)moc;

- (NSString *)bestLink; //permalink, then link
- (void)bestSharingTitle:(NSString **)aTitle andLink:(NSString **)aLink;

- (RSDataEnclosure *)fetchEnclosureWithURL:(NSURL *)aURL moc:(NSManagedObjectContext *)moc;
- (RSDataEnclosure *)insertEnclosureWithURL:(NSURL *)aURL moc:(NSManagedObjectContext *)moc;
- (RSDataEnclosure *)fetchOrInsertEnclosureWithURL:(NSURL *)aURL moc:(NSManagedObjectContext *)moc;
- (void)updateHasAudioAndVideoEnclosures;
- (RSDataEnclosure *)richestMediaEnclosure; //Looks for movie, then looks for audio
- (NSArray *)allEnclosuresWithMediaType:(RSMediaType)mediaType;
- (NSArray *)allImageEnclosures;
- (NSArray *)allImagesNotInHTMLText; //enclosure URLs plus thumbnail - array of URL strings
- (NSURL *)URLOfBiggestImageEnclosureNotInHTMLText;
- (NSURL *)URLOfBiggestImageNotInHTMLText; //checks enclosures first, then falls back to thumbnail
- (CGSize)sizeOfEnclosureImageWithURL:(NSURL *)imageURL; //if not found, or not specified, returns CGSizeZero

- (BOOL)thumbnailAppearsInHTMLText;

//- (NSDate *)bestDate; //datePublished, or dateModified, or dateArrived

- (void)markAsRead:(BOOL)flag;

+ (void)deleteArticlesMarkedForDeletion:(NSManagedObjectContext *)moc;
+ (void)markAsDeletedAllArticlesForFeedURL:(NSURL *)feedURL accountID:(NSString *)accountID moc:(NSManagedObjectContext *)moc;
//+ (void)undeleteArticlesForFeedURL:aFeed.URL accountID:self.identifier moc:rs_app_delegate.mainThreadManagedObjectContext];

@end

@interface RSDataArticle (CoreDataGeneratedAccessors)

- (void)addEnclosuresObject:(RSDataEnclosure *)value;
- (void)removeEnclosuresObject:(RSDataEnclosure *)value;
- (void)addEnclosures:(NSSet *)value;
- (void)removeEnclosures:(NSSet *)value;

- (void)addCategoriesObject:(RSDataCategory *)value;
- (void)removeCategoriesObject:(RSDataCategory *)value;
- (void)addCategories:(NSSet *)value;
- (void)removeCategories:(NSSet *)value;

@end


@interface RSDataArticle (GoogleReaderSyncing)

- (BOOL)googleSynced;
- (BOOL)logicalGoogleReadStateLocked;

@end
