//
//  RSFeed.h
//  padlynx
//
//  Created by Brent Simmons on 10/13/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSRefreshProtocols.h"
#import "RSTreeNode.h"


extern NSString *RSFeedUnreadCountDidChangeNotification;

@class RSDataAccount;


@interface RSFeed : NSObject <RSTreeNodeRepresentedObject> {
@private
	NSURL *URL;
	RSDataAccount *account;
	NSString *feedSpecifiedName;
	NSURL *homePageURL;
	NSURL *faviconURL;

	NSString *userSpecifiedName;
	
	NSString *username;
	NSString *password;

	UInt64 serviceOldestTrackedItemTimestamp;

	NSInteger daysToPersistArticles;
	NSInteger sortKey;
	NSUInteger unreadCount;

	struct {
		unsigned int sortDescending:1;
        unsigned int excludeFromDisplay:1;
        unsigned int persistArticles:1;
        unsigned int suspended:1;
		unsigned int deleted:1;
		unsigned int needsToBeSavedOnDisk:1;
		unsigned int unreadCountIsValid:1;
		unsigned int padding:1;
    } feedFlags;
}


/*All access to feeds must be locked. For read-only, thread-safe objects, use NSURLs.*/

+ (RSFeed *)feedWithURL:(NSURL *)aURL account:(RSDataAccount *)anAccount;

- (id)initWithDiskDictionary:(NSDictionary *)diskDictionary inAccount:(RSDataAccount *)anAccount;

- (void)markAsNeedsToBeSaved; //if any changes are made, must be done, so that it gets saved; call right before unlockFeeds
- (NSDictionary *)dictionaryRepresentation;

@property (nonatomic, retain) NSURL *URL;

@property (nonatomic, retain) NSURL *homePageURL;
@property (nonatomic, retain) NSURL *faviconURL;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, assign) BOOL deleted;

@property (nonatomic, assign, readonly) BOOL suspended;
@property (nonatomic, assign, readonly) BOOL excludeFromDisplay;
@property (nonatomic, assign, readonly) BOOL canBeRefreshed; //not suspended, not deleted, not excluded from display
@property (nonatomic, retain) NSString *userSpecifiedName;
@property (nonatomic, retain) NSString *feedSpecifiedName;

@property (nonatomic, assign) BOOL needsToBeSavedOnDisk;

@property (nonatomic, assign, readonly) UInt64 serviceOldestTrackedItemTimestamp;
@property (nonatomic, assign, readonly) NSInteger daysToPersistArticles;

@property (nonatomic, assign, readonly) NSInteger sortKey;

@property (nonatomic, assign) RSDataAccount *account;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign, readonly) BOOL nameIsEditable;
@property (nonatomic, assign, readonly) BOOL isSection;
@property (nonatomic, assign, readonly) BOOL isFolder;

@property (nonatomic, assign) NSUInteger unreadCount;
@property (nonatomic, assign) BOOL unreadCountIsValid;

- (CGImageRef)icon;

- (void)savePasswordInKeychain;

@end
