//
//  RSDataController.h
//  RSCoreTests
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSRefreshProtocols.h"


/*Creates Core Data stack, queue, accounts, etc.*/

extern NSString *RSCoreDataModelResourceName; //@"RSData"
extern NSString *RSCoreDataStoreFileName;

@class RSDataAccount;
@class RSCoreDataStack;
@class RSArticleListController;
@class RSGlobalAccount;


@interface RSDataController : NSObject {
@private
    BOOL managedObjectContextIsDirty;
    NSArray *currentArticles;
    NSMutableArray *accounts;
    NSMutableDictionary *listControllers;
    NSOperationQueue *coreDataBackgroundOperationQueue;
    NSTimer *saveTimer;
    RSArticleListController *currentListController;
    RSCoreDataStack *coreDataStack;
    RSDataAccount *localAccount;
    RSGlobalAccount *globalAccount;
}


- (id)initWithModelResourceName:(NSString *)modelResourceName storeFileName:(NSString *)storeFileName;

@property (nonatomic, strong, readonly) NSManagedObjectContext *mainThreadManagedObjectContext;
@property (nonatomic, assign) BOOL managedObjectContextIsDirty;
@property (nonatomic, assign, readonly) NSUInteger unreadCount;

- (void)saveMainThreadManagedObjectContext;
- (void)saveManagedObjectContext:(NSManagedObjectContext *)moc;

- (NSManagedObjectContext *)temporaryManagedObjectContext; //for an NSOperation, for instance
- (void)addCoreDataBackgroundOperation:(NSOperation *)coreDataBackgroundOperation;
- (void)cancelCoreDataBackgroundOperations;
- (void)waitUntilCoreDataBackgroundOperationsAreFinished;


/*Accounts*/

@property (nonatomic, strong, readonly) RSDataAccount *localAccount;
@property (nonatomic, strong, readonly) RSGlobalAccount *globalAccount;

- (id<RSAccount>)accountWithID:(NSString *)anAccountID; //finds existing account

- (void)updateAllUnreadCountsOnMainThread; //needed by next-unread, to be sure counts are accurate
- (void)markAllUnreadCountsAsInvalid;

- (void)saveAllAccounts;


/*Feeds*/

- (BOOL)anyAccountIsSubscribedToFeedWithURL:(NSURL *)aFeedURL;

- (void)makeAllAccountsDirty; //like after making major changes to the feeds/folders tree

/*List Controllers*/

@property (nonatomic, strong) RSArticleListController *currentListController; //the one containing data the user is looking at
- (void)setListController:(RSArticleListController *)aListController forKey:(NSString *)aKey;

/*Articles*/

@property (nonatomic, strong) NSArray *currentArticles; //the ones the user has selected

@end
