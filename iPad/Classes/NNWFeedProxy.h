//
//  NNWFeedProxy.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWProxy.h"


extern NSString *NNWTotalUnreadCountDidUpdateNotification;
extern NSString *NNWTotalUnreadCountKey;

@class NNWMostRecentItemSpecifier, NNWFeed, RSParsedGoogleSub;

@interface NNWFeedProxy : NNWProxy {
@private
	NNWMostRecentItemSpecifier *_mostRecentItem;
	BOOL _mostRecentItemIsValid;
	NSString *firstItemMsec;
	NSManagedObjectID *managedObjectID;
	NSURL *managedObjectURI;
	BOOL userExcludes;
}


+ (NNWFeedProxy *)feedProxyWithGoogleID:(NSString *)googleID;
+ (NSArray *)feedProxies;

@property (retain) NNWMostRecentItemSpecifier *mostRecentItem;
@property (assign) BOOL mostRecentItemIsValid;
@property (nonatomic, retain) NSString *firstItemMsec;
@property (nonatomic, retain) NSManagedObjectID *managedObjectID;
@property (nonatomic, retain) NSURL *managedObjectURI;
@property (assign) BOOL userExcludes;

+ (void)createProxiesForFeeds:(NSArray *)feeds;
+ (void)updateUnreadCounts;
- (void)userSetUserExcludes:(BOOL)flag;

	
- (void)updateMostRecentItemInBackground;
- (void)invalidateMostRecentItem;
- (void)updateUnreadCount;
+ (void)invalidateAllUnreadCounts;

- (NNWFeed *)managedObjectInContext:(NSManagedObjectContext *)moc;
- (NNWFeed *)updateWithParsedSubscription:(RSParsedGoogleSub *)parsedSub moc:(NSManagedObjectContext *)moc;

+ (NSString *)titleOfFeedWithGoogleID:(NSString *)googleID;

@end


@interface NNWStarredItemsProxy : NNWFeedProxy
+ (NNWStarredItemsProxy *)proxy;
- (UIImage *)proxyFeedImage;
@end


@interface NNWLatestNewsItemsProxy : NNWFeedProxy
+ (NNWLatestNewsItemsProxy *)proxy;
- (void)updateUnreadCount;
@end
