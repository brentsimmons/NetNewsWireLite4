//
//  RSDataFeed.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


/*Multiple feeds with the same URL may exist -- they'll be in different accounts.
 But each account only has one instance of a feed with a given URL.*/

@class NGFeedSpecifier;
@class RSDataArticle;
@class RSDataFolder;
@class RSDataAccount;
@class RSDataFeedSettings;
@class RSHTTPConditionalGetInfo;

@interface RSDataFeed : NSManagedObject {
}

@property (nonatomic, retain) NSString *accountIdentifier;
@property (nonatomic, retain) NSDate *dateLastUpdated;
@property (nonatomic, retain) NSString *faviconURL;
@property (nonatomic, retain) NSData *feedHash;
@property (nonatomic, retain) NSString *homePageURL;
@property (nonatomic, retain) NSString *login;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *nameForDisplay;
@property (nonatomic, retain) NSDate *serviceFirstTrackedItemDate;
@property (nonatomic, retain) NSString *serviceID;
@property (nonatomic, retain) NSNumber *sortDescending;
@property (nonatomic, retain) NSString *sortKey;
@property (nonatomic, retain) NSString *URL;
@property (nonatomic, retain) NSString *xmlBaseURL;

@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSSet *parentFolders;
@property (nonatomic, retain) RSDataFeedSettings *settings;


+ (RSDataFeed *)fetchFeedWithURL:(NSString *)aURL account:(RSDataAccount *)anAccount moc:(NSManagedObjectContext *)moc;
+ (RSDataFeed *)insertFeedWithURL:(NSString *)aURL account:(RSDataAccount *)anAccount moc:(NSManagedObjectContext *)moc;
+ (RSDataFeed *)fetchOrInsertFeedWithURL:(NSString *)aURL account:(RSDataAccount *)anAccount moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate;

+ (RSDataFeedSettings *)fetchOrInsertSettingsForFeed:(RSDataFeed *)feed moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate;

+ (NSArray *)feedSpecifiersForAccount:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc;
+ (NSArray *)feedSpecifiersForFeeds:(NSArray *)feeds account:(RSDataAccount *)account;
+ (NSArray *)notSuspendedFeedSpecifiersInAccount:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc;

+ (RSDataFeed *)fetchFeedForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc;
+ (NSArray *)fetchFeedsForFeedSpecifiers:(NSArray *)feedSpecifiers account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc;

/*Returns YES if at least one feed was deleted.*/
+ (BOOL)deleteFeedsMatchingFeedSpecifiers:(NSSet *)extraFeedsInCoreData account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc;

/*Returns YES if at least one feed was created.*/
+ (BOOL)addFeedsForFeedSpecifiers:(NSSet *)setOfConfigFeeds account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc;

- (NSSet *)fetchSetOfArticlesWithValue:(id)value forKey:(NSString *)key moc:(NSManagedObjectContext *)moc;
- (RSDataArticle *)fetchArticleWithValue:(id)value forKey:(NSString *)key moc:(NSManagedObjectContext *)moc;
//- (RSDataArticle *)fetchArticleWithGuid:(NSString *)aGuid moc:(NSManagedObjectContext *)moc;

- (RSDataArticle *)insertArticleWithMOC:(NSManagedObjectContext *)moc;

+ (RSHTTPConditionalGetInfo *)logicalConditionalGetInfoForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier account:(RSDataAccount *)account moc:(NSManagedObjectContext *)moc;

@end

@interface RSDataFeed (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(RSDataArticle *)value;
- (void)removeArticlesObject:(RSDataArticle *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

- (void)addParentFoldersObject:(RSDataFolder *)value;
- (void)removeParentFoldersObject:(RSDataFolder *)value;
- (void)addParentFolders:(NSSet *)value;
- (void)removeParentFolders:(NSSet *)value;

@end
