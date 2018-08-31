//
//  RSDataAccount.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataAccount.h"
#import "RSCoreDataUtilities.h"
#import "RSDataManagedObjects.h"
#import "RSFeed.h"
#import "RSFeedCountUnreadOperation.h"
#import "RSFileUtilities.h"
#import "RSFolder.h"
#import "RSLocalAccountFeedMetadataCache.h"
#import "RSOperationController.h"
#import "RSParsedFeedInfo.h"
#import "RSRefreshController.h"
#import "RSRefreshProtocols.h"
#import "RSSaveAccountOperation.h"
#import "RSUpdateUnreadCountsOperation.h"


NSString *RSFeedDataDidChangeNotification = @"RSFeedDataDidChangeNotification";

NSString *RSDataAccountIdentifierOnMyMac = @"Local";
NSString *RSDataAccountIdentifierGoogleReaderFormat = @"GR-%@";

static NSString *RSDataAccountIdentifierForGoogleReaderWithLogin(NSString *login) {
    return [NSString stringWithFormat:RSDataAccountIdentifierGoogleReaderFormat, login];
}

static NSString *RSDataAccountTypeKey = @"type";
static NSString *RSDataAccountLoginKey = @"login";
static NSString *RSDataAccountTitleKey = @"title";
static NSString *RSDataAccountDisabledKey = @"disabled";
static NSString *RSDataAccountFeedsKey = @"feeds";
static NSString *RSDataAccountTreeKey = @"tree";
static NSString *RSDataAccountChildrenKey = @"children";
static NSString *RSDataAccountExpandedFoldersKey = @"expandedFolders";


static RSDataAccount *gLocalAccount = nil;

@interface RSDataAccount ()

@property (nonatomic, strong, readwrite) NSMutableArray *feeds;
@property (nonatomic, strong) NSMutableDictionary *feedsDictionary;
@property (nonatomic, strong, readwrite) NSMutableArray *folders;
@property (nonatomic, strong, readwrite) RSTreeNode *accountTreeNode;
@property (nonatomic, strong) NSTimer *unreadCountTimer;
@property (nonatomic, assign, readwrite) NSUInteger unreadCount;
@property (nonatomic, strong) NSTimer *totalUnreadCountTimer;
@property (nonatomic, strong) NSTimer *saveAccountTimer;

- (void)addTreeToDictionary:(NSMutableDictionary *)accountDictionary;
- (void)loadFeedsAndFoldersFromDisk;
- (void)addFeedsToDictionary:(NSMutableDictionary *)accountDictionary;
- (void)addExpandedFolderNamesToDictionary:(NSMutableDictionary *)accountDictionary;

- (void)loadFeedsFromAccountDictionary:(NSDictionary *)accountDictionary;
- (void)buildTreeFromAccountDictionary:(NSDictionary *)anAccountDictionary;
- (void)backupAccountFile;

- (void)updateTotalUnreadCount;

@end


@implementation RSDataAccount

@synthesize accountTreeNode;
@synthesize accountType;
@synthesize disabled;
@synthesize feeds;
@synthesize feedsDictionary;
@synthesize folders;
@synthesize identifier;
@synthesize login;
@synthesize nameForDisplay;
@synthesize needsToBeSavedOnDisk;
@synthesize saveAccountTimer;
@synthesize title;
@synthesize totalUnreadCountTimer;
@synthesize unreadCount;
@synthesize unreadCountTimer;


#pragma mark Class Methods

+ (RSDataAccount *)localAccount {
    /*The one and only.*/
    if (gLocalAccount == nil)
        gLocalAccount = [[self alloc] initWithAccountType:RSAccountTypeLocal login:nil];
    return gLocalAccount;
}


#pragma mark Init

- (id)initWithAccountType:(RSAccountType)aType login:(NSString *)aLogin {
    self = [super init];
    if (self == nil)
        return nil;
    
    accountType = aType;
    login = [aLogin copy];
    if (aType == RSAccountTypeLocal)
        identifier = RSDataAccountIdentifierOnMyMac;
    else if (aType == RSAccountTypeGoogleReader && !RSStringIsEmpty(aLogin))
        identifier = RSDataAccountIdentifierForGoogleReaderWithLogin(aLogin);
    feeds = [NSMutableArray array];
    feedsDictionary = [NSMutableDictionary dictionary];
    [self backupAccountFile];
    [self loadFeedsAndFoldersFromDisk];
    [self updateTotalUnreadCount];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parserDidParseFeedInfo:) name:RSDidParseFeedInfoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleReadStatusDidChange:) name:RSDataArticleReadStatusDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(multipleArticleReadStatusDidChange:) name:RSMultipleArticlesDidChangeReadStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDidUpdateFeed:) name:RSRefreshDidUpdateFeedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSessionDidEnd:) name:RSRefreshSessionDidEndNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadCountDidCalculate:) name:RSUnreadCountDidCalculateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsSelected:) name:NNWFeedsSelectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(treeDidDeleteItems:) name:RSTreeDidDeleteItemsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articlesWereDeleted:) name:RSDataDidDeleteArticlesNotification object:nil];
    [self performSelectorOnMainThread:@selector(updateUnreadCounts) withObject:nil waitUntilDone:NO];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [unreadCountTimer rs_invalidateIfValid];
    [totalUnreadCountTimer rs_invalidateIfValid];
    [saveAccountTimer rs_invalidateIfValid];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Disk

- (NSMutableDictionary *)dictionaryRepresentation { //for disk
    NSMutableDictionary *accountDictionary = [NSMutableDictionary dictionary];
    [accountDictionary rs_safeSetObject:self.login forKey:RSDataAccountLoginKey];
    [accountDictionary rs_setInteger:self.accountType forKey:RSDataAccountTypeKey];
    [accountDictionary rs_safeSetObject:self.title forKey:RSDataAccountTitleKey];
    if (self.disabled)
        [accountDictionary rs_setBool:YES forKey:RSDataAccountDisabledKey];
    [self addFeedsToDictionary:accountDictionary];
    [self addTreeToDictionary:accountDictionary];
    [self addExpandedFolderNamesToDictionary:accountDictionary];
    [accountDictionary setObject:[NSNumber numberWithUnsignedInteger:self.unreadCount] forKey:@"unreadCount"];
    return accountDictionary;    
}


- (NSString *)pathToPlist {
    if (pathToPlist != nil)
        return pathToPlist;
    NSString *filename = [NSString stringWithFormat:@"%@Feeds.plist", self.identifier];
    pathToPlist = [rs_app_delegate.pathToDataFolder stringByAppendingPathComponent:filename];
//    pathToPlist = [RSAppSupportFilePath(filename) retain];
    return pathToPlist;
}


- (NSDictionary *)accountDictionary {
    return [NSDictionary dictionaryWithContentsOfFile:[self pathToPlist]];
}


- (void)loadFeedsAndFoldersFromDisk {
    NSDictionary *anAccountDictionary = [self accountDictionary];
    [self loadFeedsFromAccountDictionary:anAccountDictionary];
    [self buildTreeFromAccountDictionary:anAccountDictionary];
    NSNumber *unreadCountNum = [anAccountDictionary objectForKey:@"unreadCount"];
    if (unreadCountNum != nil)
        self.unreadCount = [unreadCountNum unsignedIntegerValue];
}


- (void)saveToDisk {
    NSDictionary *dictionaryRepresentation = [self dictionaryRepresentation];
    if (!RSIsEmpty(dictionaryRepresentation)) {
        @synchronized(self) {
            [dictionaryRepresentation rs_writeToFile:self.pathToPlist useBinaryFormat:YES];
        }
    }
    //        [dictionaryRepresentation writeToFile:self.pathToPlist atomically:YES];
    self.needsToBeSavedOnDisk = NO;
    for (RSFeed *oneFeed in self.feeds)
        oneFeed.needsToBeSavedOnDisk = NO;
}


- (void)saveToDiskIfNeeded {
    if (self.needsToBeSavedOnDisk)
        [self saveToDisk];
}


- (void)saveToDiskAtShutdown {
    [self saveToDisk];
}


- (void)saveDictionaryToDiskInBackground:(NSDictionary *)aDictionary {
    @synchronized(self) {
        [aDictionary rs_writeToFile:self.pathToPlist useBinaryFormat:YES];
    }
}


- (void)saveToDiskInBackgroundIfNeeded {
    if (self.needsToBeSavedOnDisk) {
        NSDictionary *dictionaryRepresentation = [self dictionaryRepresentation];
        if (RSIsEmpty(dictionaryRepresentation))
            return;
        
        NSInvocationOperation *saveOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveDictionaryToDiskInBackground:) object:dictionaryRepresentation];
        [saveOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
        [[RSOperationController sharedController] addOperation:saveOperation];    
    
        self.needsToBeSavedOnDisk = NO;
        for (RSFeed *oneFeed in self.feeds)
            oneFeed.needsToBeSavedOnDisk = NO;        
    }
}
     
     
#pragma mark Backups

- (NSString *)backupFilePathForToday {
    NSString *dateString = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale: nil];    
    NSString *filename = [NSString stringWithFormat:@"%@Feeds %@.plist", self.identifier, dateString];
    NSString *folder = [rs_app_delegate.pathToDataFolder stringByAppendingPathComponent:@"Backups"];
    RSSureFolder(folder);
    return [folder stringByAppendingPathComponent:filename];
}


- (void)backupAccountFile {
    NSString *dest = [self backupFilePathForToday];
    NSString *source = [self pathToPlist];    
    if (RSFileExists(dest) || !RSFileExists(source))
        return;
    RSFileCopy(source, dest);
}


#pragma mark Folders - Archiving

- (id)diskRepresentationForObject:(id)anObject {
    if ([anObject isKindOfClass:[RSFolder class]])
        return [(RSFolder *)anObject dictionaryRepresentation];
    if ([anObject isKindOfClass:[RSFeed class]]) {
        NSString *urlString = [((RSFeed *)anObject).URL absoluteString];
        if (!RSStringIsEmpty(urlString))
            return urlString;
    }
    return nil;        
}


- (void)addChildNodesOf:(RSTreeNode *)aTreeNode toArray:(NSMutableArray *)anArray {
    for (RSTreeNode *oneNode in aTreeNode.children) {
        id diskRepresentation = [self diskRepresentationForObject:oneNode.representedObject];
        [anArray rs_safeAddObject:diskRepresentation];
        if (oneNode.hasChildren) {
            NSMutableArray *childrenArray = [NSMutableArray array];
            [self addChildNodesOf:oneNode toArray:childrenArray];
            if ([diskRepresentation isKindOfClass:[NSMutableDictionary class]])
                [(NSMutableDictionary *)diskRepresentation setObject:childrenArray forKey:RSDataAccountChildrenKey];
        }
    }
}


- (void)addTreeToDictionary:(NSMutableDictionary *)accountDictionary {
    NSMutableArray *treeAsArray = [NSMutableArray array];
    [self addChildNodesOf:self.accountTreeNode toArray:treeAsArray];
    [accountDictionary setObject:treeAsArray forKey:RSDataAccountTreeKey];
}


- (void)addExpandedFolderNamesToDictionary:(NSMutableDictionary *)accountDictionary {
    NSMutableArray *namesOfExpandedFolders = [NSMutableArray array];
    for (RSTreeNode *oneTreeNode in self.accountTreeNode.children) {
        if (!oneTreeNode.isGroup || !oneTreeNode.expanded)
            continue;
        [namesOfExpandedFolders rs_safeAddObject:oneTreeNode.representedObject.nameForDisplay];
    }
    if (!RSIsEmpty(namesOfExpandedFolders))
        [accountDictionary setObject:namesOfExpandedFolders forKey:RSDataAccountExpandedFoldersKey];
}


#pragma mark Folders - Unarchiving

/*Feeds have a single array of all feeds, while folders are stored in a tree.
 The children of folders that are feeds use just a URL, which is the feed URL.
 This way a feed can appear in multiple places.*/


//- (NSMutableArray *)childrenWithDiskArrayOfChildren:(NSArray *)someDiskChildren {
//    NSMutableArray *unarchivedFoldersAndFeeds = [NSMutableArray array];
//    for (id oneObject in someDiskChildren) {
//        if ([oneObject isKindOfClass:[NSDictionary class]]) {
//            RSFolder *oneFolder = [[[RSFolder alloc] initWithDiskDictionary:oneObject inAccount:self] autorelease];
//            [unarchivedFoldersAndFeeds rs_safeAddObject:oneFolder];
//        }
//        else if ([oneObject isKindOfClass:[NSString class]])
//            [unarchivedFoldersAndFeeds rs_safeAddObject:[NSURL URLWithString:oneObject]];
//    }
//    return unarchivedFoldersAndFeeds;
//}
//
//
//- (void)loadFoldersFromAccountDictionary:(NSDictionary *)anAccountDictionary {
//    NSArray *someFolders = [anAccountDictionary objectForKey:RSDataAccountFoldersKey];
//    if (RSIsEmpty(someFolders)) { /*Just feeds. Top-level. URLs.*/
//        self.folders = self.feedURLs;
//        return;
//    }
//    self.folders = [self childrenWithDiskArrayOfChildren:someFolders];
//}


- (void)addArchivedItems:(NSArray *)archivedItems toTreeNode:(RSTreeNode *)aTreeNode {
    
    NSMutableArray *childNodes = [NSMutableArray array];
    
    for (id oneItem in archivedItems) {
        
        RSTreeNode *oneTreeNode = nil;
        
        if ([oneItem isKindOfClass:[NSDictionary class]]) {
            RSFolder *oneFolder = [[RSFolder alloc] initWithDiskDictionary:oneItem inAccount:self];
            oneTreeNode = [RSTreeNode treeNodeWithParent:aTreeNode representedObject:oneFolder];
            oneTreeNode.isGroup = YES;
            oneFolder.treeNode = oneTreeNode;
            NSArray *folderChildren = [oneItem objectForKey:RSDataAccountChildrenKey];
            if (!RSIsEmpty(folderChildren))
                [self addArchivedItems:folderChildren toTreeNode:oneTreeNode];
        }
        
        else if ([oneItem isKindOfClass:[NSString class]]) {
            NSURL *oneURL = [NSURL URLWithString:oneItem];
            RSFeed *oneFeed = [self.feedsDictionary objectForKey:oneURL];
            if (oneFeed != nil)
                oneTreeNode = [RSTreeNode treeNodeWithParent:aTreeNode representedObject:oneFeed];
        }
        
        [childNodes rs_safeAddObject:oneTreeNode]; 
    }
    
    aTreeNode.children = childNodes;
}


- (void)addExpansionStates:(NSArray *)namesOfExpandedFolders toTreeNode:(RSTreeNode *)aTreeNode {
    if (RSIsEmpty(namesOfExpandedFolders))
        return;
    for (RSTreeNode *oneTreeNode in aTreeNode.children) {
        if (!oneTreeNode.isGroup)
            continue;
        NSString *folderName = oneTreeNode.representedObject.nameForDisplay;
        if (RSStringIsEmpty(folderName))
            continue;
        if ([namesOfExpandedFolders containsObject:folderName])
            oneTreeNode.expanded = YES;
    }
}


- (void)buildTreeFromAccountDictionary:(NSDictionary *)anAccountDictionary {
    self.accountTreeNode = [RSTreeNode treeNodeWithParent:nil representedObject:self];
    self.accountTreeNode.isSpecialGroup = YES;
    self.accountTreeNode.isGroup = YES;
    self.accountTreeNode.sortKeyForOrderingChildren = @"name";
    self.accountTreeNode.allowsDragging = NO;
    [self addArchivedItems:[anAccountDictionary objectForKey:RSDataAccountTreeKey] toTreeNode:self.accountTreeNode];
    [self addExpansionStates:[anAccountDictionary objectForKey:RSDataAccountExpandedFoldersKey] toTreeNode:self.accountTreeNode];
}


#pragma mark Folders - General

- (RSFolder *)folderWithName:(NSString *)aFolderName {
    /*Folders are case-insensitive.*/
    NSParameterAssert(!RSStringIsEmpty(aFolderName));
    for (RSTreeNode *oneTreeNode in self.accountTreeNode.children) {
        if (!oneTreeNode.isGroup)
            continue;
        if ([aFolderName caseInsensitiveCompare:oneTreeNode.representedObject.nameForDisplay] == NSOrderedSame)
            return oneTreeNode.representedObject;
    }
    return nil;
}


- (BOOL)folderWithNameExists:(NSString *)aFolderName {
    return [self folderWithName:aFolderName] != nil;
}


- (RSFolder *)addFolderWithName:(NSString *)folderName {
    NSParameterAssert(!RSStringIsEmpty(folderName));
    if ([self folderWithNameExists:folderName])
        return nil;
    RSFolder *aFolder = [[RSFolder alloc] initWithName:folderName account:self];
    RSTreeNode *folderTreeNode = [RSTreeNode treeNodeWithParent:self.accountTreeNode representedObject:aFolder];
    folderTreeNode.isGroup = YES;
    [self.accountTreeNode addChild:folderTreeNode];
    aFolder.treeNode = folderTreeNode;
    return aFolder;
}


- (void)markAllUnreadCountsForFoldersAsInvalid {
    for (RSTreeNode *oneTreeNode in self.accountTreeNode.children) {
        if (!oneTreeNode.isGroup)
            continue;
        RSFolder *oneFolder = oneTreeNode.representedObject;
        if ([oneFolder respondsToSelector:@selector(setUnreadCountIsValid:)])
            oneFolder.unreadCountIsValid = NO;
    }    
}


#pragma mark Feeds

- (void)addFeedsToDictionary:(NSMutableDictionary *)accountDictionary {
    NSMutableArray *tempFeeds = [NSMutableArray arrayWithCapacity:[self.feeds count]];
    for (RSFeed *oneFeed in self.feeds) {
        if (!oneFeed.deleted)
            [tempFeeds rs_safeAddObject:[oneFeed dictionaryRepresentation]];
    }
    [accountDictionary rs_safeSetObject:tempFeeds forKey:RSDataAccountFeedsKey];
}


- (void)loadFeedsFromAccountDictionary:(NSDictionary *)accountDictionary {
    NSArray *feedsFromDisk = [accountDictionary objectForKey:RSDataAccountFeedsKey];
    if (RSIsEmpty(feedsFromDisk))
        return;
    NSMutableArray *tempFeedsArray = [NSMutableArray arrayWithCapacity:[feedsFromDisk count]];
    NSMutableDictionary *tempFeedsDictionary = [NSMutableDictionary dictionaryWithCapacity:[feedsFromDisk count]];
    for (NSDictionary *oneFeedDictionary in feedsFromDisk) {
        RSFeed *oneFeed = [[RSFeed alloc] initWithDiskDictionary:oneFeedDictionary inAccount:self];
        if (RSIsEmpty(oneFeed.URL))
            continue;
        [tempFeedsArray addObject:oneFeed];
        [tempFeedsDictionary setObject:oneFeed forKey:oneFeed.URL];
    }
    self.feeds = tempFeedsArray;
    self.feedsDictionary = tempFeedsDictionary;
}


- (NSArray *)allFeedsThatCanBeRefreshed {
    NSMutableArray *feedsThatCanBeRefreshed = [NSMutableArray arrayWithCapacity:[self.feeds count]];
    for (RSFeed *oneFeed in self.feeds) {
        if (oneFeed.canBeRefreshed)
            [feedsThatCanBeRefreshed addObject:oneFeed];
    }
    return feedsThatCanBeRefreshed;
}


- (NSArray *)feedURLs {
    return [self.feeds valueForKey:@"URL"];
}


- (RSFeed *)feedWithURL:(NSURL *)feedURL {
    return [self.feedsDictionary objectForKey:feedURL];
}


- (void)rebuildFeedsDictionary {
    [self.feedsDictionary removeAllObjects];
    NSMutableArray *feedsArray = [NSMutableArray array];
    NSArray *allTreeNodes = [self.accountTreeNode flatItems];
    for (RSTreeNode *oneTreeNode in allTreeNodes) {
        if (oneTreeNode.isGroup || oneTreeNode.isSpecialGroup)
            continue;
        RSFeed *oneFeed = oneTreeNode.representedObject;
        [feedsArray addObject:oneFeed];
        NSURL *oneURL = oneFeed.URL;
        if (oneURL != nil)
            [self.feedsDictionary setObject:oneFeed forKey:oneURL];
    }
    self.feeds = feedsArray;
}


- (NSString *)nameForDisplayForFeedWithURL:(NSURL *)feedURL {
    return [self feedWithURL:feedURL].nameForDisplay;
}


- (void)deleteFeedWithURL:(NSURL *)feedURL {
    RSFeed *feed = [self feedWithURL:feedURL];
    feed.deleted = YES;
    self.needsToBeSavedOnDisk = YES;
}


- (void)addFeedWithURL:(NSURL *)feedURL {
    RSFeed *existingFeedWithURL = [self feedWithURL:feedURL];
    if (!existingFeedWithURL) {
        RSFeed *feed = [RSFeed feedWithURL:feedURL account:self];
        [self.feeds rs_safeAddObject:feed];
        [self.feedsDictionary rs_safeSetObject:feed forKey:feedURL];
        self.needsToBeSavedOnDisk = YES;
    }
}


- (void)addFeed:(RSFeed *)aFeed {
    RSFeed *existingFeedWithURL = [self feedWithURL:aFeed.URL];
    if (!existingFeedWithURL) {
        [self.feeds rs_safeAddObject:aFeed];
        [self.feedsDictionary rs_safeSetObject:aFeed forKey:aFeed.URL];
        RSTreeNode *feedTreeNode = [RSTreeNode treeNodeWithParent:self.accountTreeNode representedObject:aFeed];
        [self.accountTreeNode addChild:feedTreeNode];
    }
}


- (void)addFeed:(RSFeed *)aFeed atEndOfFolder:(RSFolder *)aFolder {
    if (aFolder == nil) {
        [self addFeed:aFeed];
        if (aFeed.URL != nil)
            [[RSLocalAccountFeedMetadataCache sharedCache] deleteInfoForFeedURL:aFeed.URL];
        return;
    }
    [self.feeds rs_safeAddObject:aFeed];
    [self.feedsDictionary rs_safeSetObject:aFeed forKey:aFeed.URL];
    RSTreeNode *feedTreeNode = [RSTreeNode treeNodeWithParent:aFolder.treeNode representedObject:aFeed];
    [aFolder.treeNode addChild:feedTreeNode];
    if (aFeed.URL != nil)
        [[RSLocalAccountFeedMetadataCache sharedCache] deleteInfoForFeedURL:aFeed.URL];
}


- (void)updateTotalUnreadCount {
    NSUInteger anUnreadCount = 0;
    for (RSFeed *oneFeed in self.feeds)
        anUnreadCount += oneFeed.unreadCount;
    for (RSTreeNode *oneTreeNode in self.accountTreeNode.children) {
        if (!oneTreeNode.isGroup)
            continue;
        RSFolder *oneFolder = oneTreeNode.representedObject;
        if ([oneFolder respondsToSelector:@selector(updateUnreadCount)])
            [oneFolder updateUnreadCount];
    }    
    
    self.unreadCount = anUnreadCount;
}


- (void)totalUnreadCountTimerDidFire:(NSTimer *)aTimer {
    [self.totalUnreadCountTimer rs_invalidateIfValid];
    self.totalUnreadCountTimer = nil;
    [self updateTotalUnreadCount];
}


- (void)scheduleTotalUnreadCountUpdate {
    static NSUInteger numberOfPostpones = 0;
    if (self.totalUnreadCountTimer != nil) {
        [self.totalUnreadCountTimer rs_invalidateIfValid];
        self.totalUnreadCountTimer = nil;
    }
    
    if (rs_app_delegate.appIsShuttingDown)
        return;
    
    numberOfPostpones++;
    if (numberOfPostpones > 60) {
        numberOfPostpones = 0;
        [self totalUnreadCountTimerDidFire:nil];
        return;
    }

    NSTimeInterval delayBeforeCalculatingTotalUnreadCount = 0.1;
    if (rs_app_delegate.refreshInProgress)
        delayBeforeCalculatingTotalUnreadCount = 1.0;
    self.totalUnreadCountTimer = [NSTimer scheduledTimerWithTimeInterval:delayBeforeCalculatingTotalUnreadCount target:self selector:@selector(totalUnreadCountTimerDidFire:) userInfo:nil repeats:NO];
}


- (void)feedCountUnreadOperationDidComplete:(RSFeedCountUnreadOperation *)countUnreadOperation {
    NSURL *feedURL = countUnreadOperation.feedURL;
    if (feedURL == nil)
        return;
    RSFeed *feed = [self feedWithURL:feedURL];
    if (feed == nil)
        return;
    feed.unreadCount = countUnreadOperation.unreadCount;
    feed.unreadCountIsValid = YES;
    [self scheduleTotalUnreadCountUpdate];
}


- (void)updateUnreadCountsOnMainThread {
    for (RSFeed *oneFeed in self.feeds) {
        if (oneFeed.unreadCountIsValid)
            continue;
        NSUInteger oneUnreadCount = [RSDataArticle unreadCountForArticlesWithFeedURL:oneFeed.URL accountID:self.identifier moc:rs_app_delegate.mainThreadManagedObjectContext];
        oneFeed.unreadCount = oneUnreadCount;
        oneFeed.unreadCountIsValid = YES;
    }
    [self updateTotalUnreadCount];    
}


//- (void)unreadCountOperationDidComplete:(RSUpdateUnreadCountsOperation *)updatedUnreadCountsOperation {
//    NSArray *updatedUnreadCounts = updatedUnreadCountsOperation.unreadCounts;
//    if (RSIsEmpty(updatedUnreadCounts))
//        return;
//    for (RSUpdatedUnreadCount *oneUpdatedUnreadCount in updatedUnreadCounts) {
//        NSURL *oneFeedURL = oneUpdatedUnreadCount.feedURL;
//        RSFeed *oneFeed = [self feedWithURL:oneFeedURL];
//        if (oneFeed == nil)
//            continue;
//        oneFeed.unreadCount = oneUpdatedUnreadCount.unreadCount;
//        oneFeed.unreadCountIsValid = YES;
//    }
//}


- (void)unreadCountDidCalculate:(NSNotification *)note {
    NSURL *feedURL = [[note userInfo] objectForKey:RSURLKey];
    NSNumber *unreadCountNum = [[note userInfo] objectForKey:@"unreadCount"];
    if (feedURL == nil || unreadCountNum == nil)
        return;
    RSFeed *feed = [self feedWithURL:feedURL];
    if (feedURL == nil)
        return;
    NSLog(@"feedURL: %@", feedURL);
    feed.unreadCount = [unreadCountNum unsignedIntegerValue];
    feed.unreadCountIsValid = YES;
    [self scheduleTotalUnreadCountUpdate];
}


- (void)updateUnreadCounts {
//    NSMutableArray *URLsOfFeedsWithInvalidUnreadCount = [NSMutableArray array];
    for (RSFeed *oneFeed in self.feeds) {
        if (oneFeed.unreadCountIsValid)
            continue;
            //[URLsOfFeedsWithInvalidUnreadCount rs_safeAddObject:oneFeed.URL];
        RSFeedCountUnreadOperation *countUnreadOperation = [[RSFeedCountUnreadOperation alloc] initWithFeedURL:oneFeed.URL accountID:self.identifier delegate:self callbackSelector:@selector(feedCountUnreadOperationDidComplete:)];
        //NSLog(@"updateUnreadCounts %@", oneFeed.URL);
        [countUnreadOperation setQueuePriority:NSOperationQueuePriorityLow];
        countUnreadOperation.operationType = RSOperationTypeUpdateUnreadCount;
        countUnreadOperation.operationObject = oneFeed.URL;
//        [rs_app_delegate.dataController addCoreDataBackgroundOperation:countUnreadOperation];
        /*Since it's read-only, just doing a count, we can run this on the wider general operation queue.*/
        //[[RSOperationController sharedController] addOperation:countUnreadOperation];
        RSAddOperationIfNotInQueue(countUnreadOperation);
    }
//    if (!RSIsEmpty(URLsOfFeedsWithInvalidUnreadCount)) {
//        RSUpdateUnreadCountsOperation *updateUnreadCountsOperation = [[[RSUpdateUnreadCountsOperation alloc] initWithFeedURLs:URLsOfFeedsWithInvalidUnreadCount accountID:self.identifier delegate:nil callbackSelector:nil] autorelease];
//        updateUnreadCountsOperation.operationType = RSOperationTypeUpdateUnreadCount;
//        updateUnreadCountsOperation.operationObject = URLsOfFeedsWithInvalidUnreadCount;
//        RSAddOperationIfNotInQueue(updateUnreadCountsOperation);
////        [[RSOperationController sharedController] addOperation:updateUnreadCountsOperation];
//    }
}


- (void)unreadCountTimerDidFire:(NSTimer *)aTimer {
    [self.unreadCountTimer rs_invalidateIfValid];
    self.unreadCountTimer = nil;
    [self updateUnreadCounts];
}


- (void)scheduleUnreadCountUpdate {
    if (self.unreadCountTimer != nil) {
        [self.unreadCountTimer rs_invalidateIfValid];
        self.unreadCountTimer = nil;
    }
    if (rs_app_delegate.appIsShuttingDown)
        return;
    NSTimeInterval timeUntilRunningUnreadCountOperations = 0.15;
    if (rs_app_delegate.refreshInProgress)
        timeUntilRunningUnreadCountOperations = 1.0;
    self.unreadCountTimer = [NSTimer scheduledTimerWithTimeInterval:timeUntilRunningUnreadCountOperations target:self selector:@selector(unreadCountTimerDidFire:) userInfo:nil repeats:NO];
}


- (void)markAllFeedUnreadCountsAsInvalid {
    for (RSFeed *oneFeed in self.feeds)
        oneFeed.unreadCountIsValid = NO;    
}


- (void)markAllUnreadCountsAsInvalid {
    [self markAllUnreadCountsForFoldersAsInvalid];
    [self scheduleUnreadCountUpdate];
}


#pragma mark Import OPML

- (void)importOPMLOutlineItems:(NSArray *)outlineItems folderName:(NSString *)folderName {
    
    RSFolder *parentFolder = nil;
    
    if (!RSStringIsEmpty(folderName)) {
        parentFolder = [self folderWithName:folderName];
        if (parentFolder == nil)
            parentFolder = [self addFolderWithName:folderName];
    }
    
    
    for (NSDictionary *oneOutlineItem in outlineItems) {
        
        NSString *oneTitle = [oneOutlineItem rs_objectForCaseInsensitiveKey:@"title"];
        if (RSStringIsEmpty(oneTitle))
            oneTitle = [oneOutlineItem rs_objectForCaseInsensitiveKey:@"text"];
        
        NSArray *children = [oneOutlineItem objectForKey:@"_children"];
        if (!RSIsEmpty(children)) {
            if (folderName == nil) //top-level
                [self importOPMLOutlineItems:children folderName:oneTitle];
            else
                [self importOPMLOutlineItems:children folderName:folderName]; //flattening out folders
            continue;
        }
        
        NSString *feedURLString = [oneOutlineItem rs_objectForCaseInsensitiveKey:@"xmlurl"];
        NSString *homeURLString = [oneOutlineItem rs_objectForCaseInsensitiveKey:@"htmlurl"];
        
        if (RSStringIsEmpty(feedURLString))
            continue;
        if (RSURLIsFeedURL(feedURLString)) //in case URLs start with "feed:"
            feedURLString = RSURLWithFeedURL(feedURLString);
        
        NSURL *feedURL = [NSURL URLWithString:feedURLString];
        if ([self feedWithURL:feedURL] != nil)
            continue;
        
        RSFeed *addedFeed = [RSFeed feedWithURL:feedURL account:self];
        if (!RSStringIsEmpty(homeURLString))
            addedFeed.homePageURL =    [NSURL URLWithString:homeURLString];
        addedFeed.userSpecifiedName = oneTitle;
        
        [self addFeed:addedFeed atEndOfFolder:parentFolder];
    }
    
    self.needsToBeSavedOnDisk = YES;
}


- (void)importOPMLOutlineItems:(NSArray *)outlineItems {
    /*Too bad it isn't an RSTree.*/
    [self importOPMLOutlineItems:outlineItems folderName:nil];
}


#pragma mark Notifications

- (void)parserDidParseFeedInfo:(NSNotification *)note {
    if (rs_app_delegate.appIsShuttingDown)
        return;
    RSParsedFeedInfo *feedInfo = [note object];
    if (feedInfo == nil)
        return;
    NSURL *aFeedURL = [NSURL URLWithString:feedInfo.feedURLString];
    if (aFeedURL == nil)
        return;
    RSFeed *aFeed = [self feedWithURL:aFeedURL];
    if (aFeed == nil)
        return;
    BOOL didChangeData = NO;
    if (!RSStringIsEmpty(feedInfo.title)) {
        if (![feedInfo.title isEqualToString:aFeed.feedSpecifiedName]) {
            aFeed.feedSpecifiedName = feedInfo.title;
            didChangeData = YES;
        }
    }
    if (!RSStringIsEmpty(feedInfo.homePageURLString)) {
        if (![feedInfo.homePageURLString isEqualToString:[aFeed.homePageURL absoluteString]]) {
            aFeed.homePageURL = [NSURL URLWithString:feedInfo.homePageURLString];
            didChangeData = YES;
        }
    }
    if (didChangeData) {
        aFeed.needsToBeSavedOnDisk = YES;
        [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSFeedDataDidChangeNotification object:aFeed userInfo:nil];
    }
}


- (void)invalidateUnreadCountForFeedWithArticle:(RSDataArticle *)changedArticle {
    NSString *changedFeedURLString = changedArticle.feedURL;
    if (RSStringIsEmpty(changedFeedURLString))
        return;
    NSURL *changedFeedURL = [NSURL URLWithString:changedFeedURLString];
    RSFeed *changedFeed = [self feedWithURL:changedFeedURL];
    changedFeed.unreadCountIsValid = NO;
    [self scheduleUnreadCountUpdate];    
}


- (void)articleReadStatusDidChange:(NSNotification *)note {
    if (!rs_app_delegate.appIsShuttingDown)
        [self invalidateUnreadCountForFeedWithArticle:[note object]];
}


- (void)multipleArticleReadStatusDidChange:(NSNotification *)note {
    for (RSDataArticle *oneArticle in [[note userInfo] objectForKey:@"articles"])
        [self invalidateUnreadCountForFeedWithArticle:oneArticle];
}


- (void)refreshDidUpdateFeed:(NSNotification *)note {
    if (rs_app_delegate.appIsShuttingDown)
        return;
    NSString *refreshedAccountID = [[note userInfo] objectForKey:@"account"];
    if (![self.identifier isEqualToString:refreshedAccountID])
        return;
    NSURL *refreshedFeedURL = [[note userInfo] objectForKey:RSURLKey];
    RSFeed *refreshedFeed = [self feedWithURL:refreshedFeedURL];
    if (refreshedFeed != nil) {
        NSNumber *unreadCountNum = [[note userInfo] objectForKey:@"unreadCount"];
        if (unreadCountNum != nil) {
            refreshedFeed.unreadCount = [unreadCountNum unsignedIntegerValue];
            refreshedFeed.unreadCountIsValid = YES;
            [self scheduleTotalUnreadCountUpdate];
        }
        else {
            refreshedFeed.unreadCountIsValid = NO;
            [self scheduleUnreadCountUpdate];
        }            
    }
}


- (void)refreshSessionDidEnd:(NSNotification *)note {
    [self scheduleUnreadCountUpdate];
    [self scheduleTotalUnreadCountUpdate];
}


- (void)feedsSelected:(NSNotification *)note {
    NSArray *selectedFeeds = [[note userInfo] objectForKey:@"feeds"];
    if (RSIsEmpty(selectedFeeds))
        return;
    [self scheduleUnreadCountUpdate];
}

     
- (void)treeDidDeleteItems:(NSNotification *)note {
    [self rebuildFeedsDictionary];
}


- (void)articlesWereDeleted:(NSNotification *)note {
    //[self markAllFeedUnreadCountsAsInvalid];
    [self markAllUnreadCountsAsInvalid];
    [self scheduleTotalUnreadCountUpdate];
}


#pragma mark Account Saving

- (void)saveAccountTimerDidFire:(NSTimer *)aTimer {
    if (self.saveAccountTimer != nil) {
        [self.saveAccountTimer rs_invalidateIfValid];
        self.saveAccountTimer = nil;
    }
    [self saveToDiskInBackgroundIfNeeded];
}


- (void)scheduleSaveAccount {
    if (self.saveAccountTimer != nil) {
        [self.saveAccountTimer rs_invalidateIfValid];
        self.saveAccountTimer = nil;
    }
    self.saveAccountTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(saveAccountTimerDidFire:) userInfo:nil repeats:NO];
}


#pragma mark Accessors

- (void)setNeedsToBeSavedOnDisk:(BOOL)flag { //TODO: not access account on background thread; not run too often.
    if (flag == needsToBeSavedOnDisk)
        return;
    needsToBeSavedOnDisk = flag;
    if (!needsToBeSavedOnDisk)
        return;
    [self scheduleSaveAccount];
//    RSSaveAccountOperation *saveAccountOperation = [[[RSSaveAccountOperation alloc] initWithAccount:self] autorelease];
//    [[RSOperationController sharedController] addOperationIfNotInQueue:saveAccountOperation];
}


#pragma mark RSAccount Protocol

- (BOOL)isSubscribedToFeedWithURL:(NSURL *)aFeedURL {
    return [self feedWithURL:aFeedURL] != nil;
}

        
#pragma mark RSTreeNodeRepresentedObject Protocol

- (NSString *)nameForDisplay {
    if (self == [RSDataAccount localAccount])
        return NSLocalizedString(@"Feeds", @"Local Account Name");
    return self.title;
}


@end
