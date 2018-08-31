//
//  NNWFeed.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern NSString *NNWFeedHideShowStatusDidChangeNotification;

@class RSParsedGoogleSub;

@interface NNWFeed : NSManagedObject {
}

+ (NNWFeed *)feedWithGoogleID:(NSString *)googleID;
+ (NNWFeed *)existingFeedWithGoogleID:(NSString *)googleID moc:(NSManagedObjectContext *)moc;
+ (NNWFeed *)nonExcludedFeedWithGoogleID:(NSString *)googleID moc:(NSManagedObjectContext *)moc;
+ (BOOL)feedWithGoogleIDIsUserExcluded:(NSString *)googleID;

+ (NSManagedObject *)insertOrUpdateFeedWithGoogleDictionary:(RSParsedGoogleSub *)sub firstItemMMSecDidChange:(BOOL *)firstItemMMSecDidChange managedObjectContext:(NSManagedObjectContext *)moc;

+ (void)deleteFeedsExceptFor:(NSArray *)feeds managedObjectContext:(NSManagedObjectContext *)moc;

+ (NSArray *)allFeedIDs;

+ (void)userSetExcluded:(BOOL)flag forFeedWithGoogleID:(NSString *)googleID;

@property (nonatomic, retain) NSString *firstitemmsec;
@property (nonatomic, retain) NSString *googleID;
@property (nonatomic, retain) NSNumber *serverUnreadCount;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSNumber *userExcludes;
@property (nonatomic, retain) NSSet *folders;

@end

@interface NNWFeed (PrimitiveAccessors)
- (NSString *)primitiveFirstitemmsec;
- (void)setPrimitiveFirstitemmsec:(NSString *)timestamp;
- (NSString *)primitiveGoogleID;
- (void)setPrimitiveGoogleID:(NSString *)aGoogleID;
- (NSNumber *)primitiveServerUnreadCount;
- (void)setPrimitiveServerUnreadCount:(NSNumber *)anUnreadCount;
- (NSString *)primitiveTitle;
- (void)setPrimitiveTitle:(NSString *)aTitle;
- (NSNumber *)primitiveUserExcludes;
- (void)setPrimitiveUserExcludes:(NSNumber *)userExcludes;
- (NSSet *)primitiveFolders;
- (void)setPrimitiveFolders:(NSSet *)setOfFolders;
@end
