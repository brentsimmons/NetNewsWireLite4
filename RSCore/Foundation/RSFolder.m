//
//  RSFolder.m
//  nnw
//
//  Created by Brent Simmons on 12/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFolder.h"
#import "RSDataAccount.h"
#import "RSFeed.h"


NSString *RSFolderUnreadCountDidChangeNotification = @"RSFolderUnreadCountDidChangeNotification";


@implementation RSFolder

@synthesize account;
@synthesize name;
@synthesize treeNode;
@synthesize unreadCount;
@synthesize unreadCountIsValid;

#pragma mark Init

- (id)initWithName:(NSString *)aName account:(RSDataAccount *)anAccount {
    self = [super init];
    if (self == nil)
        return nil;
    account = anAccount;
    name = aName;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedUnreadCountDidChange:) name:RSFeedUnreadCountDidChangeNotification object:nil];
    return self;
}


static NSString *RSFolderNameKey = @"name";
static NSString *RSFolderUnreadCountKey = @"unreadCount";

- (id)initWithDiskDictionary:(NSDictionary *)diskDictionary inAccount:(RSDataAccount *)anAccount {
    NSString *aName = [diskDictionary objectForKey:RSFolderNameKey];
    if (RSStringIsEmpty(aName))
        return nil;
    self = [self initWithName:aName account:anAccount];
    if (self == nil)
        return nil;
    NSNumber *unreadCountNum = [diskDictionary objectForKey:RSFolderUnreadCountKey];
    if (unreadCountNum != nil)
        unreadCount = [unreadCountNum unsignedIntegerValue];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    treeNode = nil;
}


#pragma mark Disk Dictionary

- (NSMutableDictionary *)dictionaryRepresentation {

    /*Disk dictionary uses CFMutableDictionaryRef that doesn't copy keys, for better memory use and faster performance.*/
    CFMutableDictionaryRef diskDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 32, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    NSString *aName = self.name;
    if (aName != nil)
        CFDictionarySetValue(diskDictionary, (CFStringRef)RSFolderNameKey, (CFStringRef)aName); //Must use CFDictionarySetValue to avoid key-copying
    CFDictionarySetValue(diskDictionary, (CFStringRef)RSFolderUnreadCountKey, (CFNumberRef)[NSNumber numberWithUnsignedInteger:self.unreadCount]);
    
    return (__bridge_transfer NSMutableDictionary *)diskDictionary;

}


#pragma mark Feeds

- (NSArray *)allDescendantsThatAreFeeds {
    NSMutableArray *flatDescendants = [NSMutableArray array];
    for (RSTreeNode *oneTreeNode in self.treeNode.flatItems) {
        if ([oneTreeNode.representedObject isKindOfClass:[RSFeed class]])
            [flatDescendants addObject:oneTreeNode.representedObject];
    }
    return flatDescendants;
}


#pragma mark Unread Count


- (void)updateUnreadCount {
    NSUInteger anUnreadCount = 0;
    for (RSTreeNode *oneTreeNode in self.treeNode.flatItems)
        anUnreadCount += oneTreeNode.representedObject.countForDisplay;
    if (anUnreadCount != self.unreadCount) {
        self.unreadCount = anUnreadCount;
        [[NSNotificationCenter defaultCenter] postNotificationName:RSFolderUnreadCountDidChangeNotification object:self userInfo:nil];
    }
    self.unreadCountIsValid = YES;
}


- (void)feedUnreadCountDidChange:(NSNotification *)note {
    [self updateUnreadCount];
}


#pragma mark Attributes

- (BOOL)isFolder {
    return YES;
}


#pragma mark RSTreeNodeRepresentedObject

- (BOOL)nameIsEditable {
    return YES;
}


- (NSString *)nameForDisplay {
    return self.name;
}


- (void)setNameForDisplay:(NSString *)aName {
    self.name = aName;
}


- (NSUInteger)countForDisplay {
    return self.unreadCount;
}


- (BOOL)canBeDeleted {
    return YES;
}

@end
