//
//  RSGlobalAccount.m
//  nnw
//
//  Created by Brent Simmons on 1/18/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSGlobalAccount.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSGlobalFeed.h"
#import "RSRefreshController.h"
#import "RSTodayFeedCountUnreadOperation.h"
#import "RSTreeNode.h"


NSString *RSTodayUnreadCountKey = @"todayUnreadCount";

@interface RSGlobalAccount ()

@property (nonatomic, retain) NSTimer *todayUnreadCountTimer;
@property (nonatomic, retain) RSGlobalFeed *allUnreadFeed;
@property (nonatomic, retain) RSGlobalFeed *todayFeed;

- (void)scheduleUpdateForTodayUnreadCount;

@end


@implementation RSGlobalAccount

@synthesize allUnreadFeed;
@synthesize childTreeNodes;
@synthesize todayFeed;
@synthesize todayUnreadCountTimer;


#pragma mark Class Methods

+ (RSGlobalAccount *)globalAccount {
	static id gMyInstance = nil;
	if (gMyInstance == nil)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	
	allUnreadFeed = [[RSGlobalFeed alloc] init];
	allUnreadFeed.globalFeedType = RSGlobalFeedTypeAllUnread;
	allUnreadFeed.nameForDisplay = NSLocalizedString(@"All Unread", @"Feed name");
	
	todayFeed = [[RSGlobalFeed alloc] init];
	todayFeed.globalFeedType = RSGlobalFeedTypeToday;
	todayFeed.nameForDisplay = NSLocalizedString(@"Today", @"Feed name");
	
	accountTreeNode = [[RSTreeNode treeNodeWithParent:nil representedObject:self] retain];
	RSTreeNode *allUnreadTreeNode = [RSTreeNode treeNodeWithParent:accountTreeNode representedObject:allUnreadFeed];
	allUnreadTreeNode.allowsDragging = NO;
	RSTreeNode *todayTreeNode = [RSTreeNode treeNodeWithParent:accountTreeNode representedObject:todayFeed];
	todayTreeNode.allowsDragging = NO;
	childTreeNodes = [[NSArray arrayWithObjects:allUnreadTreeNode, todayTreeNode, nil] retain];
	
	[self performSelectorOnMainThread:@selector(setupObserving) withObject:nil waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(restoreUnreadCounts) withObject:nil waitUntilDone:NO];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleReadStatusDidChange:) name:RSDataArticleReadStatusDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleUpdateForTodayUnreadCount) name:RSRefreshSessionDidEndNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleUpdateForTodayUnreadCount) name:RSDataDidDeleteArticlesNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleUpdateForTodayUnreadCount) name:RSMultipleArticlesDidChangeReadStatusNotification object:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[todayUnreadCountTimer rs_invalidateIfValid];
	[todayUnreadCountTimer release];
	[[RSDataAccount localAccount] removeObserver:self forKeyPath:@"unreadCount"];
	[allUnreadFeed release];
	[childTreeNodes release];
	[todayFeed release];
	[super dealloc];
}


#pragma mark KVO

- (void)setupObserving {
	[[RSDataAccount localAccount] addObserver:self forKeyPath:@"unreadCount" options:0 context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"unreadCount"])
		self.allUnreadFeed.unreadCount = ((RSDataAccount *)(object)).unreadCount;
}


#pragma mark Notifications

- (void)articleReadStatusDidChange:(NSNotification *)note {
	/*Need to update today unread count?*/
	RSDataArticle *changedArticle = [note object];
	if (changedArticle == nil)
		return;
	NSDate *articleDate = changedArticle.dateForDisplay;
	if ([articleDate earlierDate:[[RSDateManager sharedManager] firstSecondOfToday]] == articleDate)
		return;
	[self scheduleUpdateForTodayUnreadCount];
}


#pragma mark Today Unread Count

- (void)restoreUnreadCounts {
	NSNumber *todayUnreadCountNum = [[NSUserDefaults standardUserDefaults] objectForKey:RSTodayUnreadCountKey];
	if (todayUnreadCountNum != nil)
		self.todayFeed.unreadCount = [todayUnreadCountNum unsignedIntegerValue];
	[self scheduleUpdateForTodayUnreadCount];
}


- (void)feedCountUnreadOperationDidComplete:(RSTodayFeedCountUnreadOperation *)countUnreadOperation {
	if (rs_app_delegate.appIsShuttingDown)
		return;
	self.todayFeed.unreadCount = countUnreadOperation.unreadCount;
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:countUnreadOperation.unreadCount] forKey:RSTodayUnreadCountKey];
}


- (void)updateTodayUnreadCount:(NSTimer *)aTimer {
	[self.todayUnreadCountTimer rs_invalidateIfValid];
	self.todayUnreadCountTimer = nil;
	if (rs_app_delegate.appIsShuttingDown)
		return;
	RSTodayFeedCountUnreadOperation *countUnreadOperation = [[[RSTodayFeedCountUnreadOperation alloc] initWithAccountID:[RSDataAccount localAccount].identifier delegate:self callbackSelector:@selector(feedCountUnreadOperationDidComplete:)] autorelease];
	[countUnreadOperation setQueuePriority:NSOperationQueuePriorityLow];
	countUnreadOperation.operationType = RSOperationTypeUpdateUnreadCount;
	countUnreadOperation.operationObject = @"today";
	[[RSOperationController sharedController] addOperation:countUnreadOperation];	
}


- (void)scheduleUpdateForTodayUnreadCount {
	if (rs_app_delegate.appIsShuttingDown)
		return;
	[self.todayUnreadCountTimer rs_invalidateIfValid];
	self.todayUnreadCountTimer = nil;
	self.todayUnreadCountTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateTodayUnreadCount:) userInfo:nil repeats:NO];
}


#pragma mark -
#pragma mark RSAccount Protocol

- (BOOL)disabled {
	return NO;
}


- (void)setDisabled:(BOOL)flag {
	;
}


- (NSString *)identifier {
	return @"global";
}


- (NSString *)login {
	return nil;
}


- (void)setLogin:(NSString *)aLogin {
	;
}


- (NSString *)title {
	return @"Global"; //never gets displayed: don't need to localize
}


- (NSInteger)accountType {
	return RSAccountTypeGlobal;
}


- (NSArray *)allFeedsThatCanBeRefreshed {
	return nil;
}


- (NSUInteger)unreadCount {
	return 0;
}


- (BOOL)isSubscribedToFeedWithURL:(NSURL *)aFeedURL {
	return NO;
}


#pragma mark RSTreeNodeRepresentedObject

- (NSString *)nameForDisplay {
	return self.title;
}


- (void)setNameForDisplay:(NSString *)aName; {
	;
}
@end
