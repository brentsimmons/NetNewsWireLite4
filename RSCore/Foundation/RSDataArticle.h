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

@property (nonatomic, strong) NSString *accountID;
@property (nonatomic, strong) NSNumber *appearsInFeed;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *commentsURL;
@property (nonatomic, strong) NSDate *dateArrived;
@property (nonatomic, strong) NSDate *dateForDisplay;
@property (nonatomic, strong) NSDate *dateModified;
@property (nonatomic, strong) NSDate *datePublished;
@property (nonatomic, strong) NSDate *dateServiceArrived;
@property (nonatomic, strong) NSString *feedURL;
@property (nonatomic, strong) NSNumber *followed;
@property (nonatomic, strong) NSString *guid;
@property (nonatomic, strong) NSNumber *hasAudioEnclosure;
@property (nonatomic, strong) NSNumber *hasVideoEnclosure;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSNumber *markedForDeletion;
@property (nonatomic, strong) NSString *originalSourceFeedURL;
@property (nonatomic, strong) NSString *originalSourceTitle;
@property (nonatomic, strong) NSString *permalink;
@property (nonatomic, strong) NSString *plainTextTitle;
@property (nonatomic, strong) NSString *plainTextPreview;
@property (nonatomic, strong) NSNumber *read;
@property (nonatomic, strong) NSNumber *savedToReadLater;
@property (nonatomic, strong) NSNumber *serviceNoLongerTracked;
@property (nonatomic, strong) NSString *serviceSpecifiedOriginalGuid;
@property (nonatomic, strong) NSNumber *starred;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSString *thumbnailURL;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *titleIsHTML;
@property (nonatomic, strong) NSNumber *userDeleted;

@property (nonatomic, strong) NSSet *categories;
@property (nonatomic, strong) RSDataArticleContent *content;
@property (nonatomic, strong) NSSet *enclosures;



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
