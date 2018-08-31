//
//  RSDataController.m
//  RSCoreTests
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataController.h"
#import "RSArticleListController.h"
#import "RSCoreDataStack.h"
#import "RSCoreDataUtilities.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSGlobalAccount.h"
#import "RSRefreshProtocols.h"


NSString *RSFeedsAndFoldersDidReorganizeNotification = @"RSFeedsAndFoldersDidReorganizeNotification";

NSString *RSCoreDataModelResourceName = @"RSData";
NSString *RSCoreDataStoreFileName = @"Articles";


@interface RSDataController ()

@property (nonatomic, assign, readwrite) NSUInteger unreadCount;
@property (nonatomic, retain) NSMutableArray *accounts;
@property (nonatomic, retain) NSMutableDictionary *listControllers;
@property (nonatomic, retain) NSTimer *saveTimer;
@property (nonatomic, retain, readonly) NSOperationQueue *coreDataBackgroundOperationQueue;
@property (nonatomic, retain, readonly) RSCoreDataStack *coreDataStack;
@property (nonatomic, retain, readwrite) RSGlobalAccount *globalAccount;

- (void)updateUnreadCount;

@end


@implementation RSDataController

@synthesize accounts;
@synthesize coreDataBackgroundOperationQueue;
@synthesize coreDataStack;
@synthesize currentArticles;
@synthesize currentListController;
@synthesize globalAccount;
@synthesize listControllers;
@synthesize localAccount;
@synthesize managedObjectContextIsDirty;
@synthesize saveTimer;
@synthesize unreadCount;


#pragma mark Init

- (id)initWithModelResourceName:(NSString *)modelResourceName storeFileName:(NSString *)storeFileName {
	self = [super init];
	if (self == nil)
		return nil;
	listControllers = [[NSMutableDictionary dictionary] retain];
	RSCoreDataUtilitiesStartup();
	coreDataStack = [[RSCoreDataStack alloc] initWithModelResourceName:modelResourceName storeFileName:storeFileName];
	coreDataBackgroundOperationQueue = [[NSOperationQueue alloc] init];
	[coreDataBackgroundOperationQueue setMaxConcurrentOperationCount:1]; //Just 1? Scared?	
	accounts = [[NSMutableArray array] retain];
	localAccount = [[RSDataAccount localAccount] retain];
	[localAccount addObserver:self forKeyPath:@"unreadCount" options:0 context:nil];
	self.unreadCount = localAccount.unreadCount;
	globalAccount = [[RSGlobalAccount globalAccount] retain];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleDidChange:) name:RSDataArticleReadStatusDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleDidChange:) name:RSMultipleArticlesDidChangeReadStatusNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[saveTimer rs_invalidateIfValid];
	[saveTimer release];
	[coreDataBackgroundOperationQueue cancelAllOperations];
	[coreDataBackgroundOperationQueue release];
	[coreDataStack release];
	[accounts release];
	[localAccount release];
	[globalAccount release];
	[listControllers release];
	[currentListController release];
	[currentArticles release];
	[super dealloc];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"unreadCount"])
		[self updateUnreadCount];
}


#pragma mark Unread Count

- (void)updateUnreadCount {
	NSUInteger anUnreadCount = 0;
	anUnreadCount += self.localAccount.unreadCount;
	for (id<RSAccount> oneAccount in self.accounts)
		anUnreadCount += oneAccount.unreadCount;
	self.unreadCount = anUnreadCount;
}


- (void)updateAllUnreadCountsOnMainThread {
	[[RSDataAccount localAccount] updateUnreadCountsOnMainThread];
	for (id<RSAccount> oneAccount in self.accounts) {
		if ([oneAccount respondsToSelector:@selector(updateUnreadCountsOnMainThread)])
			[(RSDataAccount *)oneAccount updateUnreadCountsOnMainThread];
	}
	[self updateUnreadCount];
}


#pragma mark Accounts

- (id<RSAccount>)accountWithID:(NSString *)anAccountID {
	if ([[RSDataAccount localAccount].identifier isEqualToString:anAccountID])
		return [RSDataAccount localAccount];
	for (id<RSAccount> oneAccount in self.accounts) {
		if ([oneAccount.identifier isEqualToString:anAccountID])
			return oneAccount;
	}
	return nil;
}


- (void)makeAllAccountsDirty {
	[RSDataAccount localAccount].needsToBeSavedOnDisk = YES;
	for (id<RSAccount> oneAccount in self.accounts) {
		if ([oneAccount respondsToSelector:@selector(setNeedsToBeSavedOnDisk:)])
			((RSDataAccount *)oneAccount).needsToBeSavedOnDisk = YES;
	}
}


- (void)saveAllAccounts {
	[[RSDataAccount localAccount] saveToDiskAtShutdown];
	for (id<RSAccount> oneAccount in self.accounts) {
		if ([oneAccount respondsToSelector:@selector(saveToDiskAtShutdown:)])
			[(RSDataAccount *)oneAccount saveToDiskAtShutdown];
	}
}


- (void)markAllUnreadCountsAsInvalid {
	[[RSDataAccount localAccount] markAllUnreadCountsAsInvalid];
	for (id<RSAccount> oneAccount in self.accounts) {
		if ([oneAccount respondsToSelector:@selector(markAllUnreadCountsAsInvalid)])
			[(RSDataAccount *)oneAccount markAllUnreadCountsAsInvalid];
	}
}


#pragma mark Feeds

- (BOOL)anyAccountIsSubscribedToFeedWithURL:(NSURL *)aFeedURL {
	if ([[RSDataAccount localAccount] isSubscribedToFeedWithURL:aFeedURL])
		return YES;
	for (id<RSAccount> oneAccount in self.accounts) {
		if ([oneAccount isSubscribedToFeedWithURL:aFeedURL])
			return YES;
	}
	return NO;
}


#pragma mark Operations

- (NSManagedObjectContext *)temporaryManagedObjectContext {
	NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
	[moc setPersistentStoreCoordinator:self.coreDataStack.persistentStoreCoordinator];
	[moc setUndoManager:nil];
	[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	return moc;
}


- (void)addCoreDataBackgroundOperation:(NSOperation *)coreDataBackgroundOperation {
//	NSLog(@"ops: %d", (int)[self.coreDataBackgroundOperationQueue operationCount]);
	if (rs_app_delegate.appIsShuttingDown)
		return;
	[self.coreDataBackgroundOperationQueue addOperation:coreDataBackgroundOperation];
}


- (void)cancelCoreDataBackgroundOperations {
	[self.coreDataBackgroundOperationQueue cancelAllOperations];
}


- (void)waitUntilCoreDataBackgroundOperationsAreFinished {
	[self.coreDataBackgroundOperationQueue waitUntilAllOperationsAreFinished];
}


#pragma mark List Controllers

- (void)setListController:(id)aListController forKey:(NSString *)aKey {
	[self.listControllers setObject:aListController forKey:aKey];
}


#pragma mark Managed Object Context Saving

- (void)saveManagedObjectContext:(NSManagedObjectContext *)moc {
	RSSaveManagedObjectContext(moc);
}


- (void)saveMainThreadManagedObjectContext {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(saveMainThreadManagedObjectContext) withObject:nil waitUntilDone:NO];
		return;
	}
	[self saveManagedObjectContext:self.coreDataStack.mainThreadManagedObjectContext];
}


- (void)saveTimerDidFire {
	[self.saveTimer rs_invalidateIfValid];
	self.saveTimer = nil;
	self.managedObjectContextIsDirty = NO;
	[self saveMainThreadManagedObjectContext];
}


- (void)scheduleSave {
	if (self.saveTimer != nil) {
		[self.saveTimer rs_invalidateIfValid];
		self.saveTimer = nil;
	}
	self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(saveTimerDidFire) userInfo:nil repeats:NO];
}


- (void)setManagedObjectContextIsDirty:(BOOL)isDirty {
	if (isDirty)
		[self scheduleSave];
	managedObjectContextIsDirty = isDirty;
}


#pragma mark Notifications

- (void)articleDidChange:(NSNotification *)note {
	self.managedObjectContextIsDirty = YES;
}


#pragma mark Main Thread Managed Object Context

- (NSManagedObjectContext *)mainThreadManagedObjectContext {
	if (![NSThread isMainThread]) {
		NSLog(@"managedObjectContext referenced not on main thread!");
		return nil;		
	}
	return self.coreDataStack.mainThreadManagedObjectContext;
}


@end
