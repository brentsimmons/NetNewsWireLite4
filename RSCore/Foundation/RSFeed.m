//
//  RSFeed.m
//  padlynx
//
//  Created by Brent Simmons on 10/13/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeed.h"
#import "RSDataAccount.h"
#import "RSFaviconController.h"
#import "RSKeychain.h"


NSString *RSFeedUnreadCountDidChangeNotification = @"RSFeedUnreadCountDidChangeNotification";

@interface RSFeed ()

@property (nonatomic, assign, readwrite) UInt64 serviceOldestTrackedItemTimestamp;
@property (nonatomic, assign, readwrite) NSInteger daysToPersistArticles;
@property (nonatomic, assign, readwrite) NSInteger sortKey;

- (id)initWithAccount:(id<RSAccount>)anAccount;

@end


@implementation RSFeed

@synthesize URL;
@synthesize account;
@synthesize daysToPersistArticles;
@synthesize faviconURL;
@synthesize feedSpecifiedName;
@synthesize homePageURL;
@synthesize password;
@synthesize serviceOldestTrackedItemTimestamp;
@synthesize sortKey;
@synthesize userSpecifiedName;
@synthesize username;
@synthesize unreadCount;
@synthesize nameForDisplay;


#pragma mark Class Methods - Creating

+ (RSFeed *)feedWithURL:(NSURL *)aURL account:(id<RSAccount>)anAccount {
	RSFeed *feed = [[[self alloc] initWithAccount:anAccount] autorelease];
	feed.URL = aURL;
	return feed;
}


#pragma mark Init

- (id)initWithAccount:(id<RSAccount>)anAccount {
	self = [super init];
	if (self == nil)
		return nil;
	account = anAccount;
	return self;
}


static NSString *RSFeedArchiveArticlesAsHTMLKey = @"archiveArticlesAsHTML";
static NSString *RSFeedDaysToPersistArticlesKey = @"persistDays";
static NSString *RSFeedDeletedKey = @"deleted";
static NSString *RSFeedExcludeFromDisplayKey = @"excludeFromDisplay";
static NSString *RSFeedFaviconURLKey = @"faviconURL";
static NSString *RSFeedHomePageURLKey = @"homePageURL";
static NSString *RSFeedPersistArticlesKey = @"persistArticles";
static NSString *RSFeedServiceOldestTrackedItemTimestampKey = @"serviceOldestTrackedItemTimestamp";
static NSString *RSFeedSortDescendingKey = @"sortDescending";
static NSString *RSFeedSortKey = @"sortKey";
static NSString *RSFeedSpecifiedNameKey = @"feedSpecifiedName";
static NSString *RSFeedSuspendedKey = @"suspended";
static NSString *RSFeedURLKey = @"URL";
static NSString *RSFeedUserSpecifiedNameKey = @"userSpecifiedName";
static NSString *RSFeedUsernameKey = @"username";
static NSString *RSFeedUnreadCountKey = @"unreadCount";
static NSString *RSFeedUnreadCountIsValidKey = @"unreadCountIsValid";


- (id)initWithDiskDictionary:(NSDictionary *)diskDictionary inAccount:(id<RSAccount>)anAccount {
	
	self = [self initWithAccount:anAccount];
	if (self == nil)
		return nil;
	
	NSString *urlString = [diskDictionary objectForKey:RSFeedURLKey];
	if (!RSStringIsEmpty(urlString))
		URL = [[NSURL URLWithString:urlString] retain];
	feedSpecifiedName = [[diskDictionary objectForKey:RSFeedSpecifiedNameKey] retain];
	urlString = [diskDictionary objectForKey:RSFeedHomePageURLKey];
	if (!RSStringIsEmpty(urlString))
		homePageURL = [[NSURL URLWithString:urlString] retain];
	urlString = [diskDictionary objectForKey:RSFeedFaviconURLKey];
	if (!RSStringIsEmpty(urlString))
		faviconURL = [[NSURL URLWithString:urlString] retain];
	
	userSpecifiedName = [[diskDictionary objectForKey:RSFeedUserSpecifiedNameKey] retain];
	feedSpecifiedName = [[diskDictionary objectForKey:RSFeedSpecifiedNameKey] retain];
	username = [[diskDictionary objectForKey:RSFeedUsernameKey] retain];

	serviceOldestTrackedItemTimestamp = [[diskDictionary objectForKey:RSFeedServiceOldestTrackedItemTimestampKey] unsignedLongLongValue];
	daysToPersistArticles = [diskDictionary rs_integerForKey:RSFeedDaysToPersistArticlesKey];

	sortKey = [diskDictionary rs_integerForKey:RSFeedSortKey];
	
	feedFlags.sortDescending = (unsigned int)[diskDictionary rs_boolForKey:RSFeedSortDescendingKey];

	feedFlags.excludeFromDisplay = (unsigned int)[diskDictionary rs_boolForKey:RSFeedExcludeFromDisplayKey];

	feedFlags.persistArticles = (unsigned int)[diskDictionary rs_boolForKey:RSFeedPersistArticlesKey];
	feedFlags.suspended = (unsigned int)[diskDictionary rs_boolForKey:RSFeedSuspendedKey];
	feedFlags.deleted = (unsigned int)[diskDictionary rs_boolForKey:RSFeedDeletedKey];
	
	unreadCount = [[diskDictionary objectForKey:RSFeedUnreadCountKey] unsignedIntegerValue];
	feedFlags.unreadCountIsValid = (unsigned int)[diskDictionary rs_boolForKey:RSFeedUnreadCountIsValidKey];
	
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[URL release];
	account = nil;
	[feedSpecifiedName release];
	[homePageURL release];
	[faviconURL release];
	[userSpecifiedName release];
	[username release];
	[password release];
	[super dealloc];
}


#pragma mark Disk Dictionary

- (NSDictionary *)dictionaryRepresentation {
	
	/*Disk dictionary uses CFMutableDictionaryRef that doesn't copy keys, for better memory use and faster performance.*/
	CFMutableDictionaryRef diskDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 32, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	NSString *urlString = [self.URL absoluteString];
	if (urlString != nil)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedURLKey, (CFStringRef)urlString); //Must use CFDictionarySetValue to avoid key-copying
	urlString = [self.homePageURL absoluteString];
	if (urlString != nil)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedHomePageURLKey, (CFStringRef)urlString);
	urlString = [self.faviconURL absoluteString];
	if (urlString != nil)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedFaviconURLKey, (CFStringRef)urlString);
	
	if (self.feedSpecifiedName != nil)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedSpecifiedNameKey, (CFStringRef)(self.feedSpecifiedName));
	if (self.userSpecifiedName != nil)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedUserSpecifiedNameKey, (CFStringRef)(self.userSpecifiedName));
	
	if (self.username != nil)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedUsernameKey, (CFStringRef)(self.username));

	if (self.serviceOldestTrackedItemTimestamp > 0)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedServiceOldestTrackedItemTimestampKey, (CFNumberRef)([NSNumber numberWithUnsignedLongLong:self.serviceOldestTrackedItemTimestamp]));
	
	if (self.daysToPersistArticles > 0)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedDaysToPersistArticlesKey, (CFNumberRef)([NSNumber numberWithInteger:self.daysToPersistArticles]));
	if (self.sortKey != 0)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedSortKey, (CFNumberRef)([NSNumber numberWithInteger:self.sortKey]));
	
	if (feedFlags.sortDescending)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedSortDescendingKey, kCFBooleanTrue);

	if (feedFlags.excludeFromDisplay)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedExcludeFromDisplayKey, kCFBooleanTrue);

	if (feedFlags.persistArticles)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedPersistArticlesKey, kCFBooleanTrue);

	if (feedFlags.suspended)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedSuspendedKey, kCFBooleanTrue);
	if (feedFlags.deleted)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedDeletedKey, kCFBooleanTrue);
	
	if (self.unreadCount > 0)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedUnreadCountKey, (CFNumberRef)([NSNumber numberWithUnsignedInteger:self.unreadCount]));
	if (self.unreadCountIsValid)
		CFDictionarySetValue(diskDictionary, (CFStringRef)RSFeedUnreadCountIsValidKey, (CFNumberRef)([NSNumber numberWithBool:self.unreadCountIsValid]));
		
	return [NSMakeCollectable(diskDictionary) autorelease];
}


#pragma mark Saving

- (void)markAsNeedsToBeSaved {
	self.needsToBeSavedOnDisk = YES;
}


#pragma mark Accessors

- (BOOL)suspended {
	return feedFlags.suspended;
}


- (BOOL)deleted {
	return feedFlags.deleted;
}


- (void)setDeleted:(BOOL)flag {
	feedFlags.deleted = (unsigned int)flag;
}


- (BOOL)excludeFromDisplay {
	return feedFlags.excludeFromDisplay;
}


- (BOOL)canBeRefreshed {
	return !self.suspended && !self.deleted && !self.excludeFromDisplay;
}


- (BOOL)needsToBeSavedOnDisk {
	return feedFlags.needsToBeSavedOnDisk;
}

- (void)setNeedsToBeSavedOnDisk:(BOOL)flag {
	feedFlags.needsToBeSavedOnDisk = (unsigned int)flag;
	if (flag)
		self.account.needsToBeSavedOnDisk = YES;
}


- (BOOL)unreadCountIsValid {
	return feedFlags.unreadCountIsValid;
}


- (void)setUnreadCountIsValid:(BOOL)flag {
	feedFlags.unreadCountIsValid = (unsigned int)flag;
}


- (CGImageRef)icon {
	return nil;
}


- (BOOL)isSection {
	return NO;
}


- (BOOL)isFolder {
	return NO;
}


- (NSString *)name {
	NSString *aName = self.userSpecifiedName;
	if (RSStringIsEmpty(aName))
		aName = self.feedSpecifiedName;
	if (RSStringIsEmpty(aName))
		aName = NSLocalizedString(@"Untitled Feed", @"Feeds");
	return aName;
}


- (void)setName:(NSString *)aName {
	/*User-edited name*/
	self.userSpecifiedName = aName;
}


- (void)setUnreadCount:(NSUInteger)anUnreadCount {
	if (anUnreadCount == unreadCount)
		return;
	unreadCount = anUnreadCount;
	[[NSNotificationCenter defaultCenter] postNotificationName:RSFeedUnreadCountDidChangeNotification object:self userInfo:nil];
}


#pragma mark RSTreeNodeRepresentedObject

- (BOOL)nameIsEditable {
	return YES;
}


- (BOOL)canBeDeleted {
	return YES;
}


- (NSString *)nameForDisplay {
	NSString *aNameForDisplay = self.userSpecifiedName;
	if (RSStringIsEmpty(aNameForDisplay))
		aNameForDisplay = self.feedSpecifiedName;
	return aNameForDisplay;
}


- (void)setNameForDisplay:(NSString *)aName {
	self.userSpecifiedName = aName;
}


- (NSUInteger)countForDisplay {
	return self.unreadCount;
}


- (NSURL *)associatedURL {
	return self.homePageURL;
}


#pragma mark Keychain

- (NSString *)password {
	if (password != nil)
		return password;
	if (self.username != nil)
		self.password = RSKeychainFetchInternetPassword(self.URL, self.username);
	return password;
}


- (void)savePasswordInKeychain {
	RSKeychainStoreInternetPassword(self.URL, self.username, self.password);
}


@end

