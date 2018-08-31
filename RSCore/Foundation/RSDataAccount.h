//
//  NNWAccount.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RSRefreshProtocols.h"
#import "RSTreeNode.h"


extern NSString *RSFeedDataDidChangeNotification;

/*Main thread only.*/

extern NSString *RSDataAccountIdentifierOnMyMac;

@class RSFeed;
@class RSFolder;

@interface RSDataAccount : NSObject <RSAccount, RSTreeNodeRepresentedObject> {
@private
    BOOL disabled;
    NSString *identifier;
    NSString *login;
    NSString *title;
    NSInteger accountType;
    NSMutableArray *feeds;
    NSMutableDictionary *feedsDictionary;
    NSString *pathToPlist;
    BOOL needsToBeSavedOnDisk;
    RSTreeNode *accountTreeNode;
    NSTimer *unreadCountTimer;
    NSTimer *totalUnreadCountTimer;
    NSUInteger unreadCount;
    NSTimer *saveAccountTimer;
}


+ (RSDataAccount *)localAccount; //one and only

- (id)initWithAccountType:(RSAccountType)aType login:(NSString *)aLogin; //designated initializer


@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *login;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSInteger accountType;
@property (nonatomic, strong, readonly) NSArray *allFeedsThatCanBeRefreshed; //all downloadable, not-suspended feeds. RSFeed array.
@property (nonatomic, strong, readonly) NSMutableArray *feeds; //RSFeed objects.
@property (nonatomic, strong, readonly) NSArray *feedURLs;
@property (nonatomic, strong, readonly) NSArray *folders; //RSFolder and NSURL (feed) objects - the tree.
@property (nonatomic, assign) BOOL needsToBeSavedOnDisk;
@property (nonatomic, strong, readonly) RSTreeNode *accountTreeNode;
@property (nonatomic, assign, readonly) NSUInteger unreadCount; //for entire account
@property (nonatomic, strong) NSString *nameForDisplay;

- (NSMutableDictionary *)dictionaryRepresentation; //for disk
//- (NSMutableArray *)arrayRepresentationOfChildren:(NSArray *)someChildren inFolder:(RSFolder *)aFolder;

- (void)addFeedWithURL:(NSURL *)feedURL;
- (void)deleteFeedWithURL:(NSURL *)feedURL;

- (RSFeed *)feedWithURL:(NSURL *)feedURL; //existing feed with URL (doesn't create)
- (NSString *)nameForDisplayForFeedWithURL:(NSURL *)feedURL;

- (void)saveToDiskIfNeeded;
- (void)saveToDiskAtShutdown;

/*Caller must call needsToBeSavedOnDisk.*/
- (void)addFeed:(RSFeed *)aFeed;
- (void)addFeed:(RSFeed *)aFeed atEndOfFolder:(RSFolder *)aFolder;


/*Folders*/

- (BOOL)folderWithNameExists:(NSString *)aFolderName;
- (RSFolder *)addFolderWithName:(NSString *)folderName;
- (RSFolder *)folderWithName:(NSString *)aFolderName; //existence, not creation

/*Unread counts*/

- (void)updateUnreadCountsOnMainThread;
- (void)markAllUnreadCountsAsInvalid;

/*Importing*/

- (void)importOPMLOutlineItems:(NSArray *)outlineItems;


@end

