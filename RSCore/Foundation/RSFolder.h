//
//  RSFolder.h
//  nnw
//
//  Created by Brent Simmons on 12/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSTreeNode.h"


extern NSString *RSFolderUnreadCountDidChangeNotification;


@class RSDataAccount;

@interface RSFolder : NSObject <RSTreeNodeRepresentedObject> {
@private
	BOOL unreadCountIsValid;
	NSString *name;
	NSUInteger unreadCount;
	RSDataAccount *account;
	RSTreeNode *treeNode;
}


- (id)initWithName:(NSString *)aName account:(RSDataAccount *)anAccount;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign, readonly) BOOL nameIsEditable;
@property (nonatomic, assign) RSDataAccount *account;
@property (nonatomic, assign, readonly) BOOL isFolder;

@property (nonatomic, assign) NSUInteger unreadCount;
@property (nonatomic, assign) BOOL unreadCountIsValid;

@property (nonatomic, retain, readonly) NSDictionary *dictionaryRepresentation;

@property (nonatomic, assign) RSTreeNode *treeNode; //a given folder can appear only once, so it can have just one treeNode

@property (nonatomic, retain, readonly) NSArray *allDescendantsThatAreFeeds;

- (void)updateUnreadCount;

@end
